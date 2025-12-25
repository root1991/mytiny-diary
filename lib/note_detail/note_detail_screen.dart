import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:myapp/models/note.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
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

  Widget _moodChip(int mood) {
    IconData icon;
    String label;
    switch (mood) {
      case 0:
        icon = Icons.sentiment_satisfied;
        label = 'Happy';
        break;
      case 1:
        icon = Icons.sentiment_dissatisfied;
        label = 'Sad';
        break;
      case 2:
        icon = Icons.mood_bad;
        label = 'Angry';
        break;
      default:
        icon = Icons.sentiment_neutral;
        label = 'Neutral';
    }
    return Chip(avatar: Icon(icon), label: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final hasAudio =
        note.audioPath.isNotEmpty && File(note.audioPath).existsSync();
    final hasPhoto =
        note.photo != null &&
        note.photo!.isNotEmpty &&
        File(note.photo!).existsSync();

    final LatLng? center = _centerFor(note);

    return Scaffold(
      appBar: AppBar(title: const Text('Note Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mood
            Row(
              children: [
                const Text(
                  'Mood:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                _moodChip(note.mood),
              ],
            ),
            const SizedBox(height: 12),

            // Text
            if (note.text.isNotEmpty) ...[
              const Text('Text', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(note.text),
              const SizedBox(height: 16),
            ],

            // Photo
            if (hasPhoto) ...[
              const Text(
                'Photo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Image.file(File(note.photo!), height: 200, fit: BoxFit.cover),
              const SizedBox(height: 16),
            ],

            // Audio player
            if (hasAudio) ...[
              const Text(
                'Audio',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () async {
                      if (_isPlaying) {
                        await _player.pause();
                      } else {
                        await _player.play(DeviceFileSource(note.audioPath));
                      }
                      if (mounted) {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(note.audioPath.split('/').last)),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Map
            if (center != null) ...[
              const Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: FlutterMap(
                  options: MapOptions(initialCenter: center, initialZoom: 13),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.myapp',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              if ((note.location ?? '').isNotEmpty) ...[
                const Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(note.location!),
              ],
            ],

            const SizedBox(height: 24),
            Text('Created: ${note.createdAt.toLocal()}'),
          ],
        ),
      ),
    );
  }
}
