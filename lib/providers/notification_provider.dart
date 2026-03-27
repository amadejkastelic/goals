import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../models/goal.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _enabledKey = 'notifications_enabled';
  static const String _morningHourKey = 'notification_morning_hour';
  static const String _eveningHourKey = 'notification_evening_hour';

  static const int defaultMorningHour = 9;
  static const int defaultEveningHour = 18;

  final NotificationService _notificationService = NotificationService();

  bool _notificationsEnabled = false;
  int _morningHour = defaultMorningHour;
  int _eveningHour = defaultEveningHour;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  bool get notificationsEnabled => _notificationsEnabled;
  int get morningHour => _morningHour;
  int get eveningHour => _eveningHour;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _notificationService.initialize();

      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_enabledKey) ?? false;
      _morningHour = prefs.getInt(_morningHourKey) ?? defaultMorningHour;
      _eveningHour = prefs.getInt(_eveningHourKey) ?? defaultEveningHour;

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
          await _notificationService.scheduleNotificationsForGoals(
            activeGoals,
            morningHour: _morningHour,
            eveningHour: _eveningHour,
          );
        }
      } else {
        await _notificationService.cancelAllNotifications();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);

      _notificationsEnabled = enabled;
      _error = null;
    } catch (e) {
      _error = 'Failed to update notification settings: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setMorningHour(int hour, {List<Goal>? activeGoals}) async {
    _morningHour = hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_morningHourKey, hour);
    notifyListeners();

    if (_notificationsEnabled && activeGoals != null) {
      await _rescheduleAll(activeGoals);
    }
  }

  Future<void> setEveningHour(int hour, {List<Goal>? activeGoals}) async {
    _eveningHour = hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_eveningHourKey, hour);
    notifyListeners();

    if (_notificationsEnabled && activeGoals != null) {
      await _rescheduleAll(activeGoals);
    }
  }

  Future<void> _rescheduleAll(List<Goal> goals) async {
    try {
      await _notificationService.scheduleNotificationsForGoals(
        goals,
        morningHour: _morningHour,
        eveningHour: _eveningHour,
      );
    } catch (e) {
      debugPrint('Failed to reschedule notifications: $e');
    }
  }

  Future<void> updateGoalNotifications(Goal goal) async {
    if (!_notificationsEnabled) return;

    try {
      if (goal.status == 'active') {
        await _notificationService.scheduleNotificationsForGoal(
          goal,
          morningHour: _morningHour,
          eveningHour: _eveningHour,
        );
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
      await _notificationService.scheduleNotificationsForGoals(
        goals,
        morningHour: _morningHour,
        eveningHour: _eveningHour,
      );
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
