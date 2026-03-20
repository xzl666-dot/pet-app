import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/task_data.dart';
import '../database/database_helper.dart';
import '../models/task_model.dart';

class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  // 核心方法：统一获取任务列表
  Future<List<TaskModel>> getTasks() async {
    try {
      // 第一步：尝试调用后端API（Node.js localhost:3000）
      final response = await http.get(Uri.parse('http://localhost:3000/api/tasks'));
      if (response.statusCode == 200) {
        final tasks = json.decode(response.body).map<TaskModel>((json) => TaskModel.fromMap(json)).toList();
        // API成功：同步到本地数据库
        await DatabaseHelper.instance.saveTasksToLocal(tasks);
        return tasks;
      } else {
        // API失败：读取本地数据库
        final localTasks = await DatabaseHelper.instance.getLocalTasks();
        return localTasks.isNotEmpty ? localTasks : TaskData.getAllTasks();
      }
    } catch (e) {
      // 网络/API异常：读取本地→兜底用模拟数据
      final localTasks = await DatabaseHelper.instance.getLocalTasks();
      return localTasks.isNotEmpty ? localTasks : TaskData.getAllTasks();
    }
  }

  // 标记任务完成
  Future<bool> markTaskCompleted(int taskId) async {
    // 先更新本地数据库→再调用API同步（保证本地优先）
    final localSuccess = await DatabaseHelper.instance.updateTaskStatus(taskId, true);
    if (localSuccess) {
      try {
        await http.post(Uri.parse('http://localhost:3000/api/tasks/$taskId/complete'));
      } catch (e) {
        // API同步失败不影响本地，后期可加“待同步”标记
      }
    }
    return localSuccess;
  }

  // 保存任务到本地
  Future<bool> saveTask(TaskModel task) async {
    try {
      await DatabaseHelper.instance.insertTask(task);
      // 异步同步到后端
      try {
        await http.post(
          Uri.parse('http://localhost:3000/api/tasks'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(task.toMap()),
        );
      } catch (e) {
        // API同步失败不影响本地
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // 获取任务详情
  Future<TaskModel?> getTaskById(int taskId) async {
    try {
      // 先从本地数据库获取
      final task = await DatabaseHelper.instance.getTaskById(taskId);
      if (task != null) {
        return task;
      }
      // 如果本地没有，从API获取
      final response = await http.get(Uri.parse('http://localhost:3000/api/tasks/$taskId'));
      if (response.statusCode == 200) {
        final taskMap = json.decode(response.body);
        final task = TaskModel.fromMap(taskMap);
        // 同步到本地
        await DatabaseHelper.instance.insertTask(task);
        return task;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}