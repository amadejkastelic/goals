import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../models/custom_field_definition.dart';
import '../providers/goals_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/custom_fields_provider.dart';
import '../widgets/custom_field_editor.dart';

class GoalFormScreen extends StatefulWidget {
  final Goal? goal;

  const GoalFormScreen({super.key, this.goal});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  int? _categoryId;
  DateTime _startDate = DateTime.now();
  String _status = 'active';
  bool _isSaving = false;
  List<CustomFieldDefinition> _customFields = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal?.title);
    _descriptionController = TextEditingController(
      text: widget.goal?.description,
    );
    _durationController = TextEditingController(
      text: '${widget.goal?.durationDays ?? 30}',
    );
    _categoryId = widget.goal?.categoryId;
    _startDate = widget.goal?.startDate ?? DateTime.now();
    _status = widget.goal?.status ?? 'active';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().loadCategories();
      if (widget.goal?.id != null) {
        context.read<CustomFieldsProvider>().loadDefinitionsForGoal(
          widget.goal!.id!,
        );
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'New Goal'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Consumer<CategoriesProvider>(
              builder: (context, provider, _) {
                return DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text('${cat.emoji ?? ''} ${cat.name}'.trim()),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (days)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 1 ? 'Enter a valid number' : null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date'),
              subtitle: Text(DateFormat.yMMMd().format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: ['active', 'paused', 'completed', 'abandoned'].map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s[0].toUpperCase() + s.substring(1)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            widget.goal?.id != null
                ? Consumer<CustomFieldsProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoadingForGoal(widget.goal!.id!)) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final fields = provider.getDefinitionsForGoal(
                        widget.goal!.id!,
                      );
                      if (_customFields.isEmpty && fields.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() => _customFields = List.from(fields));
                        });
                      }
                      return CustomFieldEditor(
                        fields: _customFields.isEmpty ? fields : _customFields,
                        onChanged: (f) => _customFields = f,
                      );
                    },
                  )
                : CustomFieldEditor(
                    fields: _customFields,
                    onChanged: (f) => _customFields = f,
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final goal = Goal(
        id: widget.goal?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        categoryId: _categoryId,
        durationDays: int.parse(_durationController.text),
        startDate: _startDate,
        status: _status,
      );

      final goalsProvider = context.read<GoalsProvider>();
      final customFieldsProvider = context.read<CustomFieldsProvider>();

      bool success;
      int goalId;

      if (widget.goal != null) {
        success = await goalsProvider.updateGoal(goal);
        goalId = widget.goal!.id!;
      } else {
        final newId = await goalsProvider.addGoalWithId(goal);
        if (newId == null) {
          success = false;
          goalId = 0;
        } else {
          success = true;
          goalId = newId;
        }
      }

      if (success && goalId > 0) {
        await customFieldsProvider.saveDefinitionsForGoal(
          goalId,
          _customFields.where((f) => f.name.isNotEmpty).toList(),
        );
      }

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(goalsProvider.error ?? 'Failed to save goal')),
        );
      } else if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
