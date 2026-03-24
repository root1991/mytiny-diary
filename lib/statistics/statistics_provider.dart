import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mytiny_diary/data/note_repository.dart';
import 'package:mytiny_diary/models/note.dart';

class MoodStats {
  final int totalEntries;
  final int dayStreak;
  final int topMood; // 0=happy, 1=sad, 2=angry, 3=neutral
  final Map<int, int> moodCounts; // mood index → count
  final Map<int, int> last7DaysCounts; // weekday (1=Mon..7=Sun) → count
  final String summaryText;
  final String summarySubtext;

  const MoodStats({
    required this.totalEntries,
    required this.dayStreak,
    required this.topMood,
    required this.moodCounts,
    required this.last7DaysCounts,
    required this.summaryText,
    required this.summarySubtext,
  });

  factory MoodStats.empty() => const MoodStats(
    totalEntries: 0,
    dayStreak: 0,
    topMood: 3,
    moodCounts: {},
    last7DaysCounts: {},
    summaryText: 'No entries yet',
    summarySubtext: 'Start writing to see your mood insights.',
  );

  double moodPercentage(int mood) {
    if (totalEntries == 0) return 0;
    return (moodCounts[mood] ?? 0) / totalEntries;
  }
}

final moodStatsProvider = FutureProvider<MoodStats>((ref) async {
  final notes = await NoteRepository.instance.getAll();
  if (notes.isEmpty) return MoodStats.empty();

  return _computeStats(notes);
});

MoodStats _computeStats(List<Note> notes) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Mood counts
  final moodCounts = <int, int>{};
  for (final note in notes) {
    moodCounts[note.mood] = (moodCounts[note.mood] ?? 0) + 1;
  }

  // Top mood
  int topMood = 3;
  int topCount = 0;
  for (final entry in moodCounts.entries) {
    if (entry.value > topCount) {
      topCount = entry.value;
      topMood = entry.key;
    }
  }

  // Day streak — count consecutive days backwards from today
  final daysWithEntries = <DateTime>{};
  for (final note in notes) {
    final d = note.createdAt.toLocal();
    daysWithEntries.add(DateTime(d.year, d.month, d.day));
  }
  int streak = 0;
  for (int i = 0; i < 365; i++) {
    final day = today.subtract(Duration(days: i));
    if (daysWithEntries.contains(day)) {
      streak++;
    } else {
      break;
    }
  }

  // Last 7 days counts by weekday
  final weekStart = today.subtract(Duration(days: 6));
  final last7DaysCounts = <int, int>{};
  for (int i = 0; i < 7; i++) {
    final day = weekStart.add(Duration(days: i));
    last7DaysCounts[day.weekday] = 0;
  }
  for (final note in notes) {
    final d = note.createdAt.toLocal();
    final day = DateTime(d.year, d.month, d.day);
    if (!day.isBefore(weekStart) && !day.isAfter(today)) {
      last7DaysCounts[day.weekday] =
          (last7DaysCounts[day.weekday] ?? 0) + 1;
    }
  }

  // Recent entries (last 14 days)
  final twoWeeksAgo = today.subtract(const Duration(days: 14));
  final recentCount = notes.where((n) {
    final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
    return !d.isBefore(twoWeeksAgo);
  }).length;

  final moodLabel = _moodLabel(topMood);
  final summaryText = 'Generally $moodLabel this week';
  final summarySubtext = "You've logged $recentCount entries recently.";

  return MoodStats(
    totalEntries: notes.length,
    dayStreak: streak,
    topMood: topMood,
    moodCounts: moodCounts,
    last7DaysCounts: last7DaysCounts,
    summaryText: summaryText,
    summarySubtext: summarySubtext,
  );
}

String _moodLabel(int mood) {
  switch (mood) {
    case 0: return 'Happy';
    case 1: return 'Sad';
    case 2: return 'Angry';
    default: return 'Neutral';
  }
}
