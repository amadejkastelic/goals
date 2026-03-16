import 'package:health/health.dart';
import '../models/health_data.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();
  bool _configured = false;

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
      return false;
    }
  }

  Future<bool> isHealthConnectAvailable() async {
    if (!await _ensureConfigured()) return false;

    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    if (!await _ensureConfigured()) return false;

    try {
      final available = await isHealthConnectAvailable();
      if (!available) {
        await _health.installHealthConnect();
        return false;
      }

      final granted = await _health.requestAuthorization(_dataTypes);
      return granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    if (!await _ensureConfigured()) return false;

    try {
      final available = await isHealthConnectAvailable();
      if (!available) return false;

      final hasAccess = await _health.hasPermissions(_dataTypes);
      return hasAccess == true;
    } catch (e) {
      return false;
    }
  }

  Future<HealthData?> fetchData(DateTime date) async {
    if (!await _ensureConfigured()) return null;

    try {
      final available = await isHealthConnectAvailable();
      if (!available) return null;

      final hasAuth = await hasPermissions();
      if (!hasAuth) {
        final requested = await requestPermissions();
        if (!requested) return null;
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
      } catch (_) {}

      try {
        final caloriesData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: startOfDay,
          endTime: endOfDay,
        );
        activeCalories = _aggregateNumericValue(caloriesData)?.toDouble();
      } catch (_) {}

      try {
        final heartData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: startOfDay,
          endTime: endOfDay,
        );
        heartRate = _averageNumericValue(heartData);
      } catch (_) {}

      try {
        final sleepData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.SLEEP_ASLEEP],
          startTime: startOfDay.subtract(const Duration(hours: 12)),
          endTime: endOfDay.add(const Duration(hours: 12)),
        );
        sleepMinutes = _aggregateSleepForDate(sleepData, date);
      } catch (_) {}

      if (steps == null &&
          activeCalories == null &&
          heartRate == null &&
          sleepMinutes == null) {
        return null;
      }

      return HealthData(
        steps: steps,
        activeCalories: activeCalories,
        heartRate: heartRate,
        sleepMinutes: sleepMinutes,
      );
    } catch (e) {
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

    return totalMinutes.toInt();
  }
}
