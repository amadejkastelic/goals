import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../models/category.dart';
import '../models/journal_entry.dart';
import '../providers/goals_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/fasting_provider.dart';
import '../db/database_helper.dart';
import '../widgets/journal_day_tile.dart';
import 'journal_entry_screen.dart';
import 'goal_form_screen.dart';

class GoalDetailScreen extends StatefulWidget {
  final int goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  Goal? _goal;
  Category? _category;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final goal = await DatabaseHelper.instance.readGoal(widget.goalId);
    Category? category;
    if (goal.categoryId != null) {
      final List<Category> categories = await DatabaseHelper.instance
          .readAllCategories();
      try {
        category = categories.firstWhere((c) => c.id == goal.categoryId);
      } catch (_) {}
    }

    if (mounted) {
      await context.read<JournalProvider>().loadEntriesForGoal(widget.goalId);
      if (goal.isFasting) {
        await context.read<FastingProvider>().loadSessionsForGoal(
          widget.goalId,
        );
      }
      setState(() {
        _goal = goal;
        _category = category;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal Not Found')),
        body: const Center(child: Text('This goal no longer exists.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_goal!.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => _buildMenuItems(),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<JournalProvider>(
          builder: (context, journalProvider, child) {
            return _buildBody(context, journalProvider);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, JournalProvider journalProvider) {
    final entries = journalProvider.getEntriesForGoal(widget.goalId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(
      _goal!.startDate.year,
      _goal!.startDate.month,
      _goal!.startDate.day,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (_goal!.isFasting) ...[
            const SizedBox(height: 16),
            _buildFastingStats(context),
          ],
          const SizedBox(height: 24),
          Text('Progress', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildDaysGrid(startDate, today, entries, journalProvider),
        ],
      ),
    );
  }

  Widget _buildFastingStats(BuildContext context) {
    return Consumer<FastingProvider>(
      builder: (context, provider, _) {
        final currentStreak = provider.getCurrentStreak(widget.goalId);
        final bestStreak = provider.getBestStreak(widget.goalId);
        final avgHours = provider.getAverageHours(widget.goalId);
        final longestFast = provider.getLongestFast(widget.goalId);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timelapse, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Fasting Stats',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (_goal!.fastingProtocol != null)
                      Chip(
                        label: Text(
                          _goal!.fastingProtocol!.displayName,
                          style: const TextStyle(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Current Streak',
                        '$currentStreak',
                        'days',
                        Icons.local_fire_department,
                        currentStreak > 0 ? Colors.orange : Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Best Streak',
                        '$bestStreak',
                        'days',
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Avg Fast',
                        avgHours.toStringAsFixed(1),
                        'hours',
                        Icons.analytics,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Longest Fast',
                        longestFast.toStringAsFixed(1),
                        'hours',
                        Icons.timer,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$label ($unit)',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final daysElapsed = _daysElapsed();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _goal!.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                _buildStatusChip(context),
              ],
            ),
            if (_goal!.description != null &&
                _goal!.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_goal!.description!),
            ],
            const Divider(height: 24),
            Row(
              children: [
                if (_category != null) ...[
                  Chip(
                    label: Text(
                      '${_category!.emoji ?? ''} ${_category!.name}'.trim(),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 16),
                ],
                if (_goal!.isFasting && _goal!.fastingProtocol != null) ...[
                  Chip(
                    label: Text(
                      '${_goal!.fastingProtocol!.icon} ${_goal!.fastingProtocol!.displayName}',
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Started ${dateFormat.format(_goal!.startDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Day $daysElapsed of ${_goal!.durationDays}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.edit_note, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Consumer<JournalProvider>(
                  builder: (context, jp, _) {
                    final entries = jp.getEntriesForGoal(widget.goalId);
                    return Text(
                      '${entries.length} entries',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    switch (_goal!.status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _goal!.status[0].toUpperCase() + _goal!.status.substring(1),
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildDaysGrid(
    DateTime startDate,
    DateTime today,
    List<JournalEntry> entries,
    JournalProvider journalProvider,
  ) {
    final fastingProvider = _goal!.isFasting
        ? context.read<FastingProvider>()
        : null;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _goal!.durationDays,
      itemBuilder: (context, index) {
        final dayNumber = index + 1;
        final dayDate = startDate.add(Duration(days: index));
        final isToday = dayDate == today;
        final isFuture = dayDate.isAfter(today);
        final entry = journalProvider.getEntry(widget.goalId, dayNumber);

        double? fastingAchievement;
        if (_goal!.isFasting && entry?.id != null && fastingProvider != null) {
          final session = fastingProvider.getSessionForEntry(entry!.id!);
          if (session?.actualFastingHours != null) {
            fastingAchievement =
                session!.actualFastingHours! /
                _goal!.effectiveFastingTargetHours;
          }
        }

        return JournalDayTile(
          dayNumber: dayNumber,
          date: dayDate,
          entry: entry,
          isToday: isToday,
          isFuture: isFuture,
          isFastingGoal: _goal!.isFasting,
          fastingAchievement: fastingAchievement,
          onTap: () => _openJournalEntry(dayNumber, dayDate, entry),
        );
      },
    );
  }

  void _openJournalEntry(int dayNumber, DateTime date, JournalEntry? entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(
          goalId: widget.goalId,
          dayNumber: dayNumber,
          date: date,
          existingEntry: entry,
          isFastingGoal: _goal!.isFasting,
          fastingTargetHours: _goal!.effectiveFastingTargetHours,
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(value: 'edit', child: Text('Edit')),
    ];

    if (_goal!.status != 'active') {
      items.add(const PopupMenuItem(value: 'active', child: Text('Activate')));
    }
    if (_goal!.status != 'completed') {
      items.add(
        const PopupMenuItem(value: 'complete', child: Text('Mark Complete')),
      );
    }
    if (_goal!.status != 'paused') {
      items.add(const PopupMenuItem(value: 'pause', child: Text('Pause')));
    }
    if (_goal!.status != 'abandoned') {
      items.add(const PopupMenuItem(value: 'abandon', child: Text('Abandon')));
    }

    items.add(const PopupMenuDivider());
    items.add(const PopupMenuItem(value: 'delete', child: Text('Delete')));

    return items;
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GoalFormScreen(goal: _goal)),
        );
      case 'active':
        await _updateStatus('active');
      case 'complete':
        await _updateStatus('completed');
      case 'pause':
        await _updateStatus('paused');
      case 'abandon':
        await _updateStatus('abandoned');
      case 'delete':
        await _deleteGoal();
    }
  }

  Future<void> _updateStatus(String status) async {
    final updatedGoal = Goal(
      id: _goal!.id,
      title: _goal!.title,
      description: _goal!.description,
      categoryId: _goal!.categoryId,
      durationDays: _goal!.durationDays,
      startDate: _goal!.startDate,
      status: status,
      goalType: _goal!.goalType,
      fastingProtocol: _goal!.fastingProtocol,
      fastingTargetHours: _goal!.fastingTargetHours,
      eatingWindowStart: _goal!.eatingWindowStart,
    );
    await context.read<GoalsProvider>().updateGoal(updatedGoal);
    setState(() => _goal = updatedGoal);
  }

  Future<void> _deleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text(
          'Are you sure you want to delete "${_goal!.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final goalsProvider = context.read<GoalsProvider>();
      final journalProvider = context.read<JournalProvider>();
      final fastingProvider = context.read<FastingProvider>();
      await goalsProvider.deleteGoal(widget.goalId);
      journalProvider.clearGoal(widget.goalId);
      fastingProvider.clearGoal(widget.goalId);
      if (mounted) Navigator.pop(context);
    }
  }

  int _daysElapsed() {
    final now = DateTime.now();
    final diff = now.difference(_goal!.startDate).inDays;
    return (diff + 1).clamp(1, _goal!.durationDays);
  }
}
