import 'package:flutter/material.dart';
import '../models/journal_entry.dart';

class JournalDayTile extends StatelessWidget {
  final int dayNumber;
  final DateTime date;
  final JournalEntry? entry;
  final bool isToday;
  final bool isFuture;
  final bool isFastingGoal;
  final double? fastingAchievement;
  final VoidCallback onTap;

  const JournalDayTile({
    super.key,
    required this.dayNumber,
    required this.date,
    this.entry,
    required this.isToday,
    required this.isFuture,
    this.isFastingGoal = false,
    this.fastingAchievement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getTileColor(context);
    final textColor = isFuture ? Colors.grey : Colors.white;

    return InkWell(
      onTap: isFuture ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (entry?.moodEmoji != null)
              Text(entry!.moodEmoji!, style: const TextStyle(fontSize: 12)),
            if (isFastingGoal &&
                entry != null &&
                fastingAchievement != null) ...[
              const SizedBox(height: 2),
              Text(
                fastingAchievement! >= 1.0
                    ? '✓'
                    : '${(fastingAchievement! * 100).round()}%',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTileColor(BuildContext context) {
    if (isFuture) {
      return Colors.grey.shade200;
    }
    if (isFastingGoal && entry != null) {
      if (fastingAchievement != null) {
        if (fastingAchievement! >= 1.0) {
          return Colors.green.withValues(alpha: 0.7);
        } else if (fastingAchievement! >= 0.75) {
          return Colors.orange.withValues(alpha: 0.5);
        } else if (fastingAchievement! > 0) {
          return Colors.red.shade300.withValues(alpha: 0.5);
        }
      }
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.4);
    }
    if (entry != null) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.7);
    }
    if (isToday) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);
    }
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.15);
  }
}
