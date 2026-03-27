import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goals_provider.dart';
import '../providers/categories_provider.dart';
import '../models/goal.dart';
import '../widgets/goal_card.dart';
import '../widgets/status_widgets.dart';
import 'goal_detail_screen.dart';
import 'goal_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _categoryFilter;
  final _statuses = ['all', 'active', 'paused', 'completed', 'abandoned'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<GoalsProvider>().loadGoals(),
      context.read<CategoriesProvider>().loadCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.pushNamed(context, '/categories'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<GoalsProvider, CategoriesProvider>(
          builder: (context, goalsProvider, categoriesProvider, _) {
            if (goalsProvider.isLoading) {
              return const LoadingWidget(message: 'Loading goals...');
            }

            if (goalsProvider.error != null) {
              return ErrorDisplayWidget(
                message: goalsProvider.error!,
                onRetry: () {
                  goalsProvider.clearError();
                  _loadData();
                },
              );
            }

            return Column(
              children: [
                _buildFilters(categoriesProvider),
                Expanded(
                  child: _buildGoalsList(goalsProvider, categoriesProvider),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createGoal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters(CategoriesProvider categoriesProvider) {
    return Consumer<GoalsProvider>(
      builder: (context, goalsProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _statuses.map((status) {
                    final selected = goalsProvider.statusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          status[0].toUpperCase() + status.substring(1),
                        ),
                        selected: selected,
                        onSelected: (_) =>
                            goalsProvider.setStatusFilter(status),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All Categories'),
                        selected: _categoryFilter == null,
                        onSelected: (_) =>
                            setState(() => _categoryFilter = null),
                      ),
                    ),
                    ...categoriesProvider.categories.map((cat) {
                      final selected = _categoryFilter == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${cat.emoji ?? ''} ${cat.name}'.trim()),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _categoryFilter = cat.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalsList(
    GoalsProvider goalsProvider,
    CategoriesProvider categoriesProvider,
  ) {
    var goals = goalsProvider.goals;
    if (_categoryFilter != null) {
      goals = goals.where((g) => g.categoryId == _categoryFilter).toList();
    }

    if (goals.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.flag_outlined,
        title: 'No goals yet',
        description:
            'Start tracking your progress by creating your first goal.',
        actionLabel: 'Create Goal',
        onAction: () => _createGoal(context),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          final category = categoriesProvider.categories
              .where((c) => c.id == goal.categoryId)
              .firstOrNull;
          return GoalCard(
            goal: goal,
            category: category,
            onTap: () => _openGoalDetail(context, goal),
            onDelete: () => _deleteGoal(context, goal),
          );
        },
      ),
    );
  }

  void _createGoal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GoalFormScreen()),
    );
  }

  void _openGoalDetail(BuildContext context, Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goal.id!)),
    );
  }

  void _deleteGoal(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<GoalsProvider>().deleteGoal(
                goal.id!,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.read<GoalsProvider>().error ?? 'Failed to delete',
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
