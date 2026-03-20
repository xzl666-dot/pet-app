import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../models/pet_model.dart';
import '../managers/pet_state_manager.dart';
import '../managers/auth_manager.dart';
import '../utils/token_util.dart';

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
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // 应用图标
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      spreadRadius: 6,
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🐾',
                    style: TextStyle(fontSize: 60),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 标题
              Text(
                '欢迎来到宠物养成世界！',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.displayLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '选择一只可爱的宠物开始你的养成之旅',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // 宠物名称输入
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '给你的宠物起个名字',
                    hintText: '例如：小乖',
                    prefixIcon: Icon(
                      Icons.pets,
                      color: Theme.of(context).primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 宠物种类选择标题
              Text(
                '选择宠物种类',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.displayLarge?.color,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 宠物种类选择网格
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  children: PetType.values.map((type) {
                    return _buildPetTypeCard(type);
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 确认按钮
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleConfirmSelection,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                  child: const Text('开始养成'),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
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
      final authManager = Provider.of<AuthManager>(context, listen: false);
      final user = authManager.currentUser;

      print('=== 开始创建宠物 ===');
      print('用户信息: $user');

      if (user != null) {
        final token = await TokenUtil.instance.getAccessToken();
        final userId = user.userId ?? user.id;
        
        print('Token: $token');
        print('UserId: $userId');
        
        if (userId == null) {
          throw Exception('用户ID不存在');
        }
        
        final requestBody = {
          'userId': userId,
          'petName': name,
          'petType': _selectedType.toString().split('.').last,
        };
        
        print('请求体: $requestBody');
        
        // 调用后端创建宠物接口
        final createResponse = await http.post(
          Uri.parse('http://localhost:3000/api/pet/create'),
          headers: {
            'Content-Type': 'application/json',
            'token': token ?? '',
          },
          body: jsonEncode(requestBody),
        );

        print('创建宠物响应状态码: ${createResponse.statusCode}');
        print('创建宠物响应内容: ${createResponse.body}');

        if (createResponse.statusCode == 200) {
          final createData = jsonDecode(createResponse.body);
          if (createData['code'] == 200) {
            final petId = createData['data']['petId'];
            print('宠物创建成功，petId: $petId');

            // 本地创建宠物
            await _petManager.createPetWithType(name: name, type: _selectedType);

            // 调用后端宠物选择接口
            final selectResponse = await http.post(
              Uri.parse('http://localhost:3000/api/pet/select'),
              headers: {
                'Content-Type': 'application/json',
                if (token != null) 'token': token,
              },
              body: jsonEncode({
                'userId': userId,
                'petId': petId,
              }),
            );

            print('宠物选择响应状态码: ${selectResponse.statusCode}');
            print('宠物选择响应内容: ${selectResponse.body}');

            if (selectResponse.statusCode == 200) {
              final selectData = jsonDecode(selectResponse.body);
              if (selectData['code'] == 200) {
                final needGuide = selectData['data']['needGuide'] ?? false;
                print('是否需要测试期引导: $needGuide');
                
                // 直接导航到主页，确保用户能够看到宠物信息
                print('导航到主页，宠物创建成功');
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              } else {
                throw Exception(selectData['msg'] ?? '宠物选择失败');
              }
            } else {
              throw Exception('宠物选择失败，HTTP状态码: ${selectResponse.statusCode}');
            }
          } else {
            throw Exception(createData['msg'] ?? '创建宠物失败');
          }
        } else {
          throw Exception('创建宠物失败，HTTP状态码: ${createResponse.statusCode}');
        }
      } else {
        // 如果用户未登录，创建本地宠物并导航到主页
        await _petManager.createPetWithType(name: name, type: _selectedType);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print('=== 创建宠物失败 ===');
      print('错误信息: $e');
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
