
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

  // DATABASE TABLES

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

  // Password hashing is handled by the authentication
  // service. Never store a plain-text password.
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

  // DEMO / SEED DATA

  // Adds sample team members and tasks for demonstrations.
  // Existing user accounts and user-created records are preserved.
  //
  // Demo records use fixed IDs so they are not duplicated.
  Future<void> seedDemoData() async {
    final db = await database;

    await db.transaction((txn) async {
      // SAMPLE TEAM MEMBERS

      final demoMembers = [
        {
          'id': 'demo-member-1',
          'name': 'Amina',
          'role': 'Frontend Developer',
          'email': 'amina.demo@example.com',
        },
        {
          'id': 'demo-member-2',
          'name': 'David',
          'role': 'Backend Developer',
          'email': 'david.demo@example.com',
        },
        {
          'id': 'demo-member-3',
          'name': 'Grace',
          'role': 'UI/UX Designer',
          'email': 'grace.demo@example.com',
        },
        {
          'id': 'demo-member-4',
          'name': 'Brian',
          'role': 'QA Tester',
          'email': 'brian.demo@example.com',
        },
        {
          'id': 'demo-member-5',
          'name': 'Sarah',
          'role': 'Project Manager',
          'email': 'sarah.demo@example.com',
        },
        {
          'id': 'demo-member-6',
          'name': 'Kevin',
          'role': 'Mobile Developer',
          'email': 'kevin.demo@example.com',
        },
      ];

      for (final member in demoMembers) {
        await txn.insert(
          'team_members',
          member,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      // Rename only the three original demo members
      // if they still have their original demo names.
      final oldDemoNames = {
        'demo-member-1': 'Alex Johnson',
        'demo-member-2': 'Sarah Williams',
        'demo-member-3': 'Daniel Brown',
      };

      for (final member in demoMembers.take(3)) {
        final id = member['id']!;
        await txn.update(
          'team_members',
          {
            'name': member['name'],
            'role': member['role'],
            'email': member['email'],
          },
          where: 'id = ? AND name = ?',
          whereArgs: [id, oldDemoNames[id]],
        );
      }

      // SAMPLE TASKS

      final now = DateTime.now();

      String deadline(int days) {
        return now.add(Duration(days: days)).toIso8601String();
      }

      final demoTasks = [
        {
          'id': 'demo-task-1',
          'title': 'Design Login Screen',
          'description': 'Create the login and registration UI.',
          'deadline': deadline(5),
          'status': 'In Progress',
          'priority': 'High',
          'assigned_to_id': 'demo-member-3',
        },
        {
          'id': 'demo-task-2',
          'title': 'Implement Authentication',
          'description': 'Add secure login and registration.',
          'deadline': deadline(-2),
          'status': 'In Progress',
          'priority': 'High',
          'assigned_to_id': 'demo-member-2',
        },
        {
          'id': 'demo-task-3',
          'title': 'Build Dashboard',
          'description': 'Display task statistics and progress.',
          'deadline': deadline(2),
          'status': 'Pending',
          'priority': 'Medium',
          'assigned_to_id': 'demo-member-1',
        },
        {
          'id': 'demo-task-4',
          'title': 'Test Task Creation',
          'description': 'Verify task creation and validation.',
          'deadline': deadline(-1),
          'status': 'Completed',
          'priority': 'Low',
          'assigned_to_id': 'demo-member-4',
        },
        {
          'id': 'demo-task-5',
          'title': 'Create Task Details Screen',
          'description': 'Show task information and deadlines.',
          'deadline': deadline(4),
          'status': 'In Progress',
          'priority': 'High',
          'assigned_to_id': 'demo-member-6',
        },
        {
          'id': 'demo-task-6',
          'title': 'Implement SQLite Database',
          'description': 'Save tasks and team members locally.',
          'deadline': deadline(-4),
          'status': 'Completed',
          'priority': 'High',
          'assigned_to_id': 'demo-member-2',
        },
        {
          'id': 'demo-task-7',
          'title': 'Design Team Members Screen',
          'description': 'Create the team member list interface.',
          'deadline': deadline(6),
          'status': 'Pending',
          'priority': 'Medium',
          'assigned_to_id': 'demo-member-3',
        },
        {
          'id': 'demo-task-8',
          'title': 'Fix Navigation Bugs',
          'description': 'Resolve screen navigation issues.',
          'deadline': deadline(-3),
          'status': 'Pending',
          'priority': 'High',
          'assigned_to_id': 'demo-member-6',
        },
        {
          'id': 'demo-task-9',
          'title': 'Add Form Validation',
          'description': 'Validate required fields and inputs.',
          'deadline': deadline(1),
          'status': 'In Progress',
          'priority': 'High',
          'assigned_to_id': 'demo-member-1',
        },
        {
          'id': 'demo-task-10',
          'title': 'Test User Registration',
          'description': 'Check account creation and login.',
          'deadline': deadline(-2),
          'status': 'Completed',
          'priority': 'Medium',
          'assigned_to_id': 'demo-member-4',
        },
        {
          'id': 'demo-task-11',
          'title': 'Improve App Theme',
          'description': 'Apply consistent colors and typography.',
          'deadline': deadline(7),
          'status': 'Pending',
          'priority': 'Low',
          'assigned_to_id': 'demo-member-3',
        },
        {
          'id': 'demo-task-12',
          'title': 'Implement SLA Tracking',
          'description': 'Calculate overdue and at-risk tasks.',
          'deadline': deadline(-1),
          'status': 'In Progress',
          'priority': 'High',
          'assigned_to_id': 'demo-member-2',
        },
        {
          'id': 'demo-task-13',
          'title': 'Prepare Project Documentation',
          'description': 'Document features and setup steps.',
          'deadline': deadline(3),
          'status': 'In Progress',
          'priority': 'Medium',
          'assigned_to_id': 'demo-member-5',
        },
        {
          'id': 'demo-task-14',
          'title': 'Run Integration Tests',
          'description': 'Verify the main app features.',
          'deadline': deadline(5),
          'status': 'Pending',
          'priority': 'High',
          'assigned_to_id': 'demo-member-4',
        },
        {
          'id': 'demo-task-15',
          'title': 'Prepare Final Presentation',
          'description': 'Organize the app demonstration.',
          'deadline': deadline(8),
          'status': 'Pending',
          'priority': 'Medium',
          'assigned_to_id': 'demo-member-5',
        },
      ];

      for (final task in demoTasks) {
        await txn.insert(
          'tasks',
          task,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }
}
