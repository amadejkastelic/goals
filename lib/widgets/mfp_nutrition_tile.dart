import 'package:flutter/material.dart';
import '../models/mfp_nutrition.dart';

class MFPNutritionTile extends StatelessWidget {
  final MFPNutrition nutrition;
  final VoidCallback? onRefresh;
  final VoidCallback? onRemove;
  final bool showActions;

  const MFPNutritionTile({
    super.key,
    required this.nutrition,
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
                  Icons.restaurant,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'MyFitnessPal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMacroItem(
                  context,
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: nutrition.calories.toString(),
                  unit: '',
                  color: Colors.orange,
                ),
                _buildMacroItem(
                  context,
                  icon: Icons.fitness_center,
                  label: 'Protein',
                  value: nutrition.protein.toStringAsFixed(0),
                  unit: 'g',
                  color: Colors.red,
                ),
                _buildMacroItem(
                  context,
                  icon: Icons.grain,
                  label: 'Carbs',
                  value: nutrition.carbs.toStringAsFixed(0),
                  unit: 'g',
                  color: Colors.amber,
                ),
                _buildMacroItem(
                  context,
                  icon: Icons.water_drop,
                  label: 'Fat',
                  value: nutrition.fat.toStringAsFixed(0),
                  unit: 'g',
                  color: Colors.blue,
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

  Widget _buildMacroItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            '$value$unit',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
