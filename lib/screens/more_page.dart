import 'package:flutter/material.dart';
import 'data_statistics_page.dart';
import 'user_segmentation_page.dart';
import 'teacher_dashboard_page.dart';
import 'parent_dashboard_page.dart';
import 'social_challenge_page.dart';

import 'ability_evaluation_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('更多功能'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学习相关
            _buildSectionTitle('学习相关'),
            _buildFeatureGrid([
              _buildFeatureItem(
                icon: Icons.assessment,
                title: '能力评估',
                description: '评估学习能力和水平',
                onTap: () => Navigator.pushNamed(context, '/ability'),
                color: Colors.blue,
              ),
              _buildFeatureItem(
                icon: Icons.social_distance,
                title: '社交挑战',
                description: '与好友一起学习成长',
                onTap: () => Navigator.pushNamed(context, '/social'),
                color: Colors.green,
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // 数据与分析
            _buildSectionTitle('数据与分析'),
            _buildFeatureGrid([
              _buildFeatureItem(
                icon: Icons.bar_chart,
                title: '数据统计',
                description: '四维数据可视化分析',
                onTap: () => Navigator.pushNamed(context, '/data_statistics'),
                color: Colors.purple,
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // 用户与运营
            _buildSectionTitle('用户与运营'),
            _buildFeatureGrid([
              _buildFeatureItem(
                icon: Icons.layers,
                title: '用户分层',
                description: '查看用户等级和权益',
                onTap: () => Navigator.pushNamed(context, '/user_segmentation'),
                color: Colors.red,
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // 家校联动
            _buildSectionTitle('家校联动'),
            _buildFeatureGrid([
              _buildFeatureItem(
                icon: Icons.school,
                title: '教师工作台',
                description: '管理任务模板',
                onTap: () => Navigator.pushNamed(context, '/teacher_dashboard'),
                color: Colors.teal,
              ),
              _buildFeatureItem(
                icon: Icons.family_restroom,
                title: '家长中心',
                description: '查看孩子学习情况',
                onTap: () => Navigator.pushNamed(context, '/parent_dashboard'),
                color: Colors.pink,
              ),
            ]),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  // 构建section标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  // 构建功能网格
  Widget _buildFeatureGrid(List<Widget> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
  
  // 构建功能项
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
