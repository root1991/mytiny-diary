import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:geolocator/geolocator.dart';

enum Mood {
  happy,
  sad,
  angry,
  neutral,
}

class CreateNoteState {
  final bool isRecording;
  final String transcribedText;
  final Mood selectedMood;
  final String location;
  final bool speechEnabled;

  CreateNoteState({
    required this.isRecording,
    required this.transcribedText,
    required this.selectedMood,
    required this.location,
    required this.speechEnabled,
  });

  CreateNoteState copyWith({
    bool? isRecording,
    String? transcribedText,
    Mood? selectedMood,
    String? location,
    bool? speechEnabled,
  }) {
    return CreateNoteState(
      isRecording: isRecording ?? this.isRecording,
      transcribedText: transcribedText ?? this.transcribedText,
      selectedMood: selectedMood ?? this.selectedMood,
      location: location ?? this.location,
      speechEnabled: speechEnabled ?? this.speechEnabled,
    );
  }
}

final createNoteProvider = StateNotifierProvider<CreateNoteNotifier, CreateNoteState>((ref) {
  return CreateNoteNotifier();
});

class CreateNoteNotifier extends StateNotifier<CreateNoteState> {
  final SpeechToText _speechToText = SpeechToText();
  final TextEditingController _controller = TextEditingController();

  TextEditingController get controller => _controller;

  CreateNoteNotifier() : super(CreateNoteState(
    isRecording: false,
    transcribedText: '',
    selectedMood: Mood.neutral,
    location: 'Fetching location...',
    speechEnabled: false,
  )) {
    _initSpeech();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _speechToText.stop();
    super.dispose();
  }

  // Initialize the speech to text engine
  void _initSpeech() async {
    final enabled = await _speechToText.initialize();
    state = state.copyWith(speechEnabled: enabled);
  }

  // Start listening for speech
  void startRecording() async {
    if (state.speechEnabled) {
      await _speechToText.listen(onResult: _onSpeechResult);
      state = state.copyWith(isRecording: true);
    }
  }

  // Stop listening for speech
  void stopRecording() async {
    await _speechToText.stop();
    state = state.copyWith(isRecording: false);
  }

  // Handle the speech recognition result
  void _onSpeechResult(SpeechRecognitionResult result) {
    state = state.copyWith(transcribedText: result.recognizedWords);
    _controller.text = state.transcribedText; // Update the text field
  }

  // Save the note
  void saveNote() {
    // TODO: Implement save note functionality
    print('Note saved: ${state.transcribedText}, Mood: ${state.selectedMood}, Location: ${state.location}');
  }

  // Get the current location
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

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    state = state.copyWith(location: '${position.latitude}, ${position.longitude}');
  }

  void updateSelectedMood(Mood mood) {
    state = state.copyWith(selectedMood: mood);
  }
}
