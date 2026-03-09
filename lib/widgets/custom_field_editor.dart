import 'package:flutter/material.dart';
import '../models/custom_field_definition.dart';

class CustomFieldEditor extends StatefulWidget {
  final List<CustomFieldDefinition> fields;
  final void Function(List<CustomFieldDefinition>) onChanged;

  const CustomFieldEditor({
    super.key,
    required this.fields,
    required this.onChanged,
  });

  @override
  State<CustomFieldEditor> createState() => _CustomFieldEditorState();
}

class _CustomFieldEditorState extends State<CustomFieldEditor> {
  late List<CustomFieldDefinition> _fields;

  @override
  void initState() {
    super.initState();
    _fields = List.from(widget.fields);
  }

  void _addField(CustomFieldType type) {
    final field = CustomFieldDefinition(
      goalId: 0,
      name: '',
      fieldType: type,
      sortOrder: _fields.length,
    );
    setState(() {
      _fields.add(field);
    });
    widget.onChanged(_fields);
  }

  void _updateField(int index, CustomFieldDefinition field) {
    setState(() {
      _fields[index] = field;
    });
    widget.onChanged(_fields);
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
    });
    widget.onChanged(_fields);
  }

  void _reorderFields(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final field = _fields.removeAt(oldIndex);
      _fields.insert(newIndex, field);
    });
    widget.onChanged(_fields);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Custom Fields',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            PopupMenuButton<CustomFieldType>(
              icon: const Icon(Icons.add),
              tooltip: 'Add custom field',
              onSelected: _addField,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: CustomFieldType.checkboxes,
                  child: Row(
                    children: [
                      Icon(Icons.check_box_outlined),
                      SizedBox(width: 8),
                      Text('Checkboxes'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: CustomFieldType.radio,
                  child: Row(
                    children: [
                      Icon(Icons.radio_button_checked),
                      SizedBox(width: 8),
                      Text('Radio'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: CustomFieldType.text,
                  child: Row(
                    children: [
                      Icon(Icons.text_fields),
                      SizedBox(width: 8),
                      Text('Text'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: CustomFieldType.number,
                  child: Row(
                    children: [
                      Icon(Icons.numbers),
                      SizedBox(width: 8),
                      Text('Number'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: CustomFieldType.date,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 8),
                      Text('Date'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: CustomFieldType.time,
                  child: Row(
                    children: [
                      Icon(Icons.access_time),
                      SizedBox(width: 8),
                      Text('Time'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: CustomFieldType.dropdown,
                  child: Row(
                    children: [
                      Icon(Icons.arrow_drop_down_circle_outlined),
                      SizedBox(width: 8),
                      Text('Dropdown'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: CustomFieldType.rating,
                  child: Row(
                    children: [
                      Icon(Icons.star_outline),
                      SizedBox(width: 8),
                      Text('Rating'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_fields.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No custom fields. Tap + to add one.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _fields.length,
            onReorder: _reorderFields,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final elev = animation.value;
                  return Material(
                    elevation: elev * 6,
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final field = _fields[index];
              return _FieldEditorCard(
                key: ValueKey('field_${field.name}_$index'),
                field: field,
                index: index,
                onChanged: (f) => _updateField(index, f),
                onRemove: () => _removeField(index),
              );
            },
          ),
      ],
    );
  }
}

class _FieldEditorCard extends StatefulWidget {
  final CustomFieldDefinition field;
  final int index;
  final void Function(CustomFieldDefinition) onChanged;
  final VoidCallback onRemove;

  const _FieldEditorCard({
    super.key,
    required this.field,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_FieldEditorCard> createState() => _FieldEditorCardState();
}

class _FieldEditorCardState extends State<_FieldEditorCard> {
  late TextEditingController _nameController;
  late List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.field.name);
    _optionControllers = widget.field.options
        .map((o) => TextEditingController(text: o))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateField() {
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((o) => o.isNotEmpty)
        .toList();

    widget.onChanged(
      widget.field.copyWith(
        name: _nameController.text.trim(),
        options: options,
      ),
    );
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
    _updateField();
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
    _updateField();
  }

  String _fieldTypeLabel(CustomFieldType type) {
    switch (type) {
      case CustomFieldType.checkboxes:
        return 'Checkboxes';
      case CustomFieldType.radio:
        return 'Radio';
      case CustomFieldType.text:
        return 'Text';
      case CustomFieldType.number:
        return 'Number';
      case CustomFieldType.date:
        return 'Date';
      case CustomFieldType.time:
        return 'Time';
      case CustomFieldType.dropdown:
        return 'Dropdown';
      case CustomFieldType.rating:
        return 'Rating';
    }
  }

  IconData _fieldTypeIcon(CustomFieldType type) {
    switch (type) {
      case CustomFieldType.checkboxes:
        return Icons.check_box_outlined;
      case CustomFieldType.radio:
        return Icons.radio_button_checked;
      case CustomFieldType.text:
        return Icons.text_fields;
      case CustomFieldType.number:
        return Icons.numbers;
      case CustomFieldType.date:
        return Icons.calendar_today;
      case CustomFieldType.time:
        return Icons.access_time;
      case CustomFieldType.dropdown:
        return Icons.arrow_drop_down_circle_outlined;
      case CustomFieldType.rating:
        return Icons.star_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: 0,
                  child: Icon(
                    Icons.drag_handle,
                    size: 20,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(_fieldTypeIcon(widget.field.fieldType), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fieldTypeLabel(widget.field.fieldType),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: widget.onRemove,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Field Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _updateField(),
            ),
            if (_needsOptions()) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Options', style: Theme.of(context).textTheme.bodySmall),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    onPressed: _addOption,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (_) => _updateField(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeOption(index),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  bool _needsOptions() {
    return widget.field.fieldType == CustomFieldType.dropdown ||
        widget.field.fieldType == CustomFieldType.checkboxes ||
        widget.field.fieldType == CustomFieldType.radio;
  }
}
