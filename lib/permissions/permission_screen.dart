import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mytiny_diary/permissions/permissions_provider.dart';
import 'package:mytiny_diary/theme/sanctuary_theme.dart';
import 'package:mytiny_diary/theme/neu_widgets.dart';

class PermissionScreen extends ConsumerWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionStatus = ref.watch(audioPermissionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Permission Request')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(SanctuarySpacing.xxl),
          child: _buildBody(context, theme, permissionStatus, ref),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    PermissionStatus status,
    WidgetRef ref,
  ) {
    switch (status) {
      case PermissionStatus.loading:
        return const CircularProgressIndicator();
      case PermissionStatus.granted:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuWell(
              padding: const EdgeInsets.all(SanctuarySpacing.xl),
              borderRadius: SanctuaryRadius.full,
              child: Icon(
                Icons.check_rounded,
                size: 40,
                color: SanctuaryColors.primary,
              ),
            ),
            const SizedBox(height: SanctuarySpacing.xl),
            Text(
              'Audio permission granted!',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        );
      case PermissionStatus.denied:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuWell(
              padding: const EdgeInsets.all(SanctuarySpacing.xl),
              borderRadius: SanctuaryRadius.full,
              child: Icon(
                Icons.mic_off_rounded,
                size: 40,
                color: SanctuaryColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SanctuarySpacing.xl),
            Text(
              'Please grant audio recording\npermission to use speech-to-text.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: SanctuarySpacing.xxl),
            NeuButton(
              onPressed: () => ref
                  .read(audioPermissionProvider.notifier)
                  .requestPermission(),
              child: const Text('Give Permission'),
            ),
          ],
        );
    }
  }
}
