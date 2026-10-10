import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Creates a single, shared instance of the database helper across the app.
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

 // Checks if database is already open. If it isn't, it opens it.
 Future<Database> get database async {
 if (_database != null) return _database!;
 _database = await _initDB('sla_tasks.db');
 return _database!; 
 } 

 // Finds the secure folder on the user's phone to store the database file
 Future<Database> _initDB(String filePath) async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, filePath);

 // Opens the database if it's the first time running the app
 return await openDatabase(
  path,
  version: 2,
  onCreate: _createDB,
 );
}

Future _createDB(Database db, int version) async {
  // Create Team members table
  await db.execute('''
    CREATE TABLE team_members (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    email TEXT NOT NULL,
    avatar_url TEXT
  )
''');

  // Create Tasks table
  await db.execute('''
    CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    deadline TEXT NOT NULL, -- Stored as YYYY-MM-DD
    status TEXT NOT NULL, -- "To Do", "In Progress", "Completed" instead of boolean
    priority TEXT NOT NULL, -- Explicity named column
    assigned_to_id TEXT,
    FOREIGN KEY (assigned_to_id) REFERENCES team_members (id) ON DELETE SET NULL
  )
''');
}
 
// TASKS DB

// Insert new task into the DB
Future<int> insertTask(Map<String, dynamic> taskJson) async {
  final db = await instance.database;
  return await db.insert('tasks', taskJson, conflictAlgorithm: ConflictAlgorithm.replace);
}

// Fetch all tasks
Future<List<Map<String, dynamic>>> fetchAllTasks() async {
  final db = await instance.database;
  return await db.query('tasks', orderBy: 'deadline ASC');
}

// Fetch tasks assigned to a specific team member
Future<List<Map<String, dynamic>>> fetchTasksByMember(String memberId) async {
  final db = await instance.database;
  return await db.query(
    'tasks',
    where: 'assigned_to_id =?',
    whereArgs: [memberId],
    orderBy: 'deadline ASC',
  );
}

// Updating task details 
Future<int> updateTask(String id, Map<String, dynamic> taskJson) async {
  final db = await instance.database;
  return await db.update(
    'tasks',
    taskJson,
    where: 'id = ?',
    whereArgs: [id],
  );
}

// Delete a task
Future<int> deleteTask(String id) async {
  final db = await instance.database;
  return await db.delete(
    'tasks',
    where: 'id = ?',
    whereArgs: [id],
  );
}
// TEAM MEMBERS DB 

// Add new team member
Future<int> insertMember(Map<String, dynamic> memberJson) async {
  final db = await instance.database;
  return await db.insert('team_members', memberJson, conflictAlgorithm: ConflictAlgorithm.replace);
}

// Fetch all team members
Future<List<Map<String, dynamic>>> fetchAllMembers() async{
  final db = await instance.database;
  return await db.query('team_members', orderBy: 'name ASC');
}

// Delete team members
Future<int> deleteMember(String id) async {
  final db = await instance.database;
  return await db.delete(
    'team_members',
    where: 'id =?',
    whereArgs: [id],
  );
 }
}