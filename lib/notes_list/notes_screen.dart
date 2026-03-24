import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mytiny_diary/data/note_repository.dart';
import 'package:mytiny_diary/models/note.dart';
import 'package:mytiny_diary/note_create/create_note_screen.dart';
import 'package:mytiny_diary/note_detail/note_detail_screen.dart';
import 'package:mytiny_diary/theme/sanctuary_theme.dart';
import 'package:mytiny_diary/theme/neu_widgets.dart';

final notesFutureProvider = FutureProvider<List<Note>>((ref) async {
  return NoteRepository.instance.getAll();
});

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  String _moodEmoji(int mood) {
    switch (mood) {
      case 0:
        return '😊';
      case 1:
        return '😞';
      case 2:
        return '😠';
      default:
        return '😐';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesFutureProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('MyTinyDiary')),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 64,
                    color: SanctuaryColors.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  const SizedBox(height: SanctuarySpacing.lg),
                  Text(
                    'No notes yet',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: SanctuaryColors.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: SanctuarySpacing.sm),
                  Text(
                    'Tap + to create your first entry',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: SanctuaryColors.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: SanctuarySpacing.xl,
              vertical: SanctuarySpacing.xl,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: SanctuarySpacing.lg),
                child: NeuCard(
                  padding: EdgeInsets.zero,
                  borderRadius: SanctuaryRadius.lg,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoteDetailScreen(note: note),
                      ),
                    );
                    ref.invalidate(notesFutureProvider);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Photo thumbnail (async existence check via FutureBuilder)
                      if (note.photo != null && note.photo!.isNotEmpty)
                        FutureBuilder<bool>(
                          future: File(note.photo!).exists(),
                          builder: (context, snap) {
                            if (snap.data != true) {
                              return const SizedBox.shrink();
                            }
                            return ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(SanctuaryRadius.lg),
                                topRight: Radius.circular(SanctuaryRadius.lg),
                              ),
                              child: Image.file(
                                File(note.photo!),
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                cacheWidth: 600,
                              ),
                            );
                          },
                        ),
                      // Card content
                      Padding(
                        padding: const EdgeInsets.all(SanctuarySpacing.xl),
                        child: Row(
                          children: [
                            // Mood emoji in a recessed circle
                            NeuWell(
                              padding: const EdgeInsets.all(
                                SanctuarySpacing.md,
                              ),
                              borderRadius: SanctuaryRadius.full,
                              child: Text(
                                _moodEmoji(note.mood),
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: SanctuarySpacing.lg),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.text.isEmpty ? '(No text)' : note.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  if ((note.location ?? '').isNotEmpty) ...[
                                    const SizedBox(height: SanctuarySpacing.xs),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: SanctuaryColors
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            note.location!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: SanctuarySpacing.sm),
                            // Date
                            Text(
                              note.createdAt
                                  .toLocal()
                                  .toIso8601String()
                                  .substring(5, 10), // MM-DD
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: GlassFab(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateNoteScreen()),
          );
          ref.invalidate(notesFutureProvider);
        },
      ),
    );
  }
}
