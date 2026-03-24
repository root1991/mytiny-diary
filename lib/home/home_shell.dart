import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mytiny_diary/notes_list/notes_screen.dart';
import 'package:mytiny_diary/statistics/statistics_screen.dart';
import 'package:mytiny_diary/theme/sanctuary_theme.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  static const _screens = <Widget>[
    NotesScreen(),
    StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepaintBoundary(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: NeuBottomBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}

/// Neumorphic bottom navigation bar matching the Tactile Sanctuary design.
class NeuBottomBar extends StatelessWidget {
  const NeuBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLow,
        boxShadow: [
          BoxShadow(
            color: SanctuaryColors.surfaceContainerLowest,
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: SanctuaryColors.surfaceDim.withValues(alpha: 0.30),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SanctuarySpacing.xxl,
            vertical: SanctuarySpacing.sm,
          ),
          child: Row(
            children: [
              _NeuTab(
                icon: Icons.auto_stories_rounded,
                label: 'Notes',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NeuTab(
                icon: Icons.bar_chart_rounded,
                label: 'Statistics',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeuTab extends StatelessWidget {
  const _NeuTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? SanctuaryColors.primary
        : SanctuaryColors.onSurfaceVariant.withValues(alpha: 0.5);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: SanctuarySpacing.md,
          ),
          margin: const EdgeInsets.all(SanctuarySpacing.xs),
          decoration: BoxDecoration(
            color: isSelected
                ? SanctuaryColors.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(SanctuaryRadius.xl),
            boxShadow: isSelected
                ? SanctuaryShadows.recessed(intensity: 0.6)
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: SanctuarySpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
