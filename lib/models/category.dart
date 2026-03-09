class Category {
  final int? id;
  final String name;
  final String? emoji;
  final bool isDefault;

  Category({this.id, required this.name, this.emoji, this.isDefault = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      emoji: map['emoji'] as String?,
      isDefault: map['is_default'] == 1,
    );
  }
}
