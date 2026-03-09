import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/goal.dart';
import '../models/category.dart';
import '../models/journal_entry.dart';
import '../models/media_attachment.dart';
import '../models/custom_field_definition.dart';
import '../models/custom_field_value.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('goals.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        emoji TEXT,
        is_default INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category_id INTEGER REFERENCES categories(id),
        duration_days INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active'
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER REFERENCES goals(id),
        day_number INTEGER NOT NULL,
        date TEXT NOT NULL,
        content TEXT,
        mood_emoji TEXT,
        UNIQUE(goal_id, day_number)
      )
    ''');

    await db.execute('''
      CREATE TABLE media_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        journal_entry_id INTEGER REFERENCES journal_entries(id),
        type TEXT NOT NULL,
        data BLOB NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_field_definitions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        field_type TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        options TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_field_values (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        definition_id INTEGER NOT NULL REFERENCES custom_field_definitions(id) ON DELETE CASCADE,
        journal_entry_id INTEGER NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
        value TEXT NOT NULL,
        UNIQUE(definition_id, journal_entry_id)
      )
    ''');

    await _insertDefaultCategories(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE custom_field_definitions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          goal_id INTEGER NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          field_type TEXT NOT NULL,
          sort_order INTEGER DEFAULT 0,
          options TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE custom_field_values (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          definition_id INTEGER NOT NULL REFERENCES custom_field_definitions(id) ON DELETE CASCADE,
          journal_entry_id INTEGER NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
          value TEXT NOT NULL,
          UNIQUE(definition_id, journal_entry_id)
        )
      ''');
    }
  }

  Future _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      {'name': 'Health & Fitness', 'emoji': '🏃', 'is_default': 1},
      {'name': 'Work & Career', 'emoji': '💼', 'is_default': 1},
      {'name': 'Learning', 'emoji': '📚', 'is_default': 1},
      {'name': 'Mental Wellness', 'emoji': '🧘', 'is_default': 1},
      {'name': 'Finance', 'emoji': '💰', 'is_default': 1},
      {'name': 'Hobbies & Creativity', 'emoji': '🎨', 'is_default': 1},
    ];

    for (final cat in defaultCategories) {
      await db.insert('categories', cat);
    }
  }

  Future<int> createGoal(Goal goal) async {
    final db = await instance.database;
    return await db.insert('goals', goal.toMap());
  }

  Future<Goal> readGoal(int id) async {
    final db = await instance.database;
    final maps = await db.query('goals', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) throw Exception('Goal $id not found');
    return Goal.fromMap(maps.first);
  }

  Future<List<Goal>> readAllGoals() async {
    final db = await instance.database;
    final orderBy = 'start_date DESC';
    final result = await db.query('goals', orderBy: orderBy);
    return result.map((json) => Goal.fromMap(json)).toList();
  }

  Future<int> updateGoal(Goal goal) async {
    final db = await instance.database;
    return db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await instance.database;
    return await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> createCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete(
      'categories',
      where: 'id = ? AND is_default = 0',
      whereArgs: [id],
    );
  }

  Future<int> createJournalEntry(JournalEntry entry) async {
    final db = await instance.database;
    return await db.insert('journal_entries', entry.toMap());
  }

  Future<JournalEntry?> readJournalEntry(int goalId, int dayNumber) async {
    final db = await instance.database;
    final maps = await db.query(
      'journal_entries',
      where: 'goal_id = ? AND day_number = ?',
      whereArgs: [goalId, dayNumber],
    );

    if (maps.isEmpty) return null;
    return JournalEntry.fromMap(maps.first);
  }

  Future<List<JournalEntry>> readJournalEntriesForGoal(int goalId) async {
    final db = await instance.database;
    final result = await db.query(
      'journal_entries',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'day_number ASC',
    );
    return result.map((json) => JournalEntry.fromMap(json)).toList();
  }

  Future<int> updateJournalEntry(JournalEntry entry) async {
    final db = await instance.database;
    return db.update(
      'journal_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteJournalEntry(int id) async {
    final db = await instance.database;
    return await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> createMediaAttachment(MediaAttachment attachment) async {
    final db = await instance.database;
    return await db.insert('media_attachments', attachment.toMap());
  }

  Future<List<MediaAttachment>> readMediaAttachments(int journalEntryId) async {
    final db = await instance.database;
    final result = await db.query(
      'media_attachments',
      where: 'journal_entry_id = ?',
      whereArgs: [journalEntryId],
      orderBy: 'created_at ASC',
    );
    return result.map((json) => MediaAttachment.fromMap(json)).toList();
  }

  Future<int> deleteMediaAttachment(int id) async {
    final db = await instance.database;
    return await db.delete(
      'media_attachments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> createCustomFieldDefinition(CustomFieldDefinition def) async {
    final db = await instance.database;
    return await db.insert('custom_field_definitions', def.toMap());
  }

  Future<List<CustomFieldDefinition>> readCustomFieldDefinitions(
    int goalId,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'custom_field_definitions',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'sort_order ASC',
    );
    return result.map((json) => CustomFieldDefinition.fromMap(json)).toList();
  }

  Future<int> updateCustomFieldDefinition(CustomFieldDefinition def) async {
    final db = await instance.database;
    return db.update(
      'custom_field_definitions',
      def.toMap(),
      where: 'id = ?',
      whereArgs: [def.id],
    );
  }

  Future<int> deleteCustomFieldDefinition(int id) async {
    final db = await instance.database;
    return await db.delete(
      'custom_field_definitions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCustomFieldDefinitionsForGoal(int goalId) async {
    final db = await instance.database;
    return await db.delete(
      'custom_field_definitions',
      where: 'goal_id = ?',
      whereArgs: [goalId],
    );
  }

  Future<int> createCustomFieldValue(CustomFieldValue value) async {
    final db = await instance.database;
    return await db.insert('custom_field_values', value.toMap());
  }

  Future<List<CustomFieldValue>> readCustomFieldValues(
    int journalEntryId,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'custom_field_values',
      where: 'journal_entry_id = ?',
      whereArgs: [journalEntryId],
    );
    return result.map((json) => CustomFieldValue.fromMap(json)).toList();
  }

  Future<int> updateCustomFieldValue(CustomFieldValue value) async {
    final db = await instance.database;
    return db.update(
      'custom_field_values',
      value.toMap(),
      where: 'id = ?',
      whereArgs: [value.id],
    );
  }

  Future<int> deleteCustomFieldValue(int id) async {
    final db = await instance.database;
    return await db.delete(
      'custom_field_values',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveCustomFieldValue({
    required int definitionId,
    required int journalEntryId,
    required String value,
  }) async {
    final db = await instance.database;
    final existing = await db.query(
      'custom_field_values',
      where: 'definition_id = ? AND journal_entry_id = ?',
      whereArgs: [definitionId, journalEntryId],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'custom_field_values',
        {'value': value},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('custom_field_values', {
        'definition_id': definitionId,
        'journal_entry_id': journalEntryId,
        'value': value,
      });
    }
  }
}
