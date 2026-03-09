import 'package:flutter/material.dart';
import '../models/journal_entry.dart';

class JournalDayTile extends StatelessWidget {
  final int dayNumber;
  final DateTime date;
  final JournalEntry? entry;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  const JournalDayTile({
    super.key,
    required this.dayNumber,
    required this.date,
    this.entry,
    required this.isToday,
    required this.isFuture,
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
          ],
        ),
      ),
    );
  }

  Color _getTileColor(BuildContext context) {
    if (isFuture) {
      return Colors.grey.shade200;
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
