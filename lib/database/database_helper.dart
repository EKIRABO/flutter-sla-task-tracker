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
  version: 1,
  onCreate: _createDB,
 );
}
// Creates a team members table into DB
Future _createDB(Database db, int version) async {
  await db.execute('''
    CREATE TABLE tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    assignee TEXT NOT NULL,
    deadline TEXT NOT NULL,
    isCompleted INTEGER NOT NULL,
    Priority TEXT NOT NULL
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