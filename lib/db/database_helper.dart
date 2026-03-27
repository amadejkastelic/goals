import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/goal.dart';
import '../models/category.dart';
import '../models/journal_entry.dart';
import '../models/media_attachment.dart';
import '../models/custom_field_definition.dart';
import '../models/custom_field_value.dart';
import '../models/fasting_session.dart';

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
      version: 6,
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
        status TEXT NOT NULL DEFAULT 'active',
        goal_type TEXT NOT NULL DEFAULT 'regular',
        fasting_protocol TEXT,
        fasting_target_hours REAL,
        eating_window_start TEXT
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
        mfp_calories INTEGER,
        mfp_protein REAL,
        mfp_carbs REAL,
        mfp_fat REAL,
        mfp_fiber REAL,
        mfp_sodium REAL,
        mfp_sugar REAL,
        health_steps INTEGER,
        health_active_calories REAL,
        health_heart_rate REAL,
        health_sleep_minutes INTEGER,
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
        goal_id INTEGER REFERENCES goals(id) ON DELETE CASCADE,
        journal_entry_id INTEGER REFERENCES journal_entries(id) ON DELETE CASCADE,
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

    await db.execute('''
      CREATE TABLE fasting_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        journal_entry_id INTEGER NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
        fast_started_at TEXT,
        eating_started_at TEXT,
        eating_ended_at TEXT,
        actual_fasting_hours REAL,
        feeling_tags TEXT,
        break_note TEXT
      )
    ''');

    await _insertDefaultCategories(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE custom_field_definitions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          goal_id INTEGER REFERENCES goals(id) ON DELETE CASCADE,
          journal_entry_id INTEGER REFERENCES journal_entries(id) ON DELETE CASCADE,
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

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_field_definitions_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          goal_id INTEGER REFERENCES goals(id) ON DELETE CASCADE,
          journal_entry_id INTEGER REFERENCES journal_entries(id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          field_type TEXT NOT NULL,
          sort_order INTEGER DEFAULT 0,
          options TEXT
        )
      ''');
      await db.execute('''
        INSERT INTO custom_field_definitions_new (id, goal_id, name, field_type, sort_order, options)
        SELECT id, goal_id, name, field_type, sort_order, options FROM custom_field_definitions
      ''');
      await db.execute('DROP TABLE custom_field_definitions');
      await db.execute(
        'ALTER TABLE custom_field_definitions_new RENAME TO custom_field_definitions',
      );
    }

    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE journal_entries ADD COLUMN mfp_calories INTEGER',
      );
      await db.execute(
        'ALTER TABLE journal_entries ADD COLUMN mfp_protein REAL',
      );
      await db.execute('ALTER TABLE journal_entries ADD COLUMN mfp_carbs REAL');
      await db.execute('ALTER TABLE journal_entries ADD COLUMN mfp_fat REAL');
      await db.execute('ALTER TABLE journal_entries ADD COLUMN mfp_fiber REAL');
      await db.execute(
        'ALTER TABLE journal_entries ADD COLUMN mfp_sodium REAL',
      );
      await db.execute('ALTER TABLE journal_entries ADD COLUMN mfp_sugar REAL');
    }

    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE journal_entries ADD COLUMN health_steps INTEGER',
      );
      await db.execute(
        'ALTER TABLE journal_entries ADD COLUMN health_active_calories REAL',
      );
      await db.execute(
        'ALTER TABLE journal_entries ADD COLUMN health_heart_rate REAL',
      );
      await db.execute(
        'ALTER TABLE journal_entries ADD COLUMN health_sleep_minutes INTEGER',
      );
    }

    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE goals ADD COLUMN goal_type TEXT NOT NULL DEFAULT \'regular\'',
      );
      await db.execute('ALTER TABLE goals ADD COLUMN fasting_protocol TEXT');
      await db.execute(
        'ALTER TABLE goals ADD COLUMN fasting_target_hours REAL',
      );
      await db.execute('ALTER TABLE goals ADD COLUMN eating_window_start TEXT');

      await db.execute('''
        CREATE TABLE fasting_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          journal_entry_id INTEGER NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
          fast_started_at TEXT,
          eating_started_at TEXT,
          eating_ended_at TEXT,
          actual_fasting_hours REAL,
          feeling_tags TEXT,
          break_note TEXT
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
    final map = entry.toMap();
    return db.update(
      'journal_entries',
      map,
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> clearMFPNutrition(int entryId) async {
    final db = await instance.database;
    return await db.update(
      'journal_entries',
      {
        'mfp_calories': null,
        'mfp_protein': null,
        'mfp_carbs': null,
        'mfp_fat': null,
        'mfp_fiber': null,
        'mfp_sodium': null,
        'mfp_sugar': null,
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<int> clearHealthData(int entryId) async {
    final db = await instance.database;
    return await db.update(
      'journal_entries',
      {
        'health_steps': null,
        'health_active_calories': null,
        'health_heart_rate': null,
        'health_sleep_minutes': null,
      },
      where: 'id = ?',
      whereArgs: [entryId],
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

  Future<List<CustomFieldDefinition>> readEntrySpecificDefinitions(
    int journalEntryId,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'custom_field_definitions',
      where: 'journal_entry_id = ?',
      whereArgs: [journalEntryId],
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

  Future<int> deleteEntrySpecificDefinitionsForEntry(int journalEntryId) async {
    final db = await instance.database;
    return await db.delete(
      'custom_field_definitions',
      where: 'journal_entry_id = ?',
      whereArgs: [journalEntryId],
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

  Future<int> createFastingSession(FastingSession session) async {
    final db = await instance.database;
    return await db.insert('fasting_sessions', session.toMap());
  }

  Future<FastingSession?> readFastingSessionForEntry(int journalEntryId) async {
    final db = await instance.database;
    final maps = await db.query(
      'fasting_sessions',
      where: 'journal_entry_id = ?',
      whereArgs: [journalEntryId],
    );
    if (maps.isEmpty) return null;
    return FastingSession.fromMap(maps.first);
  }

  Future<List<FastingSession>> readFastingSessionsForGoal(int goalId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT fs.* FROM fasting_sessions fs
      INNER JOIN journal_entries je ON fs.journal_entry_id = je.id
      WHERE je.goal_id = ?
      ORDER BY je.day_number ASC
    ''',
      [goalId],
    );
    return result.map((json) => FastingSession.fromMap(json)).toList();
  }

  Future<int> updateFastingSession(FastingSession session) async {
    final db = await instance.database;
    return db.update(
      'fasting_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteFastingSession(int id) async {
    final db = await instance.database;
    return await db.delete(
      'fasting_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveFastingSession(FastingSession session) async {
    final db = await instance.database;
    if (session.id != null) {
      await db.update(
        'fasting_sessions',
        session.toMap(),
        where: 'id = ?',
        whereArgs: [session.id],
      );
    } else {
      final existing = await db.query(
        'fasting_sessions',
        where: 'journal_entry_id = ?',
        whereArgs: [session.journalEntryId],
      );
      if (existing.isNotEmpty) {
        await db.update(
          'fasting_sessions',
          session.toMap(),
          where: 'journal_entry_id = ?',
          whereArgs: [session.journalEntryId],
        );
      } else {
        await db.insert('fasting_sessions', session.toMap());
      }
    }
  }
}
