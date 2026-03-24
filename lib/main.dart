import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mytiny_diary/theme/sanctuary_theme.dart';
import 'home/home_shell.dart';
import 'permissions/permissions_provider.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch permission status — currently unused for gating, but retained for future use
    ref.watch(audioPermissionProvider);

    return MaterialApp(
      theme: buildSanctuaryTheme(),
      debugShowCheckedModeBanner: false,
      home: const HomeShell(),
    );
  }
}
