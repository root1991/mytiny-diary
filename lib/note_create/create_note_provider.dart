import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:myapp/data/note_repository.dart';
import 'package:myapp/models/note.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

enum Mood { happy, sad, angry, neutral }

class CreateNoteState {
  final String transcribedText;
  final Mood selectedMood;
  final String location;
  final double? latitude;
  final double? longitude;
  final XFile? imageFile;
  final String? audioPath;
  final bool isListening;
  final bool isSaving;

  CreateNoteState({
    required this.transcribedText,
    required this.selectedMood,
    required this.location,
    this.latitude,
    this.longitude,
    this.imageFile,
    this.audioPath,
    this.isListening = false,
    this.isSaving = false,
  });

  factory CreateNoteState.initial() => CreateNoteState(
    transcribedText: '',
    selectedMood: Mood.neutral,
    location: 'Fetching location...',
    latitude: null,
    longitude: null,
    isListening: false,
    isSaving: false,
  );

  CreateNoteState copyWith({
    String? transcribedText,
    Mood? selectedMood,
    String? location,
    double? latitude,
    double? longitude,
    XFile? imageFile,
    String? audioPath,
    bool? isListening,
    bool? isSaving,
  }) {
    return CreateNoteState(
      transcribedText: transcribedText ?? this.transcribedText,
      selectedMood: selectedMood ?? this.selectedMood,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageFile: imageFile ?? this.imageFile,
      audioPath: audioPath ?? this.audioPath,
      isListening: isListening ?? this.isListening,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

final createNoteProvider =
    StateNotifierProvider.autoDispose<CreateNoteNotifier, CreateNoteState>(
      (ref) => CreateNoteNotifier(),
    );

class CreateNoteNotifier extends StateNotifier<CreateNoteState> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;

  TextEditingController get controller => _controller;

  CreateNoteNotifier() : super(CreateNoteState.initial()) {
    _controller.text = state.transcribedText;
    _initSpeech();
    _getCurrentLocation();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (e) {
          debugPrint('STT error: ${e.errorMsg}');
          state = state.copyWith(isListening: false);
        },
        onStatus: (status) {
          debugPrint('STT status: $status');
          if (status.toLowerCase().contains('notlistening') ||
              status.toLowerCase().contains('done')) {
            state = state.copyWith(isListening: false);
          }
        },
      );
      debugPrint('STT initialized: $_speechAvailable');
    } catch (e) {
      debugPrint('STT init exception: $e');
      _speechAvailable = false;
    }
  }

  @override
  void dispose() {
    _controller.clear();
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  // Voice recognition controls
  Future<void> startListening() async {
    if (state.isListening) return;
    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) {
        debugPrint('Speech recognition not available');
        return;
      }
    }
    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
      );
      state = state.copyWith(isListening: true);
    } catch (e) {
      debugPrint('startListening error: $e');
      state = state.copyWith(isListening: false);
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    state = state.copyWith(isListening: false);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords;
    state = state.copyWith(transcribedText: text);
    _controller.value = _controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
    if (result.finalResult) {
      state = state.copyWith(isListening: false);
    }
  }

  void setTranscribedText(String text) {
    state = state.copyWith(transcribedText: text);
    _controller.value = _controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  // Save the note
  Future<Note> saveNote() async {
    // Ensure listening stopped
    if (state.isListening) {
      await stopListening();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    state = state.copyWith(isSaving: true);
    try {
      // Persist image if present (copy into app dir)
      String? persistedPhotoPath;
      if (state.imageFile != null) {
        final dir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(p.join(dir.path, 'images'));
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }
        final ext = p.extension(state.imageFile!.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
        final destPath = p.join(imagesDir.path, fileName);
        await File(state.imageFile!.path).copy(destPath);
        persistedPhotoPath = destPath;
      }

      // Ensure coordinates present
      double? lat = state.latitude;
      double? lng = state.longitude;
      if (lat == null || lng == null) {
        final loc = state.location;
        if (loc.contains(',')) {
          final parts = loc.split(',');
          if (parts.length == 2) {
            lat = double.tryParse(parts[0].trim());
            lng = double.tryParse(parts[1].trim());
          }
        }
      }
      if ((lat == null || lng == null)) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          lat = position.latitude;
          lng = position.longitude;
        } catch (_) {}
      }

      final moodInt = Mood.values.indexOf(state.selectedMood);

      final note = Note(
        text: state.transcribedText,
        audioPath: state.audioPath ?? '',
        photo: persistedPhotoPath,
        location: state.location,
        latitude: lat,
        longitude: lng,
        mood: moodInt,
      );

      final saved = await NoteRepository.instance.insert(note);
      debugPrint('Note saved: ${saved.id}');
      return saved;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  // Get the current location (internal)
  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(location: 'Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(location: 'Location permissions are denied');
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    String fallback = '${position.latitude}, ${position.longitude}';
    String pretty = fallback;
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final pmark = placemarks.first;
        String city = '';
        if (pmark.locality != null && pmark.locality!.isNotEmpty) {
          city = pmark.locality!;
        } else if (pmark.subLocality != null && pmark.subLocality!.isNotEmpty) {
          city = pmark.subLocality!;
        } else if (pmark.subAdministrativeArea != null &&
            pmark.subAdministrativeArea!.isNotEmpty) {
          city = pmark.subAdministrativeArea!;
        } else if (pmark.administrativeArea != null &&
            pmark.administrativeArea!.isNotEmpty) {
          city = pmark.administrativeArea!;
        }
        final region = pmark.administrativeArea ?? '';
        final country = pmark.country ?? '';
        final parts = <String>{};
        if (city.isNotEmpty) {
          parts.add(city);
        }
        if (region.isNotEmpty && region != city) {
          parts.add(region);
        }
        if (country.isNotEmpty && country != city && country != region) {
          parts.add(country);
        }
        if (parts.isNotEmpty) {
          pretty = parts.join(', ');
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
    }

    state = state.copyWith(
      location: pretty,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  // Public method to refresh location
  Future<void> refreshLocation() async {
    _getCurrentLocation();
  }

  void updateSelectedMood(Mood mood) {
    state = state.copyWith(selectedMood: mood);
  }

  Future<void> pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      state = state.copyWith(imageFile: img);
    }
  }

  Color getBackgroundColor() {
    switch (state.selectedMood) {
      case Mood.sad:
        return Colors.blue.shade100;
      case Mood.happy:
        return Colors.red.shade100;
      case Mood.angry:
        return Colors.orange.shade100;
      case Mood.neutral:
        return Colors.white;
    }
  }
}
