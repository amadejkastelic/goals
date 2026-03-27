import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/category.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    this.category,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final daysElapsed = _daysElapsed();

    return Dismissible(
      key: Key('goal_${goal.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (goal.isFasting && goal.fastingProtocol != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(
                            '${goal.fastingProtocol!.icon} ${goal.fastingProtocol!.displayName}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    _buildStatusChip(context),
                  ],
                ),
                if (goal.description != null &&
                    goal.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    goal.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (category != null) ...[
                      Chip(
                        label: Text(
                          '${category!.emoji ?? ''} ${category!.name}'.trim(),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    Text(
                      'Day $daysElapsed of ${goal.durationDays}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: progress, minHeight: 6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    switch (goal.status) {
      case 'active':
        color = Colors.green;
      case 'paused':
        color = Colors.orange;
      case 'completed':
        color = Colors.blue;
      case 'abandoned':
        color = Colors.grey;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        goal.status[0].toUpperCase() + goal.status.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  double _calculateProgress() {
    final elapsed = _daysElapsed();
    return (elapsed / goal.durationDays).clamp(0.0, 1.0);
  }

  int _daysElapsed() {
    final now = DateTime.now();
    final diff = now.difference(goal.startDate).inDays;
    return diff + 1;
  }
}
