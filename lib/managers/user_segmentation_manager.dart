import 'dart:convert';
import '../managers/user_ability_manager.dart';
import '../managers/social_challenge_manager.dart';
import '../managers/pet_manager.dart';


class UserSegmentationManager {
  static final UserSegmentationManager instance = UserSegmentationManager._init();
  
  // 用户分层等级
  static const String NEWBIE = 'newbie'; // 新手
  static const String ACTIVE = 'active'; // 活跃用户
  static const String CORE = 'core'; // 核心用户
  static const String ELITE = 'elite'; // 精英用户
  static const String LEGEND = 'legend'; // 传奇用户
  
  // 分层标准配置
  final Map<String, Map<String, dynamic>> _segmentationCriteria = {
    NEWBIE: {
      'min_task_completion_rate': 0.0,
      'min_active_days': 0,
      'min_pet_level': 1,
      'min_friends': 0,
      'name': '新手',
      'color': '#9E9E9E',
    },
    ACTIVE: {
      'min_task_completion_rate': 0.3,
      'min_active_days': 3,
      'min_pet_level': 3,
      'min_friends': 1,
      'name': '活跃用户',
      'color': '#4CAF50',
    },
    CORE: {
      'min_task_completion_rate': 0.6,
      'min_active_days': 7,
      'min_pet_level': 6,
      'min_friends': 3,
      'name': '核心用户',
      'color': '#2196F3',
    },
    ELITE: {
      'min_task_completion_rate': 0.8,
      'min_active_days': 14,
      'min_pet_level': 10,
      'min_friends': 5,
      'name': '精英用户',
      'color': '#FF9800',
    },
    LEGEND: {
      'min_task_completion_rate': 0.9,
      'min_active_days': 30,
      'min_pet_level': 15,
      'min_friends': 8,
      'name': '传奇用户',
      'color': '#9C27B0',
    },
  };
  
  // 分层权益配置
  final Map<String, List<Map<String, dynamic>>> _segmentationBenefits = {
    NEWBIE: [
      {
        'id': 'newbie_welcome',
        'name': '新手欢迎礼包',
        'description': '获得500经验值和100金币',
        'value': 500,
        'is_active': true,
      },
      {
        'id': 'newbie_task_guide',
        'name': '任务引导',
        'description': '获得详细的任务完成指导',
        'value': 0,
        'is_active': true,
      },
    ],
    ACTIVE: [
      {
        'id': 'active_daily_bonus',
        'name': '每日活跃奖励',
        'description': '每天完成任务额外获得20%经验值',
        'value': 20,
        'is_active': true,
      },
      {
        'id': 'active_pet_bonus',
        'name': '宠物成长加速',
        'description': '宠物经验获取速度提升15%',
        'value': 15,
        'is_active': true,
      },
      {
        'id': 'active_social_bonus',
        'name': '社交互动加成',
        'description': '好友互动获得的经验提升10%',
        'value': 10,
        'is_active': true,
      },
    ],
    CORE: [
      {
        'id': 'core_task_bonus',
        'name': '任务经验加成',
        'description': '完成任务获得25%额外经验值',
        'value': 25,
        'is_active': true,
      },
      {
        'id': 'core_pet_skill',
        'name': '宠物技能解锁',
        'description': '解锁宠物特殊技能',
        'value': 0,
        'is_active': true,
      },
      {
        'id': 'core_competition_priority',
        'name': '竞赛优先匹配',
        'description': '在宠物竞赛中获得优先匹配权',
        'value': 0,
        'is_active': true,
      },
      {
        'id': 'core_ai_analysis',
        'name': '高级AI分析',
        'description': '获得更详细的AI心理分析报告',
        'value': 0,
        'is_active': true,
      },
    ],
    ELITE: [
      {
        'id': 'elite_task_mastery',
        'name': '任务精通奖励',
        'description': '完成任务获得35%额外经验值',
        'value': 35,
        'is_active': true,
      },
      {
        'id': 'elite_pet_evolution',
        'name': '宠物进化',
        'description': '宠物解锁进化形态',
        'value': 0,
        'is_active': true,
      },
      {
        'id': 'elite_exclusive_competition',
        'name': '专属竞赛',
        'description': '参与精英专属宠物竞赛',
        'value': 0,
        'is_active': true,
      },
      {
        'id': 'elite_priority_support',
        'name': '优先支持',
        'description': '获得客服优先响应权',
        'value': 0,
        'is_active': true,
      },
      {
        'id': 'elite_custom_task',
        'name': '定制任务',
        'description': '获得个性化定制任务',
        'value': 0,
        'is_active': true,
      },
    ],
    LEGEND: [
      {
        'id': 'legend_ultimate_bonus',
        'name': '终极经验加成',
        'description': '完成任务获得50%额外经验值',
        'value': 50,
        'is_active': true,
      },
      {
        'id': 'legend_pet_legendary',
        'name': '传奇宠物',
        'description': '解锁传奇级宠物形态',
        'value': 0,
        'is_active': true,
      },
      {
        'id': 'legend_grand_competition',
        'name': '传奇大赛',
        'description': '参与传奇级宠物竞赛',
        'value': 0,
        'is_active': true,
      },
      {
        'id': 'legend_personal_coach',
        'name': '专属教练',
        'description': '获得AI专属学习教练',
        'value': 0,
        'is_active': true,
      },
      {
        'id': 'legend_custom_pet',
        'name': '定制宠物',
        'description': '创建个性化定制宠物',
        'value': 0,
        'is_active': true,
      },
      {
        'id': 'legend_hall_of_fame',
        'name': '名人堂',
        'description': '进入游戏名人堂',
        'value': 0,
        'is_active': true,
      },
    ],
  };
  
  // 用户当前分层
  String _currentSegment = NEWBIE;
  
  // 用户分层历史
  final List<Map<String, dynamic>> _segmentHistory = [];
  
  UserSegmentationManager._init();
  
  // 评估用户分层
  Future<String> evaluateUserSegment() async {
    final userAbilityManager = UserAbilityManager.instance;
    final socialManager = SocialChallengeManager.instance;
    final petManager = PetManager.instance;
    
    // 初始化必要的管理器
    await userAbilityManager.initializeAbilityModel();
    await petManager.initializePet();
    
    // 1. 计算任务完成率
    final taskHistory = userAbilityManager.getTaskHistory();
    final completedTasks = taskHistory.where((task) => task['is_completed']).length;
    final taskCompletionRate = taskHistory.isNotEmpty ? completedTasks / taskHistory.length : 0.0;
    
    // 2. 计算活跃天数（模拟数据，实际应从数据库获取）
    final activeDays = taskHistory.isNotEmpty ? (taskHistory.length / 2).ceil() : 0;
    
    // 3. 获取宠物等级
    final pet = await petManager.getPet();
    final petLevel = pet.level;
    
    // 4. 获取好友数量
    final friends = await socialManager.getFriendList();
    final friendCount = friends.length;
    
    // 5. 评估用户分层
    String newSegment = NEWBIE;
    
    // 从高到低检查分层条件
    if (_checkSegmentCriteria(LEGEND, {
      'task_completion_rate': taskCompletionRate,
      'active_days': activeDays,
      'pet_level': petLevel,
      'friend_count': friendCount,
    })) {
      newSegment = LEGEND;
    } else if (_checkSegmentCriteria(ELITE, {
      'task_completion_rate': taskCompletionRate,
      'active_days': activeDays,
      'pet_level': petLevel,
      'friend_count': friendCount,
    })) {
      newSegment = ELITE;
    } else if (_checkSegmentCriteria(CORE, {
      'task_completion_rate': taskCompletionRate,
      'active_days': activeDays,
      'pet_level': petLevel,
      'friend_count': friendCount,
    })) {
      newSegment = CORE;
    } else if (_checkSegmentCriteria(ACTIVE, {
      'task_completion_rate': taskCompletionRate,
      'active_days': activeDays,
      'pet_level': petLevel,
      'friend_count': friendCount,
    })) {
      newSegment = ACTIVE;
    }
    
    // 更新当前分层
    if (newSegment != _currentSegment) {
      _segmentHistory.add({
        'segment': newSegment,
        'timestamp': DateTime.now().toString(),
        'reason': '等级提升',
      });
      _currentSegment = newSegment;
    }
    
    return newSegment;
  }
  
  // 检查分层条件
  bool _checkSegmentCriteria(String segment, Map<String, dynamic> userData) {
    final criteria = _segmentationCriteria[segment];
    if (criteria == null) return false;
    
    return userData['task_completion_rate'] >= criteria['min_task_completion_rate'] &&
           userData['active_days'] >= criteria['min_active_days'] &&
           userData['pet_level'] >= criteria['min_pet_level'] &&
           userData['friend_count'] >= criteria['min_friends'];
  }
  
  // 获取用户当前分层
  String getCurrentSegment() {
    return _currentSegment;
  }
  
  // 获取分层信息
  Map<String, dynamic>? getSegmentInfo(String segment) {
    return _segmentationCriteria[segment];
  }
  
  // 获取用户当前分层信息
  Map<String, dynamic>? getCurrentSegmentInfo() {
    return getSegmentInfo(_currentSegment);
  }
  
  // 获取用户分层权益
  List<Map<String, dynamic>> getSegmentBenefits(String segment) {
    return _segmentationBenefits[segment] ?? [];
  }
  
  // 获取用户当前分层权益
  List<Map<String, dynamic>> getCurrentSegmentBenefits() {
    return getSegmentBenefits(_currentSegment);
  }
  
  // 获取所有分层权益（包括当前分层及以下）
  List<Map<String, dynamic>> getAllAvailableBenefits() {
    final benefits = <Map<String, dynamic>>[];
    
    // 按分层等级从低到高添加权益
    final segments = [NEWBIE, ACTIVE, CORE, ELITE, LEGEND];
    
    for (final segment in segments) {
      benefits.addAll(getSegmentBenefits(segment));
      if (segment == _currentSegment) {
        break; // 只添加当前分层及以下的权益
      }
    }
    
    return benefits;
  }
  
  // 动态调整分层权益
  void adjustSegmentBenefits(String segment, String benefitId, bool isActive) {
    final benefits = _segmentationBenefits[segment];
    if (benefits != null) {
      final benefitIndex = benefits.indexWhere((b) => b['id'] == benefitId);
      if (benefitIndex != -1) {
        benefits[benefitIndex]['is_active'] = isActive;
      }
    }
  }
  
  // 获取分层进度
  Map<String, dynamic> getSegmentProgress() {
    final currentSegmentInfo = getCurrentSegmentInfo();
    if (currentSegmentInfo == null) {
      return {
        'current_segment': NEWBIE,
        'next_segment': ACTIVE,
        'progress': 0.0,
        'requirements': {},
      };
    }
    
    // 计算下一个分层
    final segments = [NEWBIE, ACTIVE, CORE, ELITE, LEGEND];
    final currentIndex = segments.indexOf(_currentSegment);
    final nextSegment = currentIndex < segments.length - 1 ? segments[currentIndex + 1] : null;
    
    if (nextSegment == null) {
      return {
        'current_segment': _currentSegment,
        'next_segment': null,
        'progress': 1.0,
        'requirements': {},
      };
    }
    
    // 计算进度（模拟数据，实际应基于真实数据）
    final progress = (currentIndex + 1) / segments.length;
    
    return {
      'current_segment': _currentSegment,
      'next_segment': nextSegment,
      'progress': progress,
      'requirements': getSegmentInfo(nextSegment) ?? {},
    };
  }
  
  // 获取分层历史
  List<Map<String, dynamic>> getSegmentHistory() {
    return _segmentHistory;
  }
}
