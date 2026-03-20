import 'dart:math';
import '../models/task_model.dart';
import './user_ability_manager.dart';


class TaskGenerator {
  static final TaskGenerator instance = TaskGenerator._init();
  final Random _random = Random();

  TaskGenerator._init();

  // 大学生专属任务题库
  final List<Map<String, dynamic>> _collegeTaskBank = [
    // 一、学习类
    // 每日基础任务
    {
      'name': '专业课听课打卡',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.medium,
      'duration': 45,
      'weight': 0.4,
      'description': '≥45分钟，标记课堂重点/疑问点',
      'tags': ['专业课', '听课', '打卡'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 15,
      'growthValue': 20,
      'happinessValue': 5
    },
    {
      'name': '当日课后作业完成并提交',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.medium,
      'duration': 60,
      'weight': 0.4,
      'description': '无拖延，及时完成当日作业',
      'tags': ['作业', '提交', '无拖延'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 18,
      'growthValue': 25,
      'happinessValue': 8
    },
    {
      'name': '英语单词打卡',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 30,
      'weight': 0.4,
      'description': '≥30个，四六级/考研/雅思适配',
      'tags': ['英语', '单词', '打卡'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 12,
      'growthValue': 15,
      'happinessValue': 5
    },
    {
      'name': '专业知识点背诵',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 15,
      'weight': 0.4,
      'description': '≥15分钟，公式/概念/理论',
      'tags': ['专业', '背诵', '知识点'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 10,
      'growthValue': 12,
      'happinessValue': 4
    },
    {
      'name': '课堂笔记整理',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 20,
      'weight': 0.4,
      'description': '≥20分钟，梳理当日听课内容',
      'tags': ['笔记', '整理', '听课内容'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 12,
      'growthValue': 16,
      'happinessValue': 6
    },
    {
      'name': '错题订正',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 10,
      'weight': 0.4,
      'description': '≥10分钟，整理当日作业/练习错题',
      'tags': ['错题', '订正', '整理'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 8,
      'growthValue': 10,
      'happinessValue': 3
    },
    {
      'name': '学习计划制定',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 5,
      'weight': 0.4,
      'description': '≥5分钟，规划次日学习任务',
      'tags': ['计划', '制定', '学习任务'],
      'benefitType': PetBenefitType.happiness,
      'benefitValue': 6,
      'growthValue': 8,
      'happinessValue': 5
    },
    {
      'name': '学习复盘',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 10,
      'weight': 0.4,
      'description': '≥10分钟，记录当日学习漏洞',
      'tags': ['复盘', '学习漏洞', '记录'],
      'benefitType': PetBenefitType.happiness,
      'benefitValue': 9,
      'growthValue': 12,
      'happinessValue': 7
    },
    {
      'name': '无手机学习打卡',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.medium,
      'duration': 60,
      'weight': 0.4,
      'description': '≥1小时，图书馆/自习室专属',
      'tags': ['无手机', '学习', '打卡'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 16,
      'growthValue': 22,
      'happinessValue': 8
    },
    {
      'name': '专业软件实操',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.medium,
      'duration': 20,
      'weight': 0.4,
      'description': '≥20分钟，如Excel/PS/编程/SPSS',
      'tags': ['专业软件', '实操', '技能'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 14,
      'growthValue': 18,
      'happinessValue': 7
    },
    {
      'name': '课前预习',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 15,
      'weight': 0.4,
      'description': '≥15分钟，预习次日专业课内容',
      'tags': ['预习', '专业课', '课前'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 10,
      'growthValue': 14,
      'happinessValue': 5
    },
    {
      'name': '文献泛读',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.medium,
      'duration': 20,
      'weight': 0.4,
      'description': '≥20分钟，专业相关期刊/论文',
      'tags': ['文献', '泛读', '专业'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 13,
      'growthValue': 17,
      'happinessValue': 6
    },
    {
      'name': '网课学习',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.medium,
      'duration': 30,
      'weight': 0.4,
      'description': '≥30分钟，慕课/公开课专业拓展',
      'tags': ['网课', '学习', '专业拓展'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 14,
      'growthValue': 19,
      'happinessValue': 7
    },
    {
      'name': '单词听写/默写',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 10,
      'weight': 0.4,
      'description': '≥10分钟，巩固当日背诵内容',
      'tags': ['单词', '听写', '默写'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 9,
      'growthValue': 12,
      'happinessValue': 4
    },
    {
      'name': '学习资料整理',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 15,
      'weight': 0.4,
      'description': '≥15分钟，分类整理课件/习题',
      'tags': ['资料', '整理', '分类'],
      'benefitType': PetBenefitType.happiness,
      'benefitValue': 11,
      'growthValue': 15,
      'happinessValue': 6
    },
    
    // 每周进阶任务
    {
      'name': '专业课章节复盘',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.weeklyAdvance,
      'difficulty': TaskDifficulty.hard,
      'duration': 120,
      'weight': 0.4,
      'description': '≥2小时，整理章节框架/思维导图',
      'tags': ['章节复盘', '思维导图', '专业课'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 30,
      'growthValue': 40,
      'happinessValue': 15
    },
    {
      'name': '图书馆自习打卡',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.weeklyAdvance,
      'difficulty': TaskDifficulty.medium,
      'duration': 90,
      'weight': 0.4,
      'description': '≥4次，每次≥1.5小时',
      'tags': ['图书馆', '自习', '打卡'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 25,
      'growthValue': 35,
      'happinessValue': 12
    },
    {
      'name': '课程论文/报告推进',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.weeklyAdvance,
      'difficulty': TaskDifficulty.hard,
      'duration': 120,
      'weight': 0.4,
      'description': '≥500字，按截止日期拆分',
      'tags': ['论文', '报告', '推进'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 35,
      'growthValue': 45,
      'happinessValue': 18
    },
    {
      'name': '期末/考证专项复习',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.weeklyAdvance,
      'difficulty': TaskDifficulty.hard,
      'duration': 180,
      'weight': 0.4,
      'description': '≥3小时，四六级/教资/计算机/考研',
      'tags': ['专项复习', '考证', '期末'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 40,
      'growthValue': 50,
      'happinessValue': 20
    },
    {
      'name': '专业习题刷题',
      'category': TaskCategory.study,
      'frequency': TaskFrequency.weeklyAdvance,
      'difficulty': TaskDifficulty.medium,
      'duration': 60,
      'weight': 0.4,
      'description': '≥1小时，课后习题/真题集',
      'tags': ['刷题', '习题', '专业'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 22,
      'growthValue': 30,
      'happinessValue': 10
    },
    
    // 二、职业规划类
    {
      'name': '毕业论文/设计选题调研',
      'category': TaskCategory.career,
      'frequency': TaskFrequency.weeklyAdvance,
      'difficulty': TaskDifficulty.hard,
      'duration': 120,
      'weight': 0.3,
      'description': '≥2小时，查阅相关文献/资料',
      'tags': ['毕业论文', '选题', '调研'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 40,
      'growthValue': 50,
      'happinessValue': 20
    },
    {
      'name': '科研项目参与',
      'category': TaskCategory.career,
      'frequency': TaskFrequency.weeklyAdvance,
      'difficulty': TaskDifficulty.hard,
      'duration': 180,
      'weight': 0.3,
      'description': '≥3小时，跟随导师做科研/课题',
      'tags': ['科研', '项目', '参与'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 45,
      'growthValue': 60,
      'happinessValue': 25
    },
    {
      'name': '专业论文撰写',
      'category': TaskCategory.career,
      'frequency': TaskFrequency.weeklyAdvance,
      'difficulty': TaskDifficulty.hard,
      'duration': 150,
      'weight': 0.3,
      'description': '≥800字，课程小论文/竞赛论文',
      'tags': ['论文', '撰写', '专业'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 38,
      'growthValue': 48,
      'happinessValue': 18
    },
    
    // 三、校园类
    // 每日基础任务
    {
      'name': '校园打卡',
      'category': TaskCategory.campus,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 10,
      'weight': 0.2,
      'description': '≥1处，教学楼/图书馆/操场/校园景点',
      'tags': ['校园', '打卡', '地点'],
      'benefitType': PetBenefitType.happiness,
      'benefitValue': 8,
      'growthValue': 10,
      'happinessValue': 12
    },
    {
      'name': '三餐规律打卡',
      'category': TaskCategory.campus,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 30,
      'weight': 0.2,
      'description': '按时吃早/中/晚餐，拒绝不吃早餐',
      'tags': ['三餐', '规律', '打卡'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 12,
      'growthValue': 15,
      'happinessValue': 10
    },
    {
      'name': '宿舍内务整理',
      'category': TaskCategory.campus,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 10,
      'weight': 0.2,
      'description': '≥10分钟，整理书桌/床铺/衣柜',
      'tags': ['宿舍', '内务', '整理'],
      'benefitType': PetBenefitType.happiness,
      'benefitValue': 9,
      'growthValue': 12,
      'happinessValue': 8
    },
    {
      'name': '校园运动打卡',
      'category': TaskCategory.campus,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.medium,
      'duration': 30,
      'weight': 0.2,
      'description': '≥30分钟，跑步/打球/跳绳/散步',
      'tags': ['运动', '校园', '打卡'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 14,
      'growthValue': 18,
      'happinessValue': 15
    },
    
    // 四、生活类
    // 每日基础任务
    {
      'name': '早起打卡',
      'category': TaskCategory.life,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.medium,
      'duration': 5,
      'weight': 0.25,
      'description': '≥7:30，无睡懒觉/熬夜补觉',
      'tags': ['早起', '打卡', '作息'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 15,
      'growthValue': 20,
      'happinessValue': 12
    },
    {
      'name': '早睡打卡',
      'category': TaskCategory.life,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.medium,
      'duration': 5,
      'weight': 0.25,
      'description': '≤23:30，无熬夜/刷手机拖延',
      'tags': ['早睡', '打卡', '作息'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 15,
      'growthValue': 20,
      'happinessValue': 12
    },
    {
      'name': '晨间拉伸',
      'category': TaskCategory.life,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 10,
      'weight': 0.25,
      'description': '≥10分钟，唤醒身体/缓解疲劳',
      'tags': ['晨间', '拉伸', '健康'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 10,
      'growthValue': 15,
      'happinessValue': 8
    },
    {
      'name': '午休打卡',
      'category': TaskCategory.life,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 20,
      'weight': 0.25,
      'description': '≥20分钟，不熬夜午休/过度午休',
      'tags': ['午休', '打卡', '健康'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 12,
      'growthValue': 16,
      'happinessValue': 10
    },
    
    // 五、成长进阶类
    // 每日提升任务
    {
      'name': '课外读物阅读',
      'category': TaskCategory.growth,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 20,
      'weight': 0.25,
      'description': '≥20分钟，文学/科普/历史/心理类',
      'tags': ['阅读', '课外', '提升'],
      'benefitType': PetBenefitType.happiness,
      'benefitValue': 12,
      'growthValue': 16,
      'happinessValue': 14
    },
    {
      'name': '技能学习打卡',
      'category': TaskCategory.growth,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.medium,
      'duration': 30,
      'weight': 0.25,
      'description': '≥30分钟，PS/PR/编程/办公软件/外语',
      'tags': ['技能', '学习', '打卡'],
      'benefitType': PetBenefitType.nutrition,
      'benefitValue': 16,
      'growthValue': 22,
      'happinessValue': 12
    },
    {
      'name': '每日复盘',
      'category': TaskCategory.growth,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 10,
      'weight': 0.25,
      'description': '≥10分钟，记录当日收获/不足',
      'tags': ['复盘', '每日', '记录'],
      'benefitType': PetBenefitType.happiness,
      'benefitValue': 11,
      'growthValue': 15,
      'happinessValue': 13
    },
    
    // 六、社交类
    {
      'name': '和家人视频/电话',
      'category': TaskCategory.social,
      'frequency': TaskFrequency.weeklyAdvance,
      'difficulty': TaskDifficulty.easy,
      'duration': 20,
      'weight': 0.2,
      'description': '≥1次，每周，聊聊校园生活',
      'tags': ['家人', '视频', '电话'],
      'benefitType': PetBenefitType.happiness,
      'benefitValue': 18,
      'growthValue': 22,
      'happinessValue': 20
    },
    {
      'name': '和同学/朋友线下交流',
      'category': TaskCategory.social,
      'frequency': TaskFrequency.weeklyAdvance,
      'difficulty': TaskDifficulty.easy,
      'duration': 60,
      'weight': 0.2,
      'description': '≥1次，每周，聚餐/散步/聊天',
      'tags': ['同学', '朋友', '线下交流'],
      'benefitType': PetBenefitType.happiness,
      'benefitValue': 20,
      'growthValue': 25,
      'happinessValue': 22
    },
    
    // 七、其他类
    // 每日放松任务
    {
      'name': '萌宠专属互动',
      'category': TaskCategory.other,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 10,
      'weight': 0.15,
      'description': '≥10分钟，喂食/玩耍/装扮，系统核心',
      'tags': ['萌宠', '互动', '放松'],
      'benefitType': PetBenefitType.happiness,
      'benefitValue': 15,
      'growthValue': 18,
      'happinessValue': 25
    },
    {
      'name': '短时放松',
      'category': TaskCategory.other,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 10,
      'weight': 0.15,
      'description': '≥10分钟，听音乐/看短视频/远眺',
      'tags': ['放松', '短时', '休息'],
      'benefitType': PetBenefitType.happiness,
      'benefitValue': 10,
      'growthValue': 12,
      'happinessValue': 18
    },
    {
      'name': '校园散步',
      'category': TaskCategory.other,
      'frequency': TaskFrequency.dailyBasic,
      'difficulty': TaskDifficulty.easy,
      'duration': 20,
      'weight': 0.15,
      'description': '≥20分钟，欣赏校园风景，放松心情',
      'tags': ['散步', '校园', '放松'],
      'benefitType': PetBenefitType.happiness,
      'benefitValue': 12,
      'growthValue': 15,
      'happinessValue': 20
    },
  ];

  // 生成单个任务
  TaskModel generateTask(Map<String, dynamic> taskTemplate, {DateTime? deadline}) {
    return TaskModel(
      name: taskTemplate['name'],
      category: taskTemplate['category'],
      frequency: taskTemplate['frequency'],
      difficulty: taskTemplate['difficulty'],
      deadline: deadline ?? DateTime.now().add(const Duration(days: 1)),
      benefitType: taskTemplate['benefitType'],
      benefitValue: taskTemplate['benefitValue'],
      growthValue: taskTemplate['growthValue'],
      happinessValue: taskTemplate['happinessValue'],
      duration: taskTemplate['duration'],
      weight: taskTemplate['weight'],
      description: taskTemplate['description'],
      tags: taskTemplate['tags'],
      isCompleted: false,
      createdAt: DateTime.now(),
    );
  }

  // 生成每日任务列表
  Future<List<TaskModel>> generateDailyTasks() async {
    final tasks = <TaskModel>[];
    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);

    // 获取用户能力评估
    final userAbilityManager = UserAbilityManager.instance;
    await userAbilityManager.initializeAbilityModel();
    final abilityModel = userAbilityManager.abilityModel;
    final overallAbility = abilityModel['overall_ability'] ?? 0.5;

    // 根据用户能力智能选择任务
    final filteredTasks = _filterTasksByUserState(overallAbility, 'normal');
    
    // 确保任务多样性：从不同分类中选择
    final categorizedTasks = _categorizeTasks(filteredTasks);
    
    // 智能任务选择
    // 1. 学习类（每日必选）
    if (categorizedTasks[TaskCategory.study] != null && categorizedTasks[TaskCategory.study]!.isNotEmpty) {
      final coreTasks = categorizedTasks[TaskCategory.study]!;
      final selectedCoreTask = coreTasks[_random.nextInt(coreTasks.length)];
      tasks.add(generateTask(selectedCoreTask, deadline: tomorrow));
    }

    // 2. 生活类（每日必选）
    if (categorizedTasks[TaskCategory.life] != null && categorizedTasks[TaskCategory.life]!.isNotEmpty) {
      final healthTasks = categorizedTasks[TaskCategory.life]!;
      final selectedHealthTask = healthTasks[_random.nextInt(healthTasks.length)];
      tasks.add(generateTask(selectedHealthTask, deadline: tomorrow));
    }

    // 3. 校园类（每日可选）
    if (categorizedTasks[TaskCategory.campus] != null && categorizedTasks[TaskCategory.campus]!.isNotEmpty) {
      final campusTasks = categorizedTasks[TaskCategory.campus]!;
      final selectedCampusTask = campusTasks[_random.nextInt(campusTasks.length)];
      tasks.add(generateTask(selectedCampusTask, deadline: tomorrow));
    }

    // 4. 成长进阶类（每日可选）
    if (categorizedTasks[TaskCategory.growth] != null && categorizedTasks[TaskCategory.growth]!.isNotEmpty) {
      final selfTasks = categorizedTasks[TaskCategory.growth]!;
      final selectedSelfTask = selfTasks[_random.nextInt(selfTasks.length)];
      tasks.add(generateTask(selectedSelfTask, deadline: tomorrow));
    }

    // 5. 其他类（每日可选）
    if (categorizedTasks[TaskCategory.other] != null && categorizedTasks[TaskCategory.other]!.isNotEmpty) {
      final leisureTasks = categorizedTasks[TaskCategory.other]!;
      final selectedLeisureTask = leisureTasks[_random.nextInt(leisureTasks.length)];
      tasks.add(generateTask(selectedLeisureTask, deadline: tomorrow));
    }

    // 6. 职业规划类（根据能力选择）
    if (overallAbility > 0.6 && categorizedTasks[TaskCategory.career] != null && categorizedTasks[TaskCategory.career]!.isNotEmpty) {
      final academicTasks = categorizedTasks[TaskCategory.career]!;
      final selectedAcademicTask = academicTasks[_random.nextInt(academicTasks.length)];
      tasks.add(generateTask(selectedAcademicTask, deadline: tomorrow));
    }

    // 7. 社交实践类（每周任务）
    if (today.weekday == 1 && categorizedTasks[TaskCategory.social] != null && categorizedTasks[TaskCategory.social]!.isNotEmpty) {
      final socialTasks = categorizedTasks[TaskCategory.social]!;
      final selectedSocialTask = socialTasks[_random.nextInt(socialTasks.length)];
      tasks.add(generateTask(selectedSocialTask, deadline: tomorrow.add(const Duration(days: 6))));
    }

    // 确保任务数量合理
    while (tasks.length < 5) {
      final randomTask = filteredTasks[_random.nextInt(filteredTasks.length)];
      if (!tasks.any((task) => task.name == randomTask['name'])) {
        tasks.add(generateTask(randomTask, deadline: tomorrow));
      }
    }

    // 打乱任务顺序
    tasks.shuffle(_random);
    return tasks;
  }

  // 根据用户状态筛选任务
  List<Map<String, dynamic>> _filterTasksByUserState(double abilityLevel, String mentalState) {
    final filteredTasks = <Map<String, dynamic>>[];

    for (final task in _collegeTaskBank) {
      // 根据心理状态调整任务
      if (mentalState == 'stressed' || mentalState == 'anxious') {
        // 压力大时减少困难任务，增加放松任务
        if (task['difficulty'] == TaskDifficulty.hard && task['category'] != TaskCategory.other) {
          continue;
        }
      }

      // 根据能力水平调整任务难度
      if (abilityLevel < 0.33 && task['difficulty'] == TaskDifficulty.hard) {
        continue;
      } else if (abilityLevel > 0.66 && task['difficulty'] == TaskDifficulty.easy && task['category'] == TaskCategory.study) {
        continue;
      }

      // 只选择每日基础任务和弹性选做任务
      if (task['frequency'] == TaskFrequency.dailyBasic || task['frequency'] == TaskFrequency.flexibleOptional) {
        filteredTasks.add(task);
      }

      // 每周一添加每周进阶任务
      final today = DateTime.now();
      if (today.weekday == 1 && task['frequency'] == TaskFrequency.weeklyAdvance) {
        filteredTasks.add(task);
      }
    }

    return filteredTasks;
  }

  // 按分类组织任务
  Map<TaskCategory, List<Map<String, dynamic>>> _categorizeTasks(List<Map<String, dynamic>> tasks) {
    final categorized = <TaskCategory, List<Map<String, dynamic>>>{};

    for (final task in tasks) {
      final category = task['category'];
      if (!categorized.containsKey(category)) {
        categorized[category] = [];
      }
      categorized[category]!.add(task);
    }

    return categorized;
  }

  // 检查是否需要生成新任务
  Future<bool> shouldGenerateNewTasks(List<TaskModel> existingTasks) async {
    // 如果没有任务，需要生成
    if (existingTasks.isEmpty) {
      return true;
    }

    // 获取今天的日期
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = DateTime(today.year, today.month, today.day + 1);

    // 检查是否有今天生成的任务
    final todayTasks = existingTasks.where((task) {
      final createdAt = task.createdAt ?? DateTime.now();
      return createdAt.isAfter(todayStart) && createdAt.isBefore(todayEnd);
    }).toList();

    // 如果今天的任务不足5个，需要生成
    return todayTasks.length < 5;
  }

  // 根据分类获取任务
  List<Map<String, dynamic>> getTasksByCategory(TaskCategory category) {
    return _collegeTaskBank.where((task) => task['category'] == category).toList();
  }

  // 根据难度获取任务
  List<Map<String, dynamic>> getTasksByDifficulty(TaskDifficulty difficulty) {
    return _collegeTaskBank.where((task) => task['difficulty'] == difficulty).toList();
  }

  // 根据频率获取任务
  List<Map<String, dynamic>> getTasksByFrequency(TaskFrequency frequency) {
    return _collegeTaskBank.where((task) => task['frequency'] == frequency).toList();
  }
}
