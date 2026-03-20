import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../managers/user_ability_manager.dart';

class AbilityAssessmentPage extends StatefulWidget {
  const AbilityAssessmentPage({Key? key}) : super(key: key);

  @override
  State<AbilityAssessmentPage> createState() => _AbilityAssessmentPageState();
}

class _AbilityAssessmentPageState extends State<AbilityAssessmentPage> {
  bool _isLoading = true;
  Map<String, dynamic> _abilityModel = {};
  String _abilityRating = '';
  List<String> _improvementSuggestions = [];
  String _recommendedDifficulty = '';
  List<LevelMatchTask> _levelMatchTasks = [];
  AbilityAssessmentReport? _latestReport;

  @override
  void initState() {
    super.initState();
    _loadAbilityAssessment();
  }

  Future<void> _loadAbilityAssessment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userAbilityManager = UserAbilityManager.instance;
      await userAbilityManager.initializeAbilityModel();

      setState(() {
        _abilityModel = userAbilityManager.abilityModel;
        _abilityRating = userAbilityManager.getAbilityRating();
        _improvementSuggestions = userAbilityManager.getAbilityImprovementSuggestions();
        _levelMatchTasks = userAbilityManager.getLevelMatchTasks();
        _latestReport = userAbilityManager.getLatestAssessmentReport();
        
        // 获取推荐的任务难度
        final recommendedDifficulty = userAbilityManager.recommendTaskDifficulty();
        switch (recommendedDifficulty) {
          case TaskDifficulty.easy:
            _recommendedDifficulty = '简单';
            break;
          case TaskDifficulty.medium:
            _recommendedDifficulty = '中等';
            break;
          case TaskDifficulty.hard:
            _recommendedDifficulty = '困难';
            break;
        }
      });
    } catch (e) {
      print('加载能力评估失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeLevelMatchTask(String taskId) async {
    // 模拟完成定级赛任务，实际项目中应根据用户完成情况计算得分
    final userAbilityManager = UserAbilityManager.instance;
    await userAbilityManager.completeLevelMatchTask(taskId, 80); // 假设得分80
    await _loadAbilityAssessment();
    
    // 显示完成成功的提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('定级赛任务完成！能力评估已更新。'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('能力评估'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 综合能力评级
                  _buildOverallAbilityCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 能力维度分析
                  const SectionTitle('能力维度分析'),
                  _buildAbilityDimensionCard('完成能力', 'completion_ability'),
                  _buildAbilityDimensionCard('效果质量', 'effect_quality'),
                  _buildAbilityDimensionCard('效率水平', 'efficiency_level'),
                  _buildAbilityDimensionCard('坚持程度', 'persistence_level'),
                  
                  const SizedBox(height: 24),
                  
                  // 主动定级赛
                  const SectionTitle('主动定级赛'),
                  _buildLevelMatchTasksCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 被动评估报告
                  if (_latestReport != null)
                    ...[
                      const SectionTitle('最新评估报告'),
                      _buildAssessmentReportCard(),
                      const SizedBox(height: 24),
                    ],
                  
                  // 推荐任务难度
                  _buildRecommendationCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 能力提升建议
                  _buildSuggestionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallAbilityCard() {
    final overallAbility = _abilityModel['overall_ability'] ?? 0.0;
    final overallPercentage = (overallAbility * 100).toInt();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '综合能力评级',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // 能力值显示
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: overallAbility,
                    strokeWidth: 15,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getAbilityColor(overallAbility),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$overallPercentage%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _abilityRating,
                      style: TextStyle(
                        fontSize: 16,
                        color: _getAbilityColor(overallAbility),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Text(
              '基于您的历史任务完成情况分析',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbilityDimensionCard(String title, String key) {
    final value = _abilityModel[key] ?? 0.0;
    final percentage = (value * 100).toInt();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getAbilityColor(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getAbilityColor(value),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getDimensionDescription(title, value),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '推荐任务难度',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                _recommendedDifficulty,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '根据您的能力水平，我们推荐您挑战这个难度的任务，以获得最佳的心流体验。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '能力提升建议',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._improvementSuggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelMatchTasksCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '定级赛任务',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '完成以下任务可以快速提升能力等级，获得更准确的能力评估',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ..._levelMatchTasks.take(5).map((task) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: task.isCompleted ? Colors.green : Theme.of(context).primaryColor,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: task.isCompleted ? Colors.green.withOpacity(0.05) : Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            task.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (task.isCompleted)
                            const Chip(
                              label: Text('已完成'),
                              labelStyle: TextStyle(fontSize: 12, color: Colors.green),
                              backgroundColor: Colors.greenAccent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '难度: ${_getDifficultyText(task.difficulty)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (!task.isCompleted)
                            ElevatedButton(
                              onPressed: () => _completeLevelMatchTask(task.id),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('完成任务'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (_levelMatchTasks.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '还有 ${_levelMatchTasks.length - 5} 个任务未显示',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentReportCard() {
    if (_latestReport == null) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '评估报告',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_latestReport!.generatedAt.month}月${_latestReport!.generatedAt.day}日',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 等级变化
            Row(
              children: [
                const Text('等级变化: '),
                Text(
                  _latestReport!.levelChange,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _latestReport!.levelChange == '等级提升' ? Colors.green : 
                           _latestReport!.levelChange == '等级下降' ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 改进领域
            if (_latestReport!.improvementAreas.isNotEmpty)
              ...[
                const Text(
                  '需要改进的领域:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _latestReport!.improvementAreas.map((area) {
                    return Chip(
                      label: Text(area),
                      labelStyle: TextStyle(fontSize: 12, color: Colors.orange),
                      backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            
            // 成就领域
            if (_latestReport!.achievementAreas.isNotEmpty)
              ...[
                const Text(
                  '表现优秀的领域:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _latestReport!.achievementAreas.map((area) {
                    return Chip(
                      label: Text(area),
                      labelStyle: TextStyle(fontSize: 12, color: Colors.green),
                      backgroundColor: Colors.greenAccent.withOpacity(0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            
            // 个性化建议
            if (_latestReport!.personalizedSuggestions.isNotEmpty)
              ...[
                const Text(
                  '个性化建议:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ..._latestReport!.personalizedSuggestions.take(3).map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.arrow_right,
                          color: Colors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
          ],
        ),
      ),
    );
  }

  String _getDifficultyText(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return '简单';
      case TaskDifficulty.medium:
        return '中等';
      case TaskDifficulty.hard:
        return '困难';
      default:
        return '未知';
    }
  }

  Color _getAbilityColor(double value) {
    if (value >= 0.8) {
      return Colors.green;
    } else if (value >= 0.6) {
      return Colors.blue;
    } else if (value >= 0.4) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getDimensionDescription(String title, double value) {
    if (value >= 0.8) {
      return '表现优秀，继续保持';
    } else if (value >= 0.6) {
      return '表现良好，有提升空间';
    } else if (value >= 0.4) {
      return '表现中等，需要加强';
    } else {
      return '表现较弱，需要重点提升';
    }
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
}
