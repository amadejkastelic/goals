import 'package:flutter/foundation.dart';
import '../models/custom_field_definition.dart';
import '../models/custom_field_value.dart';
import '../db/database_helper.dart';

class CustomFieldsProvider with ChangeNotifier {
  final Map<int, List<CustomFieldDefinition>> _definitionsByGoal = {};
  final Map<int, List<CustomFieldValue>> _valuesByEntry = {};
  final Map<int, bool> _loadingByGoal = {};
  String? error;

  List<CustomFieldDefinition> getDefinitionsForGoal(int goalId) {
    return _definitionsByGoal[goalId] ?? [];
  }

  List<CustomFieldValue> getValuesForEntry(int entryId) {
    return _valuesByEntry[entryId] ?? [];
  }

  bool isLoadingForGoal(int goalId) => _loadingByGoal[goalId] ?? false;

  Future<void> loadDefinitionsForGoal(int goalId) async {
    _loadingByGoal[goalId] = true;
    notifyListeners();

    try {
      _definitionsByGoal[goalId] = await DatabaseHelper.instance
          .readCustomFieldDefinitions(goalId);
      error = null;
    } catch (e) {
      error = 'Failed to load custom fields: $e';
    } finally {
      _loadingByGoal[goalId] = false;
      notifyListeners();
    }
  }

  Future<void> loadValuesForEntry(int entryId) async {
    try {
      _valuesByEntry[entryId] = await DatabaseHelper.instance
          .readCustomFieldValues(entryId);
      notifyListeners();
    } catch (e) {
      _valuesByEntry[entryId] = [];
    }
  }

  Future<bool> addDefinition(CustomFieldDefinition def) async {
    try {
      await DatabaseHelper.instance.createCustomFieldDefinition(def);
      await loadDefinitionsForGoal(def.goalId);
      return true;
    } catch (e) {
      error = 'Failed to add custom field: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDefinition(CustomFieldDefinition def) async {
    try {
      await DatabaseHelper.instance.updateCustomFieldDefinition(def);
      await loadDefinitionsForGoal(def.goalId);
      return true;
    } catch (e) {
      error = 'Failed to update custom field: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDefinition(int goalId, int definitionId) async {
    try {
      await DatabaseHelper.instance.deleteCustomFieldDefinition(definitionId);
      await loadDefinitionsForGoal(goalId);
      return true;
    } catch (e) {
      error = 'Failed to delete custom field: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> saveDefinitionsForGoal(
    int goalId,
    List<CustomFieldDefinition> definitions,
  ) async {
    try {
      await DatabaseHelper.instance.deleteCustomFieldDefinitionsForGoal(goalId);
      for (var i = 0; i < definitions.length; i++) {
        final def = definitions[i].copyWith(goalId: goalId, sortOrder: i);
        await DatabaseHelper.instance.createCustomFieldDefinition(def);
      }
      await loadDefinitionsForGoal(goalId);
    } catch (e) {
      error = 'Failed to save custom fields: $e';
      notifyListeners();
    }
  }

  Future<bool> saveValue({
    required int definitionId,
    required int journalEntryId,
    required String value,
  }) async {
    try {
      await DatabaseHelper.instance.saveCustomFieldValue(
        definitionId: definitionId,
        journalEntryId: journalEntryId,
        value: value,
      );
      await loadValuesForEntry(journalEntryId);
      return true;
    } catch (e) {
      error = 'Failed to save custom field value: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> saveAllValuesForEntry(
    int entryId,
    Map<int, String> values,
  ) async {
    try {
      for (final entry in values.entries) {
        await DatabaseHelper.instance.saveCustomFieldValue(
          definitionId: entry.key,
          journalEntryId: entryId,
          value: entry.value,
        );
      }
      await loadValuesForEntry(entryId);
    } catch (e) {
      error = 'Failed to save custom field values: $e';
      notifyListeners();
    }
  }

  void clearGoal(int goalId) {
    _definitionsByGoal.remove(goalId);
    _loadingByGoal.remove(goalId);
    notifyListeners();
  }

  void clearEntry(int entryId) {
    _valuesByEntry.remove(entryId);
  }
}
