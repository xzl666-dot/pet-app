import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import './mock_database.dart';
import '../models/task_model.dart';
import '../models/pet_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static MockDatabase? _mockDatabase;

  DatabaseHelper._init();
  
  bool get _isWeb => kIsWeb;

  Future<Database> get database async {
    if (_isWeb) {
      // For web platform, throw error if someone tries to use the real database
      throw UnsupportedError('Real database not supported on web');
    }
    
    if (_database != null) return _database!;

    _database = await _initDB('pet_app.db');
    return _database!;
  }
  
  MockDatabase get mockDatabase {
    if (_isWeb) {
      _mockDatabase ??= MockDatabase();
      return _mockDatabase!;
    }
    throw UnsupportedError('Mock database only supported on web');
  }

  Future<Database> _initDB(String filePath) async {
    // Only called for native platforms
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // 创建任务表
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        deadline INTEGER NOT NULL,
        benefit_type INTEGER NOT NULL,
        benefit_value INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');

    // 创建宠物表
    await db.execute('''
      CREATE TABLE pets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL DEFAULT 0,
        form INTEGER NOT NULL,
        nutrition INTEGER NOT NULL,
        happiness INTEGER NOT NULL,
        skill_point INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL
      )
    ''');

    // 更新现有表添加type字段（如果不存在）
    try {
      await db.execute('ALTER TABLE pets ADD COLUMN type INTEGER NOT NULL DEFAULT 0');
    } catch (e) {
      // 如果字段已存在，忽略错误
    }

    // 创建数据统计量表
    await db.execute('''
      CREATE TABLE statistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        task_completion_rate REAL NOT NULL,
        daily_usage_duration INTEGER NOT NULL,
        ime_value REAL NOT NULL,
        user_id TEXT NOT NULL,
        version_type TEXT NOT NULL
      )
    ''');

    // 创建用户表
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        is_admin INTEGER NOT NULL DEFAULT 0,
        is_online INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // 任务相关操作
  Future<TaskModel> createTask(TaskModel task) async {
    if (_isWeb) {
      return mockDatabase.createTask(task);
    }
    final db = await instance.database;
    final id = await db.insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  Future<TaskModel?> readTask(int id) async {
    if (_isWeb) {
      return mockDatabase.readTask(id);
    }
    final db = await instance.database;
    final maps = await db.query(
      'tasks',
      columns: ['id', 'name', 'difficulty', 'deadline', 'benefit_type', 'benefit_value', 'is_completed', 'created_at', 'completed_at'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TaskModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<TaskModel>> readAllTasks() async {
    if (_isWeb) {
      return mockDatabase.readAllTasks();
    }
    final db = await instance.database;
    final orderBy = 'deadline ASC';
    final result = await db.query('tasks', orderBy: orderBy);

    return result.map((map) => TaskModel.fromMap(map)).toList();
  }

  Future<int> updateTask(TaskModel task) async {
    if (_isWeb) {
      return mockDatabase.updateTask(task);
    }
    final db = await instance.database;

    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    if (_isWeb) {
      return mockDatabase.deleteTask(id);
    }
    final db = await instance.database;

    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 宠物相关操作
  Future<PetModel> createPet(PetModel pet) async {
    if (_isWeb) {
      return mockDatabase.createPet(pet);
    }
    final db = await instance.database;
    final id = await db.insert('pets', pet.toMap());
    return pet.copyWith(id: id);
  }

  Future<PetModel?> readPet(int id) async {
    if (_isWeb) {
      return mockDatabase.readPet(id);
    }
    final db = await instance.database;
    final maps = await db.query(
      'pets',
      columns: ['id', 'name', 'type', 'form', 'nutrition', 'happiness', 'skill_point', 'created_at', 'last_updated'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return PetModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<PetModel>> readAllPets() async {
    if (_isWeb) {
      return mockDatabase.readAllPets();
    }
    final db = await instance.database;
    final result = await db.query('pets');

    return result.map((map) => PetModel.fromMap(map)).toList();
  }

  Future<int> updatePet(PetModel pet) async {
    if (_isWeb) {
      return mockDatabase.updatePet(pet);
    }
    final db = await instance.database;

    return db.update(
      'pets',
      pet.toMap(),
      where: 'id = ?',
      whereArgs: [pet.id],
    );
  }

  // 数据统计相关操作
  Future<void> insertStatistics(Map<String, dynamic> statistics) async {
    if (_isWeb) {
      return mockDatabase.insertStatistics(statistics);
    }
    final db = await instance.database;
    await db.insert('statistics', statistics);
  }

  Future<void> updateStatistics(Map<String, dynamic> statistics) async {
    if (_isWeb) {
      return mockDatabase.updateStatistics(statistics);
    }
    final db = await instance.database;
    await db.update(
      'statistics',
      statistics,
      where: 'date = ?',
      whereArgs: [statistics['date']],
    );
  }

  Future<List<Map<String, dynamic>>> readStatisticsByDateRange(
    String startDate,
    String endDate,
  ) async {
    if (_isWeb) {
      return mockDatabase.readStatisticsByDateRange(startDate, endDate);
    }
    final db = await instance.database;
    return await db.query(
      'statistics',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
    );
  }

  // 用户相关操作
  Future<User> createUser(User user) async {
    if (_isWeb) {
      return mockDatabase.createUser(user);
    }
    final db = await instance.database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<User?> getUserById(int id) async {
    if (_isWeb) {
      return mockDatabase.getUserById(id);
    }
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: ['id', 'username', 'password_hash', 'is_admin', 'is_online'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    if (_isWeb) {
      return mockDatabase.getUserByUsername(username);
    }
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: ['id', 'username', 'password_hash', 'is_admin', 'is_online'],
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateUser(User user) async {
    if (_isWeb) {
      return mockDatabase.updateUser(user);
    }
    final db = await instance.database;

    return db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    if (_isWeb) {
      return mockDatabase.deleteUser(id);
    }
    final db = await instance.database;

    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<User>> getAllUsers() async {
    if (_isWeb) {
      return mockDatabase.getAllUsers();
    }
    final db = await instance.database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<void> close() async {
    if (!_isWeb) {
      final db = await instance.database;
      db.close();
    }
    // No need to close mock database for web
  }
}