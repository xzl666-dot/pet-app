import 'dart:convert';
import 'dart:html';
import '../models/task_model.dart';
import '../models/pet_model.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

/// Mock database implementation for web platform
class MockDatabase {
  // In-memory storage for tasks
  List<TaskModel> _tasks = [];
  
  // In-memory storage for pets
  List<PetModel> _pets = [];
  
  // In-memory storage for statistics
  List<Map<String, dynamic>> _statistics = [];

  // In-memory storage for users
  List<User> _users = [];

  // In-memory storage for challenges
  List<Map<String, dynamic>> _challenges = [];

  // In-memory storage for challenge records
  List<Map<String, dynamic>> _challengeRecords = [];
  
  // Auto-increment IDs
  int _taskIdCounter = 1;
  int _petIdCounter = 1;
  int _statIdCounter = 1;
  int _userIdCounter = 1;
  int _challengeRecordIdCounter = 1;
  
  // Storage keys for localStorage
  static const String _usersStorageKey = 'pet_app_users';
  static const String _userIdCounterStorageKey = 'pet_app_user_id_counter';
  static const String _challengesStorageKey = 'pet_app_challenges';
  static const String _challengeRecordsStorageKey = 'pet_app_challenge_records';
  
  MockDatabase() {
    _loadUsersFromStorage();
    _loadChallengesFromStorage();
  }
  
  // Load users from localStorage
  void _loadUsersFromStorage() {
    if (kIsWeb) {
      try {
        // Load users
        final usersJson = window.localStorage[_usersStorageKey];
        if (usersJson != null) {
          final List<dynamic> usersList = jsonDecode(usersJson);
          _users = usersList.map((user) => User.fromMap(user)).toList();
        }
        
        // Load user ID counter
        final userIdCounterJson = window.localStorage[_userIdCounterStorageKey];
        if (userIdCounterJson != null) {
          _userIdCounter = int.parse(userIdCounterJson);
        }
      } catch (e) {
        print('Error loading users from localStorage: $e');
        // If error occurs, initialize with empty data
        _users = [];
        _userIdCounter = 1;
      }
    }
  }
  
  // Save users to localStorage
  void _saveUsersToStorage() {
    if (kIsWeb) {
      try {
        // Save users
        final usersJson = jsonEncode(_users.map((user) => user.toMap()).toList());
        window.localStorage[_usersStorageKey] = usersJson;
        
        // Save user ID counter
        window.localStorage[_userIdCounterStorageKey] = _userIdCounter.toString();
      } catch (e) {
        print('Error saving users to localStorage: $e');
      }
    }
  }

  // Load challenges from localStorage
  void _loadChallengesFromStorage() {
    if (kIsWeb) {
      try {
        // Load challenges
        final challengesJson = window.localStorage[_challengesStorageKey];
        if (challengesJson != null) {
          final List<dynamic> challengesList = jsonDecode(challengesJson);
          _challenges = List<Map<String, dynamic>>.from(challengesList);
        }

        // Load challenge records
        final challengeRecordsJson = window.localStorage[_challengeRecordsStorageKey];
        if (challengeRecordsJson != null) {
          final List<dynamic> recordsList = jsonDecode(challengeRecordsJson);
          _challengeRecords = List<Map<String, dynamic>>.from(recordsList);
        }
      } catch (e) {
        print('Error loading challenges from localStorage: $e');
        // If error occurs, initialize with empty data
        _challenges = [];
        _challengeRecords = [];
      }
    }
  }

  // Save challenges to localStorage
  void _saveChallengesToStorage() {
    if (kIsWeb) {
      try {
        // Save challenges
        final challengesJson = jsonEncode(_challenges);
        window.localStorage[_challengesStorageKey] = challengesJson;

        // Save challenge records
        final challengeRecordsJson = jsonEncode(_challengeRecords);
        window.localStorage[_challengeRecordsStorageKey] = challengeRecordsJson;
      } catch (e) {
        print('Error saving challenges to localStorage: $e');
      }
    }
  }
  
  // Task operations
  Future<TaskModel> createTask(TaskModel task) async {
    final newTask = task.copyWith(id: _taskIdCounter++);
    _tasks.add(newTask);
    return newTask;
  }
  
  Future<TaskModel?> readTask(int id) async {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<List<TaskModel>> readAllTasks() async {
    return [..._tasks];
  }
  
  Future<int> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      return 1;
    }
    return 0;
  }
  
  Future<int> deleteTask(int id) async {
    final initialLength = _tasks.length;
    _tasks.removeWhere((task) => task.id == id);
    return initialLength - _tasks.length;
  }

  // TaskService需要的方法
  Future<void> saveTasksToLocal(List<TaskModel> tasks) async {
    _tasks = tasks;
  }

  Future<List<TaskModel>> getLocalTasks() async {
    return [..._tasks];
  }

  Future<bool> updateTaskStatus(int taskId, bool isCompleted) async {
    final task = await readTask(taskId);
    if (task == null) return false;
    
    final updatedTask = task.copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
    );
    
    final result = await updateTask(updatedTask);
    return result > 0;
  }
  
  // Pet operations
  Future<PetModel> createPet(PetModel pet) async {
    final newPet = pet.copyWith(id: _petIdCounter++);
    _pets.add(newPet);
    return newPet;
  }
  
  Future<PetModel?> readPet(int id) async {
    try {
      return _pets.firstWhere((pet) => pet.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<List<PetModel>> readAllPets() async {
    return [..._pets];
  }
  
  Future<int> updatePet(PetModel pet) async {
    final index = _pets.indexWhere((p) => p.id == pet.id);
    if (index != -1) {
      _pets[index] = pet;
      return 1;
    }
    return 0;
  }
  
  // Statistics operations
  Future<void> insertStatistics(Map<String, dynamic> statistics) async {
    final newStat = {...statistics, 'id': _statIdCounter++};
    _statistics.add(newStat);
  }
  
  Future<void> updateStatistics(Map<String, dynamic> statistics) async {
    final index = _statistics.indexWhere((s) => s['date'] == statistics['date']);
    if (index != -1) {
      _statistics[index] = {...statistics, 'id': _statistics[index]['id']};
    } else {
      await insertStatistics(statistics);
    }
  }
  
  Future<List<Map<String, dynamic>>> readStatisticsByDateRange(
    String startDate,
    String endDate,
  ) async {
    return _statistics.where((stat) {
      final date = stat['date'];
      return date.compareTo(startDate) >= 0 && date.compareTo(endDate) <= 0;
    }).toList();
  }

  // User operations
  Future<User> createUser(User user) async {
    final newUser = user.copyWith(id: _userIdCounter++);
    _users.add(newUser);
    _saveUsersToStorage();
    return newUser;
  }

  Future<User?> getUserById(int id) async {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    try {
      return _users.firstWhere((user) => user.username == username);
    } catch (e) {
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    return [..._users];
  }

  Future<int> updateUser(User user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
      _saveUsersToStorage();
      return 1;
    }
    return 0;
  }

  Future<int> deleteUser(int id) async {
    final initialLength = _users.length;
    _users.removeWhere((user) => user.id == id);
    _saveUsersToStorage();
    return initialLength - _users.length;
  }

  // Challenge operations
  Future<void> createChallenge(Map<String, dynamic> challenge) async {
    _challenges.add(challenge);
    _saveChallengesToStorage();
  }

  Future<Map<String, dynamic>?> getChallengeById(String challengeId) async {
    try {
      return _challenges.firstWhere((challenge) => challenge['challengeId'] == challengeId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getChallengesByStatus(int status) async {
    return _challenges.where((challenge) => challenge['status'] == status).toList();
  }

  Future<List<Map<String, dynamic>>> getChallengesByUserId(int userId) async {
    return _challenges.where((challenge) => challenge['publisherId'] == userId || challenge['opponentId'] == userId).toList();
  }

  Future<int> updateChallenge(Map<String, dynamic> challenge) async {
    final index = _challenges.indexWhere((c) => c['challengeId'] == challenge['challengeId']);
    if (index != -1) {
      _challenges[index] = challenge;
      _saveChallengesToStorage();
      return 1;
    }
    return 0;
  }

  // Challenge record operations
  Future<void> createChallengeRecord(Map<String, dynamic> record) async {
    final newRecord = {...record, 'id': _challengeRecordIdCounter++};
    _challengeRecords.add(newRecord);
    _saveChallengesToStorage();
  }

  Future<List<Map<String, dynamic>>> getChallengeRecordsByChallengeId(String challengeId) async {
    return _challengeRecords.where((record) => record['challengeId'] == challengeId).toList();
  }

  Future<List<Map<String, dynamic>>> getChallengeRecordsByUserId(int userId) async {
    return _challengeRecords.where((record) => record['userId'] == userId).toList();
  }

  Future<int> updateChallengeRecord(Map<String, dynamic> record) async {
    final index = _challengeRecords.indexWhere((r) => r['id'] == record['id']);
    if (index != -1) {
      _challengeRecords[index] = record;
      _saveChallengesToStorage();
      return 1;
    }
    return 0;
  }
}
