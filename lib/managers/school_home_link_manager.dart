import 'dart:convert';
import '../models/task_model.dart';

class SchoolHomeLinkManager {
  static final SchoolHomeLinkManager instance = SchoolHomeLinkManager._init();
  
  // 任务模板库
  final List<Map<String, dynamic>> _taskTemplates = [
    {
      'id': 'template_001',
      'name': '基础数学练习',
      'subject': '数学',
      'grade': '小学',
      'description': '包含基础算术、应用题等练习',
      'difficulty': TaskDifficulty.easy,
      'duration': 30,
      'benefit_value': 10,
      'category': '基础训练',
      'is_public': true,
      'creator': '系统',
    },
    {
      'id': 'template_002',
      'name': '阅读理解训练',
      'subject': '语文',
      'grade': '小学',
      'description': '提高阅读理解能力的专项训练',
      'difficulty': TaskDifficulty.medium,
      'duration': 45,
      'benefit_value': 15,
      'category': '阅读理解',
      'is_public': true,
      'creator': '系统',
    },
    {
      'id': 'template_003',
      'name': '英语口语练习',
      'subject': '英语',
      'grade': '小学',
      'description': '提升英语口语表达能力',
      'difficulty': TaskDifficulty.medium,
      'duration': 30,
      'benefit_value': 12,
      'category': '口语训练',
      'is_public': true,
      'creator': '系统',
    },
    {
      'id': 'template_004',
      'name': '数学思维拓展',
      'subject': '数学',
      'grade': '初中',
      'description': '培养数学思维能力的拓展练习',
      'difficulty': TaskDifficulty.hard,
      'duration': 60,
      'benefit_value': 20,
      'category': '思维训练',
      'is_public': true,
      'creator': '系统',
    },
    {
      'id': 'template_005',
      'name': '作文写作指导',
      'subject': '语文',
      'grade': '初中',
      'description': '提升作文写作水平的指导练习',
      'difficulty': TaskDifficulty.hard,
      'duration': 90,
      'benefit_value': 25,
      'category': '写作训练',
      'is_public': true,
      'creator': '系统',
    },
  ];
  
  // 教师创建的模板
  final List<Map<String, dynamic>> _teacherCreatedTemplates = [];
  
  // 家长查看权限设置
  final Map<String, dynamic> _parentPermissions = {
    'can_view_tasks': true,
    'can_view_progress': true,
    'can_view_achievements': true,
    'can_view_mental_state': false,
    'can_view_social': false,
    'can_manage_tasks': false,
  };
  
  // 学生-家长关联
  final Map<String, String> _studentParentMap = {
    'user_001': 'parent_001', // 学生ID -> 家长ID
  };
  
  SchoolHomeLinkManager._init();
  
  // 获取任务模板库
  List<Map<String, dynamic>> getTaskTemplates({String? subject, String? grade, String? category}) {
    var templates = [..._taskTemplates, ..._teacherCreatedTemplates];
    
    if (subject != null) {
      templates = templates.where((template) => template['subject'] == subject).toList();
    }
    
    if (grade != null) {
      templates = templates.where((template) => template['grade'] == grade).toList();
    }
    
    if (category != null) {
      templates = templates.where((template) => template['category'] == category).toList();
    }
    
    return templates;
  }
  
  // 创建任务模板
  void createTaskTemplate(Map<String, dynamic> template) {
    final newTemplate = {
      'id': 'template_${DateTime.now().millisecondsSinceEpoch}',
      'created_at': DateTime.now().toString(),
      ...template,
    };
    
    _teacherCreatedTemplates.add(newTemplate);
  }
  
  // 更新任务模板
  void updateTaskTemplate(String templateId, Map<String, dynamic> updates) {
    // 先检查教师创建的模板
    final teacherTemplateIndex = _teacherCreatedTemplates.indexWhere((t) => t['id'] == templateId);
    if (teacherTemplateIndex != -1) {
      _teacherCreatedTemplates[teacherTemplateIndex] = {
        ..._teacherCreatedTemplates[teacherTemplateIndex],
        ...updates,
        'updated_at': DateTime.now().toString(),
      };
    }
    
    // 再检查系统模板（系统模板不可修改）
    final systemTemplateIndex = _taskTemplates.indexWhere((t) => t['id'] == templateId);
    if (systemTemplateIndex != -1) {
      // 系统模板不可修改，可选择复制为教师模板后修改
      final systemTemplate = _taskTemplates[systemTemplateIndex];
      final copiedTemplate = {
        ...systemTemplate,
        'id': 'template_${DateTime.now().millisecondsSinceEpoch}',
        'is_public': false,
        'creator': 'teacher',
        'created_at': DateTime.now().toString(),
        ...updates,
      };
      _teacherCreatedTemplates.add(copiedTemplate);
    }
  }
  
  // 删除任务模板（仅教师创建的模板可删除）
  void deleteTaskTemplate(String templateId) {
    _teacherCreatedTemplates.removeWhere((t) => t['id'] == templateId);
  }
  
  // 获取家长权限
  Map<String, dynamic> getParentPermissions(String parentId) {
    // 实际项目中应根据家长ID获取对应权限
    return _parentPermissions;
  }
  
  // 更新家长权限
  void updateParentPermissions(String parentId, Map<String, dynamic> permissions) {
    // 实际项目中应根据家长ID更新对应权限
    _parentPermissions.addAll(permissions);
  }
  
  // 获取学生家长ID
  String? getParentId(String studentId) {
    return _studentParentMap[studentId];
  }
  
  // 关联学生和家长
  void linkStudentParent(String studentId, String parentId) {
    _studentParentMap[studentId] = parentId;
  }
  
  // 获取家长可查看的学生数据
  Map<String, dynamic> getParentViewData(String studentId) {
    // 实际项目中应从数据库获取真实数据
    return {
      'student_id': studentId,
      'student_name': '学生姓名',
      'tasks': {
        'total': 20,
        'completed': 15,
        'in_progress': 3,
        'pending': 2,
      },
      'progress': {
        'weekly_completion_rate': 0.75,
        'monthly_completion_rate': 0.8,
        'continuous_days': 7,
      },
      'achievements': {
        'total': 12,
        'recent': [
          {
            'name': '连续打卡7天',
            'date': DateTime.now().subtract(Duration(days: 1)).toString(),
          },
          {
            'name': '任务完成率80%',
            'date': DateTime.now().subtract(Duration(days: 3)).toString(),
          },
        ],
      },
      'pet': {
        'name': '宠物名称',
        'level': 5,
        'happiness': 80,
        'experience': 120,
      },
    };
  }
  
  // 教师分配任务给学生
  void assignTaskToStudent(String teacherId, String studentId, Map<String, dynamic> taskData) {
    // 实际项目中应将任务分配记录保存到数据库
    print('教师 $teacherId 分配任务给学生 $studentId: ${taskData['name']}');
  }
  
  // 获取教师分配的任务
  List<Map<String, dynamic>> getAssignedTasks(String studentId) {
    // 实际项目中应从数据库获取真实数据
    return [
      {
        'id': 'assigned_001',
        'name': '数学 homework',
        'assigned_by': '张老师',
        'assigned_at': DateTime.now().subtract(Duration(days: 1)).toString(),
        'due_date': DateTime.now().add(Duration(days: 2)).toString(),
        'status': 'in_progress',
      },
      {
        'id': 'assigned_002',
        'name': '语文作文',
        'assigned_by': '李老师',
        'assigned_at': DateTime.now().subtract(Duration(days: 2)).toString(),
        'due_date': DateTime.now().add(Duration(days: 1)).toString(),
        'status': 'pending',
      },
    ];
  }
}
