import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../managers/auth_manager.dart';
import '../screens/add_friend_page.dart';
import '../screens/friend_detail_page.dart';
import '../screens/social_challenge_page.dart';

class FriendModel {
  final String userId;
  final String nickname;
  final String remark;
  final String avatar;
  final String major;
  final String grade;
  final PetInfo pet;
  final int intimacy;
  final bool isOnline;
  final String addTime; 

  FriendModel({
    required this.userId,
    required this.nickname,
    this.remark = '',
    this.avatar = '',
    this.major = '',
    this.grade = '',
    required this.pet,
    this.intimacy = 0,
    this.isOnline = false,
    this.addTime = '',
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      userId: json['userId']?.toString() ?? '',
      nickname: json['nickname'] ?? '',
      remark: json['remark'] ?? '',
      avatar: json['avatar'] ?? '',
      major: json['major'] ?? '',
      grade: json['grade'] ?? '',
      pet: PetInfo.fromJson(json['pet'] ?? {}),
      intimacy: json['intimacy'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      addTime: json['addTime'] ?? '',
    );
  }
}

class PetInfo {
  final String species;
  final String stage;
  final int level;
  final int nutrition;
  final int happiness;

  PetInfo({
    required this.species,
    required this.stage,
    required this.level,
    required this.nutrition,
    required this.happiness,
  });

  factory PetInfo.fromJson(Map<String, dynamic> json) {
    return PetInfo(
      species: json['species'] ?? '小猫',
      stage: json['stage'] ?? '幼年',
      level: json['level'] ?? 1,
      nutrition: json['nutrition'] ?? 50,
      happiness: json['happiness'] ?? 50,
    );
  }
}

class FriendListPage extends StatefulWidget {
  const FriendListPage({Key? key}) : super(key: key);

  @override
  _FriendListPageState createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  List<FriendModel> _friends = [];
  List<FriendModel> _filteredFriends = [];
  List<dynamic> _friendRequests = [];
  List<dynamic> _sentRequests = [];
  List<FriendModel> _blacklist = [];
  String _searchKey = '';
  int _activeTab = 0; 
  int _requestSubTab = 0; 
  String _sortBy = 'intimacy'; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadFriendRequests();
  }

  // 加载好友列表
  Future<void> _loadFriends() async {
    try {
      final token = AuthManager.instance.currentUser?.token;
      final currentUser = AuthManager.instance.currentUser;
      if (token == null || currentUser == null || currentUser.userId == null) return;

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/social/friends?userId=${currentUser.userId}&petId=${currentUser.petId ?? 1}'),
        headers: {'token': token},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final friendsData = (data['data']['friends'] ?? []) as List;
          setState(() {
            _friends = friendsData.map((e) => FriendModel.fromJson(e)).toList();
            _sortFriends();
            _filterFriends(_searchKey);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('加载好友列表失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 加载好友申请
  Future<void> _loadFriendRequests() async {
    try {
      final token = AuthManager.instance.currentUser?.token;
      final currentUser = AuthManager.instance.currentUser;
      if (token == null || currentUser == null || currentUser.userId == null) return;

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/social/friend-requests?userId=${currentUser.userId}'),
        headers: {'token': token},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          setState(() {
            _friendRequests = (data['data']['receivedRequests'] ?? []) as List;
            _sentRequests = (data['data']['sentRequests'] ?? []) as List;
          });
        }
      }
    } catch (e) {
      print('加载好友申请失败: $e');
    }
  }

  // 排序好友列表
  void _sortFriends() {
    switch (_sortBy) {
      case 'intimacy':
        _friends.sort((a, b) {
          if (a.intimacy != b.intimacy) {
            return b.intimacy.compareTo(a.intimacy);
          } else {
            return b.addTime.compareTo(a.addTime);
          }
        });
        break;
      case 'level':
        _friends.sort((a, b) => b.pet.level.compareTo(a.pet.level));
        break;
      case 'time':
        _friends.sort((a, b) => a.addTime.compareTo(b.addTime));
        break;
    }
  }

  // 搜索过滤
  void _filterFriends(String keyword) {
    setState(() {
      _searchKey = keyword;
      if (keyword.isEmpty) {
        _filteredFriends = _friends;
      } else {
        _filteredFriends = _friends.where((friend) => 
          friend.nickname.contains(keyword) ||
          friend.remark.contains(keyword) ||
          friend.major.contains(keyword)
        ).toList();
      }
    });
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

  // 构建好友列表项
  Widget buildFriendItem(FriendModel friend) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () => _toFriendDetail(friend.userId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 左侧区域：头像 + 宠物图标
              Stack(
                children: [
                  CircleAvatar(
                    child: const Icon(Icons.person, size: 30),
                    radius: 25,
                    backgroundColor: Colors.grey[100],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Text(
                        _getPetIcon(friend.pet.species),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              // 中间区域：信息
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.remark.isNotEmpty ? friend.remark : friend.nickname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${friend.major} ${friend.grade}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "宠物：${friend.pet.species} | ${friend.pet.stage} | Lv.${friend.pet.level}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "营养：${friend.pet.nutrition} · 幸福：${friend.pet.happiness}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "亲密度：${friend.intimacy}/2000",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 右侧区域：操作按钮
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _startChallenge(friend.userId),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: const Text('发起挑战', style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )),
                  ),
                  const SizedBox(height: 8),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(child: Text('设置备注'), value: 'remark'),
                      const PopupMenuItem(child: Text('删除好友'), value: 'delete'),
                      const PopupMenuItem(child: Text('加入黑名单'), value: 'blacklist'),
                    ],
                    onSelected: (value) => _handleFriendOp(friend.userId, value),
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 处理好友操作
  void _handleFriendOp(String userId, String operation) {
    switch (operation) {
      case 'remark':
        _setRemark(userId);
        break;
      case 'delete':
        _deleteFriend(userId);
        break;
      case 'blacklist':
        _addToBlacklist(userId);
        break;
    }
  }

  // 设置备注
  void _setRemark(String userId) {
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
                await _callSetRemarkAPI(userId, controller.text);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 调用设置备注API
  Future<void> _callSetRemarkAPI(String friendId, String remark) async {
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
          'friendId': friendId,
          'remark': remark,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          _loadFriends();
          _showSnackBar('备注设置成功');
        } else {
          _showSnackBar('设置失败: ${data['msg']}');
        }
      } else {
        _showSnackBar('设置失败: 网络请求失败');
      }
    } catch (e) {
      print('设置备注失败: $e');
      _showSnackBar('设置失败: 网络错误');
    }
  }

  // 删除好友
  void _deleteFriend(String userId) {
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
                await _callDeleteFriendAPI(userId);
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  // 调用删除好友API
  Future<void> _callDeleteFriendAPI(String friendId) async {
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
          'friendId': friendId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          _loadFriends();
          _showSnackBar('已删除好友');
        } else {
          _showSnackBar('删除失败: ${data['msg']}');
        }
      } else {
        _showSnackBar('删除失败: 网络请求失败');
      }
    } catch (e) {
      print('删除好友失败: $e');
      _showSnackBar('删除失败: 网络错误');
    }
  }

  // 加入黑名单
  void _addToBlacklist(String userId) {
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
                await _callBlockFriendAPI(userId);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 调用拉黑好友API
  Future<void> _callBlockFriendAPI(String friendId) async {
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
          'friendId': friendId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          _loadFriends();
          _showSnackBar('已加入黑名单');
        } else {
          _showSnackBar('操作失败: ${data['msg']}');
        }
      } else {
        _showSnackBar('操作失败: 网络请求失败');
      }
    } catch (e) {
      print('拉黑好友失败: $e');
      _showSnackBar('操作失败: 网络错误');
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

  // 跳转到添加好友页面
  void _toAddFriend() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const AddFriendPage()),
    ).then((_) {
      _loadFriendRequests();
    });
  }

  // 跳转到好友详情页面
  void _toFriendDetail(String friendId) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => FriendDetailPage(friendId: friendId)),
    );
  }

  // 发起挑战
  void _startChallenge(String opponentId) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => ChallengeCreatePage(
          opponentId: opponentId,
        ),
      ),
    );
  }

  // 构建标签页
  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: _activeTab == 0 ? BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.blue, width: 2)),
                ) : null,
                child: Text('全部好友', style: TextStyle(
                  color: _activeTab == 0 ? Colors.blue : Colors.black,
                  fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.w500,
                )),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: _activeTab == 1 ? BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.blue, width: 2)),
                ) : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text('好友申请', style: TextStyle(
                      color: _activeTab == 1 ? Colors.blue : Colors.black,
                      fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.w500,
                    )),
                    if (_friendRequests.isNotEmpty) 
                      Positioned(
                        top: -5,
                        right: -15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _friendRequests.length.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: _activeTab == 2 ? BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.blue, width: 2)),
                ) : null,
                child: Text('黑名单', style: TextStyle(
                  color: _activeTab == 2 ? Colors.blue : Colors.black,
                  fontWeight: _activeTab == 2 ? FontWeight.bold : FontWeight.w500,
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建好友申请子标签
  Widget _buildRequestSubTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _requestSubTab = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: _requestSubTab == 0 ? BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.blue, width: 2)),
              ) : null,
              child: const Text('收到的申请', style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              )),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _requestSubTab = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: _requestSubTab == 1 ? BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.blue, width: 2)),
              ) : null,
              child: const Text('发出的申请', style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              )),
            ),
          ),
        ),
      ],
    );
  }

  // 构建好友申请列表
  Widget _buildFriendRequests() {
    return Column(
      children: [
        _buildRequestSubTabs(),
        Expanded(
          child: _requestSubTab == 0
              ? _buildReceivedRequests()
              : _buildSentRequests(),
        ),
      ],
    );
  }

  // 构建收到的申请列表
  Widget _buildReceivedRequests() {
    if (_friendRequests.isEmpty) {
      return const Center(child: Text('暂无好友申请'));
    }

    return ListView.builder(
      itemCount: _friendRequests.length,
      itemBuilder: (context, index) {
        final request = _friendRequests[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request['senderNickname'] ?? '未知用户'),
                      const Text('请求添加你为好友', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _acceptFriendRequest(request['id'].toString()),
                      child: const Text('接受'),
                    ),
                    TextButton(
                      onPressed: () => _rejectFriendRequest(request['id'].toString()),
                      child: const Text('拒绝'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建发出的申请列表
  Widget _buildSentRequests() {
    if (_sentRequests.isEmpty) {
      return const Center(child: Text('暂无发出的申请'));
    }

    return ListView.builder(
      itemCount: _sentRequests.length,
      itemBuilder: (context, index) {
        final request = _sentRequests[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request['receiverNickname'] ?? '未知用户'),
                      const Text('申请已发送', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _withdrawFriendRequest(request['id'].toString()),
                  child: const Text('撤回'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 接受好友申请
  Future<void> _acceptFriendRequest(String requestId) async {
    try {
      final token = AuthManager.instance.currentUser?.token;
      final currentUser = AuthManager.instance.currentUser;
      if (token == null || currentUser == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/social/friend-request/accept'),
        headers: {
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': currentUser.userId.toString(),
          'petId': currentUser.petId?.toString() ?? '1',
          'requestId': requestId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          _loadFriendRequests();
          _loadFriends();
          _showSnackBar('已同意好友申请');
        } else {
          _showSnackBar('操作失败: ${data['msg']}');
        }
      }
    } catch (e) {
      print('接受好友申请失败: $e');
    }
  }

  // 拒绝好友申请
  Future<void> _rejectFriendRequest(String requestId) async {
    try {
      final token = AuthManager.instance.currentUser?.token;
      final currentUser = AuthManager.instance.currentUser;
      if (token == null || currentUser == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/social/friend-request/reject'),
        headers: {
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': currentUser.userId.toString(),
          'requestId': requestId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          _loadFriendRequests();
          _showSnackBar('已拒绝好友申请');
        } else {
          _showSnackBar('操作失败: ${data['msg']}');
        }
      }
    } catch (e) {
      print('拒绝好友申请失败: $e');
    }
  }

  // 撤回好友申请
  Future<void> _withdrawFriendRequest(String requestId) async {
    try {
      final token = AuthManager.instance.currentUser?.token;
      final currentUser = AuthManager.instance.currentUser;
      if (token == null || currentUser == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/social/friend-request/withdraw'),
        headers: {
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': currentUser.userId.toString(),
          'requestId': requestId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          _loadFriendRequests();
          _showSnackBar('已撤回好友申请');
        } else {
          _showSnackBar('操作失败: ${data['msg']}');
        }
      }
    } catch (e) {
      print('撤回好友申请失败: $e');
    }
  }

  // 构建排序选项
  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            '排序：',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          DropdownButton<String>(
            value: _sortBy,
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
                _sortFriends();
                _filterFriends(_searchKey);
              });
            },
            items: const [
              DropdownMenuItem(value: 'intimacy', child: Text('亲密度')),
              DropdownMenuItem(value: 'level', child: Text('宠物等级')),
              DropdownMenuItem(value: 'time', child: Text('添加时间')),
            ],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
            underline: Container(),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('好友列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _toAddFriend,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          if (_activeTab == 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索好友（昵称/备注/专业）',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchKey.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => _filterFriends(''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: _filterFriends,
              ),
            ),
          ],
          
          // 标签页
          _buildTabs(),
          
          // 好友列表区
          if (_activeTab == 0) ...[
            _buildSortOptions(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredFriends.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '暂无好友，快去添加吧～',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _toAddFriend,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('添加好友'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredFriends.length,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemBuilder: (c, i) => buildFriendItem(_filteredFriends[i]),
                        ),
            ),
          ] else if (_activeTab == 1) ...[
            Expanded(
              child: _buildFriendRequests(),
            ),
          ] else if (_activeTab == 2) ...[
            Expanded(
              child: _blacklist.isEmpty
                  ? const Center(child: Text('黑名单为空'))
                  : ListView.builder(
                      itemCount: _blacklist.length,
                      itemBuilder: (c, i) => buildFriendItem(_blacklist[i]),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
