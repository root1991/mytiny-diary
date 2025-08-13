import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/note_create/create_note_provider.dart';
import 'dart:io';

class CreateNoteScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createNoteState = ref.watch(createNoteProvider);
    final createNoteNotifier = ref.read(createNoteProvider.notifier);
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

    Color _getBackgroundColor(Mood mood) {
    // Interpolate between colors based on mood
      if (mood == Mood.sad) {
        return Colors.blue.shade100;
      } else if (mood == Mood.happy) {
        return Colors.red.shade100;
      } else {
        return Colors.white;
      }
  }

  @override
  void dispose() {
    _speechToText.stop();
 WidgetsBinding.instance.removeObserver(this); // Removed 'this' as it's not needed here
    super.dispose();
  }

  void _initSpeech() async {
    _isListening = await _speechToText.initialize();
    setState(() {});
    if (_isListening) {
      _speechToText.listen(onResult: _onSpeechResult);
    }
  }

  void _onSpeechResult(result) {
    setState(() {
      _text = result.recognizedWords;
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {_location = '${position.latitude}, ${position.longitude}';});
  } // Added closing brace for _getCurrentLocation


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Note'),
      ),
      backgroundColor: _getBackgroundColor(), // Set background color based on mood
 body: Padding( // Added padding to the Padding widget
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Placeholder for transcribed text
            Text(
              'Start speaking to record your note...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            // Placeholder for location picker
             ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16.0),
              ),
              onPressed: _getCurrentLocation,
              child: Text('Pick Location'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_location),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                setState(() {
                  _imageFile = image;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16.0),
              ),
              child: Text('Pick Photo'),
            ),
            if (_imageFile != null)
              Image.file(
                File(_imageFile!.path),
                height: 150,
              ),

            SizedBox(height: 20),
            // Placeholder for mood selection
            Slider(
              min: -10.0,
              max: 10.0,
              value: _mood,
              onChanged: (newValue) {
                setState(() {
                  _mood = newValue;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}