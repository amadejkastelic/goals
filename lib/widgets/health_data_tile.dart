import 'package:flutter/material.dart';
import '../models/health_data.dart';

class HealthDataTile extends StatelessWidget {
  final HealthData healthData;
  final VoidCallback? onRefresh;
  final VoidCallback? onRemove;
  final bool showActions;

  const HealthDataTile({
    super.key,
    required this.healthData,
    this.onRefresh,
    this.onRemove,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Health Data',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                if (healthData.steps != null)
                  _buildMetricItem(
                    context,
                    icon: Icons.directions_walk,
                    label: 'Steps',
                    value: healthData.formattedSteps,
                    color: Colors.green,
                  ),
                if (healthData.activeCalories != null)
                  _buildMetricItem(
                    context,
                    icon: Icons.local_fire_department,
                    label: 'Active Cal',
                    value: healthData.formattedCalories,
                    color: Colors.orange,
                  ),
                if (healthData.heartRate != null)
                  _buildMetricItem(
                    context,
                    icon: Icons.favorite_border,
                    label: 'Avg HR',
                    value: healthData.formattedHeartRate,
                    color: Colors.red,
                  ),
                if (healthData.sleepMinutes != null)
                  _buildMetricItem(
                    context,
                    icon: Icons.bedtime,
                    label: 'Sleep',
                    value: healthData.formattedSleep,
                    color: Colors.indigo,
                  ),
              ],
            ),
            if (showActions && (onRefresh != null || onRemove != null)) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onRefresh != null)
                    TextButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                    ),
                  if (onRemove != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      label: Text(
                        'Remove',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
