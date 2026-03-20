import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../managers/auth_manager.dart';

class EvaluationReportPage extends StatefulWidget {
  const EvaluationReportPage({super.key});

  @override
  State<EvaluationReportPage> createState() => _EvaluationReportPageState();
}

class _EvaluationReportPageState extends State<EvaluationReportPage> {
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authManager = Provider.of<AuthManager>(context, listen: false);
      final user = authManager.currentUser;

      if (user == null) {
        throw Exception('用户未登录');
      }

      final response = await http.get(
        Uri.parse(
          'http://localhost:3000/api/testPeriod/ability/report?userId=${user.id}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          setState(() {
            _reportData = data['data'];
            _isLoading = false;
          });
        } else {
          throw Exception(data['msg'] ?? '加载失败');
        }
      } else {
        throw Exception('网络请求失败');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('评估报告'),
        backgroundColor: Colors.blue[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
              ? const Center(child: Text('暂无评估报告'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildAbilityLevelSection(),
                      _buildIndicatorsSection(),
                      _buildPetInfoSection(),
                      _buildRecommendTasksSection(),
                      _buildSuggestionsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAbilityLevelSection() {
    final abilityLevel = _reportData!['abilityLevel'];
    final levelColors = {
      'S': Colors.purple,
      'A': Colors.blue,
      'B': Colors.green,
      'C': Colors.orange,
      'D': Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      color: levelColors[abilityLevel],
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                abilityLevel,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: levelColors[abilityLevel],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _reportData!['abilityLevelDesc'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '总分: ${_reportData!['totalScore']}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsSection() {
    final indicators = _reportData!['indicators'];
    final indicatorLabels = {
      'taskFinishRate': '任务完成率',
      'continuousFinishDays': '连续完成天数',
      'limitFinishCount': '极限难度完成数',
      'imeValue': '心流值',
      'avgEfficiency': '平均效率',
      'avgScore': '平均效果分',
    };

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '评估指标',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...indicatorLabels.entries.map((entry) {
            final key = entry.key;
            final label = entry.value;
            final value = indicators[key];
            return _buildIndicatorItem(label, value);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildIndicatorItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value is int ? '$value%' : '$value',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetInfoSection() {
    final petInfo = _reportData!['petInfo'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '宠物信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPetInfoItem('评估等级', petInfo['abilityLevel']),
          _buildPetInfoItem('初始等级', '${petInfo['initialLevel']}级'),
          _buildPetInfoItem('初始经验', '${petInfo['initialExp']}经验'),
          _buildPetInfoItem('当前等级', '${petInfo['level']}级'),
          _buildPetInfoItem('当前经验', '${petInfo['exp']}经验'),
        ],
      ),
    );
  }

  Widget _buildPetInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendTasksSection() {
    final recommendTasks = _reportData!['recommendTasks'] as List;

    if (recommendTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '推荐任务',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...recommendTasks.map((task) => _buildRecommendTaskItem(task)).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendTaskItem(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '难度: ${task['difficulty']}星',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.star, size: 20, color: Colors.orange[400]),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    final suggestions = _reportData!['suggestions'] as List;

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '提升建议',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb,
                      size: 20,
                      color: Colors.orange[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}