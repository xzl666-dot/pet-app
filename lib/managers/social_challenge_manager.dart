import 'dart:math';
import 'dart:convert';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../managers/user_ability_manager.dart';
import '../managers/auth_manager.dart';
import '../managers/api_manager.dart';
import '../database/database_helper.dart';

class Friend {
  String id;
  String nickname;
  String avatar;
  int level;
  int petGrowthValue;
  bool isOnline;
  DateTime lastActive;
  bool isNPC;

  Friend({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.level,
    required this.petGrowthValue,
    this.isOnline = false,
    required this.lastActive,
    this.isNPC = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'avatar': avatar,
      'level': level,
      'pet_growth_value': petGrowthValue,
      'is_online': isOnline,
      'last_active': lastActive.toString(),
      'is_npc': isNPC,
    };
  }

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['id'] ?? '',
      nickname: map['nickname'] ?? '',
      avatar: map['avatar'] ?? '',
      level: map['level'] ?? 0,
      petGrowthValue: map['pet_growth_value'] ?? 0,
      isOnline: map['is_online'] ?? false,
      lastActive: DateTime.parse(map['last_active'] ?? DateTime.now().toString()),
      isNPC: map['is_npc'] ?? false,
    );
  }
}

class Competition {
  String id;
  String opponentId;
  String opponentNickname;
  int durationDays;
  DateTime startTime;
  DateTime endTime;
  int initialGrowthValue;
  int currentGrowthValue;
  int opponentGrowthValue;
  String status;
  String? result;

  Competition({
    required this.id,
    required this.opponentId,
    required this.opponentNickname,
    required this.durationDays,
    required this.startTime,
    required this.endTime,
    required this.initialGrowthValue,
    required this.currentGrowthValue,
    required this.opponentGrowthValue,
    required this.status,
    this.result,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'opponent_id': opponentId,
      'opponent_nickname': opponentNickname,
      'duration_days': durationDays,
      'start_time': startTime.toString(),
      'end_time': endTime.toString(),
      'initial_growth_value': initialGrowthValue,
      'current_growth_value': currentGrowthValue,
      'opponent_growth_value': opponentGrowthValue,
      'status': status,
      'result': result,
    };
  }

  factory Competition.fromMap(Map<String, dynamic> map) {
    return Competition(
      id: map['id'] ?? '',
      opponentId: map['opponent_id'] ?? '',
      opponentNickname: map['opponent_nickname'] ?? '',
      durationDays: map['duration_days'] ?? 1,
      startTime: DateTime.parse(map['start_time'] ?? DateTime.now().toString()),
      endTime: DateTime.parse(map['end_time'] ?? DateTime.now().toString()),
      initialGrowthValue: map['initial_growth_value'] ?? 0,
      currentGrowthValue: map['current_growth_value'] ?? 0,
      opponentGrowthValue: map['opponent_growth_value'] ?? 0,
      status: map['status'] ?? 'pending',
      result: map['result'],
    );
  }
}

class SocialChallengeManager {
  static final SocialChallengeManager instance = SocialChallengeManager._init();
  final Random _random = Random();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // NPC列表
  final List<Friend> _npcList = [];
  
  SocialChallengeManager._init();

  // 初始化NPC列表
  void _initializeNPCs() {
    if (_npcList.isEmpty) {
      final npcNames = [
        '学习小能手', '任务达人', '宠物大师', '挑战王', '成长冠军',
        '坚持之星', '效率专家', '质量王者', '全能选手', '进步神速'
      ];
      
      for (int i = 0; i < 10; i++) {
        _npcList.add(Friend(
          id: 'npc_$i',
          nickname: npcNames[i],
          avatar: 'https://picsum.photos/seed/npc$i/200',
          level: 3 + _random.nextInt(5),
          petGrowthValue: 1000 + _random.nextInt(2000),
          lastActive: DateTime.now().subtract(Duration(hours: _random.nextInt(24))),
          isNPC: true,
        ));
      }
    }
  }

  // 获取好友列表
  Future<List<Friend>> getFriendList() async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      // 调用后端API获取好友列表
      final currentUser = authManager.currentUser;
      final petId = currentUser?.petId?.toString() ?? '1';
      final response = await ApiManager.instance.getFriendList(
        currentUser?.userId?.toString() ?? '',
        petId
      );
      
      if (response['code'] == 200) {
        final friendsData = response['data']['friends'] as List;
        final friends = friendsData.map((f) => Friend.fromMap(f)).toList();
        return friends;
      }
    } catch (e) {
      print('获取好友列表失败: $e');
    }

    // 生成模拟好友数据
    return _generateMockFriends();
  }

  // 搜索添加好友
  Future<bool> addFriend(String nickname) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      // 调用后端API添加好友
      // 这里简化处理，使用固定的petId=1，实际应该从用户数据中获取
      final response = await ApiManager.instance.addFriend(
        currentUser.userId?.toString() ?? '',
        '1', // 固定petId，实际应该从用户数据中获取
        nickname
      );
      return response['code'] == 200;
    } catch (e) {
      print('添加好友失败: $e');
      return false;
    }
  }

  // 随机匹配陌生人
  Future<List<Friend>> getStrangerList() async {
    _initializeNPCs();
    
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      // 调用后端API获取陌生人列表
      final strangersData = await ApiManager.instance.getStrangerList();
      final strangers = strangersData.map((s) => Friend.fromMap(s)).toList();
      
      // 添加NPC到陌生人列表
      final npcCount = min(3, _npcList.length);
      final randomNPCs = _npcList.sublist(0, npcCount);
      strangers.addAll(randomNPCs);
      
      return strangers;
    } catch (e) {
      print('获取陌生人列表失败: $e');
    }

    // 生成模拟陌生人数据
    return _generateMockStrangers();
  }

  // 发起宠物成长竞赛
  Future<Competition> startPetCompetition(String opponentId, int durationDays) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      // 调用后端API发起竞赛
      final response = await ApiManager.instance.startPetCompetition(opponentId, durationDays);
      if (response['code'] == 200) {
        return Competition.fromMap(response['data']);
      }
    } catch (e) {
      print('发起竞赛失败: $e');
    }

    // 生成模拟竞赛数据
    return _generateMockCompetition(opponentId, durationDays);
  }

  // 获取进行中的竞赛
  Future<List<Competition>> getActiveCompetitions() async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      // 调用后端API获取竞赛列表
      final response = await ApiManager.instance.getActiveCompetitions();
      if (response['code'] == 200) {
        return (response['data'] as List).map((c) => Competition.fromMap(c)).toList();
      }
    } catch (e) {
      print('获取竞赛列表失败: $e');
    }

    // 生成模拟竞赛数据
    return [];
  }

  // 更新竞赛数据
  Future<Competition> updateCompetitionData(String competitionId) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      // 调用后端API更新竞赛数据
      final response = await ApiManager.instance.updateCompetitionData(competitionId);
      if (response['code'] == 200) {
        return Competition.fromMap(response['data']);
      }
    } catch (e) {
      print('更新竞赛数据失败: $e');
    }

    // 生成模拟更新数据
    throw Exception('更新竞赛数据失败');
  }

  // 结算竞赛
  Future<Competition> settleCompetition(String competitionId) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      // 调用后端API结算竞赛
      final response = await ApiManager.instance.settleCompetition(competitionId);
      if (response['code'] == 200) {
        return Competition.fromMap(response['data']);
      }
    } catch (e) {
      print('结算竞赛失败: $e');
    }

    // 生成模拟结算数据
    throw Exception('结算竞赛失败');
  }

  // 获取排行榜
  Future<List<Map<String, dynamic>>> getLeaderboard(String type, int limit) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      // 调用后端API获取排行榜
      final response = await ApiManager.instance.getLeaderboard(type, limit);
      if (response['code'] == 200) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
    } catch (e) {
      print('获取排行榜失败: $e');
    }

    // 生成模拟排行榜数据
    return _generateMockLeaderboard(type, limit);
  }

  // 创建挑战
  Future<Map<String, dynamic>> createChallenge(String taskId, String challengeName) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    // 调用后端API创建挑战
    final response = await ApiManager.instance.createChallenge(taskId, challengeName);
    if (response['code'] != 200) {
      throw Exception(response['msg']);
    }

    return response['data'];
  }

  // 创建好友挑战
  Future<Map<String, dynamic>> createFriendChallenge(String taskId, String challengeName, String opponentId, String opponentNickname) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      // 调用后端API创建好友挑战
      final response = await ApiManager.instance.createFriendChallenge(taskId, challengeName, opponentId, opponentNickname);
      if (response['code'] != 200) {
        throw Exception(response['msg']);
      }

      return response['data'];
    } catch (e) {
      print('创建好友挑战失败: $e');
      // 生成模拟数据
      return {
        'challengeId': 'friend_challenge_${DateTime.now().millisecondsSinceEpoch}',
        'taskId': taskId,
        'challengeName': challengeName,
        'opponentId': opponentId,
        'opponentNickname': opponentNickname,
        'opponentLevel': 5,
      };
    }
  }

  // 匹配对手
  Future<Map<String, dynamic>?> matchOpponent(String challengeId) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    // 调用后端API匹配对手
    final response = await ApiManager.instance.matchOpponent(challengeId);
    if (response['code'] != 200) {
      // 如果没有匹配到对手，返回null
      if (response['msg'] == '暂无匹配对手') {
        return null;
      }
      throw Exception(response['msg']);
    }

    return response['data'];
  }

  // 同步挑战完成数据
  Future<Map<String, dynamic>> syncChallengeData(String challengeId, int finishStatus, int? finishTime, int? taskScore) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    // 调用后端API同步挑战数据
    final response = await ApiManager.instance.syncChallengeData(challengeId, finishStatus, finishTime, taskScore);
    if (response['code'] != 200) {
      throw Exception(response['msg']);
    }

    return response['data'];
  }

  // 挑战结算
  Future<Map<String, dynamic>> settleChallenge(String challengeId) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    // 调用后端API进行挑战结算
    final response = await ApiManager.instance.settleChallenge(challengeId);
    if (response['code'] != 200) {
      throw Exception(response['msg']);
    }

    return response['data'];
  }

  // 获取挑战记录
  Future<Map<String, dynamic>> getChallengeRecords(int page, int size) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    // 调用后端API获取挑战记录
    final response = await ApiManager.instance.getChallengeRecords(page, size);
    if (response['code'] != 200) {
      throw Exception(response['msg']);
    }

    return response['data'];
  }

  // 获取挑战大厅列表
  Future<Map<String, dynamic>> getChallengeHall(int page, int size) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    // 调用后端API获取挑战大厅列表
    final response = await ApiManager.instance.getChallengeHall(page, size);
    if (response['code'] != 200) {
      throw Exception(response['msg']);
    }

    return response['data'];
  }

  // 获取挑战统计
  Future<Map<String, dynamic>> getChallengeStatistics() async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    // 获取用户挑战记录
    final response = await ApiManager.instance.getChallengeRecords(1, 100);
    if (response['code'] != 200) {
      throw Exception(response['msg']);
    }

    final records = response['data']['list'];
    final totalChallenges = records.length;
    
    int wonChallenges = 0;
    for (final record in records) {
      if (record['settleResult'] == '胜') {
        wonChallenges++;
      }
    }

    final winRate = totalChallenges > 0 ? wonChallenges / totalChallenges : 0.0;
    
    return {
      'total_challenges': totalChallenges,
      'won_challenges': wonChallenges,
      'win_rate': winRate,
      'current_score': currentUser.challengeScore,
    };
  }

  // 生成模拟好友数据
  List<Friend> _generateMockFriends() {
    final friends = [
      Friend(
        id: 'friend_1',
        nickname: '小明',
        avatar: 'https://picsum.photos/seed/friend1/200',
        level: 5,
        petGrowthValue: 1500,
        isOnline: true,
        lastActive: DateTime.now(),
      ),
      Friend(
        id: 'friend_2',
        nickname: '小红',
        avatar: 'https://picsum.photos/seed/friend2/200',
        level: 4,
        petGrowthValue: 1200,
        isOnline: false,
        lastActive: DateTime.now().subtract(Duration(hours: 2)),
      ),
      Friend(
        id: 'friend_3',
        nickname: '小李',
        avatar: 'https://picsum.photos/seed/friend3/200',
        level: 6,
        petGrowthValue: 1800,
        isOnline: true,
        lastActive: DateTime.now(),
      ),
    ];
    return friends;
  }

  // 生成模拟陌生人数据
  List<Friend> _generateMockStrangers() {
    _initializeNPCs();
    
    final strangers = [
      Friend(
        id: 'stranger_1',
        nickname: '学习小能手',
        avatar: 'https://picsum.photos/seed/stranger1/200',
        level: 3,
        petGrowthValue: 800,
        lastActive: DateTime.now().subtract(Duration(hours: 5)),
      ),
      Friend(
        id: 'stranger_2',
        nickname: '任务达人',
        avatar: 'https://picsum.photos/seed/stranger2/200',
        level: 4,
        petGrowthValue: 1100,
        lastActive: DateTime.now().subtract(Duration(hours: 1)),
      ),
    ];
    
    // 添加NPC
    strangers.addAll(_npcList.take(3));
    
    return strangers;
  }

  // 生成模拟竞赛数据
  Competition _generateMockCompetition(String opponentId, int durationDays) {
    final now = DateTime.now();
    return Competition(
      id: 'competition_${now.millisecondsSinceEpoch}',
      opponentId: opponentId,
      opponentNickname: '对手昵称',
      durationDays: durationDays,
      startTime: now,
      endTime: now.add(Duration(days: durationDays)),
      initialGrowthValue: 1000,
      currentGrowthValue: 1000,
      opponentGrowthValue: 1000,
      status: 'active',
    );
  }

  // 生成模拟排行榜数据
  List<Map<String, dynamic>> _generateMockLeaderboard(String type, int limit) {
    final List<Map<String, dynamic>> leaderboard = [];
    for (int i = 1; i <= limit; i++) {
      leaderboard.add({
        'rank': i,
        'id': 'user_$i',
        'nickname': '用户$i',
        'avatar': 'https://picsum.photos/seed/user$i/200',
        'level': 5 + (limit - i),
        'value': 2000 - (i * 100),
      });
    }
    return leaderboard;
  }
}


