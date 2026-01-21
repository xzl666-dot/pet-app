import '../models/task_model.dart';
import 'database_helper.dart';

class TaskDatabase {
  static final TaskDatabase instance = TaskDatabase._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  TaskDatabase._init();

  Future<TaskModel> create(TaskModel task) async {
    return await _dbHelper.createTask(task);
  }

  Future<TaskModel?> readTask(int id) async {
    return await _dbHelper.readTask(id);
  }

  Future<List<TaskModel>> readAllTasks() async {
    return await _dbHelper.readAllTasks();
  }

  Future<List<TaskModel>> readTasksByDifficulty(TaskDifficulty difficulty) async {
    final tasks = await _dbHelper.readAllTasks();
    return tasks.where((task) => task.difficulty == difficulty).toList();
  }

  Future<List<TaskModel>> readTasksByCompletion(bool isCompleted) async {
    final tasks = await _dbHelper.readAllTasks();
    return tasks.where((task) => task.isCompleted == isCompleted).toList();
  }

  Future<int> update(TaskModel task) async {
    return await _dbHelper.updateTask(task);
  }

  Future<int> delete(int id) async {
    return await _dbHelper.deleteTask(id);
  }

  Future<int> markAsCompleted(int id) async {
    final task = await readTask(id);
    if (task != null) {
      return await update(task.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      ));
    }
    return 0;
  }

  Future<void> close() async {
    await _dbHelper.close();
  }
}