import 'package:flutter/foundation.dart';
import '../models/fasting_session.dart';
import '../db/database_helper.dart';

class FastingProvider with ChangeNotifier {
  final Map<int, FastingSession> _sessionsByEntry = {};
  final Map<int, List<FastingSession>> _sessionsByGoal = {};
  final Map<int, bool> _loadingByGoal = {};

  FastingSession? getSessionForEntry(int entryId) {
    return _sessionsByEntry[entryId];
  }

  List<FastingSession> getSessionsForGoal(int goalId) {
    return _sessionsByGoal[goalId] ?? [];
  }

  bool isLoadingForGoal(int goalId) => _loadingByGoal[goalId] ?? false;

  Future<void> loadSessionsForEntry(int entryId) async {
    try {
      final session = await DatabaseHelper.instance.readFastingSessionForEntry(
        entryId,
      );
      if (session != null) {
        _sessionsByEntry[entryId] = session;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load fasting session for entry $entryId: $e');
    }
  }

  Future<void> loadSessionsForGoal(int goalId) async {
    _loadingByGoal[goalId] = true;
    notifyListeners();

    try {
      final sessions = await DatabaseHelper.instance.readFastingSessionsForGoal(
        goalId,
      );
      _sessionsByGoal[goalId] = sessions;
      for (final session in sessions) {
        _sessionsByEntry[session.journalEntryId] = session;
      }
    } catch (e) {
      debugPrint('Failed to load fasting sessions for goal $goalId: $e');
    } finally {
      _loadingByGoal[goalId] = false;
      notifyListeners();
    }
  }

  Future<FastingSession?> saveSession(FastingSession session) async {
    try {
      await DatabaseHelper.instance.saveFastingSession(session);

      FastingSession saved;
      if (session.id != null) {
        saved = session;
      } else {
        final existing = await DatabaseHelper.instance
            .readFastingSessionForEntry(session.journalEntryId);
        saved = existing ?? session;
      }

      _sessionsByEntry[saved.journalEntryId] = saved;
      notifyListeners();
      return saved;
    } catch (e) {
      debugPrint('Failed to save fasting session: $e');
      return null;
    }
  }

  Future<bool> deleteSession(int entryId) async {
    try {
      final session = _sessionsByEntry[entryId];
      if (session?.id != null) {
        await DatabaseHelper.instance.deleteFastingSession(session!.id!);
      }
      _sessionsByEntry.remove(entryId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to delete fasting session: $e');
      return false;
    }
  }

  int getCurrentStreak(int goalId) {
    final sessions = _sessionsByGoal[goalId];
    if (sessions == null || sessions.isEmpty) return 0;

    final sorted = List<FastingSession>.from(sessions)
      ..sort((a, b) {
        final aId = _sessionsByEntry.entries
            .firstWhere((e) => e.value.id == a.id, orElse: () => MapEntry(0, a))
            .key;
        final bId = _sessionsByEntry.entries
            .firstWhere((e) => e.value.id == b.id, orElse: () => MapEntry(0, b))
            .key;
        return aId.compareTo(bId);
      });

    int streak = 0;
    for (int i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].actualFastingHours != null &&
          sorted[i].actualFastingHours! > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int getBestStreak(int goalId) {
    final sessions = _sessionsByGoal[goalId];
    if (sessions == null || sessions.isEmpty) return 0;

    int bestStreak = 0;
    int currentStreak = 0;

    for (final session in sessions) {
      if (session.actualFastingHours != null &&
          session.actualFastingHours! > 0) {
        currentStreak++;
        if (currentStreak > bestStreak) bestStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    }
    return bestStreak;
  }

  double getAverageHours(int goalId) {
    final sessions = _sessionsByGoal[goalId];
    if (sessions == null || sessions.isEmpty) return 0.0;

    final withHours = sessions
        .where((s) => s.actualFastingHours != null)
        .toList();
    if (withHours.isEmpty) return 0.0;

    final total = withHours.fold<double>(
      0.0,
      (sum, s) => sum + s.actualFastingHours!,
    );
    return total / withHours.length;
  }

  double getLongestFast(int goalId) {
    final sessions = _sessionsByGoal[goalId];
    if (sessions == null || sessions.isEmpty) return 0.0;

    return sessions
        .where((s) => s.actualFastingHours != null)
        .fold<double>(
          0.0,
          (max, s) => s.actualFastingHours! > max ? s.actualFastingHours! : max,
        );
  }

  void clearGoal(int goalId) {
    _sessionsByGoal.remove(goalId);
    _loadingByGoal.remove(goalId);
    notifyListeners();
  }
}
