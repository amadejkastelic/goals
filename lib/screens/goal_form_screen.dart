import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../models/custom_field_definition.dart';
import '../models/fasting_protocol.dart';
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
  late TextEditingController _customHoursController;
  int? _categoryId;
  DateTime _startDate = DateTime.now();
  String _status = 'active';
  String _goalType = 'regular';
  FastingProtocol _fastingProtocol = FastingProtocol.sixteenEight;
  TimeOfDay _eatingWindowStart = const TimeOfDay(hour: 12, minute: 0);
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
    _customHoursController = TextEditingController(
      text: widget.goal?.fastingTargetHours?.toStringAsFixed(0) ?? '16',
    );
    _categoryId = widget.goal?.categoryId;
    _startDate = widget.goal?.startDate ?? DateTime.now();
    _status = widget.goal?.status ?? 'active';
    _goalType = widget.goal?.goalType ?? 'regular';
    _fastingProtocol =
        widget.goal?.fastingProtocol ?? FastingProtocol.sixteenEight;

    if (widget.goal?.eatingWindowStart != null) {
      final parts = widget.goal!.eatingWindowStart!.split(':');
      _eatingWindowStart = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

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
    _customHoursController.dispose();
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
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildGoalTypeToggle(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _goalType == 'fasting'
                      ? 'Fasting Goal Title'
                      : 'Title',
                  border: const OutlineInputBorder(),
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
              if (_goalType == 'fasting') ...[
                _buildFastingProtocolPicker(),
                const SizedBox(height: 16),
                _buildEatingWindowStart(),
                const SizedBox(height: 16),
              ],
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
              if (_goalType == 'regular') ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                widget.goal?.id != null
                    ? Consumer<CustomFieldsProvider>(
                        builder: (context, provider, _) {
                          if (provider.isLoadingForGoal(widget.goal!.id!)) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
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
                            fields: _customFields.isEmpty
                                ? fields
                                : _customFields,
                            onChanged: (f) => _customFields = f,
                          );
                        },
                      )
                    : CustomFieldEditor(
                        fields: _customFields,
                        onChanged: (f) => _customFields = f,
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalTypeToggle() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'regular',
          label: Text('Regular'),
          icon: Icon(Icons.flag),
        ),
        ButtonSegment(
          value: 'fasting',
          label: Text('Fasting'),
          icon: Icon(Icons.timelapse),
        ),
      ],
      selected: {_goalType},
      onSelectionChanged: (selected) {
        setState(() => _goalType = selected.first);
      },
    );
  }

  Widget _buildFastingProtocolPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fasting Protocol', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: FastingProtocol.values.map((protocol) {
            final isSelected = _fastingProtocol == protocol;
            return InkWell(
              onTap: () => setState(() => _fastingProtocol = protocol),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            protocol.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            protocol.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        protocol.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.7)
                              : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_fastingProtocol == FastingProtocol.custom) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customHoursController,
            decoration: const InputDecoration(
              labelText: 'Target fasting hours',
              border: OutlineInputBorder(),
              suffixText: 'hours',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (_fastingProtocol != FastingProtocol.custom) return null;
              final n = double.tryParse(v ?? '');
              return n == null || n < 1 || n > 48 ? 'Enter 1-48 hours' : null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEatingWindowStart() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule),
      title: const Text('Eating window starts at'),
      subtitle: Text(
        _eatingWindowStart.format(context),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _pickEatingWindowStart,
    );
  }

  Future<void> _pickEatingWindowStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _eatingWindowStart,
    );
    if (picked != null) {
      setState(() => _eatingWindowStart = picked);
    }
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
      double? fastingTargetHours;
      if (_goalType == 'fasting') {
        if (_fastingProtocol == FastingProtocol.custom) {
          fastingTargetHours = double.tryParse(_customHoursController.text);
        } else {
          fastingTargetHours = _fastingProtocol.targetFastingHours;
        }
      }

      final eatingWindowStartStr =
          '${_eatingWindowStart.hour.toString().padLeft(2, '0')}:${_eatingWindowStart.minute.toString().padLeft(2, '0')}';

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
        goalType: _goalType,
        fastingProtocol: _goalType == 'fasting' ? _fastingProtocol : null,
        fastingTargetHours: fastingTargetHours,
        eatingWindowStart: _goalType == 'fasting' ? eatingWindowStartStr : null,
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

      if (success && goalId > 0 && _goalType == 'regular') {
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
