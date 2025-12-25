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
import 'package:record/record.dart';

// Helper class must be top-level, not nested
import 'dart:typed_data';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

class _WavData {
  _WavData(this.sampleRate, this.samples);
  final int sampleRate;
  final List<double> samples;
}

// (Removed unused Iterable extension)

enum Mood { happy, sad, angry, neutral }

class CreateNoteState {
  final String transcribedText;
  final Mood selectedMood;
  final String location;
  final double? latitude;
  final double? longitude;
  final XFile? imageFile;
  final String? audioPath;
  final bool isListening; // retained but always false now
  final bool isSaving;
  final bool isRecording;
  final bool isTranscribing;
  final double? downloadProgress; // 0..1 for model download
  final String? transcriptionError;

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
    this.isRecording = false,
    this.isTranscribing = false,
    this.downloadProgress,
    this.transcriptionError,
  });

  factory CreateNoteState.initial() => CreateNoteState(
    transcribedText: '',
    selectedMood: Mood.neutral,
    location: 'Fetching location...',
    latitude: null,
    longitude: null,
    isListening: false,
    isSaving: false,
    isRecording: false,
    isTranscribing: false,
    downloadProgress: null,
    transcriptionError: null,
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
    bool? isRecording,
    bool? isTranscribing,
    double? downloadProgress,
    String? transcriptionError,
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
      // new optionals (fallback to false if null in initial)
      // ignore: prefer_if_null_operators
      isRecording: isRecording ?? this.isRecording,
      isTranscribing: isTranscribing ?? this.isTranscribing,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      transcriptionError: transcriptionError ?? this.transcriptionError,
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
  // (Removed live speech_to_text fields)
  final AudioRecorder _recorder = AudioRecorder();
  sherpa.OfflineRecognizer? _whisper;
  bool _whisperReady = false;
  bool _sherpaInitialized = false; // ensures global native init only once

  // (Austrian hotwords removed)

  TextEditingController get controller => _controller;

  CreateNoteNotifier() : super(CreateNoteState.initial()) {
    _controller.text = state.transcribedText;
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _controller.clear();
    _controller.dispose();
    try {
      _recorder.dispose();
    } catch (_) {}
    super.dispose();
  }

  void setTranscribedText(String text) {
    // Keep manual edits as-is
    state = state.copyWith(transcribedText: text);
    _controller.value = _controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  // Save the note
  Future<Note> saveNote() async {
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

  // ---- One-button: Start = record to file; Stop = stop & offline transcribe (Whisper) ----
  Future<void> startRecording() async {
    // Live STT removed

    // Start file recording
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      // Plugin will usually request automatically, so continue
    }

    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(dir.path, 'audio'));
    if (!await audioDir.exists()) await audioDir.create(recursive: true);
    final outPath = p.join(
      audioDir.path,
      '${DateTime.now().millisecondsSinceEpoch}.wav',
    );

    try {
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: outPath,
      );
      state = state.copyWith(isRecording: true, transcriptionError: null);
      debugPrint('Recording started: $outPath');
    } catch (e) {
      debugPrint('startRecording error: $e');
      state = state.copyWith(isRecording: false);
    }
  }

  Future<void> stopRecordingAndTranscribe() async {
    // Live STT removed

    // Stop recorder and get path
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      debugPrint('stopRecording error: $e');
    }

    state = state.copyWith(isRecording: false);
    if (path == null) return;
    state = state.copyWith(
      audioPath: path,
      isTranscribing: true,
      transcriptionError: null,
    );

    try {
      await _ensureWhisper();
      if (!_whisperReady || _whisper == null) {
        debugPrint('Whisper model not ready. Skipping offline transcription.');
        return;
      }

      final wav = await _readWavPcm16(path);
      if (wav == null) {
        debugPrint('Unsupported WAV format or read error.');
        return;
      }

      final stream = _whisper!.createStream();
      try {
        stream.acceptWaveform(
          sampleRate: wav.sampleRate,
          samples: Float32List.fromList(wav.samples),
        );
        _whisper!.decode(stream);
        final res = _whisper!.getResult(stream);
        final text = res.text.trim();
        if (text.isNotEmpty) {
          setTranscribedText(text);
        }
      } finally {
        stream.free();
      }
    } catch (e) {
      debugPrint('Transcription failed: $e');
      final errStr = e.toString();
      String friendly;
      if (errStr.contains('Failed to download Whisper tiny model')) {
        friendly =
            'Offline speech model download failed. Please connect to the internet once, then try again.';
      } else if (errStr.contains('Failed host lookup') ||
          errStr.contains('SocketException')) {
        friendly =
            'No network connection. Connect to the internet to enable transcription.';
      } else {
        friendly = 'Offline transcription failed: $errStr';
      }
      state = state.copyWith(transcriptionError: friendly);
    } finally {
      state = state.copyWith(isTranscribing: false);
    }
  }

  Future<void> _ensureWhisper() async {
    if (_whisperReady && _whisper != null) return;

    // Initialize the native sherpa-onnx core once (required before creating recognizers)
    if (!_sherpaInitialized) {
      try {
        sherpa.initBindings();
        _sherpaInitialized = true;
        debugPrint(
          'sherpa-onnx core initialized (version: ${sherpa.getVersion()}, git: ${sherpa.getGitSha1()})',
        );
      } catch (e) {
        debugPrint('sherpa-onnx core init failed (continuing): $e');
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory(p.join(dir.path, 'models', 'whisper-tiny'));
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
      // Will download below if missing
    }

    String encoder = p.join(modelDir.path, 'encoder.onnx');
    String decoder = p.join(modelDir.path, 'decoder.onnx');
    String tokens = p.join(modelDir.path, 'tokens.txt');
    if (!File(encoder).existsSync() ||
        !File(decoder).existsSync() ||
        !File(tokens).existsSync()) {
      debugPrint('Whisper model files missing. Downloading tiny model...');
      await _downloadWhisperTiny(modelDir);
      // Re-evaluate in case we normalized filenames after extraction
      if (!File(encoder).existsSync() ||
          !File(decoder).existsSync() ||
          !File(tokens).existsSync()) {
        // Try to find them by pattern inside modelDir
        encoder = await _findModelFile(modelDir, contains: 'encoder.onnx');
        decoder = await _findModelFile(modelDir, contains: 'decoder.onnx');
        tokens = await _findModelFile(modelDir, contains: 'tokens.txt');
        if (encoder.isEmpty || decoder.isEmpty || tokens.isEmpty) {
          throw Exception('Whisper tiny model files not found after download');
        }
      }
    }

    // Determine if english-only model (look for original tiny.en-* filenames still present)
    bool englishOnly = false;
    try {
      await for (final ent in modelDir.list(recursive: true)) {
        if (ent is File) {
          final name = p.basename(ent.path).toLowerCase();
          if (name.contains('tiny.en-encoder') ||
              name.contains('tiny.en-decoder') ||
              name.contains('tiny.en-tokens')) {
            englishOnly = true;
            break;
          }
        }
      }
    } catch (_) {}

    // Force English recognition regardless of model multilingual capability
    sherpa.OfflineRecognizer? created;
    Exception? lastErr;
    for (final lang in <String>['en', '']) {
      if (created != null) break;
      try {
        final modelCfg = sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: encoder,
            decoder: decoder,
            language: lang,
            task: 'transcribe',
            tailPaddings: -1,
          ),
          tokens: tokens,
          numThreads: 2,
          provider: 'cpu',
          debug: false,
        );
        final recCfg = sherpa.OfflineRecognizerConfig(
          model: modelCfg,
          decodingMethod: 'greedy_search',
        );
        try {
          _whisper?.free();
        } catch (_) {}
        created = sherpa.OfflineRecognizer(recCfg);
        debugPrint(
          'Whisper recognizer initialized (forced lang="$lang", englishOnly=$englishOnly).',
        );
      } catch (e) {
        lastErr = e is Exception ? e : Exception(e.toString());
        debugPrint('Whisper init attempt with lang="$lang" failed: $e');
      }
    }
    if (created == null) {
      throw Exception('Failed to initialize Whisper recognizer: $lastErr');
    }
    _whisper = created;
    _whisperReady = true;
  }

  Future<void> _downloadWhisperTiny(Directory modelDir) async {
    // Download official tarball(s) and extract. Prefer multilingual tiny; fallback to tiny.en.
    final candidates = [
      // multilingual tiny
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-tiny.tar.bz2',
      // english-only tiny.en
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-tiny.en.tar.bz2',
    ];

    Exception? lastError;
    for (int i = 0; i < candidates.length; i++) {
      final url = candidates[i];
      final tmpTar = File(p.join(modelDir.path, 'tmp-whisper.tar.bz2'));
      final client = http.Client();
      try {
        // Step 1: Download tarball with progress
        final req = http.Request('GET', Uri.parse(url));
        final resp = await client.send(req);
        if (resp.statusCode != 200) {
          throw Exception('HTTP ${resp.statusCode}');
        }
        final sink = tmpTar.openWrite();
        int received = 0;
        final contentLen = resp.contentLength ?? 0;
        await for (final chunk in resp.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (contentLen > 0) {
            final frac =
                (received / contentLen) * 0.9; // 90% for download stage
            state = state.copyWith(downloadProgress: frac);
          }
        }
        await sink.flush();
        await sink.close();

        // Step 2: Extract tar.bz2 (remaining 10%)
        final bytes = await tmpTar.readAsBytes();
        final tarBytes = BZip2Decoder().decodeBytes(bytes);
        final archive = TarDecoder().decodeBytes(tarBytes);
        int fileIdx = 0;
        final fileCount = archive.files.isEmpty ? 1 : archive.files.length;
        for (final f in archive.files) {
          final outPath = p.join(modelDir.path, f.name);
          if (f.isFile) {
            final outFile = File(outPath);
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(f.content as List<int>);
          } else {
            await Directory(outPath).create(recursive: true);
          }
          fileIdx++;
          state = state.copyWith(
            downloadProgress: 0.9 + (fileIdx / fileCount) * 0.1,
          );
        }

        // Normalize filenames to encoder.onnx/decoder.onnx/tokens.txt at root of modelDir
        await _normalizeWhisperFiles(modelDir);
        state = state.copyWith(downloadProgress: null);
        try {
          await tmpTar.delete();
        } catch (_) {}
        return; // success
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        debugPrint('Whisper download attempt ${i + 1} failed: $e');
      } finally {
        client.close();
        try {
          if (await tmpTar.exists()) await tmpTar.delete();
        } catch (_) {}
      }
    }
    state = state.copyWith(downloadProgress: null);
    throw Exception(
      'Failed to download Whisper tiny model: ${lastError ?? 'Unknown error'}',
    );
  }

  Future<void> _normalizeWhisperFiles(Directory modelDir) async {
    // Try to find encoder/decoder/tokens in any extracted subdir and copy to root with standard names
    final encoderPath = await _findModelFile(
      modelDir,
      contains: 'encoder.onnx',
    );
    final decoderPath = await _findModelFile(
      modelDir,
      contains: 'decoder.onnx',
    );
    final tokensPath = await _findModelFile(modelDir, contains: 'tokens.txt');
    if (encoderPath.isEmpty || decoderPath.isEmpty || tokensPath.isEmpty) {
      throw Exception('Extracted Whisper files not found');
    }
    // Prefer non-int8 if both exist
    String pickEnc = encoderPath;
    String pickDec = decoderPath;
    if (pickEnc.endsWith('.int8.onnx')) {
      final alt = await _findModelFile(
        modelDir,
        contains: 'encoder.onnx',
        preferNonInt8: true,
      );
      if (alt.isNotEmpty) pickEnc = alt;
    }
    if (pickDec.endsWith('.int8.onnx')) {
      final alt = await _findModelFile(
        modelDir,
        contains: 'decoder.onnx',
        preferNonInt8: true,
      );
      if (alt.isNotEmpty) pickDec = alt;
    }
    // Copy to root
    await File(pickEnc).copy(p.join(modelDir.path, 'encoder.onnx'));
    await File(pickDec).copy(p.join(modelDir.path, 'decoder.onnx'));
    await File(tokensPath).copy(p.join(modelDir.path, 'tokens.txt'));
  }

  Future<String> _findModelFile(
    Directory modelDir, {
    required String contains,
    bool preferNonInt8 = false,
  }) async {
    String? best;
    await for (final ent in modelDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (ent is File) {
        final name = p.basename(ent.path).toLowerCase();
        if (name.contains(contains.toLowerCase())) {
          if (best == null) {
            best = ent.path;
          } else if (preferNonInt8 &&
              name.endsWith('.onnx') &&
              !name.contains('int8')) {
            best = ent.path; // prefer float32
          }
        }
      }
    }
    return best ?? '';
  }

  Future<_WavData?> _readWavPcm16(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      if (bytes.length < 44) return null;
      if (String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF') return null;
      if (String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') return null;

      int pos = 12;
      int? sampleRate;
      int? numChannels;
      int? bitsPerSample;
      int dataOffset = -1;
      int dataSize = 0;

      while (pos + 8 <= bytes.length) {
        final chunkId = String.fromCharCodes(bytes.sublist(pos, pos + 4));
        final chunkSize = _le32(bytes, pos + 4);
        if (chunkId == 'fmt ') {
          final audioFormat = _le16(bytes, pos + 8);
          numChannels = _le16(bytes, pos + 10);
          sampleRate = _le32(bytes, pos + 12);
          bitsPerSample = _le16(bytes, pos + 22);
          if (audioFormat != 1) return null; // PCM only
        } else if (chunkId == 'data') {
          dataOffset = pos + 8;
          dataSize = chunkSize;
          break;
        }
        pos += 8 + chunkSize;
      }

      if (dataOffset < 0 ||
          sampleRate == null ||
          numChannels == null ||
          bitsPerSample != 16) {
        return null;
      }

      // Convert 16-bit PCM mono/first-channel to float
      final ByteData bd = ByteData.sublistView(
        Uint8List.fromList(bytes.sublist(dataOffset, dataOffset + dataSize)),
      );
      final int frames = bd.lengthInBytes ~/ 2 ~/ numChannels;
      final samples = List<double>.filled(frames, 0.0, growable: false);
      int idx = 0;
      for (int i = 0; i < frames; i++) {
        final val = bd.getInt16((i * numChannels) * 2, Endian.little);
        samples[idx++] = val / 32768.0;
      }
      return _WavData(sampleRate, samples);
    } catch (e) {
      debugPrint('readWav error: $e');
      return null;
    }
  }

  int _le16(List<int> b, int offset) {
    return b[offset] | (b[offset + 1] << 8);
  }

  int _le32(List<int> b, int offset) {
    return b[offset] |
        (b[offset + 1] << 8) |
        (b[offset + 2] << 16) |
        (b[offset + 3] << 24);
  }

  // Whisper-related helpers removed
}
