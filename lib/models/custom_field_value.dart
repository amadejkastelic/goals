class CustomFieldValue {
  final int? id;
  final int definitionId;
  final int journalEntryId;
  final String value;

  CustomFieldValue({
    this.id,
    required this.definitionId,
    required this.journalEntryId,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'definition_id': definitionId,
      'journal_entry_id': journalEntryId,
      'value': value,
    };
  }

  factory CustomFieldValue.fromMap(Map<String, dynamic> map) {
    return CustomFieldValue(
      id: map['id'] as int?,
      definitionId: map['definition_id'] as int,
      journalEntryId: map['journal_entry_id'] as int,
      value: map['value'] as String? ?? '',
    );
  }

  CustomFieldValue copyWith({
    int? id,
    int? definitionId,
    int? journalEntryId,
    String? value,
  }) {
    return CustomFieldValue(
      id: id ?? this.id,
      definitionId: definitionId ?? this.definitionId,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      value: value ?? this.value,
    );
  }
}
