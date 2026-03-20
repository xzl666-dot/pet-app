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
        is_online INTEGER NOT NULL DEFAULT 0,
        challenge_win INTEGER NOT NULL DEFAULT 0,
        challenge_lose INTEGER NOT NULL DEFAULT 0,
        challenge_score INTEGER NOT NULL DEFAULT 100
      )
    ''');

    // 添加挑战相关表
    await db.execute('''
      CREATE TABLE challenge (
        challengeId TEXT PRIMARY KEY,
        publisherId INTEGER NOT NULL,
        opponentId INTEGER,
        taskId INTEGER NOT NULL,
        challengeName TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        createTime TEXT NOT NULL,
        matchTime TEXT,
        settleTime TEXT,
        winnerId INTEGER,
        FOREIGN KEY (publisherId) REFERENCES users (id),
        FOREIGN KEY (opponentId) REFERENCES users (id),
        FOREIGN KEY (taskId) REFERENCES tasks (id),
        FOREIGN KEY (winnerId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE challenge_record (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challengeId TEXT NOT NULL,
        userId INTEGER NOT NULL,
        finishStatus INTEGER NOT NULL,
        finishTime INTEGER,
        taskScore INTEGER,
        comprehensiveScore REAL,
        petExpReward INTEGER,
        challengeScoreChange INTEGER,
        syncTime TEXT NOT NULL,
        FOREIGN KEY (challengeId) REFERENCES challenge (challengeId),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // 添加索引
    await db.execute('CREATE INDEX idx_challenge_publisherId ON challenge (publisherId)');
    await db.execute('CREATE INDEX idx_challenge_opponentId ON challenge (opponentId)');
    await db.execute('CREATE INDEX idx_challenge_taskId ON challenge (taskId)');
    await db.execute('CREATE INDEX idx_challenge_status ON challenge (status)');
    await db.execute('CREATE INDEX idx_challengeRecord_challengeId ON challenge_record (challengeId)');
    await db.execute('CREATE INDEX idx_challengeRecord_userId ON challenge_record (userId)');

    // 为现有用户表添加挑战相关字段（如果不存在）
    try {
      await db.execute('ALTER TABLE users ADD COLUMN challenge_win INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE users ADD COLUMN challenge_lose INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE users ADD COLUMN challenge_score INTEGER NOT NULL DEFAULT 100');
    } catch (e) {
      // 如果字段已存在，忽略错误
    }
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

  // TaskService需要的方法
  Future<void> saveTasksToLocal(List<TaskModel> tasks) async {
    if (_isWeb) {
      return mockDatabase.saveTasksToLocal(tasks);
    }
    final db = await instance.database;
    final batch = db.batch();
    
    // 清空现有任务
    await db.delete('tasks');
    
    // 插入新任务
    for (final task in tasks) {
      batch.insert('tasks', task.toMap());
    }
    
    await batch.commit();
  }

  Future<List<TaskModel>> getLocalTasks() async {
    if (_isWeb) {
      return mockDatabase.getLocalTasks();
    }
    return await readAllTasks();
  }

  Future<bool> updateTaskStatus(int taskId, bool isCompleted) async {
    if (_isWeb) {
      return mockDatabase.updateTaskStatus(taskId, isCompleted);
    }
    final db = await instance.database;
    final task = await readTask(taskId);
    if (task == null) return false;
    
    final updatedTask = task.copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
    );
    
    final result = await updateTask(updatedTask);
    return result > 0;
  }

  Future<TaskModel?> getTaskById(int taskId) async {
    return await readTask(taskId);
  }

  Future<void> insertTask(TaskModel task) async {
    await createTask(task);
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
      columns: ['id', 'username', 'password_hash', 'is_admin', 'is_online', 'challenge_win', 'challenge_lose', 'challenge_score'],
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
      columns: ['id', 'username', 'password_hash', 'is_admin', 'is_online', 'challenge_win', 'challenge_lose', 'challenge_score'],
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

  // Challenge operations
  Future<void> createChallenge(Map<String, dynamic> challenge) async {
    if (_isWeb) {
      return mockDatabase.createChallenge(challenge);
    }
    final db = await instance.database;
    await db.insert('challenge', challenge);
  }

  Future<Map<String, dynamic>?> getChallengeById(String challengeId) async {
    if (_isWeb) {
      return mockDatabase.getChallengeById(challengeId);
    }
    final db = await instance.database;
    final maps = await db.query(
      'challenge',
      where: 'challengeId = ?',
      whereArgs: [challengeId],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getChallengesByStatus(int status) async {
    if (_isWeb) {
      return mockDatabase.getChallengesByStatus(status);
    }
    final db = await instance.database;
    return await db.query(
      'challenge',
      where: 'status = ?',
      whereArgs: [status],
    );
  }

  Future<List<Map<String, dynamic>>> getChallengesByUserId(int userId) async {
    if (_isWeb) {
      return mockDatabase.getChallengesByUserId(userId);
    }
    final db = await instance.database;
    return await db.query(
      'challenge',
      where: 'publisherId = ? OR opponentId = ?',
      whereArgs: [userId, userId],
    );
  }

  Future<int> updateChallenge(Map<String, dynamic> challenge) async {
    if (_isWeb) {
      return mockDatabase.updateChallenge(challenge);
    }
    final db = await instance.database;
    return await db.update(
      'challenge',
      challenge,
      where: 'challengeId = ?',
      whereArgs: [challenge['challengeId']],
    );
  }

  // Challenge record operations
  Future<void> createChallengeRecord(Map<String, dynamic> record) async {
    if (_isWeb) {
      return mockDatabase.createChallengeRecord(record);
    }
    final db = await instance.database;
    await db.insert('challenge_record', record);
  }

  Future<List<Map<String, dynamic>>> getChallengeRecordsByChallengeId(String challengeId) async {
    if (_isWeb) {
      return mockDatabase.getChallengeRecordsByChallengeId(challengeId);
    }
    final db = await instance.database;
    return await db.query(
      'challenge_record',
      where: 'challengeId = ?',
      whereArgs: [challengeId],
    );
  }

  Future<List<Map<String, dynamic>>> getChallengeRecordsByUserId(int userId) async {
    if (_isWeb) {
      return mockDatabase.getChallengeRecordsByUserId(userId);
    }
    final db = await instance.database;
    return await db.query(
      'challenge_record',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateChallengeRecord(Map<String, dynamic> record) async {
    if (_isWeb) {
      return mockDatabase.updateChallengeRecord(record);
    }
    final db = await instance.database;
    return await db.update(
      'challenge_record',
      record,
      where: 'id = ?',
      whereArgs: [record['id']],
    );
  }

  Future<void> close() async {
    if (!_isWeb) {
      final db = await instance.database;
      db.close();
    }
    // No need to close mock database for web
  }
}