import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../managers/data_statistics_manager.dart';
import '../managers/user_ability_manager.dart';
import '../managers/social_challenge_manager.dart';
import '../managers/pet_manager.dart';


class DataStatisticsPage extends StatefulWidget {
  const DataStatisticsPage({Key? key}) : super(key: key);

  @override
  State<DataStatisticsPage> createState() => _DataStatisticsPageState();
}

class _DataStatisticsPageState extends State<DataStatisticsPage> {
  final DataStatisticsManager _statsManager = DataStatisticsManager.instance;
  final UserAbilityManager _abilityManager = UserAbilityManager.instance;
  final SocialChallengeManager _socialManager = SocialChallengeManager.instance;
  final PetManager _petManager = PetManager.instance;
  
  bool _isLoading = true;
  Map<String, dynamic> _fourDimensionalData = {};
  List<Map<String, dynamic>> _weeklyData = [];
  Map<String, dynamic> _dataInsights = {};
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 初始化必要的管理器
      await _abilityManager.initializeAbilityModel();
      await _petManager.initializePet();
      
      // 加载四维数据
      final fourDimensionalData = await _generateFourDimensionalData();
      
      // 加载周数据
      final weeklyData = await _generateWeeklyData();
      
      // 生成数据洞察
      final dataInsights = _generateDataInsights(fourDimensionalData, weeklyData);
      
      setState(() {
        _fourDimensionalData = fourDimensionalData;
        _weeklyData = weeklyData;
        _dataInsights = dataInsights;
      });
    } catch (e) {
      print('加载数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 生成四维数据
  Future<Map<String, dynamic>> _generateFourDimensionalData() async {
    // 1. 任务维度
    final tasks = await _abilityManager.getTaskHistory();
    final completedTasks = tasks.where((task) => task['is_completed']).length;
    final taskCompletionRate = tasks.isNotEmpty ? completedTasks / tasks.length : 0.0;
    
    // 2. 宠物维度
    final pet = await _petManager.getPet();
    final petGrowthProgress = pet.exp / (_petManager.getRequiredExperience(pet.level + 1) + pet.exp);
    
    // 3. 社交维度
    final friends = await _socialManager.getFriendList();
    final activeFriends = friends.where((friend) => friend.isOnline).length;
    final friendActivityRate = friends.isNotEmpty ? activeFriends / friends.length : 0.0;
    
    final competitions = await _socialManager.getActiveCompetitions();
    final competitionCount = competitions.length;
    
    // 4. 心理维度
    final mentalState = 'normal';
    final stateSeverity = 1;
    
    final mentalHealthScore = 1.0 - (stateSeverity / 4.0);
    
    return {
      'task': {
        'completion_rate': taskCompletionRate,
        'total_tasks': tasks.length,
        'completed_tasks': completedTasks,
      },
      'pet': {
        'growth_progress': petGrowthProgress,
        'level': pet.level,
        'happiness': pet.happiness / 100.0,
      },
      'social': {
        'friend_activity_rate': friendActivityRate,
        'total_friends': friends.length,
        'active_friends': activeFriends,
        'competition_count': competitionCount,
      },
      'mental': {
        'health_score': mentalHealthScore,
        'current_state': mentalState,
      },
    };
  }
  
  // 生成周数据
  Future<List<Map<String, dynamic>>> _generateWeeklyData() async {
    final weeklyData = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.month}/${date.day}';
      
      // 模拟每日数据（实际项目中应从数据库获取）
      final taskScore = (0.5 + (i % 3) * 0.1).clamp(0.0, 1.0);
      final petScore = (0.4 + (i % 4) * 0.15).clamp(0.0, 1.0);
      final socialScore = (0.3 + (i % 5) * 0.12).clamp(0.0, 1.0);
      final mentalScore = (0.6 + (i % 3) * 0.08).clamp(0.0, 1.0);
      
      weeklyData.add({
        'date': dateStr,
        'task_score': taskScore,
        'pet_score': petScore,
        'social_score': socialScore,
        'mental_score': mentalScore,
        'total_score': (taskScore + petScore + socialScore + mentalScore) / 4,
      });
    }
    
    return weeklyData;
  }
  
  // 生成数据洞察
  Map<String, dynamic> _generateDataInsights(
      Map<String, dynamic> fourDimensionalData,
      List<Map<String, dynamic>> weeklyData) {
    final insights = {
      'strengths': <String>[],
      'weaknesses': <String>[],
      'recommendations': <String>[],
      'trends': <String>[],
    };
    
    // 分析优势
    final taskScore = fourDimensionalData['task']['completion_rate'] ?? 0.0;
    final petScore = ((fourDimensionalData['pet']['growth_progress'] ?? 0.0) + (fourDimensionalData['pet']['happiness'] ?? 0.0)) / 2;
    final socialScore = fourDimensionalData['social']['friend_activity_rate'] ?? 0.0;
    final mentalScore = fourDimensionalData['mental']['health_score'] ?? 0.0;
    
    if (taskScore > 0.7) {
      (insights['strengths'] as List<String>).add('任务完成率高，学习态度积极');
    }
    
    if (petScore > 0.7) {
      (insights['strengths'] as List<String>).add('宠物成长良好，照顾用心');
    }
    
    if (socialScore > 0.5) {
      (insights['strengths'] as List<String>).add('社交活跃，朋友互动频繁');
    }
    
    if (mentalScore > 0.7) {
      (insights['strengths'] as List<String>).add('心理状态良好，情绪稳定');
    }
    
    // 分析劣势
    if (taskScore < 0.4) {
      (insights['weaknesses'] as List<String>).add('任务完成率较低，需要提高学习效率');
      (insights['recommendations'] as List<String>).add('建议制定合理的学习计划，分解任务目标');
    }
    
    if (petScore < 0.4) {
      (insights['weaknesses'] as List<String>).add('宠物成长缓慢，需要增加互动');
      (insights['recommendations'] as List<String>).add('建议每天花时间与宠物互动，完成宠物相关任务');
    }
    
    if (socialScore < 0.3) {
      (insights['weaknesses'] as List<String>).add('社交活跃度低，朋友互动较少');
      (insights['recommendations'] as List<String>).add('建议主动添加朋友，参与社交竞赛活动');
    }
    
    if (mentalScore < 0.4) {
      (insights['weaknesses'] as List<String>).add('心理状态不佳，需要调整');
      (insights['recommendations'] as List<String>).add('建议使用AI心理助手，适当休息放松');
    }
    
    // 分析趋势
    if (weeklyData.length >= 7) {
      final firstTotalScore = weeklyData[0]['total_score'] ?? 0.0;
      final lastTotalScore = weeklyData[6]['total_score'] ?? 0.0;
      
      if (lastTotalScore > firstTotalScore + 0.1) {
        (insights['trends'] as List<String>).add('整体状态呈上升趋势，继续保持');
      } else if (lastTotalScore < firstTotalScore - 0.1) {
        (insights['trends'] as List<String>).add('整体状态呈下降趋势，需要关注');
      } else {
        (insights['trends'] as List<String>).add('整体状态稳定，建议寻求突破');
      }
    }
    
    return insights;
  }
  
  // 构建四维数据雷达图
  Widget _buildFourDimensionalChart() {
    final taskValue = _fourDimensionalData['task']['completion_rate'] ?? 0.0;
    final petValue = ((_fourDimensionalData['pet']['growth_progress'] ?? 0.0) + (_fourDimensionalData['pet']['happiness'] ?? 0.0)) / 2;
    final socialValue = _fourDimensionalData['social']['friend_activity_rate'] ?? 0.0;
    final mentalValue = _fourDimensionalData['mental']['health_score'] ?? 0.0;

    final radarData = RadarChartData(
      radarBackgroundColor: Colors.transparent,
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      radarBorderData: const BorderSide(color: Colors.blue, width: 2),
      dataSets: [
        RadarDataSet(
          fillColor: Colors.blue.withOpacity(0.2),
          borderColor: Colors.blue,
          borderWidth: 2,
          dataEntries: [
            RadarEntry(value: taskValue),
            RadarEntry(value: petValue),
            RadarEntry(value: socialValue),
            RadarEntry(value: mentalValue),
          ],
        ),
      ],
      gridBorderData: const BorderSide(color: Colors.grey, width: 1),
    );
    
    return Container(
      height: 300,
      child: RadarChart(radarData),
    );
  }
  
  // 构建周数据趋势图
  Widget _buildWeeklyTrendChart() {
    final lineBarsData = [
      LineChartBarData(
        spots: _weeklyData.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value['total_score'] as double);
        }).toList(),
        isCurved: true,
        color: Colors.blue,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue.withOpacity(0.1),
        ),
      ),
    ];

    final lineChartData = LineChartData(
      lineBarsData: lineBarsData,
      minX: 0,
      maxX: (_weeklyData.length - 1).toDouble(),
      minY: 0,
      maxY: 1,
      gridData: const FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: true,
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < _weeklyData.length) {
                return Text(_weeklyData[value.toInt()]['date'] as String, style: const TextStyle(fontSize: 10));
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10));
            },
          ),
        ),
      ),
    );
    
    return Container(
      height: 250,
      child: LineChart(lineChartData),
    );
  }
  
  // 构建数据洞察卡片
  Widget _buildDataInsightsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '数据洞察',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 优势
            if (_dataInsights['strengths']?.isNotEmpty ?? false)
              _buildInsightSection('优势', _dataInsights['strengths']),
            
            // 劣势
            if (_dataInsights['weaknesses']?.isNotEmpty ?? false)
              _buildInsightSection('需要改进', _dataInsights['weaknesses']),
            
            // 建议
            if (_dataInsights['recommendations']?.isNotEmpty ?? false)
              _buildInsightSection('建议', _dataInsights['recommendations']),
            
            // 趋势
            if (_dataInsights['trends']?.isNotEmpty ?? false)
              _buildInsightSection('趋势', _dataInsights['trends']),
          ],
        ),
      ),
    );
  }
  
  // 构建洞察部分
  Widget _buildInsightSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 12),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据统计'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 四维数据概览
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            '四维数据概览',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          _buildFourDimensionalChart(),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDimensionCard('任务', '${(_fourDimensionalData['task']['completion_rate'] * 100).toStringAsFixed(1)}%'),
                              _buildDimensionCard('宠物', '${(_fourDimensionalData['pet']['level'])}级'),
                              _buildDimensionCard('社交', '${_fourDimensionalData['social']['total_friends']}人'),
                              _buildDimensionCard('心理', _fourDimensionalData['mental']['current_state']),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 周数据趋势
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            '周数据趋势',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          _buildWeeklyTrendChart(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 数据洞察
                  _buildDataInsightsCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 数据驱动决策建议
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '数据驱动决策',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '基于你的四维数据分析，我们为你提供以下决策建议：',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          ...(_dataInsights['recommendations'] ?? []).map((recommendation) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  recommendation,
                                  style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 刷新按钮
                  Center(
                    child: ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('刷新数据'),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
  
  // 构建维度卡片
  Widget _buildDimensionCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}


