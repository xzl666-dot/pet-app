import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/pet_model.dart';
import '../managers/auth_manager.dart';
import '../managers/pet_growth_manager.dart';
import '../utils/token_util.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({Key? key}) : super(key: key);

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final _authManager = AuthManager.instance;
  Map<String, int> _items = {
    'fresh_milk_pack': 0,      // 鲜鲜羊奶包
    'rainbow_cat_stick': 0,    // 彩虹逗猫棒
    'frozen_salmon': 0,        // 冻干三文鱼块
    'star_bubble_machine': 0,   // 星空泡泡机
    'love_cookie': 0,           // 爱心曲奇
    'growth_shake': 0,          // 成长奶昔
    'exp_cookie': 0,            // 经验饼干
    'super_exp_cake': 0,       // 超级经验蛋糕
    'spring_cherry_cake': 0,    // 春日樱花糕
  };
  PetModel? _pet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final user = _authManager.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userId = user.userId ?? user.id;
      final token = await TokenUtil.instance.getAccessToken();

      // 获取宠物数据
      final petListResponse = await http.get(
        Uri.parse('http://localhost:3000/api/pet/list?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'token': token,
        },
      ).timeout(const Duration(seconds: 10));

      if (petListResponse.statusCode == 200) {
        final petListData = jsonDecode(petListResponse.body);
        if (petListData['code'] == 200) {
          final petList = petListData['data']['petList'] ?? [];
          if (petList.isNotEmpty) {
            final selectedPetId = petListData['data']['selectedPetId'];
            final petData = selectedPetId != null
                ? petList.firstWhere((pet) => pet['petId'] == selectedPetId, orElse: () => petList[0])
                : petList[0];
            _pet = PetModel.fromMap(petData);
          }
        }
      }

      if (_pet != null) {
        // 获取真实物品数据
        final itemsResponse = await http.get(
          Uri.parse('http://localhost:3000/api/items/list?userId=$userId&petId=${_pet!.id}'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'token': token,
          },
        ).timeout(const Duration(seconds: 10));

        if (itemsResponse.statusCode == 200) {
          final itemsData = jsonDecode(itemsResponse.body);
          if (itemsData['code'] == 200) {
            setState(() {
              final Map<String, dynamic> remoteItems = itemsData['data']['items'];
              remoteItems.forEach((key, value) {
                _items[key] = value as int;
              });
              _isLoading = false;
            });
            return;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('加载物品数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _useItem(String itemId, int count) async {
    if (_pet == null) return;

    // 检查物品数量是否足够
    if ((_items[itemId] ?? 0) < count) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('道具不足'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final userId = user.userId ?? user.id;
      final token = await TokenUtil.instance.getAccessToken();

      // 调用物品使用API
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/items/use'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'petId': _pet!.id,
          'itemId': itemId,
          'itemNum': count,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          // 更新物品数量
          setState(() {
            _items[itemId] = (_items[itemId] ?? 0) - count;
          });

          // 根据道具类型更新宠物属性
          String effectMessage = '';
          switch (itemId) {
            case 'fresh_milk_pack':
              effectMessage = '营养值 +10';
              break;
            case 'rainbow_cat_stick':
              effectMessage = '快乐值 +10';
              break;
            case 'frozen_salmon':
              effectMessage = '营养值 +25';
              break;
            case 'star_bubble_machine':
              effectMessage = '快乐值 +25';
              break;
            case 'love_cookie':
              effectMessage = '亲密度 +8，快乐值 +5';
              break;
            case 'growth_shake':
              effectMessage = '经验 +15，营养值 +10';
              break;
            case 'exp_cookie':
              effectMessage = '经验 +30';
              break;
            case 'super_exp_cake':
              effectMessage = '经验 +60';
              break;
            case 'spring_cherry_cake':
              effectMessage = '营养 +40，快乐 +40，亲密度 +15';
              break;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('使用成功：${data['msg']}，$effectMessage'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 延迟返回并刷新首页
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context, true); // 返回 true 表示需要刷新
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['msg']),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('使用物品失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('使用物品失败，请重试'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('我的物品'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在加载物品数据...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的物品'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildItemCard(
            name: '鲜鲜羊奶包',
            itemId: 'fresh_milk_pack',
            count: _items['fresh_milk_pack'] ?? 0,
            icon: Icons.local_drink,
            description: '增加宠物营养值',
            effect: '营养值 +10',
          ),
          const SizedBox(height: 12),
          _buildItemCard(
            name: '彩虹逗猫棒',
            itemId: 'rainbow_cat_stick',
            count: _items['rainbow_cat_stick'] ?? 0,
            icon: Icons.color_lens,
            description: '增加宠物快乐值',
            effect: '快乐值 +10',
          ),
          const SizedBox(height: 12),
          _buildItemCard(
            name: '冻干三文鱼块',
            itemId: 'frozen_salmon',
            count: _items['frozen_salmon'] ?? 0,
            icon: Icons.food_bank,
            description: '大幅增加宠物营养值',
            effect: '营养值 +25',
          ),
          const SizedBox(height: 12),
          _buildItemCard(
            name: '星空泡泡机',
            itemId: 'star_bubble_machine',
            count: _items['star_bubble_machine'] ?? 0,
            icon: Icons.bubble_chart,
            description: '大幅增加宠物快乐值',
            effect: '快乐值 +25',
          ),
          const SizedBox(height: 12),
          _buildItemCard(
            name: '爱心曲奇',
            itemId: 'love_cookie',
            count: _items['love_cookie'] ?? 0,
            icon: Icons.favorite,
            description: '增加宠物亲密度和快乐值',
            effect: '亲密度 +8，快乐值 +5',
          ),
          const SizedBox(height: 12),
          _buildItemCard(
            name: '成长奶昔',
            itemId: 'growth_shake',
            count: _items['growth_shake'] ?? 0,
            icon: Icons.local_cafe,
            description: '增加宠物经验和营养值',
            effect: '经验 +15，营养值 +10',
          ),
          const SizedBox(height: 12),
          _buildItemCard(
            name: '经验饼干',
            itemId: 'exp_cookie',
            count: _items['exp_cookie'] ?? 0,
            icon: Icons.cookie,
            description: '增加宠物经验值',
            effect: '经验 +30',
          ),
          const SizedBox(height: 12),
          _buildItemCard(
            name: '超级经验蛋糕',
            itemId: 'super_exp_cake',
            count: _items['super_exp_cake'] ?? 0,
            icon: Icons.cake,
            description: '大幅增加宠物经验值',
            effect: '经验 +60',
          ),
          const SizedBox(height: 12),
          _buildItemCard(
            name: '春日樱花糕',
            itemId: 'spring_cherry_cake',
            count: _items['spring_cherry_cake'] ?? 0,
            icon: Icons.local_florist,
            description: '全面提升宠物属性',
            effect: '营养 +40，快乐 +40，亲密度 +15',
          ),

        ],
      ),
    );
  }

  Widget _buildItemCard({
    required String name,
    required String itemId,
    required int count,
    required IconData icon,
    required String description,
    required String effect,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    effect,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  'x$count',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: count > 0 ? () => _useItem(itemId, 1) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: count > 0 ? Colors.blue : Colors.grey[300],
                    minimumSize: const Size(60, 36),
                  ),
                  child: const Text('使用'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
