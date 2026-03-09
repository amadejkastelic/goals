import 'dart:convert';

enum CustomFieldType {
  checkboxes,
  text,
  number,
  date,
  time,
  dropdown,
  radio,
  rating,
}

class CustomFieldDefinition {
  final int? id;
  final int? goalId;
  final int? journalEntryId;
  final String name;
  final CustomFieldType fieldType;
  final int sortOrder;
  final List<String> options;

  CustomFieldDefinition({
    this.id,
    this.goalId,
    this.journalEntryId,
    required this.name,
    required this.fieldType,
    this.sortOrder = 0,
    this.options = const [],
  }) : assert(
         goalId != null || journalEntryId != null,
         'Either goalId or journalEntryId must be provided',
       );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'journal_entry_id': journalEntryId,
      'name': name,
      'field_type': fieldType.name,
      'sort_order': sortOrder,
      'options': options.isEmpty ? null : jsonEncode(options),
    };
  }

  factory CustomFieldDefinition.fromMap(Map<String, dynamic> map) {
    List<String> options = [];
    if (map['options'] != null) {
      final decoded = jsonDecode(map['options'] as String);
      if (decoded is List) {
        options = decoded.map((e) => e.toString()).toList();
      }
    }

    return CustomFieldDefinition(
      id: map['id'] as int?,
      goalId: map['goal_id'] as int?,
      journalEntryId: map['journal_entry_id'] as int?,
      name: map['name'] as String,
      fieldType: CustomFieldType.values.firstWhere(
        (e) => e.name == map['field_type'],
        orElse: () => CustomFieldType.text,
      ),
      sortOrder: map['sort_order'] as int? ?? 0,
      options: options,
    );
  }

  CustomFieldDefinition copyWith({
    int? id,
    int? goalId,
    int? journalEntryId,
    String? name,
    CustomFieldType? fieldType,
    int? sortOrder,
    List<String>? options,
  }) {
    return CustomFieldDefinition(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      name: name ?? this.name,
      fieldType: fieldType ?? this.fieldType,
      sortOrder: sortOrder ?? this.sortOrder,
      options: options ?? this.options,
    );
  }
}
