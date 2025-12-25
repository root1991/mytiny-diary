import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum PermissionStatus {
  loading,
  granted,
  denied,
}

class AudioPermissionNotifier extends StateNotifier<PermissionStatus> {
  AudioPermissionNotifier() : super(PermissionStatus.loading) {
    _checkPermission();
  }

  final SpeechToText _speechToText = SpeechToText();

  Future<void> _checkPermission() async {
    final isAvailable = await _speechToText.hasPermission;
    if (isAvailable) {
      state = PermissionStatus.granted;
    } else {
      state = PermissionStatus.denied;
    }
  }

  Future<void> requestPermission() async {
    state = PermissionStatus.loading;
    final isAvailable = await _speechToText.initialize();
    if (isAvailable) {
      state = PermissionStatus.granted;
    } else {
      state = PermissionStatus.denied;
    }
  }
}

final audioPermissionProvider =
    StateNotifierProvider<AudioPermissionNotifier, PermissionStatus>(
        (ref) => AudioPermissionNotifier());