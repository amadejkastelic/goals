import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../models/media_attachment.dart';
import '../db/database_helper.dart';

class JournalProvider with ChangeNotifier {
  final Map<int, List<JournalEntry>> _entriesByGoal = {};
  final Map<int, List<MediaAttachment>> _mediaByEntry = {};
  final Map<int, bool> _loadingByGoal = {};
  final Map<int, String?> _errorByGoal = {};

  List<JournalEntry> getEntriesForGoal(int goalId) {
    return _entriesByGoal[goalId] ?? [];
  }

  JournalEntry? getEntry(int goalId, int dayNumber) {
    final entries = _entriesByGoal[goalId];
    if (entries == null) return null;
    try {
      return entries.firstWhere((e) => e.dayNumber == dayNumber);
    } catch (_) {
      return null;
    }
  }

  List<MediaAttachment> getMediaForEntry(int entryId) {
    return _mediaByEntry[entryId] ?? [];
  }

  bool isLoadingForGoal(int goalId) => _loadingByGoal[goalId] ?? false;
  String? errorForGoal(int goalId) => _errorByGoal[goalId];

  Future<void> loadEntriesForGoal(int goalId) async {
    _loadingByGoal[goalId] = true;
    _errorByGoal[goalId] = null;
    notifyListeners();

    try {
      _entriesByGoal[goalId] = await DatabaseHelper.instance
          .readJournalEntriesForGoal(goalId);
      _errorByGoal[goalId] = null;
    } catch (e) {
      _errorByGoal[goalId] = 'Failed to load entries: $e';
    } finally {
      _loadingByGoal[goalId] = false;
      notifyListeners();
    }
  }

  Future<void> loadMediaForEntry(int entryId) async {
    try {
      _mediaByEntry[entryId] = await DatabaseHelper.instance
          .readMediaAttachments(entryId);
      notifyListeners();
    } catch (e) {
      _mediaByEntry[entryId] = [];
    }
  }

  Future<JournalEntry?> saveEntry(JournalEntry entry) async {
    try {
      debugPrint(
        'saveEntry: id=${entry.id}, mfpNutrition=${entry.mfpNutrition?.calories}',
      );
      JournalEntry savedEntry;
      if (entry.id != null) {
        await DatabaseHelper.instance.updateJournalEntry(entry);
        savedEntry = entry;
      } else {
        final id = await DatabaseHelper.instance.createJournalEntry(entry);
        savedEntry = JournalEntry(
          id: id,
          goalId: entry.goalId,
          dayNumber: entry.dayNumber,
          date: entry.date,
          content: entry.content,
          moodEmoji: entry.moodEmoji,
          mfpNutrition: entry.mfpNutrition,
        );
      }
      await loadEntriesForGoal(entry.goalId);
      return savedEntry;
    } catch (e) {
      _errorByGoal[entry.goalId] = 'Failed to save entry: $e';
      notifyListeners();
      return null;
    }
  }

  Future<JournalEntry?> saveEntryWithClearedNutrition(
    JournalEntry entry,
  ) async {
    try {
      if (entry.id != null) {
        await DatabaseHelper.instance.clearMFPNutrition(entry.id!);
      }
      await loadEntriesForGoal(entry.goalId);

      return JournalEntry(
        id: entry.id,
        goalId: entry.goalId,
        dayNumber: entry.dayNumber,
        date: entry.date,
        content: entry.content,
        moodEmoji: entry.moodEmoji,
        mfpNutrition: null,
      );
    } catch (e) {
      _errorByGoal[entry.goalId] = 'Failed to clear nutrition: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> addMedia(MediaAttachment attachment) async {
    try {
      await DatabaseHelper.instance.createMediaAttachment(attachment);
      await loadMediaForEntry(attachment.journalEntryId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMedia(int entryId, int mediaId) async {
    try {
      await DatabaseHelper.instance.deleteMediaAttachment(mediaId);
      await loadMediaForEntry(entryId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEntry(int goalId, int entryId) async {
    try {
      await DatabaseHelper.instance.deleteJournalEntry(entryId);
      _mediaByEntry.remove(entryId);
      await loadEntriesForGoal(goalId);
      return true;
    } catch (e) {
      _errorByGoal[goalId] = 'Failed to delete entry: $e';
      notifyListeners();
      return false;
    }
  }

  void clearGoal(int goalId) {
    _entriesByGoal.remove(goalId);
    _loadingByGoal.remove(goalId);
    _errorByGoal.remove(goalId);
    notifyListeners();
  }

  void clearError(int goalId) {
    _errorByGoal[goalId] = null;
    notifyListeners();
  }
}
