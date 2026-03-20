import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/token_util.dart';

class ApiManager {
  static final ApiManager instance = ApiManager._init();
  final Dio _dio = Dio();
  static const String baseUrl = 'http://localhost:3000/api';

  ApiManager._init() {
    // 初始化Dio
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);

    // 添加请求拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 添加token到请求头
        final token = await TokenUtil.instance.getAccessToken();
        if (token != null) {
          options.headers['token'] = token;
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioError error, handler) async {
        // 处理403错误（token过期）
        if (error.response?.statusCode == 403) {
          // 尝试刷新token
          final refreshed = await TokenUtil.instance.refreshToken();
          if (refreshed) {
            // 重新发起请求
            final newOptions = Options(
              method: error.requestOptions.method,
              headers: {
                'token': await TokenUtil.instance.getAccessToken(),
              },
            );
            try {
              final newResponse = await _dio.request(
                error.requestOptions.path,
                options: newOptions,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              return handler.resolve(newResponse);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  // 登录
  Future<Map<String, dynamic>> login(String username, String password, String deviceId, String deviceName) async {
    final response = await _dio.post('/user/login', data: {
      'username': username,
      'password': password,
      'deviceId': deviceId,
      'versionType': 1,
    });
    return response.data;
  }

  // 刷新令牌
  Future<Map<String, dynamic>> refreshToken(String refreshToken, String deviceId) async {
    final response = await _dio.post('/user/refresh-token', data: {
      'refreshToken': refreshToken,
      'deviceId': deviceId,
    });
    return response.data;
  }

  // 注册
  Future<Map<String, dynamic>> register(String username, String password, String versionType) async {
    final response = await _dio.post('/user/register', data: {
      'username': username,
      'password': password,
      'nickname': username,
      'versionType': 1,
    });
    return response.data;
  }

  // 检查用户名是否存在
  Future<Map<String, dynamic>> checkUsername(String username) async {
    final response = await _dio.get('/user/check-username', queryParameters: {
      'username': username,
    });
    return response.data;
  }

  // 获取用户信息
  Future<Map<String, dynamic>> getUserInfo() async {
    final response = await _dio.get('/user/info');
    return response.data;
  }

  // 退出登录
  Future<Map<String, dynamic>> logout(String refreshToken, String deviceId) async {
    final response = await _dio.post('/user/logout', data: {
      'refreshToken': refreshToken,
      'deviceId': deviceId,
    });
    return response.data;
  }

  // 重置密码
  Future<Map<String, dynamic>> resetPassword(String username, String newPassword) async {
    final response = await _dio.post('/user/reset-password', data: {
      'username': username,
      'password': newPassword,
    });
    return response.data;
  }

  // 创建挑战
  Future<Map<String, dynamic>> createChallenge(String taskId, String challengeName) async {
    final response = await _dio.post('/challenge/create', data: {
      'taskId': taskId,
      'challengeName': challengeName,
    });
    return response.data;
  }

  // 匹配对手
  Future<Map<String, dynamic>> matchOpponent(String challengeId) async {
    final response = await _dio.get('/challenge/match/$challengeId');
    return response.data;
  }

  // 同步挑战数据
  Future<Map<String, dynamic>> syncChallengeData(String challengeId, int finishStatus, int? finishTime, int? taskScore) async {
    final response = await _dio.post('/challenge/sync', data: {
      'challengeId': challengeId,
      'finishStatus': finishStatus,
      'finishTime': finishTime,
      'taskScore': taskScore,
    });
    return response.data;
  }

  // 挑战结算
  Future<Map<String, dynamic>> settleChallenge(String challengeId) async {
    final response = await _dio.get('/challenge/settle/$challengeId');
    return response.data;
  }

  // 获取挑战记录
  Future<Map<String, dynamic>> getChallengeRecords(int page, int size) async {
    final response = await _dio.get('/challenge/record/$page/$size');
    return response.data;
  }

  // 获取挑战大厅
  Future<Map<String, dynamic>> getChallengeHall(int page, int size) async {
    final response = await _dio.get('/challenge/hall/$page/$size');
    return response.data;
  }

  // 状态识别
  Future<Map<String, dynamic>> recognizeState() async {
    final response = await _dio.get('/state/recognize');
    return response.data;
  }

  // 手动标记状态
  Future<Map<String, dynamic>> manualState(int stateCode) async {
    final response = await _dio.post('/state/manual', data: {
      'stateCode': stateCode,
    });
    return response.data;
  }

  // 获取任务推荐
  Future<Map<String, dynamic>> getTaskRecommend() async {
    final response = await _dio.get('/task/recommend');
    return response.data;
  }

  // 标记任务完成
  Future<Map<String, dynamic>> finishTask(int taskId, bool isCompleted) async {
    final response = await _dio.post('/task/finish', data: {
      'taskId': taskId,
      'isCompleted': isCompleted,
    });
    return response.data;
  }

  // 获取任务列表
  Future<Map<String, dynamic>> getTaskList() async {
    final response = await _dio.get('/task/list');
    return response.data;
  }

  // 开始宠物竞赛
  Future<Map<String, dynamic>> startPetCompetition(String opponentId, int durationDays) async {
    final response = await _dio.post('/competition/start', data: {
      'opponentId': opponentId,
      'durationDays': durationDays,
    });
    return response.data;
  }

  // 获取活跃竞赛
  Future<Map<String, dynamic>> getActiveCompetitions() async {
    final response = await _dio.get('/competition/active');
    return response.data;
  }

  // 更新竞赛数据
  Future<Map<String, dynamic>> updateCompetitionData(String competitionId) async {
    final response = await _dio.post('/competition/update', data: {
      'competitionId': competitionId,
    });
    return response.data;
  }

  // 结算竞赛
  Future<Map<String, dynamic>> settleCompetition(String competitionId) async {
    final response = await _dio.get('/competition/settle/$competitionId');
    return response.data;
  }

  // 获取排行榜
  Future<Map<String, dynamic>> getLeaderboard(String type, int limit) async {
    final response = await _dio.get('/competition/leaderboard', queryParameters: {
      'type': type,
      'limit': limit,
    });
    return response.data;
  }

  // 创建好友挑战
  Future<Map<String, dynamic>> createFriendChallenge(String taskId, String challengeName, String opponentId, String opponentNickname) async {
    final response = await _dio.post('/challenge/create-friend', data: {
      'taskId': taskId,
      'challengeName': challengeName,
      'opponentId': opponentId,
      'opponentNickname': opponentNickname,
    });
    return response.data;
  }

  // 获取好友列表
  Future<Map<String, dynamic>> getFriendList(String userId, String petId) async {
    final response = await _dio.get('/social/friends', queryParameters: {
      'userId': userId,
      'petId': petId
    });
    return response.data;
  }

  // 添加好友
  Future<Map<String, dynamic>> addFriend(String userId, String petId, String targetNickname) async {
    final response = await _dio.post('/social/add-friend', data: {
      'userId': userId,
      'petId': petId,
      'targetNickname': targetNickname
    });
    return response.data;
  }

  // 获取陌生人列表
  Future<List<Map<String, dynamic>>> getStrangerList() async {
    final response = await _dio.get('/social/strangers');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // 获取好友申请列表
  Future<Map<String, dynamic>> getFriendRequests(String userId) async {
    final response = await _dio.get('/social/friend-requests', queryParameters: {
      'userId': userId
    });
    return response.data;
  }

  // 接受好友申请
  Future<Map<String, dynamic>> acceptFriendRequest(String userId, String petId, String requestId) async {
    final response = await _dio.post('/social/friend-request/accept', data: {
      'userId': userId,
      'petId': petId,
      'requestId': requestId
    });
    return response.data;
  }

  // 拒绝好友申请
  Future<Map<String, dynamic>> rejectFriendRequest(String userId, String requestId) async {
    final response = await _dio.post('/social/friend-request/reject', data: {
      'userId': userId,
      'requestId': requestId
    });
    return response.data;
  }

  // 获取用户详细信息
  Future<Map<String, dynamic>> getUserDetail(String userId) async {
    final response = await _dio.get('/social/user-detail', queryParameters: {
      'userId': userId
    });
    return response.data;
  }

  // 积分兑换
  Future<Map<String, dynamic>> exchangeItem(String userId, String petId, String itemId, int itemNum) async {
    final response = await _dio.post('/incentive/integral/exchange', data: {
      'userId': userId,
      'petId': petId,
      'itemId': itemId,
      'itemNum': itemNum,
    });
    return response.data;
  }

  // 使用道具
  Future<Map<String, dynamic>> useItem(String userId, String petId, String itemId, int itemNum) async {
    final response = await _dio.post('/items/use', data: {
      'userId': userId,
      'petId': petId,
      'itemId': itemId,
      'itemNum': itemNum,
    });
    return response.data;
  }

  // 获取个人中心看板数据
  Future<Map<String, dynamic>> getUserDashboard(String userId) async {
    final response = await _dio.get('/user_center/dashboard', queryParameters: {
      'userId': userId,
    });
    return response.data;
  }

  // 每日签到 (打卡)
  Future<Map<String, dynamic>> checkIn() async {
    final response = await _dio.post('/user_center/check-in');
    return response.data;
  }

  // 获取打卡记录
  Future<Map<String, dynamic>> getCheckInData() async {
    final response = await _dio.get('/user_center/check-in');
    return response.data;
  }

  // 获取成就列表
  Future<Map<String, dynamic>> getAchievements() async {
    final response = await _dio.get('/user_center/achievements');
    return response.data;
  }

  // 领取成就奖励
  Future<Map<String, dynamic>> claimAchievementReward(int achievementId) async {
    final response = await _dio.post('/user_center/achievement/reward', data: {
      'achievementId': achievementId,
    });
    return response.data;
  }

  // 开启能力评估
  Future<Map<String, dynamic>> startAbilityAssessment() async {
    final response = await _dio.post('/task/start-assessment');
    return response.data;
  }

  // 添加自定义任务
  Future<Map<String, dynamic>> addCustomTask(String name) async {
    final response = await _dio.post('/task/add-custom', data: {
      'name': name,
    });
    return response.data;
  }

  // 获取宠物列表
  Future<Map<String, dynamic>> getPetList(String userId) async {
    final response = await _dio.get('/pet/list', queryParameters: {
      'userId': userId,
    });
    return response.data;
  }

  // 获取激励核心数据
  Future<Map<String, dynamic>> getIncentiveCore(String userId, String petId) async {
    final response = await _dio.get('/incentive/core', queryParameters: {
      'userId': userId,
      'petId': petId,
    });
    return response.data;
  }

  // 同步偏好
  Future<Map<String, dynamic>> syncIncentivePreference(String userId, String petId, Map<String, dynamic> preference) async {
    final response = await _dio.post('/incentive/prefer/sync', data: {
      'userId': userId,
      'petId': petId,
      'preference': preference,
    });
    return response.data;
  }

  // 领取福利
  Future<Map<String, dynamic>> receiveWelfare(String userId, String petId, String welfareType) async {
    final response = await _dio.post('/incentive/welfare/receive', data: {
      'userId': userId,
      'petId': petId,
      'welfareType': welfareType,
    });
    return response.data;
  }

  // 领取每周任务奖励
  Future<Map<String, dynamic>> receiveWeeklyTaskReward(String userId, String petId, int weeklyTaskCount) async {
    final response = await _dio.post('/incentive/weekly-task/reward', data: {
      'userId': userId,
      'petId': petId,
      'weeklyTaskCount': weeklyTaskCount,
    });
    return response.data;
  }

  // 领取月度等级福利
  Future<Map<String, dynamic>> receiveMonthlyWelfare(String userId, String petId, String abilityLevel) async {
    final response = await _dio.post('/incentive/monthly-welfare/receive', data: {
      'userId': userId,
      'petId': petId,
      'abilityLevel': abilityLevel,
    });
    return response.data;
  }

  // 每日签到
  Future<Map<String, dynamic>> signIn(String userId, String petId) async {
    final response = await _dio.post('/incentive/sign-in', data: {
      'userId': userId,
      'petId': petId,
    });
    return response.data;
  }

  // 解锁成就
  Future<Map<String, dynamic>> unlockAchievement(String userId, String petId, String achievementId) async {
    final response = await _dio.post('/incentive/achievement/unlock', data: {
      'userId': userId,
      'petId': petId,
      'achievementId': achievementId,
    });
    return response.data;
  }
}
