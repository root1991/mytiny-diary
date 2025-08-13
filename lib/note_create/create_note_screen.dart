import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/note_create/create_note_provider.dart';
import 'dart:io';

class CreateNoteScreen extends ConsumerWidget {
  const CreateNoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createNoteProvider);
    final notifier = ref.read(createNoteProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Note')),
      backgroundColor: notifier.getBackgroundColor(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Transcribed text (from live voice recognition or manual typing)
              Text(
                state.transcribedText.isEmpty
                    ? 'Tap Start and speak to transcribe.'
                    : state.transcribedText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: state.isListening
                        ? null
                        : notifier.startListening,
                    icon: const Icon(Icons.hearing),
                    label: const Text('Start'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: state.isListening
                        ? notifier.stopListening
                        : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16.0),
                ),
                onPressed: notifier.refreshLocation,
                child: const Text('Pick Location'),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(state.location),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await notifier.pickImage();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16.0),
                ),
                child: const Text('Pick Photo'),
              ),
              if (state.imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Image.file(File(state.imageFile!.path), height: 150),
                ),
              const SizedBox(height: 24),
              const Text(
                'Select Mood:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: Mood.values.map((m) {
                  return ChoiceChip(
                    label: Text(m.name),
                    selected: state.selectedMood == m,
                    onSelected: (_) => notifier.updateSelectedMood(m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: notifier.controller,
                onChanged: notifier.setTranscribedText,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isSaving
                    ? null
                    : () async {
                        final saved = await notifier.saveNote();
                        if (context.mounted) Navigator.of(context).pop(saved);
                      },
                child: state.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
