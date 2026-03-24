import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mytiny_diary/note_create/create_note_provider.dart';
import 'package:mytiny_diary/models/note.dart';
import 'package:mytiny_diary/theme/sanctuary_theme.dart';
import 'package:mytiny_diary/theme/neu_widgets.dart';
import 'dart:io';

class CreateNoteScreen extends ConsumerStatefulWidget {
  final Note? existingNote;
  const CreateNoteScreen({super.key, this.existingNote});

  @override
  ConsumerState<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends ConsumerState<CreateNoteScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      // Load synchronously via ref.read — safe in initState for writes.
      // This ensures audioPath/photo/mood are in state before the first build.
      ref.read(createNoteProvider.notifier).loadExistingNote(widget.existingNote!);
    }
  }

  Color _moodBackground(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return SanctuaryColors.moodHappy;
      case Mood.sad:
        return SanctuaryColors.moodSad;
      case Mood.angry:
        return SanctuaryColors.moodAngry;
      case Mood.neutral:
        return SanctuaryColors.surface;
    }
  }

  String _moodEmoji(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return '😊';
      case Mood.sad:
        return '😞';
      case Mood.angry:
        return '😠';
      case Mood.neutral:
        return '😐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createNoteProvider);
    final notifier = ref.read(createNoteProvider.notifier);
    final theme = Theme.of(context);
    final isDownloading = (state.downloadProgress ?? 0) > 0;
    final isBusy = state.isTranscribing || isDownloading;
    final isEditing = widget.existingNote != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Note' : 'Create Note')),
      backgroundColor: _moodBackground(state.selectedMood),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SanctuarySpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Recording hero area ──
            NeuCard(
              color: SanctuaryColors.surfaceContainerLow.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(
                horizontal: SanctuarySpacing.xl,
                vertical: SanctuarySpacing.xxl,
              ),
              borderRadius: SanctuaryRadius.xxl,
              child: Column(
                children: [
                  // Recording indicator
                  if (state.isRecording)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: SanctuarySpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: SanctuaryColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: SanctuarySpacing.sm),
                          Text(
                            'Recording…',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: SanctuaryColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Transcription text preview
                  Text(
                    state.transcribedText.isEmpty
                        ? 'Tap the mic and speak…'
                        : state.transcribedText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: state.transcribedText.isEmpty
                          ? SanctuaryColors.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            )
                          : SanctuaryColors.onSurface,
                      height: 1.6,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (state.transcriptionError != null) ...[
                    const SizedBox(height: SanctuarySpacing.md),
                    Text(
                      state.transcriptionError!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: SanctuaryColors.error,
                      ),
                    ),
                  ],

                  // Download progress
                  if (isDownloading) ...[
                    const SizedBox(height: SanctuarySpacing.lg),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(SanctuaryRadius.full),
                      child: LinearProgressIndicator(
                        value: (state.downloadProgress ?? 0).clamp(0.0, 1.0),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: SanctuarySpacing.xs),
                    Text(
                      'Downloading speech model… ${((state.downloadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],

                  const SizedBox(height: SanctuarySpacing.xl),

                  // Mic button – large, neumorphic
                  NeuButton(
                    enabled: !isBusy,
                    color: state.isRecording
                        ? SanctuaryColors.error.withValues(alpha: 0.15)
                        : SanctuaryColors.primaryContainer,
                    borderRadius: SanctuaryRadius.full,
                    padding: const EdgeInsets.all(SanctuarySpacing.xl),
                    onPressed: () async {
                      if (state.isRecording) {
                        await notifier.stopRecordingAndTranscribe();
                      } else {
                        await notifier.startRecording();
                      }
                    },
                    child: state.isTranscribing
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: SanctuaryColors.primary,
                            ),
                          )
                        : isDownloading
                        ? const Icon(Icons.cloud_download_rounded, size: 28)
                        : Icon(
                            state.isRecording
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            size: 28,
                            color: state.isRecording
                                ? SanctuaryColors.error
                                : SanctuaryColors.onPrimaryContainer,
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: SanctuarySpacing.xxl),

            // ── Location ──
            NeuButton(
              expanded: true,
              onPressed: notifier.refreshLocation,
              color: SanctuaryColors.surfaceContainerLow,
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 20),
                  const SizedBox(width: SanctuarySpacing.md),
                  Expanded(
                    child: Text(
                      state.location,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: SanctuaryColors.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: SanctuarySpacing.lg),

            // ── Photo ──
            NeuButton(
              expanded: true,
              onPressed: () async => notifier.pickImage(),
              color: SanctuaryColors.surfaceContainerLow,
              child: Row(
                children: [
                  const Icon(Icons.photo_library_rounded, size: 20),
                  const SizedBox(width: SanctuarySpacing.md),
                  Text(
                    state.imageFile != null ? 'Change Photo' : 'Add Photo',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (state.imageFile != null) ...[
              const SizedBox(height: SanctuarySpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(SanctuaryRadius.lg),
                child: Image.file(
                  File(state.imageFile!.path),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ] else if (state.existingPhotoPath != null && state.existingPhotoPath!.isNotEmpty) ...[
              const SizedBox(height: SanctuarySpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(SanctuaryRadius.lg),
                child: Image.file(
                  File(state.existingPhotoPath!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: SanctuarySpacing.xxl),

            // ── Mood selector ──
            SectionLabel('Mood'),
            const SizedBox(height: SanctuarySpacing.sm),
            Wrap(
              spacing: SanctuarySpacing.sm,
              runSpacing: SanctuarySpacing.sm,
              children: Mood.values.map((m) {
                final selected = state.selectedMood == m;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_moodEmoji(m)),
                      const SizedBox(width: 6),
                      Text(m.name[0].toUpperCase() + m.name.substring(1)),
                    ],
                  ),
                  selected: selected,
                  onSelected: (_) => notifier.updateSelectedMood(m),
                );
              }).toList(),
            ),

            const SizedBox(height: SanctuarySpacing.xxl),

            // ── Writing space ──
            SectionLabel('Your thoughts'),
            NeuWell(
              color: SanctuaryColors.surfaceContainerLowest,
              padding: EdgeInsets.zero,
              borderRadius: SanctuaryRadius.lg,
              child: TextField(
                controller: notifier.controller,
                onChanged: notifier.setTranscribedText,
                maxLines: null,
                minLines: 5,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                decoration: InputDecoration(
                  hintText: 'Write or dictate your note…',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(SanctuarySpacing.xl),
                ),
              ),
            ),

            const SizedBox(height: SanctuarySpacing.xxl),

            // ── Save ──
            NeuButton(
              expanded: true,
              enabled: !state.isSaving,
              onPressed: () async {
                final saved = await notifier.saveNote();
                if (context.mounted) Navigator.of(context).pop(saved);
              },
              child: Center(
                child: state.isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: SanctuaryColors.primary,
                        ),
                      )
                    : Text(isEditing ? 'Update Note' : 'Save Note'),
              ),
            ),

            const SizedBox(height: SanctuarySpacing.xxl),
          ],
        ),
      ),
    );
  }
}
