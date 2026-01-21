import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../models/pet_model.dart';
import '../managers/auth_manager.dart';
import '../managers/pet_state_manager.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PetStateManager _petManager = PetStateManager.instance;
  List<User> _users = [];
  Map<int, PetModel?> _userPets = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _dbHelper.getAllUsers();
      final userPets = <int, PetModel?>{};

      // 为每个用户加载宠物信息
      for (final user in users) {
        try {
          final hasPet = await _petManager.hasPet();
          if (hasPet) {
            final pet = await _petManager.getOrCreatePet();
            userPets[user.id!] = pet;
          } else {
            userPets[user.id!] = null;
          }
        } catch (e) {
          print('Error loading pet for user ${user.id}: $e');
          userPets[user.id!] = null;
        }
      }

      setState(() {
        _users = users;
        _userPets = userPets;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUsers();
  }

  Widget _buildPetInfo(int userId) {
    final pet = _userPets[userId];
    if (pet == null) {
      return const Text('暂无宠物信息');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('宠物名称: ${pet.name}'),
        Text('宠物类型: ${pet.type.getTypeName()}'),
        Text('宠物形态: ${pet.form.getFormName()}'),
        Text('营养值: ${pet.nutrition}'),
        Text('幸福值: ${pet.happiness}'),
        Text('技能点: ${pet.skillPoint}'),
        Text('创建时间: ${pet.createdAt.toString()}'),
        Text('最后更新: ${pet.lastUpdated.toString()}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理员面板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthManager.instance.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: '退出登录',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUsers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
                ? const Center(child: Text('暂无用户数据'))
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '用户名: ${user.username}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: user.isOnline ? Colors.green : Colors.grey,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (user.isAdmin)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            '管理员',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('ID: ${user.id}'),
                              Text('密码哈希: ${user.passwordHash}'),
                              const SizedBox(height: 12),
                              const Text(
                                '养成进度:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildPetInfo(user.id!),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
