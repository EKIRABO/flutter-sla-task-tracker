
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
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
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

    await _createUsersTable(db);
  }

  // Upgrade existing databases without deleting saved data.
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 3) {
      await _createUsersTable(db);
    }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE COLLATE NOCASE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // USER ACCOUNT OPERATIONS

  // Password hashing will be handled by an authentication
  // service. Never save a plain-text password here.
  Future<int> createUser({
    required String name,
    required String email,
    required String passwordHash,
    required String passwordSalt,
  }) async {
    final db = await database;

    return db.insert(
      'users',
      {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password_hash': passwordHash,
        'password_salt': passwordSalt,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Map<String, Object?>?> findUserByEmail(
    String email,
  ) async {
    final db = await database;

    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  Future<Map<String, Object?>?> findUserById(
    int id,
  ) async {
    final db = await database;

    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
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
