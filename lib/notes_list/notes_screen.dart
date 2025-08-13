import 'package:flutter/material.dart';

import 'package:myapp/note_create/create_note_screen.dart';
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
      ),
      body: ListView.builder(
        itemCount: 0, // Placeholder for now
        itemBuilder: (context, index) {
          return const ListTile(
            // Placeholder for note item
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateNoteScreen()));
        },
        tooltip: 'Start Recording',
        child: const Icon(Icons.mic),
      ),
    );
  }
}