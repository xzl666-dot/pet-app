import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import '../models/study_task_model.dart';
import '../managers/auth_manager.dart';
import '../managers/user_ability_manager.dart';
import '../managers/task_generator.dart';
import '../managers/pet_growth_manager.dart';
import '../utils/token_util.dart';

enum FeedbackType {
  success,
  warning,
  error,
  info,
}

class LearningCenterPage extends StatefulWidget {
  const LearningCenterPage({Key? key}) : super(key: key);

  @override
  State<LearningCenterPage> createState() => _LearningCenterPageState();
}

class _LearningCenterPageState extends State<LearningCenterPage> {
  int _currentTab = 0;
  final _authManager = AuthManager.instance;
  final _userAbilityManager = UserAbilityManager.instance;
  final _taskGenerator = TaskGenerator.instance;
  final _petGrowthManager = PetGrowthManager();
  final _audioPlayer = AudioPlayer();
  
  // 学习任务相关
  List<StudyTaskModel> _tasks = [];
  List<StudyTaskModel> _recommendedTasks = [];
  bool _isTasksLoading = true;
  bool _isGeneratingTasks = false;
  int _selectedSubject = -1;
  int _selectedDifficulty = -1;
  
  // 评估计算相关
  bool _isEvaluationLoading = false;
  Map<String, dynamic>? _evaluationData;
  String _selectedTimeType = 'all';
  
  // 心流理论相关
  FlowState _currentFlowState = FlowState.medium;
  int _focusLevel = 50;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    await _userAbilityManager.initializeAbilityModel();
    await _loadTasks();
    await _loadEvaluationData();
    await _generateRecommendedTasks();
  }
  
  Future<void> _generateRecommendedTasks() async {
    setState(() => _isGeneratingTasks = true);
    
    try {
      final abilityModel = _userAbilityManager.abilityModel;
      final overallAbility = abilityModel['overall_ability'] ?? 0.5;
      
      // 根据用户能力生成推荐任务
      final recommendedTasks = await _taskGenerator.generateDailyTasks();
      
      // 为每个任务添加推荐理由和能力匹配分数
      final tasksWithRecommendations = recommendedTasks.map((task) {
        double matchScore;
        String reason;
        
        // 根据任务难度和用户能力计算匹配分数
        switch (task.difficulty) {
          case TaskDifficulty.easy:
            matchScore = overallAbility < 0.4 ? 0.9 : (overallAbility < 0.7 ? 0.7 : 0.5);
            reason = '适合当前能力水平的基础任务';
            break;
          case TaskDifficulty.medium:
            matchScore = overallAbility > 0.3 && overallAbility < 0.8 ? 0.9 : 0.6;
            reason = '略具挑战性，有助于能力提升';
            break;
          case TaskDifficulty.hard:
            matchScore = overallAbility > 0.6 ? 0.8 : 0.4;
            reason = '高难度任务，挑战自我极限';
            break;
          default:
            matchScore = 0.5;
            reason = '适合当前能力水平的任务';
            break;
        }
        
        return StudyTaskModel(
          id: task.id,
          name: task.name,
          description: '', // TaskModel中没有description属性，使用默认值
          subject: SubjectType.math, // 默认科目，实际应该根据任务类型匹配
          difficulty: TaskDifficulty.values[task.difficulty.index], // 转换类型
          deadline: task.deadline,
          benefitType: PetBenefitType.values[task.benefitType.index], // 转换类型
          benefitValue: task.benefitValue,
          isCompleted: task.isCompleted,
          createdAt: task.createdAt,
          completedAt: task.completedAt,
          recommendedReason: reason,
          abilityMatchScore: matchScore,
        );
      }).toList();
      
      // 按匹配分数排序
      tasksWithRecommendations.sort((a, b) => (b.abilityMatchScore ?? 0).compareTo(a.abilityMatchScore ?? 0));
      
      setState(() {
        _recommendedTasks = tasksWithRecommendations;
        _isGeneratingTasks = false;
      });
    } catch (e) {
      print('生成推荐任务失败: $e');
      setState(() => _isGeneratingTasks = false);
    }
  }
  
  // 任务拆分方法
  List<SubTask> _splitTaskIntoSubTasks(StudyTaskModel task) {
    final subTasks = <SubTask>[];
    
    switch (task.difficulty) {
      case TaskDifficulty.easy:
        subTasks.addAll([
          SubTask(name: '开始任务', stepNumber: 1, description: '准备好学习环境'),
          SubTask(name: '执行任务', stepNumber: 2, description: '按照计划完成任务'),
          SubTask(name: '完成任务', stepNumber: 3, description: '确认任务完成情况'),
        ]);
        break;
      case TaskDifficulty.medium:
        subTasks.addAll([
          SubTask(name: '任务规划', stepNumber: 1, description: '制定详细的执行计划'),
          SubTask(name: '第一阶段', stepNumber: 2, description: '完成任务的前半部分'),
          SubTask(name: '休息调整', stepNumber: 3, description: '短暂休息，恢复精力'),
          SubTask(name: '第二阶段', stepNumber: 4, description: '完成任务的后半部分'),
          SubTask(name: '任务总结', stepNumber: 5, description: '总结任务完成情况'),
        ]);
        break;
      case TaskDifficulty.hard:
        subTasks.addAll([
          SubTask(name: '任务分析', stepNumber: 1, description: '分析任务难点和关键点'),
          SubTask(name: '资源准备', stepNumber: 2, description: '准备所需的学习资源'),
          SubTask(name: '第一阶段', stepNumber: 3, description: '完成基础部分'),
          SubTask(name: '第二阶段', stepNumber: 4, description: '攻克核心难点'),
          SubTask(name: '第三阶段', stepNumber: 5, description: '完成剩余部分'),
          SubTask(name: '质量检查', stepNumber: 6, description: '检查任务完成质量'),
          SubTask(name: '经验总结', stepNumber: 7, description: '总结经验教训'),
        ]);
        break;
      default:
        subTasks.addAll([
          SubTask(name: '开始任务', stepNumber: 1, description: '准备好学习环境'),
          SubTask(name: '执行任务', stepNumber: 2, description: '按照计划完成任务'),
          SubTask(name: '完成任务', stepNumber: 3, description: '确认任务完成情况'),
        ]);
        break;
    }
    
    return subTasks;
  }
  
  // 多感官反馈方法
  Future<void> _provideMultiSensoryFeedback(FeedbackType type) async {
    // 视觉反馈
    _showVisualFeedback(type);
    
    // 听觉反馈
    await _playAudioFeedback(type);
    
    // 触觉反馈
    await _triggerHapticFeedback(type);
  }
  
  void _showVisualFeedback(FeedbackType type) {
    // 显示不同类型的视觉反馈
    final message = _getFeedbackMessage(type);
    final color = _getFeedbackColor(type);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _playAudioFeedback(FeedbackType type) async {
    // 这里应该播放不同类型的音频，现在仅做示例
    try {
      // 实际项目中应该使用真实的音频文件
      // await _audioPlayer.play(AssetSource('sounds/${_getFeedbackSound(type)}'));
    } catch (e) {
      print('播放音频失败: $e');
    }
  }
  
  Future<void> _triggerHapticFeedback(FeedbackType type) async {
    // 触发不同类型的触觉反馈
    // 注意：Web平台不支持振动，所以这里只在移动平台上尝试
    if (!kIsWeb) {
      // 在实际应用中，这里应该使用Flutter的HapticFeedback类
      // 或者在移动平台上使用vibration包
      // 但为了简化，我们暂时不实现具体的振动逻辑
      print('触发触觉反馈: $type');
    }
  }
  
  String _getFeedbackMessage(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return '任务完成！太棒了！';
      case FeedbackType.warning:
        return '注意：任务即将到期';
      case FeedbackType.error:
        return '任务失败，请重试';
      case FeedbackType.info:
        return '任务已更新';
    }
  }
  
  Color _getFeedbackColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Colors.green;
      case FeedbackType.warning:
        return Colors.orange;
      case FeedbackType.error:
        return Colors.red;
      case FeedbackType.info:
        return Colors.blue;
    }
  }
  
  String _getFeedbackSound(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return 'success.mp3';
      case FeedbackType.warning:
        return 'warning.mp3';
      case FeedbackType.error:
        return 'error.mp3';
      case FeedbackType.info:
        return 'info.mp3';
    }
  }
  
  // 心流状态调整方法
  void _adjustFlowState(FlowState newState) {
    setState(() {
      _currentFlowState = newState;
      
      // 根据心流状态调整专注度
      switch (newState) {
        case FlowState.low:
          _focusLevel = 30;
          break;
        case FlowState.medium:
          _focusLevel = 50;
          break;
        case FlowState.high:
          _focusLevel = 80;
          break;
        case FlowState.peak:
          _focusLevel = 100;
          break;
      }
    });
    
    // 提供心流状态反馈
    _provideMultiSensoryFeedback(FeedbackType.info);
  }
  
  // 质量评估方法
  Map<String, dynamic> _evaluateTaskQuality(StudyTaskModel task) {
    // 这里应该根据实际完成情况评估任务质量
    // 现在仅做示例实现
    final random = Random();
    
    return {
      'qualityScore': random.nextInt(31) + 70, // 70-100
      'accuracy': (random.nextDouble() * 30 + 70) / 100, // 0.7-1.0
      'efficiency': (random.nextDouble() * 30 + 70) / 100, // 0.7-1.0
      'completionTime': task.difficulty == TaskDifficulty.easy ? 15 : 
                        task.difficulty == TaskDifficulty.medium ? 30 : 45,
    };
  }
  
  // 更新任务进度
  void _updateTaskProgress(StudyTaskModel task, int step) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          currentStep: step,
        );
      }
    });
    
    // 提供进度反馈
    _provideMultiSensoryFeedback(FeedbackType.info);
  }
  
  // 完成子任务
  void _completeSubTask(StudyTaskModel task, int subTaskIndex) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        final updatedTask = _tasks[index];
        if (updatedTask.subTasks != null && updatedTask.subTasks!.length > subTaskIndex) {
          updatedTask.subTasks![subTaskIndex] = SubTask(
            name: updatedTask.subTasks![subTaskIndex].name,
            isCompleted: true,
            stepNumber: updatedTask.subTasks![subTaskIndex].stepNumber,
            description: updatedTask.subTasks![subTaskIndex].description,
          );
          
          // 检查是否所有子任务都已完成
          final allCompleted = updatedTask.subTasks!.every((st) => st.isCompleted);
          if (allCompleted) {
            _tasks[index] = updatedTask.copyWith(
              isCompleted: true,
              completedAt: DateTime.now(),
              currentStep: updatedTask.totalSteps,
            );
            
            // 评估任务质量
            final qualityData = _evaluateTaskQuality(updatedTask);
            _tasks[index] = _tasks[index].copyWith(
              qualityScore: qualityData['qualityScore'],
              accuracy: qualityData['accuracy'],
              efficiency: qualityData['efficiency'],
              completionTime: qualityData['completionTime'],
            );
            
            // 提供完成反馈
            _provideMultiSensoryFeedback(FeedbackType.success);
          } else {
            // 更新当前步骤
            final nextStep = updatedTask.subTasks!.where((st) => st.isCompleted).length + 1;
            _tasks[index] = updatedTask.copyWith(
              currentStep: nextStep,
            );
            
            // 提供步骤完成反馈
            _provideMultiSensoryFeedback(FeedbackType.info);
          }
        }
      }
    });
  }

  // 学习任务方法
  Future<void> _loadTasks() async {
    setState(() => _isTasksLoading = true);

    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      String url = 'http://localhost:3000/api/studyTask/list?userId=$userId';
      if (_selectedSubject != -1) {
        url += '&subject=$_selectedSubject';
      }
      if (_selectedDifficulty != -1) {
        url += '&difficulty=$_selectedDifficulty';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          setState(() {
            _tasks = (data['data']['taskList'] as List)
                .map((taskData) {
                  final task = StudyTaskModel.fromMap(taskData);
                  // 为每个任务生成子任务
                  if (task.subTasks == null || task.subTasks!.isEmpty) {
                    final subTasks = _splitTaskIntoSubTasks(task);
                    return task.copyWith(
                      subTasks: subTasks,
                      totalSteps: subTasks.length,
                      currentStep: 1,
                    );
                  }
                  return task;
                })
                .toList();
            _isTasksLoading = false;
          });
        }
      } else {
        // 模拟数据，当API调用失败时使用
        _generateMockTasks();
      }
    } catch (e) {
      print('加载学习任务失败: $e');
      // 生成模拟任务数据
      _generateMockTasks();
    }
  }
  
  // 生成模拟任务数据
  void _generateMockTasks() {
    final mockTasks = <StudyTaskModel>[];
    final now = DateTime.now();
    
    // 生成不同难度的任务
    for (int i = 0; i < 3; i++) {
      final difficulty = TaskDifficulty.values[i];
      final subTasks = _splitTaskIntoSubTasks(StudyTaskModel(
        name: '任务 $i',
        subject: SubjectType.math,
        difficulty: difficulty,
        deadline: now.add(Duration(days: 1)),
        benefitType: PetBenefitType.happiness,
        benefitValue: 10,
      ));
      
      mockTasks.add(StudyTaskModel(
        id: i + 1,
        name: '${difficulty.getDifficultyName()}任务 ${i + 1}',
        description: '这是一个${difficulty.getDifficultyName()}难度的学习任务',
        subject: SubjectType.values[i % SubjectType.values.length],
        difficulty: difficulty,
        deadline: now.add(Duration(days: 1)),
        benefitType: PetBenefitType.values[i % PetBenefitType.values.length],
        benefitValue: difficulty.getExpReward(),
        isCompleted: false,
        createdAt: now,
        subTasks: subTasks,
        totalSteps: subTasks.length,
        currentStep: 1,
        recommendedReason: '根据您的能力水平推荐',
        abilityMatchScore: 0.8,
      ));
    }
    
    setState(() {
      _tasks = mockTasks;
      _isTasksLoading = false;
    });
  }

  Future<void> _completeTask(StudyTaskModel task) async {
    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      // 评估任务质量
      final qualityData = _evaluateTaskQuality(task);

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/studyTask/complete'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'taskId': task.id,
          'qualityScore': qualityData['qualityScore'],
          'completionTime': qualityData['completionTime'],
          'accuracy': qualityData['accuracy'],
          'efficiency': qualityData['efficiency'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          setState(() {
            final index = _tasks.indexWhere((t) => t.id == task.id);
            if (index != -1) {
              _tasks[index] = task.copyWith(
                isCompleted: true,
                completedAt: DateTime.now(),
                qualityScore: qualityData['qualityScore'],
                completionTime: qualityData['completionTime'],
                accuracy: qualityData['accuracy'],
                efficiency: qualityData['efficiency'],
                currentStep: task.totalSteps,
              );
            }
          });

          // 提供多感官反馈
          await _provideMultiSensoryFeedback(FeedbackType.success);

          // 获取基础经验值
          final baseExpGain = data['data']['expReward'] ?? task.difficulty.getExpReward();
          
          // 根据营养值调整经验值
          final pet = await _petGrowthManager.getCurrentPet();
          int expGain = baseExpGain;
          if (pet != null) {
            if (pet.nutrition >= 80) {
              // 营养值≥80时，经验+10%
              expGain = (baseExpGain * 1.1).round();
            } else if (pet.nutrition < 30) {
              // 营养值＜30时，经验-10%
              expGain = (baseExpGain * 0.9).round();
            } else if (pet.nutrition <= 0) {
              // 营养值≤0时，无法获取经验
              expGain = 0;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('宠物营养不足，无法获得经验值'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
          
          // 更新经验值
          await _petGrowthManager.updatePetExp(expGain);
          
          // 检查连续完成任务天数
          await _checkConsecutiveTaskCompletion();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('任务完成！获得 ${expGain} 经验值'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // 模拟完成任务
        await _simulateTaskCompletion(task, qualityData);
      }
    } catch (e) {
      print('完成任务失败: $e');
      // 模拟完成任务
      final qualityData = _evaluateTaskQuality(task);
      await _simulateTaskCompletion(task, qualityData);
    }
  }
  
  // 检查连续完成任务天数
  Future<void> _checkConsecutiveTaskCompletion() async {
    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      // 这里应该从后端获取连续完成任务的天数
      // 暂时模拟连续7天完成任务的情况
      final consecutiveDays = 7;
      if (consecutiveDays >= 7) {
        // 连续7天完成任务，奖励20亲密度
        await _updatePetIntimacy(20);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('连续7天完成任务，获得20亲密度！'),
              backgroundColor: Colors.purple,
            ),
          );
        }
      }
    } catch (e) {
      print('检查连续任务完成失败: $e');
    }
  }

  // 更新宠物亲密度
  Future<void> _updatePetIntimacy(int intimacyGain) async {
    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/pet/updateStatus'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'petId': 1, // 暂时使用固定petId
          'intimacy': intimacyGain, // 后端应该累加而不是覆盖
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          print('亲密度更新成功');
        }
      }
    } catch (e) {
      print('更新亲密度失败: $e');
    }
  }

  // 模拟任务完成
  Future<void> _simulateTaskCompletion(StudyTaskModel task, Map<String, dynamic> qualityData) async {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
          qualityScore: qualityData['qualityScore'],
          completionTime: qualityData['completionTime'],
          accuracy: qualityData['accuracy'],
          efficiency: qualityData['efficiency'],
          currentStep: task.totalSteps,
        );
      }
    });

    // 提供多感官反馈
    await _provideMultiSensoryFeedback(FeedbackType.success);

    // 获取经验值
    final expGain = task.difficulty.getExpReward();
    await _petGrowthManager.updatePetExp(expGain);

    // 检查连续完成任务天数
    await _checkConsecutiveTaskCompletion();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('任务完成！获得 ${expGain} 经验值'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateTaskDialog(),
    ).then((result) {
      if (result == true) {
        _loadTasks();
      }
    });
  }

  // 评估计算方法
  Future<void> _loadEvaluationData() async {
    setState(() => _isEvaluationLoading = true);

    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      String url = 'http://localhost:3000/api/evaluationCalc/query?userId=$userId&petId=1';
      if (_selectedTimeType != 'all') {
        url += '&timeType=$_selectedTimeType';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          setState(() {
            _evaluationData = data['data'];
            _isEvaluationLoading = false;
          });
        }
      }
    } catch (e) {
      print('加载评估数据失败: $e');
      setState(() => _isEvaluationLoading = false);
    }
  }

  Future<void> _calculateEvaluation() async {
    setState(() => _isEvaluationLoading = true);

    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/evaluationCalc/calculate'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'petId': 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          setState(() {
            _evaluationData = data['data'];
            _isEvaluationLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('评估完成！等级：${data['data']['level']}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('计算评估失败: $e');
      setState(() => _isEvaluationLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('计算评估失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习中心'),
        actions: [
          if (_currentTab == 0)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateTaskDialog,
              tooltip: '创建任务',
            ),
          if (_currentTab == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _calculateEvaluation,
              tooltip: '重新计算',
            ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        initialIndex: _currentTab,
        child: Column(
          children: [
            TabBar(
              onTap: (index) {
                setState(() {
                  _currentTab = index;
                });
              },
              tabs: const [
                Tab(text: '学习任务'),
                Tab(text: '能力评估'),
              ],
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildTasksTab(),
                  _buildEvaluationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    return Column(
      children: [
        _buildSubjectFilter(),
        _buildDifficultyFilter(),
        Expanded(
          child: _isTasksLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 推荐任务部分
                      if (_recommendedTasks.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '推荐任务',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (_isGeneratingTasks)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(),
                                  ),
                                if (!_isGeneratingTasks)
                                  TextButton(
                                    onPressed: _generateRecommendedTasks,
                                    child: const Text('刷新推荐'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._recommendedTasks.take(3).map((task) => _buildTaskCard(task)),
                            const SizedBox(height: 24),
                          ],
                        ),
                      
                      // 所有任务部分
                      const Text(
                        '所有任务',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_tasks.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text('暂无学习任务'),
                          ),
                        )
                      else
                        ..._tasks.map((task) => _buildTaskCard(task)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSubjectFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: SubjectType.values.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterChip('全部', -1 == _selectedSubject, () {
              setState(() {
                _selectedSubject = -1;
              });
              _loadTasks();
            });
          }
          final subject = SubjectType.values[index - 1];
          return _buildFilterChip(
            subject.getSubjectIcon() + ' ' + subject.getSubjectName(),
            subject.index == _selectedSubject,
            () {
              setState(() {
                _selectedSubject = subject.index;
              });
              _loadTasks();
            },
          );
        },
      ),
    );
  }

  Widget _buildDifficultyFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: TaskDifficulty.values.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterChip('全部难度', -1 == _selectedDifficulty, () {
              setState(() {
                _selectedDifficulty = -1;
              });
              _loadTasks();
            });
          }
          final difficulty = TaskDifficulty.values[index - 1];
          return _buildFilterChip(
            difficulty.getDifficultyName(),
            difficulty.index == _selectedDifficulty,
            () {
              setState(() {
                _selectedDifficulty = difficulty.index;
              });
              _loadTasks();
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.blue.withOpacity(0.2),
        checkmarkColor: Colors.blue,
      ),
    );
  }

  Widget _buildTaskCard(StudyTaskModel task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务头部信息
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.subject.getSubjectColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        task.subject.getSubjectIcon(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.subject.getSubjectName(),
                        style: TextStyle(
                          color: task.subject.getSubjectColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(task.difficulty).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.difficulty.getDifficultyName(),
                    style: TextStyle(
                      color: _getDifficultyColor(task.difficulty),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            // 推荐理由
            if (task.recommendedReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        task.recommendedReason!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // 任务名称
            const SizedBox(height: 12),
            Text(
              task.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // 任务描述
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            
            // 任务进度条
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: task.progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(task.isCompleted ? Colors.green : Colors.blue),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '进度: ${(task.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  '步骤: ${task.currentStep}/${task.totalSteps}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            // 任务详情
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '截止: ${DateFormat('yyyy-MM-dd').format(task.deadline)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.redeem, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '奖励: ${task.benefitValue} ${task.benefitType.toString().split('.').last}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            // 任务质量评估（仅当任务已完成时显示）
            if (task.isCompleted && task.qualityScore != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '任务评估',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildQualityMetric('质量分数', '${task.qualityScore}', Colors.green),
                          const SizedBox(width: 16),
                          _buildQualityMetric('准确率', '${(task.accuracy! * 100).toStringAsFixed(0)}%', Colors.blue),
                          const SizedBox(width: 16),
                          _buildQualityMetric('效率', '${(task.efficiency! * 100).toStringAsFixed(0)}%', Colors.orange),
                        ],
                      ),
                      if (task.completionTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '完成时间: ${task.completionTime} 分钟',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            
            // 任务操作按钮
            const SizedBox(height: 16),
            Row(
              children: [
                // 查看详情按钮
                OutlinedButton(
                  onPressed: () => _showTaskDetailDialog(task),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  child: const Text('查看详情'),
                ),
                const Spacer(),
                // 完成按钮
                if (!task.isCompleted)
                  ElevatedButton(
                    onPressed: () => _completeTask(task),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('完成任务'),
                  )
                else
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 32,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建质量评估指标
  Widget _buildQualityMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  // 显示任务详情对话框
  void _showTaskDetailDialog(StudyTaskModel task) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 任务标题
                Text(
                  task.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // 任务基本信息
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.subject.getSubjectColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.subject.getSubjectName(),
                        style: TextStyle(
                          color: task.subject.getSubjectColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(task.difficulty).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.difficulty.getDifficultyName(),
                        style: TextStyle(
                          color: _getDifficultyColor(task.difficulty),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // 任务描述
                if (task.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                
                // 任务进度
                const SizedBox(height: 16),
                Text(
                  '任务进度',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: task.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(task.isCompleted ? Colors.green : Colors.blue),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(task.progress * 100).toStringAsFixed(0)}% 完成',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                
                // 子任务列表
                if (task.subTasks != null && task.subTasks!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '子任务',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...task.subTasks!.map((subTask) => CheckboxListTile(
                          title: Text(subTask.name),
                          subtitle: subTask.description != null ? Text(subTask.description!) : null,
                          value: subTask.isCompleted,
                          onChanged: task.isCompleted ? null : (value) {
                            final subTaskIndex = task.subTasks!.indexOf(subTask);
                            _completeSubTask(task, subTaskIndex);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        )),
                      ],
                    ),
                  ),
                
                // 任务其他信息
                const SizedBox(height: 16),
                Text(
                  '任务信息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '截止: ${DateFormat('yyyy-MM-dd HH:mm').format(task.deadline)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.redeem, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '奖励: ${task.benefitValue} ${task.benefitType.toString().split('.').last}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (task.abilityMatchScore != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_esports, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '能力匹配: ${(task.abilityMatchScore! * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // 关闭按钮
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationTab() {
    return _isEvaluationLoading
        ? const Center(child: CircularProgressIndicator())
        : _evaluationData == null
            ? const Center(child: Text('暂无评估数据'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeFilter(),
                    const SizedBox(height: 20),
                    _buildEvaluationSummary(),
                    const SizedBox(height: 20),
                    _buildStatisticsCards(),
                    const SizedBox(height: 20),
                    _buildEvaluationDetails(),
                  ],
                ),
              );
  }

  Widget _buildTimeFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          final types = ['all', 'today', 'week', 'month'];
          final labels = ['全部', '今日', '本周', '本月'];
          final isSelected = types[index] == _selectedTimeType;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[index]),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedTimeType = types[index];
                });
                _loadEvaluationData();
              },
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEvaluationSummary() {
    final data = _evaluationData!;
    final level = data['level'] ?? 'D';
    final totalScore = data['totalScore'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getLevelIcon(level),
                  size: 80,
                  color: _getLevelColor(level),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前评估等级',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      level,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getLevelColor(level),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '总分: $totalScore',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final stats = _evaluationData!['statistics'] ?? {};
    return Column(
      children: [
        _buildStatCard(
          '准确率',
          '${stats['averageAccuracy']?.toStringAsFixed(1) ?? 0}%',
          Icons.check_circle,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          '完成效率',
          '${stats['averageEfficiency']?.toStringAsFixed(1) ?? 0}%',
          Icons.speed,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          '质量分数',
          '${stats['averageQualityScore'] ?? 0}分',
          Icons.star,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          '完成任务',
          '${stats['totalTasks'] ?? 0}个',
          Icons.task_alt,
          Colors.purple,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          '高质量任务',
          '${stats['highQualityTasks'] ?? 0}个',
          Icons.workspace_premium,
          Colors.amber,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          '高质量率',
          '${stats['highQualityRate'] ?? 0}%',
          Icons.trending_up,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationDetails() {
    final calcDataList = _evaluationData!['calcDataList'] as List? ?? [];
    if (calcDataList.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('暂无详细数据')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '评估历史',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...calcDataList.map((data) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(
                                DateTime.parse(data['evaluationDate']),
                              ),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              '总分: ${data['totalScore']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildDetailItem('准确率', '${data['accuracy']}%', Colors.green),
                            const SizedBox(width: 16),
                            _buildDetailItem('效率', '${data['completionEfficiency']}%', Colors.blue),
                            const SizedBox(width: 16),
                            _buildDetailItem('质量', '${data['qualityScore']}分', Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getDifficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'S':
        return Icons.workspace_premium;
      case 'A':
        return Icons.star;
      case 'B':
        return Icons.star_half;
      case 'C':
        return Icons.star_border;
      case 'D':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.help;
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'S':
        return Colors.purple;
      case 'A':
        return Colors.blue;
      case 'B':
        return Colors.green;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class CreateTaskDialog extends StatefulWidget {
  const CreateTaskDialog({Key? key}) : super(key: key);

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  SubjectType _selectedSubject = SubjectType.math;
  TaskDifficulty _selectedDifficulty = TaskDifficulty.easy;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authManager = AuthManager.instance;
      final user = authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/studyTask/create'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'name': _nameController.text,
          'description': _descriptionController.text,
          'subject': _selectedSubject.index,
          'difficulty': _selectedDifficulty.index,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('任务创建成功'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('创建任务失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建任务失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建学习任务'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '任务名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入任务名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '任务描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SubjectType>(
                value: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: '科目',
                  border: OutlineInputBorder(),
                ),
                items: SubjectType.values.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Row(
                      children: [
                        Text(subject.getSubjectIcon()),
                        const SizedBox(width: 8),
                        Text(subject.getSubjectName()),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubject = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskDifficulty>(
                value: _selectedDifficulty,
                decoration: const InputDecoration(
                  labelText: '难度',
                  border: OutlineInputBorder(),
                ),
                items: TaskDifficulty.values.map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(difficulty.getDifficultyName()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _createTask,
          child: const Text('创建'),
        ),
      ],
    );
  }
}
