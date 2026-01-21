import 'package:flutter/material.dart';

class BackgroundInfoPage extends StatefulWidget {
  const BackgroundInfoPage({Key? key}) : super(key: key);

  @override
  State<BackgroundInfoPage> createState() => _BackgroundInfoPageState();
}

class _BackgroundInfoPageState extends State<BackgroundInfoPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目背景信息'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 标签栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TabButton(
                    title: '理论调研',
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                Expanded(
                  child: TabButton(
                    title: '行业调研',
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ),
                Expanded(
                  child: TabButton(
                    title: '用户调研',
                    isSelected: _selectedTab == 2,
                    onTap: () => setState(() => _selectedTab = 2),
                  ),
                ),
              ],
            ),
          ),
          
          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildTheoryResearch();
      case 1:
        return _buildIndustryResearch();
      case 2:
        return _buildUserResearch();
      default:
        return Container();
    }
  }

  Widget _buildTheoryResearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('核心理论'),
        const ContentCard(
          title: '心流计算理论',
          content: 'David E. Melnikoff 等人提出的心流计算理论，旨在通过量化方法评估用户在任务执行过程中的沉浸感和投入程度。',
        ),
        
        const SizedBox(height: 20),
        const SectionTitle('核心模型'),
        const ContentCard(
          title: '任务 - 收益价值评估模型',
          content: '量化沉浸感的关键指标，通过评估任务与收益之间的关联性，计算用户在完成任务过程中获得的心理满足感和成就感。',
        ),
        
        const SizedBox(height: 20),
        const SectionTitle('心流提升路径'),
        const ContentCard(
          title: '建立任务与收益的强关联性',
          content: '确保用户能够清晰地感知到完成任务后获得的具体收益，增强行为动机。',
        ),
        const ContentCard(
          title: '降低行为不确定性',
          content: '提供即时反馈，让用户能够快速了解自己的行为结果，减少焦虑感。',
        ),
      ],
    );
  }

  Widget _buildIndustryResearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('任务管理 APP'),
        const ContentCard(
          title: '优点',
          content: '实用、高效，能够帮助用户有条理地管理日常任务和工作。',
        ),
        const ContentCard(
          title: '缺点',
          content: '枯燥、趣味性低、用户粘性差，容易让用户产生厌倦感。',
        ),
        
        const SizedBox(height: 20),
        const SectionTitle('宠物养成游戏'),
        const ContentCard(
          title: '优点',
          content: '有趣、互动性强、用户粘性高，能够吸引用户长期参与。',
        ),
        const ContentCard(
          title: '缺点',
          content: '缺乏实用价值，娱乐与现实目标脱节，用户可能会感到浪费时间。',
        ),
        
        const SizedBox(height: 20),
        const SectionTitle('市场空白'),
        const ContentCard(
          title: '趣味性与实用性兼具的结合体',
          content: '现有产品要么过于实用缺乏乐趣，要么过于娱乐缺乏价值，市场急需一款能够平衡两者的创新产品。',
        ),
      ],
    );
  }

  Widget _buildUserResearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('调研对象'),
        const ContentCard(
          content: '30 名目标用户（学生与职场新人）',
        ),
        
        const SizedBox(height: 20),
        const SectionTitle('核心痛点'),
        const ContentCard(
          title: '任务没动力',
          content: '缺乏即时反馈和正向激励，用户难以持续保持完成任务的积极性。',
        ),
        const ContentCard(
          title: '游戏玩完没意义',
          content: '娱乐与现实目标脱节，用户在游戏结束后会感到空虚和浪费时间。',
        ),
        
        const SizedBox(height: 20),
        const SectionTitle('用户需求'),
        const ContentCard(
          content: '急需兼顾 "趣味性" 与 "实用性" 的工具，让用户在娱乐中实现自我提升。',
        ),
      ],
    );
  }
}

class TabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const TabButton({
    Key? key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
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
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
}

class ContentCard extends StatelessWidget {
  final String? title;
  final String content;

  const ContentCard({
    Key? key,
    this.title,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (title != null)
              const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
