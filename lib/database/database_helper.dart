
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;
  static Future<Database>? _databaseOpening;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    return _databaseOpening ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    try {
      final dbPath = await getDatabasesPath();

      final db = await openDatabase(
        join(dbPath, 'sla_tasks.db'),
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _createDatabase,
      );

      _database = db;
      return db;
    } catch (_) {
      _databaseOpening = null;
      rethrow;
    }
  }

  Future<void> _createDatabase(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE team_members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        email TEXT NOT NULL,
        avatar_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        deadline TEXT NOT NULL,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        assigned_to_id TEXT,
        FOREIGN KEY (assigned_to_id)
          REFERENCES team_members (id)
          ON DELETE SET NULL
      )
    ''');
  }

  // TASK OPERATIONS

  Future<int> insertTask(
    Map<String, Object?> task,
  ) async {
    final db = await database;

    return db.insert(
      'tasks',
      task,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fetch tasks together with assignee names.
  Future<List<Map<String, Object?>>> fetchAllTasks() async {
    final db = await database;

    return db.rawQuery('''
      SELECT tasks.*, team_members.name AS assignee_name
      FROM tasks
      LEFT JOIN team_members
        ON tasks.assigned_to_id = team_members.id
      ORDER BY tasks.deadline ASC
    ''');
  }

  Future<List<Map<String, Object?>>> fetchTasksByMember(
    String memberId,
  ) async {
    final db = await database;

    return db.rawQuery(
      '''
      SELECT tasks.*, team_members.name AS assignee_name
      FROM tasks
      LEFT JOIN team_members
        ON tasks.assigned_to_id = team_members.id
      WHERE tasks.assigned_to_id = ?
      ORDER BY tasks.deadline ASC
      ''',
      [memberId],
    );
  }

  Future<int> updateTask(
    String id,
    Map<String, Object?> task,
  ) async {
    final db = await database;

    return db.update(
      'tasks',
      task,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;

    return db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // TEAM MEMBER OPERATIONS

  Future<int> insertMember(
    Map<String, Object?> member,
  ) async {
    final db = await database;

    return db.insert(
      'team_members',
      member,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> fetchAllMembers() async {
    final db = await database;

    return db.query(
      'team_members',
      orderBy: 'name ASC',
    );
  }

  Future<int> deleteMember(String id) async {
    final db = await database;

    return db.delete(
      'team_members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
