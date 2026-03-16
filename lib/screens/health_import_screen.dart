import 'package:flutter/material.dart';
import '../models/health_data.dart';
import '../services/health_service.dart';

class HealthImportScreen extends StatefulWidget {
  final DateTime date;

  const HealthImportScreen({super.key, required this.date});

  @override
  State<HealthImportScreen> createState() => _HealthImportScreenState();
}

class _HealthImportScreenState extends State<HealthImportScreen> {
  final _healthService = HealthService();
  bool _isLoading = true;
  bool _healthConnectAvailable = false;
  bool _hasPermissions = false;
  HealthData? _healthData;
  String? _error;

  bool _includeSteps = true;
  bool _includeCalories = true;
  bool _includeHeartRate = true;
  bool _includeSleep = true;

  @override
  void initState() {
    super.initState();
    _checkAndFetchData();
  }

  Future<void> _checkAndFetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _healthConnectAvailable = await _healthService.isHealthConnectAvailable();

      if (!_healthConnectAvailable) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _hasPermissions = await _healthService.hasPermissions();

      if (!_hasPermissions) {
        final result = await _healthService.requestPermissions();
        _hasPermissions = result == HealthConnectStatus.available;
      }

      if (_hasPermissions) {
        _healthData = await _healthService.fetchData(widget.date);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _importSelected() {
    if (_healthData == null) return;

    HealthData selectedData = HealthData(
      steps: _includeSteps ? _healthData!.steps : null,
      activeCalories: _includeCalories ? _healthData!.activeCalories : null,
      heartRate: _includeHeartRate ? _healthData!.heartRate : null,
      sleepMinutes: _includeSleep ? _healthData!.sleepMinutes : null,
    );

    if (!selectedData.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one metric')),
      );
      return;
    }

    Navigator.of(context).pop(selectedData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Health Data'),
        actions: [
          if (_healthData != null)
            TextButton.icon(
              onPressed: _importSelected,
              icon: const Icon(Icons.check),
              label: const Text('Import'),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError(theme);
    }

    if (!_healthConnectAvailable) {
      return _buildNotAvailable(theme);
    }

    if (!_hasPermissions) {
      return _buildNoPermissions(theme);
    }

    if (_healthData == null || !_healthData!.hasData) {
      return _buildNoData(theme);
    }

    return _buildDataSelection(theme);
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading health data',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkAndFetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAvailable(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Health Connect Not Available',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Health Connect is required to import health data.\n\n'
              '1. Install Health Connect from Play Store\n'
              '2. Open Samsung Health > Settings > Health Connect\n'
              '3. Enable data sync',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await _healthService.requestPermissions();
                _checkAndFetchData();
              },
              icon: const Icon(Icons.download),
              label: const Text('Install Health Connect'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPermissions(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              'Permission Required',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'To import health data, you need to grant permission in Health Connect.\n\n'
              'Tap the button below, then allow access to:\n'
              '• Steps\n'
              '• Active Calories\n'
              '• Heart Rate\n'
              '• Sleep',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await _healthService.requestPermissions();
                if (result == HealthConnectStatus.available) {
                  _checkAndFetchData();
                } else if (mounted) {
                  final error = _healthService.lastError ?? 'Permission denied';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error)));
                }
              },
              icon: const Icon(Icons.key),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoData(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              'No Health Data',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No health data available for ${_formatDate(widget.date)}.\n\n'
              'Make sure Samsung Health is syncing data to Health Connect.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSelection(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select data to import for ${_formatDate(widget.date)}:',
            style: theme.textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              if (_healthData!.steps != null)
                _buildMetricTile(
                  icon: Icons.directions_walk,
                  title: 'Steps',
                  value: _healthData!.formattedSteps,
                  color: Colors.green,
                  isSelected: _includeSteps,
                  onChanged: (v) => setState(() => _includeSteps = v),
                ),
              if (_healthData!.activeCalories != null)
                _buildMetricTile(
                  icon: Icons.local_fire_department,
                  title: 'Active Calories',
                  value: _healthData!.formattedCalories,
                  color: Colors.orange,
                  isSelected: _includeCalories,
                  onChanged: (v) => setState(() => _includeCalories = v),
                ),
              if (_healthData!.heartRate != null)
                _buildMetricTile(
                  icon: Icons.favorite_border,
                  title: 'Average Heart Rate',
                  value: _healthData!.formattedHeartRate,
                  color: Colors.red,
                  isSelected: _includeHeartRate,
                  onChanged: (v) => setState(() => _includeHeartRate = v),
                ),
              if (_healthData!.sleepMinutes != null)
                _buildMetricTile(
                  icon: Icons.bedtime,
                  title: 'Sleep',
                  value: _healthData!.formattedSleep,
                  color: Colors.indigo,
                  isSelected: _includeSleep,
                  onChanged: (v) => setState(() => _includeSleep = v),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isSelected,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (v) => onChanged(v ?? false),
      ),
      onTap: () => onChanged(!isSelected),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
