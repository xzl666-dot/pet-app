import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../managers/auth_manager.dart';
import '../screens/social_challenge_page.dart';

class FriendDetailPage extends StatefulWidget {
  final String friendId;

  const FriendDetailPage({Key? key, required this.friendId}) : super(key: key);

  @override
  _FriendDetailPageState createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends State<FriendDetailPage> {
  Map<String, dynamic> _friendData = {};
  List<dynamic> _battleRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendDetail();
    _loadBattleRecords();
  }

  // 加载好友详情
  Future<void> _loadFriendDetail() async {
    try {
      final token = AuthManager.instance.currentUser?.token;
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/social/user-detail?userId=${widget.friendId}'),
        headers: {'token': token},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          setState(() {
            _friendData = data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('加载好友详情失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 加载对战记录
  Future<void> _loadBattleRecords() async {
    try {
      // 这里简化处理，实际应该调用API
      // 暂时使用模拟数据
      await Future.delayed(const Duration(milliseconds: 100));
      
      setState(() {
        _battleRecords = [
          {
            'date': '2024-01-01',
            'result': '胜',
            'score': '100:80',
            'task': '数学压轴题挑战',
          },
          {
            'date': '2023-12-30',
            'result': '负',
            'score': '75:90',
            'task': '物理实验挑战',
          },
        ];
      });
    } catch (e) {
      print('加载对战记录失败: $e');
    }
  }

  // 获取宠物图标
  String _getPetIcon(String species) {
    switch (species) {
      case '小猫':
        return '🐱';
      case '小狗':
        return '🐶';
      case '小鸡':
        return '🐥';
      case '小兔':
        return '🐰';
      default:
        return '🐱';
    }
  }

  // 发起挑战
  void _startChallenge() {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => ChallengeCreatePage(
          opponentId: widget.friendId,
        ),
      ),
    );
  }

  // 设置备注
  void _setRemark() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('设置备注'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '请输入备注（最多10个字符）'),
            maxLength: 10,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _callSetRemarkAPI(controller.text);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 调用设置备注API
  Future<void> _callSetRemarkAPI(String remark) async {
    try {
      final token = AuthManager.instance.currentUser?.token;
      final currentUser = AuthManager.instance.currentUser;
      if (token == null || currentUser == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/social/set-remark'),
        headers: {
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': currentUser.userId.toString(),
          'petId': currentUser.petId?.toString() ?? '1',
          'friendId': widget.friendId,
          'remark': remark,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          _loadFriendDetail();
          _showSnackBar('备注设置成功');
        } else {
          _showSnackBar('设置失败: ${data['msg']}');
        }
      }
    } catch (e) {
      print('设置备注失败: $e');
    }
  }

  // 删除好友
  void _deleteFriend() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除好友'),
          content: const Text('确定删除该好友吗？删除后亲密度将清零'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _callDeleteFriendAPI();
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  // 调用删除好友API
  Future<void> _callDeleteFriendAPI() async {
    try {
      final token = AuthManager.instance.currentUser?.token;
      final currentUser = AuthManager.instance.currentUser;
      if (token == null || currentUser == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/social/delete-friend'),
        headers: {
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': currentUser.userId.toString(),
          'petId': currentUser.petId?.toString() ?? '1',
          'friendId': widget.friendId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          _showSnackBar('已删除好友');
          Navigator.pop(context);
        } else {
          _showSnackBar('删除失败: ${data['msg']}');
        }
      }
    } catch (e) {
      print('删除好友失败: $e');
    }
  }

  // 加入黑名单
  void _addToBlacklist() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('加入黑名单'),
          content: const Text('确定要将这个好友加入黑名单吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _callBlockFriendAPI();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 调用拉黑好友API
  Future<void> _callBlockFriendAPI() async {
    try {
      final token = AuthManager.instance.currentUser?.token;
      final currentUser = AuthManager.instance.currentUser;
      if (token == null || currentUser == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/social/block-friend'),
        headers: {
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': currentUser.userId.toString(),
          'petId': currentUser.petId?.toString() ?? '1',
          'friendId': widget.friendId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          _showSnackBar('已加入黑名单');
          Navigator.pop(context);
        } else {
          _showSnackBar('操作失败: ${data['msg']}');
        }
      }
    } catch (e) {
      print('拉黑好友失败: $e');
    }
  }

  // 显示SnackBar提示
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('好友详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = _friendData['user'] ?? {};
    final pet = _friendData['pet'] ?? {};
    final intimacy = _friendData['intimacy'] ?? 0;
    final addTime = _friendData['addTime'] ?? '2024-01-01';

    return Scaffold(
      appBar: AppBar(
        title: Text(user['nickname'] ?? '好友详情'),
      ),
      body: Column(
        children: [
          // 顶部信息栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 头像
                CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50, color: Colors.grey[600]),
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                // 名称
                Text(
                  user['nickname'] ?? '未知',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${user['major'] ?? '学生'} ${user['grade'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                // 亲密度模块
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '亲密度',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$intimacy/2000',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: LinearProgressIndicator(
                          value: intimacy / 2000,
                          backgroundColor: Colors.grey[200],
                          color: Colors.pink,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '添加于 $addTime',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 宠物信息卡片
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '宠物信息',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 18),
                          // 左图右文布局
                          Row(
                            children: [
                              // 宠物形象图
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[100]!, width: 1),
                                ),
                                child: Center(
                                  child: Text(
                                    _getPetIcon(pet['petType']?.toString() ?? '1'),
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // 信息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '物种：${pet['petType']?.toString() ?? '1'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '阶段：${pet['stage'] ?? '幼年'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '等级：Lv.${pet['level'] ?? 1}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '营养值：${pet['nutrition'] ?? 50}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '幸福度：${pet['happiness'] ?? 50}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 对战记录区
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '对战记录',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_battleRecords.isEmpty)
                            const Center(
                              child: Text(
                                '暂无与该好友的对战记录',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          if (_battleRecords.isNotEmpty)
                            Column(
                              children: _battleRecords.map((record) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              record['task'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              record['date'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        record['result'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: record['result'] == '胜' ? Colors.green : 
                                                 record['result'] == '负' ? Colors.red : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 80), // 为底部操作栏留出空间
                ],
              ),
            ),
          ),
          
          // 底部操作栏
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                // 发起挑战按钮
                Expanded(
                  flex: 4,
                  child: ElevatedButton(
                    onPressed: _startChallenge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: const Text('发起挑战'),
                  ),
                ),
                // 更多操作按钮
                Expanded(
                  flex: 1,
                  child: PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(child: Text('设置备注'), value: 'remark'),
                      const PopupMenuItem(child: Text('删除好友'), value: 'delete'),
                      const PopupMenuItem(child: Text('加入黑名单'), value: 'blacklist'),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'remark':
                          _setRemark();
                          break;
                        case 'delete':
                          _deleteFriend();
                          break;
                        case 'blacklist':
                          _addToBlacklist();
                          break;
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      child: const Icon(Icons.more_vert),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
