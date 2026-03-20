import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../managers/auth_manager.dart';
import '../utils/token_util.dart';

class EvaluationCalcPage extends StatefulWidget {
  const EvaluationCalcPage({Key? key}) : super(key: key);

  @override
  State<EvaluationCalcPage> createState() => _EvaluationCalcPageState();
}

class _EvaluationCalcPageState extends State<EvaluationCalcPage> {
  final _authManager = AuthManager.instance;
  bool _isLoading = false;
  Map<String, dynamic>? _evaluationData;
  String _selectedTimeType = 'all';

  @override
  void initState() {
    super.initState();
    _loadEvaluationData();
  }

  Future<void> _loadEvaluationData() async {
    setState(() => _isLoading = true);

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
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('加载评估数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateEvaluation() async {
    setState(() => _isLoading = true);

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
            _isLoading = false;
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
      setState(() => _isLoading = false);
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
        title: const Text('评估计算'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _calculateEvaluation,
            tooltip: '重新计算',
          ),
        ],
      ),
      body: _isLoading
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