import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mytiny_diary/theme/sanctuary_theme.dart';

/// Mood colors for charts (distinct, vibrant versions for data visualization).
class MoodChartColors {
  MoodChartColors._();
  static const Color happy = Color(0xFFFF8A80);   // Soft Coral
  static const Color sad = Color(0xFFA2B4C5);     // Muted Blue-Grey
  static const Color angry = Color(0xFFFFB74D);   // Soft Orange
  static const Color neutral = Color(0xFFC7DDF2); // Soft Sky Blue

  static Color forMood(int mood) {
    switch (mood) {
      case 0: return happy;
      case 1: return sad;
      case 2: return angry;
      default: return neutral;
    }
  }

  static String label(int mood) {
    switch (mood) {
      case 0: return 'Happy';
      case 1: return 'Sad';
      case 2: return 'Angry';
      default: return 'Neutral';
    }
  }

  static String emoji(int mood) {
    switch (mood) {
      case 0: return '😊';
      case 1: return '😞';
      case 2: return '😠';
      default: return '😐';
    }
  }
}

/// A custom-painted donut chart for mood distribution.
class MoodDonutChart extends StatelessWidget {
  const MoodDonutChart({
    super.key,
    required this.moodCounts,
    required this.totalEntries,
    this.size = 140,
  });

  final Map<int, int> moodCounts;
  final int totalEntries;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DonutPainter(moodCounts: moodCounts, total: totalEntries),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.moodCounts, required this.total});

  final Map<int, int> moodCounts;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 20.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    if (total == 0) {
      // Empty state — draw a faint ring
      final emptyPaint = Paint()
        ..color = SanctuaryColors.surfaceContainerHigh
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius - strokeWidth / 2, emptyPaint);
      return;
    }

    // Sort moods by count descending for consistent rendering
    final entries = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double startAngle = -math.pi / 2; // Start from top
    for (final entry in entries) {
      if (entry.value == 0) continue;
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = MoodChartColors.forMood(entry.key)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle - 0.04, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.total != total || old.moodCounts != moodCounts;
}

/// A simple bar chart for 7-day mood entry trend.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.last7DaysCounts,
    this.height = 120,
  });

  final Map<int, int> last7DaysCounts;
  final double height;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1=Mon..7=Sun

    // Build ordered list starting 6 days ago
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final maxCount = last7DaysCounts.values.fold<int>(0, math.max);
    final normalMax = maxCount < 1 ? 1 : maxCount;

    return SizedBox(
      height: height + 32, // bar area + count label + day label + spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          final count = last7DaysCounts[day.weekday] ?? 0;
          final fraction = count / normalMax;
          final isToday = day.weekday == todayWeekday &&
              day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (count > 0)
                    Text(
                      '$count',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: SanctuaryColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Container(
                    height: math.max(4, fraction * (height - 20)),
                    decoration: BoxDecoration(
                      color: isToday
                          ? SanctuaryColors.primary
                          : SanctuaryColors.primaryContainer,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      boxShadow: isToday
                          ? SanctuaryShadows.extruded(intensity: 0.4)
                          : [],
                    ),
                  ),
                  const SizedBox(height: SanctuarySpacing.xs),
                  Text(
                    _dayLabels[day.weekday - 1],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isToday
                          ? SanctuaryColors.primary
                          : SanctuaryColors.onSurfaceVariant.withValues(alpha: 0.6),
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
