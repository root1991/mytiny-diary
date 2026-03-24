import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mytiny_diary/models/note.dart';
import 'package:mytiny_diary/theme/sanctuary_theme.dart';
import 'package:mytiny_diary/theme/neu_widgets.dart';
import 'package:mytiny_diary/data/note_repository.dart';
import 'package:mytiny_diary/note_create/create_note_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _ready = false;
  bool _mapExpanded = false; // FlutterMap only loads on user tap

  // Async file-existence checks cached in state (avoid synchronous I/O in build)
  bool _hasAudio = false;
  bool _hasPhoto = false;
  bool _filesChecked = false;

  late Note _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _checkFiles();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _listenToRouteTransition();
    }
  }

  void _listenToRouteTransition() {
    final route = ModalRoute.of(context);
    if (route?.animation != null && !route!.animation!.isCompleted) {
      void listener(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          route.animation!.removeStatusListener(listener);
          if (mounted) setState(() => _ready = true);
        }
      }

      route.animation!.addStatusListener(listener);
    } else {
      _ready = true;
    }
  }

  Future<void> _checkFiles() async {
    final note = _note;
    final audioExists =
        note.audioPath.isNotEmpty && await File(note.audioPath).exists();
    final photoExists =
        note.photo != null &&
        note.photo!.isNotEmpty &&
        await File(note.photo!).exists();
    if (mounted) {
      setState(() {
        _hasAudio = audioExists;
        _hasPhoto = photoExists;
        _filesChecked = true;
      });
    }
  }

  AudioPlayer _ensurePlayer() {
    if (_player == null) {
      _player = AudioPlayer();
      _player!.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
    return _player!;
  }

  Future<void> _editNote() async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateNoteScreen(existingNote: _note),
      ),
    );
    if (result != null && mounted) {
      // Reload the note from DB to get the latest data
      final updated = await NoteRepository.instance.getById(_note.id!);
      if (updated != null && mounted) {
        setState(() {
          _note = updated;
          _filesChecked = false;
          _mapExpanded = false;
        });
        _checkFiles();
      }
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: SanctuaryColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await NoteRepository.instance.delete(_note.id!);
      if (mounted) {
        Navigator.pop(context, 'deleted');
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  LatLng? _parseLatLng(String? location) {
    if (location == null || location.isEmpty) return null;
    final parts = location.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng? _centerFor(Note note) {
    if (note.latitude != null && note.longitude != null) {
      return LatLng(note.latitude!, note.longitude!);
    }
    return _parseLatLng(note.location);
  }

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

  String _moodLabel(int mood) {
    switch (mood) {
      case 0:
        return 'Happy';
      case 1:
        return 'Sad';
      case 2:
        return 'Angry';
      default:
        return 'Neutral';
    }
  }

  String _formattedDate(DateTime dt) {
    final d = dt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Color _moodBackground(int mood) {
    switch (mood) {
      case 0:
        return SanctuaryColors.moodHappy;
      case 1:
        return SanctuaryColors.moodSad;
      case 2:
        return SanctuaryColors.moodAngry;
      default:
        return SanctuaryColors.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;
    final theme = Theme.of(context);

    final LatLng? center = _centerFor(note);

    return Scaffold(
      backgroundColor: _moodBackground(note.mood),
      appBar: AppBar(
        title: const Text('Note Details'),
        backgroundColor: _moodBackground(note.mood),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
            onPressed: _editNote,
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            tooltip: 'Delete',
            onPressed: _deleteNote,
          ),
        ],
      ),
      body: !_filesChecked
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(SanctuarySpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Date & Mood header ──
                  NeuCard(
                    padding: const EdgeInsets.all(SanctuarySpacing.xl),
                    borderRadius: SanctuaryRadius.xxl,
                    child: Row(
                      children: [
                        NeuWell(
                          padding: const EdgeInsets.all(SanctuarySpacing.md),
                          borderRadius: SanctuaryRadius.full,
                          child: Text(
                            _moodEmoji(note.mood),
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                        const SizedBox(width: SanctuarySpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _moodLabel(note.mood),
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formattedDate(note.createdAt),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Text ──
                  if (note.text.isNotEmpty) ...[
                    const SizedBox(height: SanctuarySpacing.xxl),
                    const SectionLabel('Entry'),
                    NeuWell(
                      color: SanctuaryColors.surfaceContainerLowest,
                      padding: const EdgeInsets.all(SanctuarySpacing.xl),
                      borderRadius: SanctuaryRadius.lg,
                      child: Text(
                        note.text,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                      ),
                    ),
                  ],

                  // ── Heavy sections deferred until route transition completes ──
                  if (!_ready) ...[
                    const SizedBox(height: SanctuarySpacing.xxl),
                    const Center(child: CircularProgressIndicator()),
                  ],

                  // ── Photo ──
                  if (_ready && _hasPhoto) ...[
                    const SizedBox(height: SanctuarySpacing.xxl),
                    const SectionLabel('Photo'),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(SanctuaryRadius.lg),
                      child: Image.file(
                        File(note.photo!),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: 800,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded || frame != null)
                                return child;
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: frame == null
                                    ? const SizedBox(height: 220)
                                    : child,
                              );
                            },
                      ),
                    ),
                  ],

                  // ── Audio player ──
                  if (_ready && _hasAudio) ...[
                    const SizedBox(height: SanctuarySpacing.xxl),
                    const SectionLabel('Audio'),
                    NeuCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SanctuarySpacing.lg,
                        vertical: SanctuarySpacing.md,
                      ),
                      child: Row(
                        children: [
                          // Play/Pause in a recessed well
                          GestureDetector(
                            onTap: () async {
                              final player = _ensurePlayer();
                              if (_isPlaying) {
                                await player.pause();
                              } else {
                                await player.play(
                                  DeviceFileSource(note.audioPath),
                                );
                              }
                              if (mounted) {
                                setState(() => _isPlaying = !_isPlaying);
                              }
                            },
                            child: NeuWell(
                              padding: const EdgeInsets.all(
                                SanctuarySpacing.md,
                              ),
                              borderRadius: SanctuaryRadius.full,
                              child: Icon(
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 24,
                                color: SanctuaryColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: SanctuarySpacing.lg),
                          Expanded(
                            child: Text(
                              note.audioPath.split('/').last,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Map ──
                  if (_ready && center != null) ...[
                    const SizedBox(height: SanctuarySpacing.xxl),
                    const SectionLabel('Location'),
                    if (_mapExpanded)
                      RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(SanctuaryRadius.lg),
                          child: SizedBox(
                            height: 220,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: center,
                                initialZoom: 13,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.mytinydiary',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: center,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: SanctuaryColors.error,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      NeuCard(
                        onTap: () => setState(() => _mapExpanded = true),
                        padding: const EdgeInsets.symmetric(
                          horizontal: SanctuarySpacing.lg,
                          vertical: SanctuarySpacing.xl,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map_rounded, size: 24,
                              color: SanctuaryColors.primary),
                            const SizedBox(width: SanctuarySpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (note.location ?? '').isNotEmpty
                                        ? note.location!
                                        : '${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}',
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Tap to show map',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: SanctuaryColors.onSurfaceVariant.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 20,
                              color: SanctuaryColors.onSurfaceVariant.withValues(alpha: 0.4)),
                          ],
                        ),
                      ),
                  ] else if (_ready && (note.location ?? '').isNotEmpty) ...[
                    const SizedBox(height: SanctuarySpacing.xxl),
                    const SectionLabel('Location'),
                    NeuCard(
                      padding: const EdgeInsets.all(SanctuarySpacing.lg),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18),
                          const SizedBox(width: SanctuarySpacing.sm),
                          Expanded(
                            child: Text(
                              note.location!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: SanctuarySpacing.xxxl),
                ],
              ),
            ),
    );
  }
}
