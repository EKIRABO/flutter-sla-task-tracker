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
      final databasePath = await getDatabasesPath();
      final database = await openDatabase(
        join(databasePath, 'sla_tasks.db'),
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createDatabase,
      );
      _database = database;
      return database;
    } catch (_) {
      _databaseOpening = null;
      rethrow;
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
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
        FOREIGN KEY (assigned_to_id) REFERENCES team_members (id)
          ON DELETE SET NULL
      )
    ''');
  }

  Future<List<Map<String, Object?>>> fetchAllTasks() async {
    final db = await database;
    return db.rawQuery('''
      SELECT tasks.*, team_members.name AS assignee_name
      FROM tasks
      LEFT JOIN team_members ON tasks.assigned_to_id = team_members.id
      ORDER BY tasks.deadline ASC
    ''');
  }

  Future<int> insertTask(Map<String, Object?> task) async {
    final db = await database;
    return db.insert(
      'tasks',
      task,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> fetchAllMembers() async {
    final db = await database;
    return db.query('team_members', orderBy: 'name ASC');
  }

  Future<int> insertMember(Map<String, Object?> member) async {
    final db = await database;
    return db.insert(
      'team_members',
      member,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteMember(String id) async {
    final db = await database;
    return db.delete('team_members', where: 'id = ?', whereArgs: [id]);
  }
}
