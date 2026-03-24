import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mytiny_diary/statistics/statistics_provider.dart';
import 'package:mytiny_diary/statistics/mood_charts.dart';
import 'package:mytiny_diary/theme/sanctuary_theme.dart';
import 'package:mytiny_diary/theme/neu_widgets.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(moodStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Analytics')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) {
          if (stats.totalEntries == 0) {
            return _EmptyState(theme: theme);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(SanctuarySpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Summary Card ──
                _SummaryCard(stats: stats, theme: theme),
                const SizedBox(height: SanctuarySpacing.xl),

                // ── Mood Distribution ──
                _MoodDistributionCard(stats: stats, theme: theme),
                const SizedBox(height: SanctuarySpacing.xl),

                // ── Weekly Highlights ──
                _WeeklyHighlights(stats: stats, theme: theme),
                const SizedBox(height: SanctuarySpacing.xl),

                // ── 7-Day Trend ──
                _WeeklyTrendCard(stats: stats, theme: theme),
                const SizedBox(height: SanctuarySpacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeuWell(
            padding: const EdgeInsets.all(SanctuarySpacing.xl),
            borderRadius: SanctuaryRadius.full,
            child: Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: SanctuaryColors.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: SanctuarySpacing.xl),
          Text(
            'No entries yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: SanctuaryColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: SanctuarySpacing.sm),
          Text(
            'Start writing to see your mood insights',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: SanctuaryColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Card
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats, required this.theme});
  final MoodStats stats;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(SanctuarySpacing.xl),
      borderRadius: SanctuaryRadius.xxl,
      child: Row(
        children: [
          NeuWell(
            padding: const EdgeInsets.all(SanctuarySpacing.lg),
            borderRadius: SanctuaryRadius.full,
            child: Text(
              MoodChartColors.emoji(stats.topMood),
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: SanctuarySpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.summaryText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: SanctuarySpacing.xs),
                Text(
                  stats.summarySubtext,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: SanctuaryColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mood Distribution (Donut Chart + Legend)
// ─────────────────────────────────────────────────────────────────────────────

class _MoodDistributionCard extends StatelessWidget {
  const _MoodDistributionCard({required this.stats, required this.theme});
  final MoodStats stats;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final topPct = (stats.moodPercentage(stats.topMood) * 100).round();

    return NeuCard(
      padding: const EdgeInsets.all(SanctuarySpacing.xl),
      borderRadius: SanctuaryRadius.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Distribution',
            style: theme.textTheme.labelLarge?.copyWith(
              color: SanctuaryColors.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: SanctuarySpacing.xl),
          Row(
            children: [
              // Donut chart with center label
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MoodDonutChart(
                      moodCounts: stats.moodCounts,
                      totalEntries: stats.totalEntries,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$topPct%',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          MoodChartColors.label(stats.topMood),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: SanctuaryColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SanctuarySpacing.xl),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [0, 3, 1, 2].map((mood) {
                    final count = stats.moodCounts[mood] ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    final pct = (stats.moodPercentage(mood) * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: SanctuarySpacing.md,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: MoodChartColors.forMood(mood),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: SanctuarySpacing.sm),
                          Expanded(
                            child: Text(
                              MoodChartColors.label(mood),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly Highlights (3 metric cards)
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyHighlights extends StatelessWidget {
  const _WeeklyHighlights({required this.stats, required this.theme});
  final MoodStats stats;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Total Entries',
            value: '${stats.totalEntries}',
            icon: Icons.edit_note_rounded,
            theme: theme,
          ),
        ),
        const SizedBox(width: SanctuarySpacing.md),
        Expanded(
          child: _MetricTile(
            label: 'Day Streak',
            value: '${stats.dayStreak}',
            icon: Icons.local_fire_department_rounded,
            theme: theme,
          ),
        ),
        const SizedBox(width: SanctuarySpacing.md),
        Expanded(
          child: _MetricTile(
            label: 'Top Mood',
            value: MoodChartColors.emoji(stats.topMood),
            icon: Icons.favorite_rounded,
            theme: theme,
            valueIsEmoji: true,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.theme,
    this.valueIsEmoji = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final ThemeData theme;
  final bool valueIsEmoji;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SanctuarySpacing.md,
        vertical: SanctuarySpacing.lg,
      ),
      borderRadius: SanctuaryRadius.xxl,
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: SanctuaryColors.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: SanctuarySpacing.sm),
          Text(
            value,
            style: valueIsEmoji
                ? const TextStyle(fontSize: 24)
                : theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
          ),
          const SizedBox(height: SanctuarySpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: SanctuaryColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7-Day Trend (Bar Chart)
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyTrendCard extends StatelessWidget {
  const _WeeklyTrendCard({required this.stats, required this.theme});
  final MoodStats stats;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(SanctuarySpacing.xl),
      borderRadius: SanctuaryRadius.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Trend',
            style: theme.textTheme.labelLarge?.copyWith(
              color: SanctuaryColors.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: SanctuarySpacing.lg),
          WeeklyBarChart(last7DaysCounts: stats.last7DaysCounts),
        ],
      ),
    );
  }
}
