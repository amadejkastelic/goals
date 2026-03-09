import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/goal.dart';
import '../data/motivational_quotes.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int morningHour = 9;
  static const int eveningHour = 18;
  static const int minute = 0;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<void> scheduleNotificationsForGoal(Goal goal) async {
    if (goal.id == null || goal.status != 'active') return;

    await cancelNotificationsForGoal(goal);

    final quote = MotivationalQuotes.getRandomQuote();

    await _scheduleDailyNotification(
      id: goal.id! * 10 + 1,
      title: 'Morning reminder: ${goal.title}',
      body: quote,
      hour: morningHour,
      payload: 'goal_${goal.id}',
    );

    await _scheduleDailyNotification(
      id: goal.id! * 10 + 2,
      title: 'Evening reminder: ${goal.title}',
      body: MotivationalQuotes.getRandomQuote(),
      hour: eveningHour,
      payload: 'goal_${goal.id}',
    );
  }

  Future<void> cancelNotificationsForGoal(Goal goal) async {
    if (goal.id == null) return;

    await _notifications.cancel(goal.id! * 10 + 1);
    await _notifications.cancel(goal.id! * 10 + 2);
  }

  Future<void> scheduleNotificationsForGoals(List<Goal> goals) async {
    for (final goal in goals) {
      if (goal.status == 'active') {
        await scheduleNotificationsForGoal(goal);
      } else {
        await cancelNotificationsForGoal(goal);
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    String? payload,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'goals_reminders',
          'Goal Reminders',
          channelDescription: 'Daily reminders for your active goals',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}
