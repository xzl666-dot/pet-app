import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../managers/auth_manager.dart';
import '../managers/social_challenge_manager.dart';
import '../managers/state_manager.dart';
import '../managers/api_manager.dart';
import '../utils/token_util.dart';
import '../models/user_model.dart';

class AppStateProvider extends ChangeNotifier {
  // 单例
  static final AppStateProvider instance = AppStateProvider._init();

  // 管理器
  final AuthManager _authManager = AuthManager.instance;
  final SocialChallengeManager _challengeManager = SocialChallengeManager.instance;
  final StateManager _stateManager = StateManager.instance;

  // 状态
  User? _currentUser;
  Map<String, dynamic>? _challengeStats;
  Map<String, dynamic>? _currentState;
  int _userPoints = 0;
  bool _isLoading = false;

  AppStateProvider._init() {
    // 初始化时加载用户信息
    _loadUserInfo();
    // 监听 AuthManager 变化，确保用户登录后能自动加载数据
    _authManager.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    print('AppStateProvider: AuthManager 状态变化, isLoggedIn: ${_authManager.isLoggedIn}');
    if (_authManager.isLoggedIn) {
      _loadUserInfo();
    } else {
      _userPoints = 0;
      _challengeStats = null;
      _currentState = null;
      notifyListeners();
    }
  }

  // 获取当前用户
  User? get currentUser => _authManager.currentUser;

  // 获取挑战统计
  Map<String, dynamic>? get challengeStats => _challengeStats;

  // 获取当前状态
  Map<String, dynamic>? get currentState => _currentState;

  // 获取用户积分
  int get userPoints => _userPoints;

  // 获取加载状态
  bool get isLoading => _isLoading;

  // 加载用户信息
  Future<void> _loadUserInfo() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = _authManager.currentUser;
      if (_currentUser != null) {
        // 加载挑战统计
        await loadChallengeStats();
        // 加载用户状态
        await loadUserState();
        // 加载用户积分
        await loadUserPoints();
      }
    } catch (e) {
      print('加载用户信息失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 登录
  Future<bool> login(String username, String password, String deviceId, String deviceName) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 调用登录API
      final response = await _authManager.login(username, password);
      if (response) {
        // 登录成功，加载用户信息
        await _loadUserInfo();
        return true;
      }
      return false;
    } catch (e) {
      print('登录失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 登出
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authManager.logout();
      _currentUser = null;
      _challengeStats = null;
      _currentState = null;
      _userPoints = 0;
    } catch (e) {
      print('登出失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 加载挑战统计
  Future<void> loadChallengeStats() async {
    if (currentUser == null) return;

    try {
      _challengeStats = await _challengeManager.getChallengeStatistics();
      notifyListeners();
    } catch (e) {
      print('加载挑战统计失败: $e');
    }
  }

  // 加载用户状态
  Future<void> loadUserState() async {
    if (currentUser == null) return;

    try {
      _currentState = await _stateManager.recognizeState();
      notifyListeners();
    } catch (e) {
      print('加载用户状态失败: $e');
    }
  }

  // 手动标记状态
  Future<bool> manualState(int stateCode) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _stateManager.manualState(stateCode);
      _currentState = result;
      notifyListeners();
      return true;
    } catch (e) {
      print('手动标记状态失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 加载用户积分
  Future<void> loadUserPoints() async {
    print('AppStateProvider: 开始加载用户积分, 当前用户: ${currentUser?.userId ?? currentUser?.id}');
    if (currentUser == null) {
      print('AppStateProvider: 加载积分失败 - 用户未登录');
      return;
    }

    try {
      final userId = (currentUser!.userId ?? currentUser!.id).toString();
      print('AppStateProvider: 正在请求宠物列表, userId: $userId');
      
      // 获取宠物列表以获取选中的宠物ID
      final petListRes = await ApiManager.instance.getPetList(userId);
      print('AppStateProvider: 宠物列表响应: code=${petListRes['code']}, selectedPetId=${petListRes['data']?['selectedPetId']}');
      
      if (petListRes['code'] == 200) {
        final selectedPetId = petListRes['data']['selectedPetId'];
        
        if (selectedPetId != null) {
          print('AppStateProvider: 正在获取激励核心数据, PetId: $selectedPetId');
          // 使用统一的 ApiManager 请求激励核心接口
          final response = await ApiManager.instance.getIncentiveCore(userId, selectedPetId.toString());
          print('AppStateProvider: 激励核心响应: code=${response['code']}, integral=${response['data']?['integral']}');

          if (response['code'] == 200) {
            _userPoints = response['data']['integral'] ?? 0;
            notifyListeners();
            print('AppStateProvider: 全局积分已更新: $_userPoints');
          } else {
            print('AppStateProvider: 获取激励核心数据失败: ${response['msg']}');
          }
        } else {
          print('AppStateProvider: 未找到选中的宠物，无法加载积分');
          _userPoints = 0;
          notifyListeners();
        }
      } else {
        print('AppStateProvider: 宠物列表查询失败: code=${petListRes['code']}, msg=${petListRes['msg']}');
      }
    } catch (e) {
      print('加载用户积分失败: $e');
    }
  }

  // 更新积分
  void updateUserPoints(int points) {
    _userPoints = points;
    notifyListeners();
  }

  // 刷新状态
  Future<void> refreshState() async {
    await _loadUserInfo();
  }
}
