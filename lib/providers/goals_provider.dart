import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../db/database_helper.dart';

class GoalsProvider extends ChangeNotifier {
  List<Goal> _goals = [];
  String _statusFilter = 'all';
  bool _isLoading = false;
  String? _error;
  void Function(Goal)? onGoalChanged;
  void Function(int)? onGoalDeleted;
  void Function()? onGoalsLoaded;

  List<Goal> get goals {
    if (_statusFilter == 'all') return _goals;
    return _goals.where((g) => g.status == _statusFilter).toList();
  }

  List<Goal> get activeGoals =>
      _goals.where((g) => g.status == 'active').toList();

  String get statusFilter => _statusFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGoals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _goals = await DatabaseHelper.instance.readAllGoals();
      _error = null;
      onGoalsLoaded?.call();
    } catch (e) {
      _error = 'Failed to load goals: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<bool> addGoal(Goal goal) async {
    try {
      final id = await DatabaseHelper.instance.createGoal(goal);
      final newGoal = goal.copyWith(id: id);
      await loadGoals();
      onGoalChanged?.call(newGoal);
      return true;
    } catch (e) {
      _error = 'Failed to add goal: $e';
      notifyListeners();
      return false;
    }
  }

  Future<int?> addGoalWithId(Goal goal) async {
    try {
      final id = await DatabaseHelper.instance.createGoal(goal);
      final newGoal = goal.copyWith(id: id);
      await loadGoals();
      onGoalChanged?.call(newGoal);
      return id;
    } catch (e) {
      _error = 'Failed to add goal: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateGoal(Goal goal) async {
    try {
      await DatabaseHelper.instance.updateGoal(goal);
      await loadGoals();
      onGoalChanged?.call(goal);
      return true;
    } catch (e) {
      _error = 'Failed to update goal: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGoal(int id) async {
    try {
      await DatabaseHelper.instance.deleteGoal(id);
      await loadGoals();
      onGoalDeleted?.call(id);
      return true;
    } catch (e) {
      _error = 'Failed to delete goal: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
