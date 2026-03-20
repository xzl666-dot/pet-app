import '../managers/api_manager.dart';
import '../models/user_model.dart';
import '../managers/auth_manager.dart';

class StateManager {
  static final StateManager instance = StateManager._init();

  StateManager._init();

  // 状态类型定义
  static const int STATE_NORMAL = 0; // 正常
  static const int STATE_TIRED = 1; // 疲惫
  static const int STATE_LAZY = 2; // 懈怠
  static const int STATE_FOCUSED = 3; // 专注

  // 状态名称映射
  static const Map<int, String> stateNames = {
    STATE_NORMAL: '正常',
    STATE_TIRED: '疲惫',
    STATE_LAZY: '懈怠',
    STATE_FOCUSED: '专注',
  };

  // 状态颜色映射
  static const Map<int, String> stateColors = {
    STATE_NORMAL: '#4CAF50', // 绿色
    STATE_TIRED: '#9E9E9E', // 灰色
    STATE_LAZY: '#FFC107', // 黄色
    STATE_FOCUSED: '#F44336', // 红色
  };

  // 识别用户状态
  Future<Map<String, dynamic>> recognizeState() async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    // 调用后端API识别状态
    final response = await ApiManager.instance.recognizeState();
    if (response['code'] != 200) {
      throw Exception(response['msg']);
    }

    return response['data'];
  }

  // 手动标记状态
  Future<Map<String, dynamic>> manualState(int stateCode) async {
    final authManager = AuthManager.instance;
    final currentUser = authManager.currentUser;
    if (currentUser == null) {
      throw Exception('用户未登录');
    }

    // 调用后端API手动标记状态
    final response = await ApiManager.instance.manualState(stateCode);
    if (response['code'] != 200) {
      throw Exception(response['msg']);
    }

    return response['data'];
  }

  // 获取状态适配策略
  String getAdaptStrategy(int stateCode) {
    switch (stateCode) {
      case STATE_TIRED:
        return '推荐轻量任务，减少任务量';
      case STATE_LAZY:
        return '推荐趣味型任务，增加即时反馈';
      case STATE_FOCUSED:
        return '推荐进阶任务，提升宠物收益';
      case STATE_NORMAL:
      default:
        return '正常推荐任务';
    }
  }

  // 获取状态反馈文字
  String getFeedbackText(int stateCode) {
    switch (stateCode) {
      case STATE_TIRED:
        return '你看起来有点累，试试轻量任务吧～';
      case STATE_LAZY:
        return '来点趣味任务，重拾动力吧～';
      case STATE_FOCUSED:
        return '专注状态拉满，挑战进阶任务吧！';
      case STATE_NORMAL:
      default:
        return '';
    }
  }
}
