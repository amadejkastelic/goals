import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/custom_field_definition.dart';

class CustomFieldInput extends StatefulWidget {
  final CustomFieldDefinition definition;
  final String? initialValue;
  final void Function(String) onChanged;
  final bool readOnly;

  const CustomFieldInput({
    super.key,
    required this.definition,
    this.initialValue,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<CustomFieldInput> createState() => _CustomFieldInputState();
}

class _CustomFieldInputState extends State<CustomFieldInput> {
  late dynamic _value;
  TextEditingController? _textController;

  @override
  void initState() {
    super.initState();
    _value = _parseInitialValue();
    _initControllerIfNeeded();
  }

  void _initControllerIfNeeded() {
    if (widget.definition.fieldType == CustomFieldType.text ||
        widget.definition.fieldType == CustomFieldType.number) {
      final initialText = widget.definition.fieldType == CustomFieldType.text
          ? _value as String
          : (_value == 0 ? '' : _value.toString());
      _textController = TextEditingController(text: initialText);
    }
  }

  @override
  void dispose() {
    _textController?.dispose();
    super.dispose();
  }

  dynamic _parseInitialValue() {
    final initial = widget.initialValue;
    if (initial == null || initial.isEmpty) {
      return _getDefaultValue();
    }

    switch (widget.definition.fieldType) {
      case CustomFieldType.checkboxes:
        try {
          final decoded = jsonDecode(initial);
          if (decoded is List) {
            return Set<String>.from(decoded.map((e) => e.toString()));
          }
        } catch (_) {}
        return <String>{};
      case CustomFieldType.radio:
        return initial;
      case CustomFieldType.text:
        return initial;
      case CustomFieldType.number:
        return num.tryParse(initial) ?? 0;
      case CustomFieldType.date:
        return DateTime.tryParse(initial);
      case CustomFieldType.time:
        return initial;
      case CustomFieldType.dropdown:
        return initial;
      case CustomFieldType.rating:
        return int.tryParse(initial) ?? 0;
    }
  }

  dynamic _getDefaultValue() {
    switch (widget.definition.fieldType) {
      case CustomFieldType.checkboxes:
        return <String>{};
      case CustomFieldType.radio:
        return null;
      case CustomFieldType.text:
        return '';
      case CustomFieldType.number:
        return 0;
      case CustomFieldType.date:
        return null;
      case CustomFieldType.time:
        return null;
      case CustomFieldType.dropdown:
        return null;
      case CustomFieldType.rating:
        return 0;
    }
  }

  void _updateValue(dynamic newValue) {
    setState(() {
      _value = newValue;
    });
    widget.onChanged(_valueToString(newValue));
  }

  String _valueToString(dynamic value) {
    if (value == null) return '';
    switch (widget.definition.fieldType) {
      case CustomFieldType.checkboxes:
        if (value is Set<String>) {
          return jsonEncode(value.toList());
        }
        return '[]';
      case CustomFieldType.date:
        return (value as DateTime).toIso8601String();
      default:
        return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      return _buildReadOnly();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.definition.name,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        _buildInput(),
      ],
    );
  }

  Widget _buildReadOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.definition.name,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(_getDisplayValue()),
      ],
    );
  }

  String _getDisplayValue() {
    if (_value == null) return 'Not set';

    switch (widget.definition.fieldType) {
      case CustomFieldType.checkboxes:
        final selected = _value as Set<String>;
        if (selected.isEmpty) return 'None selected';
        return selected.join(', ');
      case CustomFieldType.text:
        final text = _value as String;
        return text.isEmpty ? 'Not set' : text;
      case CustomFieldType.number:
        return _value.toString();
      case CustomFieldType.date:
        final date = _value as DateTime?;
        return date != null ? DateFormat.yMMMd().format(date) : 'Not set';
      case CustomFieldType.time:
        final timeStr = _value as String?;
        if (timeStr == null || timeStr.isEmpty) return 'Not set';
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final time = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
          return time.format(context);
        }
        return timeStr;
      case CustomFieldType.dropdown:
      case CustomFieldType.radio:
        return _value?.toString() ?? 'Not set';
      case CustomFieldType.rating:
        final rating = _value as int;
        return '★' * rating + '☆' * (5 - rating);
    }
  }

  Widget _buildInput() {
    switch (widget.definition.fieldType) {
      case CustomFieldType.checkboxes:
        return _buildCheckboxes();
      case CustomFieldType.radio:
        return _buildRadio();
      case CustomFieldType.text:
        return _buildText();
      case CustomFieldType.number:
        return _buildNumber();
      case CustomFieldType.date:
        return _buildDate();
      case CustomFieldType.time:
        return _buildTime();
      case CustomFieldType.dropdown:
        return _buildDropdown();
      case CustomFieldType.rating:
        return _buildRating();
    }
  }

  Widget _buildCheckboxes() {
    final selected = _value as Set<String>;
    final options = widget.definition.options;
    return Column(
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return CheckboxListTile(
          title: Text(opt),
          value: isSelected,
          onChanged: (checked) {
            final newSet = Set<String>.from(selected);
            if (checked == true) {
              newSet.add(opt);
            } else {
              newSet.remove(opt);
            }
            _updateValue(newSet);
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget _buildRadio() {
    final selected = _value as String?;
    final options = widget.definition.options;
    return Column(
      children: options.map((opt) {
        return ListTile(
          title: Text(opt),
          leading: Radio<String>(
            // ignore: deprecated_member_use
            value: opt,
            // ignore: deprecated_member_use
            groupValue: selected,
            // ignore: deprecated_member_use
            onChanged: (v) => _updateValue(v),
            visualDensity: VisualDensity.compact,
          ),
          contentPadding: EdgeInsets.zero,
          onTap: () => _updateValue(opt),
        );
      }).toList(),
    );
  }

  Widget _buildText() {
    return TextField(
      controller: _textController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      maxLines: null,
      onChanged: (v) {
        _value = v;
        widget.onChanged(v);
      },
    );
  }

  Widget _buildNumber() {
    return TextField(
      controller: _textController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final parsed = num.tryParse(v);
        _value = parsed ?? 0;
        widget.onChanged(v);
      },
    );
  }

  Widget _buildDate() {
    final date = _value as DateTime?;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          _updateValue(picked);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? DateFormat.yMMMd().format(date) : 'Select date',
        ),
      ),
    );
  }

  Widget _buildTime() {
    final timeStr = _value as String?;
    TimeOfDay? time;
    if (timeStr != null && timeStr.isNotEmpty) {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (picked != null) {
          _updateValue(
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
          );
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          suffixIcon: Icon(Icons.access_time),
        ),
        child: Text(time != null ? time.format(context) : 'Select time'),
      ),
    );
  }

  Widget _buildDropdown() {
    final options = widget.definition.options;
    return DropdownButtonFormField<String>(
      key: ValueKey('dropdown_${widget.definition.id}'),
      initialValue: _value as String?,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: options.map((opt) {
        return DropdownMenuItem(value: opt, child: Text(opt));
      }).toList(),
      onChanged: (v) => _updateValue(v),
    );
  }

  Widget _buildRating() {
    final rating = _value as int;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          icon: Icon(
            starValue <= rating ? Icons.star : Icons.star_border,
            color: starValue <= rating ? Colors.amber : null,
          ),
          onPressed: () => _updateValue(starValue),
          visualDensity: VisualDensity.compact,
        );
      }),
    );
  }
}
