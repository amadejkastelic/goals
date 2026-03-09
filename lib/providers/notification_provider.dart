import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../models/goal.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const int defaultMorningHour = 9;
  static const int defaultEveningHour = 18;

  final NotificationService _notificationService = NotificationService();

  bool _notificationsEnabled = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _notificationService.initialize();

      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? false;

      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize notifications: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(
    bool enabled, {
    List<Goal>? activeGoals,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (enabled) {
        final granted = await _notificationService.requestPermissions();
        if (!granted) {
          _error = 'Notification permission denied';
          _isLoading = false;
          notifyListeners();
          return;
        }

        if (activeGoals != null) {
          await _notificationService.scheduleNotificationsForGoals(activeGoals);
        }
      } else {
        await _notificationService.cancelAllNotifications();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, enabled);

      _notificationsEnabled = enabled;
      _error = null;
    } catch (e) {
      _error = 'Failed to update notification settings: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateGoalNotifications(Goal goal) async {
    if (!_notificationsEnabled) return;

    try {
      if (goal.status == 'active') {
        await _notificationService.scheduleNotificationsForGoal(goal);
      } else {
        await _notificationService.cancelNotificationsForGoal(goal);
      }
    } catch (e) {
      debugPrint('Failed to update goal notifications: $e');
    }
  }

  Future<void> refreshAllNotifications(List<Goal> goals) async {
    if (!_notificationsEnabled) return;

    try {
      await _notificationService.scheduleNotificationsForGoals(goals);
    } catch (e) {
      debugPrint('Failed to refresh notifications: $e');
    }
  }

  Future<void> removeAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('Failed to cancel notifications: $e');
    }
  }
}
