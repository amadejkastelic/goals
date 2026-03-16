import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../models/health_data.dart';

enum HealthConnectStatus {
  available,
  notInstalled,
  needsUpdate,
  permissionDenied,
}

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();
  bool _configured = false;
  String? _lastError;

  String? get lastError => _lastError;

  static const List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
  ];

  Future<bool> _ensureConfigured() async {
    if (_configured) return true;
    try {
      await _health.configure();
      _configured = true;
      return true;
    } catch (e) {
      _lastError = 'Failed to configure health: $e';
      return false;
    }
  }

  Future<HealthConnectStatus> getHealthConnectStatus() async {
    if (!await _ensureConfigured()) return HealthConnectStatus.notInstalled;

    try {
      final status = await _health.getHealthConnectSdkStatus();
      debugPrint('Health Connect SDK status: $status');
      switch (status) {
        case HealthConnectSdkStatus.sdkAvailable:
          return HealthConnectStatus.available;
        case HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired:
          return HealthConnectStatus.needsUpdate;
        default:
          return HealthConnectStatus.notInstalled;
      }
    } catch (e) {
      _lastError = 'Failed to get HC status: $e';
      return HealthConnectStatus.notInstalled;
    }
  }

  Future<bool> isHealthConnectAvailable() async {
    final status = await getHealthConnectStatus();
    return status == HealthConnectStatus.available;
  }

  Future<HealthConnectStatus> requestPermissions() async {
    if (!await _ensureConfigured()) {
      return HealthConnectStatus.notInstalled;
    }

    try {
      final status = await getHealthConnectStatus();
      debugPrint('HC status before request: $status');

      if (status == HealthConnectStatus.notInstalled ||
          status == HealthConnectStatus.needsUpdate) {
        debugPrint('Installing Health Connect...');
        await _health.installHealthConnect();
        return status;
      }

      debugPrint('Requesting authorization for: $_dataTypes');
      final granted = await _health.requestAuthorization(_dataTypes);
      debugPrint('Authorization result: $granted');

      if (!granted) {
        _lastError = 'Permission denied by user';
        return HealthConnectStatus.permissionDenied;
      }

      return HealthConnectStatus.available;
    } catch (e) {
      _lastError = 'Permission request failed: $e';
      debugPrint('Permission error: $e');
      return HealthConnectStatus.permissionDenied;
    }
  }

  Future<bool> hasPermissions() async {
    if (!await _ensureConfigured()) return false;

    try {
      final available = await isHealthConnectAvailable();
      if (!available) return false;

      final hasAccess = await _health.hasPermissions(_dataTypes);
      debugPrint('Has permissions: $hasAccess');
      return hasAccess == true;
    } catch (e) {
      _lastError = 'Permission check failed: $e';
      debugPrint('Permission check error: $e');
      return false;
    }
  }

  Future<HealthData?> fetchData(DateTime date) async {
    if (!await _ensureConfigured()) return null;

    try {
      final available = await isHealthConnectAvailable();
      if (!available) {
        _lastError = 'Health Connect not available';
        return null;
      }

      final hasAuth = await hasPermissions();
      if (!hasAuth) {
        final result = await requestPermissions();
        if (result != HealthConnectStatus.available) {
          return null;
        }
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      int? steps;
      double? activeCalories;
      double? heartRate;
      int? sleepMinutes;

      try {
        final stepsData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: startOfDay,
          endTime: endOfDay,
        );
        steps = _aggregateNumericValue(stepsData);
        debugPrint('Steps: $steps');
      } catch (e) {
        debugPrint('Failed to fetch steps: $e');
      }

      try {
        final caloriesData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: startOfDay,
          endTime: endOfDay,
        );
        activeCalories = _aggregateNumericValue(caloriesData)?.toDouble();
        debugPrint('Calories: $activeCalories');
      } catch (e) {
        debugPrint('Failed to fetch calories: $e');
      }

      try {
        final heartData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: startOfDay,
          endTime: endOfDay,
        );
        heartRate = _averageNumericValue(heartData);
        debugPrint('Heart rate: $heartRate');
      } catch (e) {
        debugPrint('Failed to fetch heart rate: $e');
      }

      try {
        final sleepData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.SLEEP_ASLEEP],
          startTime: startOfDay.subtract(const Duration(hours: 12)),
          endTime: endOfDay.add(const Duration(hours: 12)),
        );
        sleepMinutes = _aggregateSleepForDate(sleepData, date);
        debugPrint('Sleep minutes: $sleepMinutes');
      } catch (e) {
        debugPrint('Failed to fetch sleep: $e');
      }

      if (steps == null &&
          activeCalories == null &&
          heartRate == null &&
          sleepMinutes == null) {
        _lastError = 'No health data found for this date';
        return null;
      }

      return HealthData(
        steps: steps,
        activeCalories: activeCalories,
        heartRate: heartRate,
        sleepMinutes: sleepMinutes,
      );
    } catch (e) {
      _lastError = 'Failed to fetch health data: $e';
      debugPrint('Fetch error: $e');
      return null;
    }
  }

  int? _aggregateNumericValue(List<HealthDataPoint> data) {
    if (data.isEmpty) return null;
    double total = 0;
    for (final point in data) {
      final value = point.value;
      if (value is NumericHealthValue) {
        total += value.numericValue;
      }
    }
    return total.toInt();
  }

  double? _averageNumericValue(List<HealthDataPoint> data) {
    if (data.isEmpty) return null;
    double total = 0;
    int count = 0;
    for (final point in data) {
      final value = point.value;
      if (value is NumericHealthValue) {
        total += value.numericValue;
        count++;
      }
    }
    if (count == 0) return null;
    return total / count;
  }

  int? _aggregateSleepForDate(List<HealthDataPoint> data, DateTime targetDate) {
    if (data.isEmpty) return null;

    final targetDateOnly = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final dayStart = targetDateOnly.subtract(const Duration(hours: 12));
    final dayEnd = targetDateOnly.add(const Duration(hours: 36));

    double totalMinutes = 0;
    for (final point in data) {
      if (point.dateFrom.isAfter(dayStart) && point.dateFrom.isBefore(dayEnd)) {
        final value = point.value;
        if (value is NumericHealthValue) {
          totalMinutes += value.numericValue;
        }
      }
    }

    return totalMinutes > 0 ? totalMinutes.toInt() : null;
  }
}
