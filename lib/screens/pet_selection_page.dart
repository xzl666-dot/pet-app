import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../managers/pet_state_manager.dart';

class PetSelectionPage extends StatefulWidget {
  const PetSelectionPage({Key? key}) : super(key: key);

  @override
  State<PetSelectionPage> createState() => _PetSelectionPageState();
}

class _PetSelectionPageState extends State<PetSelectionPage> {
  final _petManager = PetStateManager.instance;
  final TextEditingController _nameController = TextEditingController();
  PetType _selectedType = PetType.chick;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择你的宠物'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 标题
            const Text(
              '欢迎来到宠物养成世界！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // 宠物名称输入
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '给你的宠物起个名字',
                hintText: '例如：小乖',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            
            // 宠物种类选择标题
            const Text(
              '选择宠物种类',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // 宠物种类选择网格
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: PetType.values.map((type) {
                return _buildPetTypeCard(type);
              }).toList(),
            ),
            const SizedBox(height: 40),
            
            // 确认按钮
            ElevatedButton(
              onPressed: _handleConfirmSelection,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('开始养成'),
            ),
          ],
        ),
      ),
    );
  }

  // 构建宠物种类卡片
  Widget _buildPetTypeCard(PetType type) {
    final isSelected = _selectedType == type;
    String emoji;
    String typeName;
    Color baseColor;

    // 根据宠物种类设置外观
    switch (type) {
      case PetType.chick:
        emoji = '🐣';
        typeName = '小鸡';
        baseColor = Colors.yellow;
        break;
      case PetType.puppy:
        emoji = '🐶';
        typeName = '小狗';
        baseColor = Colors.brown;
        break;
      case PetType.kitten:
        emoji = '🐱';
        typeName = '小猫';
        baseColor = Colors.grey;
        break;
      case PetType.bunny:
        emoji = '🐰';
        typeName = '小兔';
        baseColor = Colors.pink;
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Card(
        elevation: isSelected ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 3)
              : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? baseColor.withOpacity(0.1) : Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 8),
              Text(
                typeName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 处理确认选择
  Future<void> _handleConfirmSelection() async {
    final name = _nameController.text.trim().isEmpty
        ? '我的宠物'
        : _nameController.text.trim();

    try {
      // 创建宠物
      await _petManager.createPetWithType(name: name, type: _selectedType);

      // 导航到主页
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建宠物失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
