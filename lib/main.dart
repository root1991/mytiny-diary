import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'permissions/permission_screen.dart';
import 'notes_list/notes_screen.dart';
import 'permissions/permissions_provider.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

 @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionStatus = ref.watch(audioPermissionProvider);

    return MaterialApp(
      home: switch (permissionStatus) {
        PermissionStatus.loading || PermissionStatus.denied => NotesScreen(),
        PermissionStatus.granted => NotesScreen(),
      },
    );
  }
}
