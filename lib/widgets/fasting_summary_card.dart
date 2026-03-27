import 'package:flutter/material.dart';
import '../models/fasting_session.dart';

class FastingSummaryCard extends StatelessWidget {
  final FastingSession session;
  final double targetHours;
  final bool readOnly;

  const FastingSummaryCard({
    super.key,
    required this.session,
    required this.targetHours,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = session.achievementRatio(targetHours);
    final achieved = ratio >= 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  achieved ? Icons.check_circle : Icons.timelapse,
                  color: achieved ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fasting Summary',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  session.formattedActualHours,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: achieved ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProgressBar(context, ratio),
            const SizedBox(height: 8),
            Text(
              'Target: ${targetHours.toStringAsFixed(targetHours == targetHours.roundToDouble() ? 0 : 1)}h',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            if (session.fastStartedAt != null) ...[
              const SizedBox(height: 12),
              _buildTimeRow(
                context,
                'Fast started',
                _formatTime(session.fastStartedAt!),
                Icons.bedtime,
              ),
            ],
            if (session.eatingStartedAt != null) ...[
              _buildTimeRow(
                context,
                'Eating window',
                _formatTime(session.eatingStartedAt!),
                Icons.restaurant,
              ),
            ],
            if (session.eatingEndedAt != null) ...[
              _buildTimeRow(
                context,
                'Fast resumed',
                _formatTime(session.eatingEndedAt!),
                Icons.bedtime,
              ),
            ],
            if (session.feelingTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: session.feelingTags.map((tag) {
                  return Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            if (session.breakNote != null && session.breakNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Broke fast with: ${session.breakNote}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double ratio) {
    final clamped = ratio.clamp(0.0, 1.5);
    final percent = (clamped * 100).round();

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clamped >= 1.0 ? 1.0 : clamped,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              clamped >= 1.0
                  ? Colors.green
                  : clamped >= 0.75
                  ? Colors.orange
                  : Colors.red.shade300,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$percent%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: clamped >= 1.0
                  ? Colors.green
                  : clamped >= 0.75
                  ? Colors.orange
                  : Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow(
    BuildContext context,
    String label,
    String time,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            time,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
