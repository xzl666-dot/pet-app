import 'package:flutter/material.dart';
import '../managers/school_home_link_manager.dart';

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({Key? key}) : super(key: key);

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  final SchoolHomeLinkManager _manager = SchoolHomeLinkManager.instance;
  
  bool _isLoading = true;
  Map<String, dynamic>? _parentData;
  Map<String, dynamic>? _studentData;
  List<Map<String, dynamic>> _assignedTasks = [];
  Map<String, dynamic>? _permissions;
  
  @override
  void initState() {
    super.initState();
    _loadParentData();
  }
  
  Future<void> _loadParentData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 模拟家长ID
      const parentId = 'parent_001';
      const studentId = 'user_001';
      
      // 获取家长权限
      final permissions = _manager.getParentPermissions(parentId);
      
      // 获取学生数据
      final studentData = _manager.getParentViewData(studentId);
      
      // 获取教师分配的任务
      final assignedTasks = _manager.getAssignedTasks(studentId);
      
      setState(() {
        _permissions = permissions;
        _studentData = studentData;
        _assignedTasks = assignedTasks;
        _parentData = {
          'id': parentId,
          'name': '家长姓名',
        };
      });
    } catch (e) {
      print('加载家长数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 构建学习概览卡片
  Widget _buildLearningOverviewCard() {
    if (_studentData == null || !(_permissions?['can_view_progress'] ?? false)) {
      return Container();
    }
    
    final progress = _studentData!['progress'];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '学习概览',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('周完成率', '${(progress['weekly_completion_rate'] * 100).toStringAsFixed(0)}%', Colors.blue),
                _buildStatCard('月完成率', '${(progress['monthly_completion_rate'] * 100).toStringAsFixed(0)}%', Colors.green),
                _buildStatCard('连续打卡', '${progress['continuous_days']}天', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建任务完成情况卡片
  Widget _buildTaskCompletionCard() {
    if (_studentData == null || !(_permissions?['can_view_tasks'] ?? false)) {
      return Container();
    }
    
    final tasks = _studentData!['tasks'];
    final totalTasks = tasks['total'];
    final completedTasks = tasks['completed'];
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '任务完成情况',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: completionRate,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 16,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTaskStatusCard('已完成', tasks['completed'], Colors.green),
                _buildTaskStatusCard('进行中', tasks['in_progress'], Colors.blue),
                _buildTaskStatusCard('待完成', tasks['pending'], Colors.orange),
                _buildTaskStatusCard('总计', tasks['total'], Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建成就卡片
  Widget _buildAchievementCard() {
    if (_studentData == null || !(_permissions?['can_view_achievements'] ?? false)) {
      return Container();
    }
    
    final achievements = _studentData!['achievements'];
    
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
                  '近期成就',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '总计: ${achievements['total']}个',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (achievements['recent'].isNotEmpty)
              ...achievements['recent'].map((achievement) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.yellow[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.star, color: Colors.yellow),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement['name'],
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                achievement['date'],
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })
            else
              const Text('暂无成就记录'),
          ],
        ),
      ),
    );
  }
  
  // 构建宠物状态卡片
  Widget _buildPetStatusCard() {
    if (_studentData == null) {
      return Container();
    }
    
    final pet = _studentData!['pet'];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '宠物状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🐱', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(width: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet['name'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('等级: ${pet['level']}级'),
                    const SizedBox(height: 4),
                    Text('心情: ${pet['happiness']}%'),
                    const SizedBox(height: 4),
                    Text('经验: ${pet['experience']}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建教师分配任务卡片
  Widget _buildAssignedTasksCard() {
    if (_assignedTasks.isEmpty) {
      return Container();
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '教师分配任务',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_assignedTasks.isNotEmpty)
              ..._assignedTasks.map((task) {
                return Card(
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
                              task['name'],
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Chip(
                              label: Text(
                                _getStatusText(task['status']),
                                style: TextStyle(fontSize: 12),
                              ),
                              backgroundColor: _getStatusColor(task['status']),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '分配教师: ${task['assigned_by']}',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '分配时间: ${task['assigned_at']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '截止时间: ${task['due_date']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              })
            else
              const Text('暂无教师分配的任务'),
          ],
        ),
      ),
    );
  }
  
  // 构建统计卡片
  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建任务状态卡片
  Widget _buildTaskStatusCard(String title, int value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
  
  // 获取任务状态文本
  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return '已完成';
      case 'in_progress':
        return '进行中';
      case 'pending':
        return '待完成';
      default:
        return status;
    }
  }
  
  // 获取任务状态颜色
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green[100]!;
      case 'in_progress':
        return Colors.blue[100]!;
      case 'pending':
        return Colors.orange[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('家长中心'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 欢迎信息
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '欢迎，${_parentData?['name']}',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '查看${_studentData?['student_name']}的学习情况',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 学习概览
                  _buildLearningOverviewCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 任务完成情况
                  _buildTaskCompletionCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 成就
                  _buildAchievementCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 宠物状态
                  _buildPetStatusCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 教师分配任务
                  _buildAssignedTasksCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 刷新按钮
                  Center(
                    child: ElevatedButton(
                      onPressed: _loadParentData,
                      child: const Text('刷新数据'),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
