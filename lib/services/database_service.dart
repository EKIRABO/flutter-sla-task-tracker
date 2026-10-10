import '../models/task.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  final List<Task> _tasks = <Task>[];

  Future<List<Task>> getTasks() async {
    return List<Task>.unmodifiable(_tasks);
  }

  Future<void> insertTask(Task task) async {
    final taskToInsert = task.id == null
        ? task.copyWith(id: 'task-${DateTime.now().microsecondsSinceEpoch}')
        : task;

    _tasks.add(taskToInsert);
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((existingTask) => existingTask.id == task.id);
    if (index == -1) {
      await insertTask(task);
      return;
    }

    _tasks[index] = task;
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
  }
}
