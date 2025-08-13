import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/permissions/permissions_provider.dart';

class PermissionScreen extends ConsumerWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionStatus = ref.watch(audioPermissionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Request'),
      ),
      body: Center(
        child: _buildBody(context, permissionStatus, ref),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PermissionStatus status, WidgetRef ref) {
    switch (status) {
      case PermissionStatus.loading:
        return const CircularProgressIndicator();
      case PermissionStatus.granted:
        return const Text(
          'Audio permission granted!',
          textAlign: TextAlign.center,
        );
      case PermissionStatus.denied:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Please grant audio recording permission to use speech-to-text.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(audioPermissionProvider.notifier).requestPermission(),
              child: const Text('Give Permission'),
            ),
          ],
        );
    }
  }
}