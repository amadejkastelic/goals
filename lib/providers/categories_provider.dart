import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../db/database_helper.dart';

class CategoriesProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await DatabaseHelper.instance.readAllCategories();
      _error = null;
    } catch (e) {
      _error = 'Failed to load categories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(Category category) async {
    try {
      await DatabaseHelper.instance.createCategory(category);
      await loadCategories();
      return true;
    } catch (e) {
      _error = 'Failed to add category: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      await DatabaseHelper.instance.updateCategory(category);
      await loadCategories();
      return true;
    } catch (e) {
      _error = 'Failed to update category: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await DatabaseHelper.instance.deleteCategory(id);
      await loadCategories();
      return true;
    } catch (e) {
      _error = 'Failed to delete category: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
