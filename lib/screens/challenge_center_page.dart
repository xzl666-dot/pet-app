import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../managers/social_challenge_manager.dart';
import '../managers/api_manager.dart';
import '../managers/auth_manager.dart';
import '../providers/app_state_provider.dart';
import 'pet_center_page.dart';

class ChallengeCenterPage extends StatefulWidget {
  const ChallengeCenterPage({Key? key}) : super(key: key);

  @override
  State<ChallengeCenterPage> createState() => _ChallengeCenterPageState();
}

class _ChallengeCenterPageState extends State<ChallengeCenterPage> {
  final SocialChallengeManager _challengeManager = SocialChallengeManager.instance;
  bool _hasUnreadRequests = false;
  int _unreadRequestCount = 0;
  int _userPoints = 0;
  bool _isPointsLoading = true;
  List<dynamic> _challengeRecords = [];
  bool _isRecordsLoading = true;
  Map<String, dynamic> _stats = {'total': 0, 'win': 0, 'rate': '0%', 'title': '暂无'};

  @override
  void initState() {
    super.initState();
    _checkFriendRequests();
    _loadUserPoints();
    _loadChallengeRecords();
  }

  Future<void> _loadChallengeRecords() async {
    setState(() => _isRecordsLoading = true);
    try {
      final response = await ApiManager.instance.getChallengeRecords(1, 5);
      if (response['code'] == 200) {
        setState(() {
          _challengeRecords = response['data']['list'];
          _isRecordsLoading = false;
          
          // 计算统计数据
          int total = response['data']['total'] ?? 0;
          int win = _challengeRecords.where((r) => r['settleResult'] == '胜').length;
          // 这里的win只是当前页的，实际应该从后端获取完整统计，暂时简化
          double rate = total > 0 ? (win / total * 100) : 0;
          
          _stats = {
            'total': total,
            'win': win,
            'rate': '${rate.toStringAsFixed(0)}%',
            'title': total > 10 ? '挑战达人' : (total > 0 ? '成长先锋' : '新手'),
          };
        });
      }
    } catch (e) {
      print('加载挑战记录失败: $e');
      setState(() => _isRecordsLoading = false);
    }
  }

  Future<void> _loadUserPoints() async {
    setState(() => _isPointsLoading = true);
    try {
      final authManager = AuthManager.instance;
      final currentUser = authManager.currentUser;
      if (currentUser != null) {
        final userId = (currentUser.userId ?? currentUser.id).toString();
        // 获取宠物列表以获取选中的宠物ID
        final petListRes = await ApiManager.instance.getPetList(userId);
        
        if (petListRes['code'] == 200) {
          final selectedPetId = petListRes['data']['selectedPetId'];
          if (selectedPetId != null) {
            final response = await ApiManager.instance.getIncentiveCore(userId, selectedPetId.toString());
            if (response['code'] == 200) {
              setState(() {
                _userPoints = response['data']['integral'];
              });
            }
          }
        }
      }
    } catch (e) {
      print('加载挑战中心积分失败: $e');
    } finally {
      setState(() => _isPointsLoading = false);
    }
  }

  Future<void> _checkFriendRequests() async {
    // 模拟检查未读好友请求
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _hasUnreadRequests = true;
      _unreadRequestCount = 2;
    });
  }

  void _openFriendManagement() {
    // 打开好友管理页面
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const FriendManagementPage()),
    );
  }

  void _openRandomMatch() {
    // 打开随机匹配页面
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const RandomMatchPage()),
    );
  }

  void _openFriendChallenge() {
    // 打开好友挑战页面
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const FriendChallengePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('挑战中心'),
        backgroundColor: Colors.pinkAccent,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.people_alt),
                onPressed: _openFriendManagement,
              ),
              if (_hasUnreadRequests)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadRequestCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 挑战模式选择
            const Text('挑战模式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildChallengeModeCard(
                    title: '随机匹配',
                    description: '匹配真实用户和NPC，公平比拼成长值',
                    icon: Icons.group,
                    color: Colors.blue,
                    onTap: _openRandomMatch,
                  );
                } else {
                  return _buildChallengeModeCard(
                    title: '好友挑战',
                    description: '邀请好友进行成长比拼，奖励更丰厚',
                    icon: Icons.person_add,
                    color: Colors.green,
                    onTap: _openFriendChallenge,
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // 积分信息
            const Text('我的积分', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text('当前可用积分', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 8),
                      _isPointsLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('$_userPoints', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 挑战统计
            const Text('挑战统计', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('总挑战', '${_stats['total']}'),
                  _buildStatItem('获胜', '${_stats['win']}'),
                  _buildStatItem('胜率', '${_stats['rate']}'),
                  _buildStatItem('称号', '${_stats['title']}'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 最近挑战
            const Text('最近挑战', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildChallengeRecordsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeRecordsList() {
    if (_isRecordsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_challengeRecords.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('暂无挑战记录', style: TextStyle(color: Colors.grey)),
      ));
    }
    return Column(
      children: _challengeRecords.map((record) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _buildRecentChallengeItem(
          opponent: record['opponentNickname'] ?? '未知',
          result: record['settleResult'] ?? '平',
          score: '-', // 后端记录接口暂未返回具体分数，显示占位
          opponentScore: '-',
          time: record['settleTime'] ?? record['createTime'] ?? '',
        ),
      )).toList(),
    );
  }

  Widget _buildChallengeModeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(icon, size: 32, color: color),
              alignment: Alignment.center,
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentChallengeItem({
    required String opponent,
    required String result,
    required String score,
    required String opponentScore,
    required String time,
  }) {
    Color resultColor = result == '胜' ? Colors.green : result == '平' ? Colors.grey : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.person, color: Colors.grey),
            alignment: Alignment.center,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opponent, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(result, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: resultColor)),
              const SizedBox(height: 4),
              Text('$score : $opponentScore', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// 好友管理页面
class FriendManagementPage extends StatefulWidget {
  const FriendManagementPage({Key? key}) : super(key: key);

  @override
  State<FriendManagementPage> createState() => _FriendManagementPageState();
}

class _FriendManagementPageState extends State<FriendManagementPage> {
  final SocialChallengeManager _socialManager = SocialChallengeManager.instance;
  List<FriendRequest> _friendRequests = [];
  List<Friend> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendData();
  }

  Future<void> _loadFriendData() async {
    try {
      // 获取当前用户
      final authManager = AuthManager.instance;
      final currentUser = authManager.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 获取用户的宠物ID
      final petId = currentUser.petId?.toString() ?? '1';

      // 调用后端API获取好友申请列表
      final requestsResponse = await ApiManager.instance.getFriendRequests(
        currentUser.userId?.toString() ?? ''
      );

      // 调用后端API获取好友列表
      final friendsResponse = await ApiManager.instance.getFriendList(
        currentUser.userId?.toString() ?? '',
        petId
      );

      setState(() {
        if (requestsResponse['code'] == 200) {
          _friendRequests = (requestsResponse['data']['requests'] as List).map((request) => 
            FriendRequest(
              id: request['id'],
              nickname: request['senderNickname'],
              level: 1,
              avatar: ''
            )
          ).toList();
        } else {
          _friendRequests = [];
        }
        
        // 从API获取好友列表
        if (friendsResponse['code'] == 200) {
          _friends = (friendsResponse['data']['friends'] as List).map((friend) => 
            Friend(
              id: friend['userId'].toString(),
              nickname: friend['nickname'],
              level: friend['level'],
              avatar: friend['avatar'] ?? '',
              isOnline: friend['isOnline'] ?? false,
              lastOnline: friend['lastOnline'] != null ? _formatLastOnline(friend['lastOnline']) : '',
              petGrowthValue: friend['petGrowthValue'] ?? 0,
              petName: friend['petName'] ?? '未命名宠物',
              petAvatar: friend['petAvatar'] ?? '',
              petType: friend['petType'] ?? 1,
              abilityLevel: friend['abilityLevel'] ?? 'D'
            )
          ).toList();
        } else {
          _friends = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      print('加载好友数据失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatLastOnline(dynamic lastOnline) {
    if (lastOnline == null) return '';
    try {
      final dateTime = DateTime.parse(lastOnline.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return '刚刚';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}分钟前';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}小时前';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}天前';
      } else {
        return '${dateTime.month}月${dateTime.day}日';
      }
    } catch (e) {
      return '';
    }
  }

  Future<void> _acceptFriendRequest(FriendRequest request) async {
    try {
      // 获取当前用户
      final authManager = AuthManager.instance;
      final currentUser = authManager.currentUser;
      if (currentUser == null) {
        return;
      }

      // 调用后端API接受好友申请
      final response = await ApiManager.instance.acceptFriendRequest(
        currentUser.userId?.toString() ?? '',
        '1', // 固定petId，实际应该从用户数据中获取
        request.id
      );

      if (response['code'] == 200) {
        setState(() {
          _friendRequests.remove(request);
          _friends.add(Friend(
            id: request.id,
            nickname: request.nickname,
            level: request.level,
            avatar: request.avatar,
            isOnline: true,
            petGrowthValue: 0,
          ));
        });
      }
    } catch (e) {
      print('接受好友申请失败: $e');
    }
  }

  Future<void> _rejectFriendRequest(FriendRequest request) async {
    try {
      // 获取当前用户
      final authManager = AuthManager.instance;
      final currentUser = authManager.currentUser;
      if (currentUser == null) {
        return;
      }

      // 调用后端API拒绝好友申请
      final response = await ApiManager.instance.rejectFriendRequest(
        currentUser.userId?.toString() ?? '',
        request.id
      );

      if (response['code'] == 200) {
        setState(() {
          _friendRequests.remove(request);
        });
      }
    } catch (e) {
      print('拒绝好友申请失败: $e');
    }
  }

  void _openAddFriend() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const AddFriendPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('好友管理'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: '好友列表'),
                Tab(text: '好友申请'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // 好友列表
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: _openAddFriend,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('添加好友'),
                        ),
                      ),
                      Expanded(
                        child: _friends.isEmpty
                            ? const Center(child: Text('暂无好友，点击添加好友'))
                            : ListView.builder(
                                itemCount: _friends.length,
                                itemBuilder: (context, index) {
                                  final friend = _friends[index];
                                  return _buildFriendItem(friend);
                                },
                              ),
                      ),
                    ],
                  ),
                  // 好友申请
                  _friendRequests.isEmpty
                      ? const Center(child: Text('暂无好友申请'))
                      : ListView.builder(
                          itemCount: _friendRequests.length,
                          itemBuilder: (context, index) {
                            final request = _friendRequests[index];
                            return _buildFriendRequestItem(request);
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendItem(Friend friend) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showFriendDetail(friend);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: friend.avatar.isNotEmpty ? NetworkImage(friend.avatar) : null,
                    child: friend.avatar.isEmpty ? Text(friend.nickname.isNotEmpty ? friend.nickname[0] : '?', style: const TextStyle(fontSize: 20)) : null,
                    backgroundColor: friend.avatar.isEmpty ? Colors.grey : null,
                  ),
                  if (friend.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          friend.nickname,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.pink[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Lv.${friend.level}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.pink[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (friend.isNPC)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Chip(
                              label: const Text('NPC'),
                              labelStyle: const TextStyle(fontSize: 10),
                              backgroundColor: Colors.grey[200],
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.pets,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          friend.petName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          friend.abilityLevel == 'S' 
                            ? Icons.star 
                            : friend.abilityLevel == 'A' 
                              ? Icons.star_half 
                              : Icons.star_border,
                          size: 14,
                          color: friend.abilityLevel == 'S' 
                            ? Colors.red 
                            : friend.abilityLevel == 'A' 
                              ? Colors.orange 
                              : Colors.grey,
                        ),
                        Text(
                          friend.abilityLevel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      friend.isOnline ? '在线' : (friend.lastOnline ?? '离线'),
                      style: TextStyle(
                        fontSize: 11,
                        color: friend.isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      _challengeFriend(friend);
                    },
                    icon: const Icon(Icons.sports_martial_arts),
                    color: Colors.pinkAccent,
                    tooltip: '发起挑战',
                  ),
                  IconButton(
                    onPressed: () {
                      _showFriendDetail(friend);
                    },
                    icon: const Icon(Icons.info_outline),
                    color: Colors.blue,
                    tooltip: '查看详情',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFriendDetail(Friend friend) async {
    try {
      final response = await ApiManager.instance.getUserDetail(friend.id);
      if (response['code'] == 200) {
        showDialog(
          context: context,
          builder: (context) => UserDetailDialog(userDetail: response['data']),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取好友信息失败: ${response['msg']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取好友信息失败: $e')),
      );
    }
  }

  void _challengeFriend(Friend friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeDetailPage(
          opponentId: friend.id,
          opponentNickname: friend.nickname,
        ),
      ),
    );
  }

  Widget _buildFriendRequestItem(FriendRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(request.avatar),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.nickname, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('等级: ${request.level}', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () async => await _acceptFriendRequest(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  child: const Text('接受', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async => await _rejectFriendRequest(request),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  child: const Text('拒绝', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// 添加好友页面
class AddFriendPage extends StatefulWidget {
  const AddFriendPage({Key? key}) : super(key: key);

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _userDetail;

  Future<void> _searchAndAddFriend() async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入好友昵称')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 获取当前用户
      final authManager = AuthManager.instance;
      final currentUser = authManager.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('用户未登录')),
        );
        return;
      }

      // 调用后端API发送好友申请
      final response = await ApiManager.instance.addFriend(
        currentUser.userId?.toString() ?? '',
        '1',
        _nicknameController.text
      );

      if (response['code'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('好友申请发送成功！')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加好友失败: ${response['msg']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('添加好友失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUser() async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入好友昵称')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _userDetail = null;
    });

    try {
      // 获取当前用户
      final authManager = AuthManager.instance;
      final currentUser = authManager.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('用户未登录')),
        );
        return;
      }

      // 先查找用户ID
      final userResponse = await ApiManager.instance.getUserInfo();
      if (userResponse['code'] != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('获取用户信息失败')),
        );
        return;
      }

      // 这里需要实现一个根据昵称查找用户的API
      // 暂时使用模拟数据
      setState(() {
        _userDetail = {
          'user': {
            'nickname': _nicknameController.text,
            'avatar': '',
            'isOnline': true,
            'challengeWin': 10,
            'challengeLose': 5,
            'challengeScore': 1200
          },
          'pet': {
            'petName': '小萌宠',
            'petAvatar': '',
            'level': 15,
            'exp': 1250,
            'expThreshold': 2000,
            'nutrition': 80,
            'happiness': 75,
            'intimacy': 60,
            'skillPoint': 5,
            'abilityLevel': 'A',
            'petDesc': '一只可爱的小萌宠'
          },
          'social': {
            'likeNum': 25,
            'helpNum': 10,
            'beLikedNum': 30,
            'beHelpedNum': 15
          },
          'incentive': {
            'integral': 500,
            'integralGet': 800,
            'integralConsume': 300,
            'chestUnlock': ['basic', 'elite'],
            'achievementUnlock': ['first_win', 'level_10']
          },
          'evaluationCalc': {
            'taskCompletionCount': 50,
            'totalScore': 4500
          }
        };
      });

      // 自动显示用户详情
      _showUserDetail();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('查找用户失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showUserDetail() {
    if (_userDetail == null) return;

    showDialog(
      context: context,
      builder: (context) => UserDetailDialog(userDetail: _userDetail!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加好友'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '搜索添加好友',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '输入宠物昵称搜索好友，添加后可发起挑战',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '好友昵称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _searchUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text('搜索中...'),
                            ],
                          )
                        : const Text('查看'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _searchAndAddFriend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('发送申请'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// 随机匹配页面
class RandomMatchPage extends StatefulWidget {
  const RandomMatchPage({Key? key}) : super(key: key);

  @override
  State<RandomMatchPage> createState() => _RandomMatchPageState();
}

class _RandomMatchPageState extends State<RandomMatchPage> {
  int _selectedPeriod = 7; // 默认7天
  bool _isMatching = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Friend? _matchedOpponent;

  // 虚拟对手数据
  final List<Friend> _virtualOpponents = [
    Friend(id: '1', nickname: '流浪的风', level: 12, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 1050),
    Friend(id: '2', nickname: '夏日柠檬', level: 15, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 1250),
    Friend(id: '3', nickname: '星际旅行者', level: 18, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 1450),
    Friend(id: '4', nickname: '梦想家', level: 10, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 850),
    Friend(id: '5', nickname: '夜猫子', level: 14, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 1150),
    Friend(id: '6', nickname: '阳光女孩', level: 16, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 1350),
    Friend(id: '7', nickname: '冒险家', level: 13, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 950),
    Friend(id: '8', nickname: '文艺青年', level: 17, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 1550),
    Friend(id: '9', nickname: '深海蓝鲸', level: 9, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 750),
    Friend(id: '10', nickname: '云端漫步', level: 11, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 950),
    Friend(id: '11', nickname: '森林守护者', level: 19, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 1650),
    Friend(id: '12', nickname: '星际探险家', level: 20, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 1750),
    Friend(id: '13', nickname: '月光女神', level: 8, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 650),
    Friend(id: '14', nickname: '火焰战士', level: 21, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 1850),
    Friend(id: '15', nickname: '冰雪皇后', level: 7, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 550),
    Friend(id: '16', nickname: '雷霆战将', level: 22, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 1950),
    Friend(id: '17', nickname: '风之使者', level: 6, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 450),
    Friend(id: '18', nickname: '地之守护者', level: 23, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 2050),
    Friend(id: '19', nickname: '水之精灵', level: 5, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 350),
    Friend(id: '20', nickname: '火之凤凰', level: 24, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 2150),
    Friend(id: '21', nickname: '光明使者', level: 4, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 250),
    Friend(id: '22', nickname: '黑暗骑士', level: 25, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 2250),
    Friend(id: '23', nickname: '智慧老者', level: 3, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 150),
    Friend(id: '24', nickname: '青春少女', level: 26, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 2350),
    Friend(id: '25', nickname: '神秘访客', level: 2, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 50),
    Friend(id: '26', nickname: '时空旅行者', level: 27, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 2450),
    Friend(id: '27', nickname: '远古守护者', level: 1, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 0),
    Friend(id: '28', nickname: '未来战士', level: 28, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 2550),
    Friend(id: '29', nickname: '星际商人', level: 29, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 2650),
    Friend(id: '30', nickname: '宇宙探险家', level: 30, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 2750),
    Friend(id: '31', nickname: '银河守护者', level: 31, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 2850),
    Friend(id: '32', nickname: '星云漫步者', level: 32, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 2950),
    Friend(id: '33', nickname: '黑洞猎手', level: 33, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 3050),
    Friend(id: '34', nickname: '白洞守护者', level: 34, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 3150),
    Friend(id: '35', nickname: '暗物质学者', level: 35, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 3250),
    Friend(id: '36', nickname: '反物质研究员', level: 36, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 3350),
    Friend(id: '37', nickname: '量子物理学家', level: 37, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 3450),
    Friend(id: '38', nickname: '相对论专家', level: 38, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 3550),
    Friend(id: '39', nickname: '宇宙学家', level: 39, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 3650),
    Friend(id: '40', nickname: '天体物理学家', level: 40, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 3750),
    Friend(id: '41', nickname: '星系制图师', level: 41, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 3850),
    Friend(id: '42', nickname: '星球改造者', level: 42, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 3950),
    Friend(id: '43', nickname: '外星生物学家', level: 43, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 4050),
    Friend(id: '44', nickname: '星际语言学家', level: 44, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 4150),
    Friend(id: '45', nickname: '太空工程师', level: 45, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 4250),
    Friend(id: '46', nickname: '宇宙建筑师', level: 46, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 4350),
    Friend(id: '47', nickname: '量子工程师', level: 47, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 4450),
    Friend(id: '48', nickname: '时间物理学家', level: 48, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 4550),
    Friend(id: '49', nickname: '空间物理学家', level: 49, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 4650),
    Friend(id: '50', nickname: '多维空间探索者', level: 50, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 4750),
    Friend(id: '51', nickname: '平行宇宙旅行者', level: 51, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 4850),
    Friend(id: '52', nickname: '宇宙意识觉醒者', level: 52, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 4950),
    Friend(id: '53', nickname: '星际文明研究者', level: 53, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 5050),
    Friend(id: '54', nickname: '宇宙法则守护者', level: 54, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 5150),
    Friend(id: '55', nickname: '时空管理员', level: 55, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 5250),
    Friend(id: '56', nickname: '宇宙平衡者', level: 56, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 5350),
    Friend(id: '57', nickname: '混沌秩序维护者', level: 57, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 5450),
    Friend(id: '58', nickname: '宇宙命运编织者', level: 58, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 5550),
    Friend(id: '59', nickname: '终极存在', level: 59, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 5650),
    Friend(id: '60', nickname: '宇宙起源探索者', level: 60, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 5750),
    Friend(id: '61', nickname: '银河之心', level: 61, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 5850),
    Friend(id: '62', nickname: '星云之眼', level: 62, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 5950),
    Friend(id: '63', nickname: '黑洞之魂', level: 63, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 6050),
    Friend(id: '64', nickname: '白洞之光', level: 64, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 6150),
    Friend(id: '65', nickname: '暗物质之影', level: 65, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 6250),
    Friend(id: '66', nickname: '反物质之辉', level: 66, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 6350),
    Friend(id: '67', nickname: '量子之舞', level: 67, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 6450),
    Friend(id: '68', nickname: '相对论之美', level: 68, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 6550),
    Friend(id: '69', nickname: '宇宙之音', level: 69, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 6650),
    Friend(id: '70', nickname: '天体之韵', level: 70, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 6750),
    Friend(id: '71', nickname: '星系之语', level: 71, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 6850),
    Friend(id: '72', nickname: '星球之歌', level: 72, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 6950),
    Friend(id: '73', nickname: '外星之秘', level: 73, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 7050),
    Friend(id: '74', nickname: '星际之桥', level: 74, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 7150),
    Friend(id: '75', nickname: '太空之翼', level: 75, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 7250),
    Friend(id: '76', nickname: '宇宙之帆', level: 76, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 7350),
    Friend(id: '77', nickname: '量子之海', level: 77, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 7450),
    Friend(id: '78', nickname: '时间之河', level: 78, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 7550),
    Friend(id: '79', nickname: '空间之网', level: 79, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 7650),
    Friend(id: '80', nickname: '多维之境', level: 80, avatar: '', isOnline: true, isNPC: true, petGrowthValue: 7750),
  ];

  void _startMatching() {
    setState(() {
      _isMatching = true;
    });

    // 模拟匹配过程
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isMatching = false;
        // 随机选择一个虚拟对手
        final random = Random();
        _matchedOpponent = _virtualOpponents[random.nextInt(_virtualOpponents.length)];
      });
    });
  }

  void _searchOpponent() {
    setState(() {
      _isSearching = true;
    });

    // 模拟搜索过程
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isSearching = false;
        // 根据搜索内容筛选对手
        final searchText = _searchController.text.toLowerCase();
        if (searchText.isNotEmpty) {
          final filteredOpponents = _virtualOpponents.where((opponent) => 
            opponent.nickname.toLowerCase().contains(searchText)
          ).toList();
          if (filteredOpponents.isNotEmpty) {
            _matchedOpponent = filteredOpponents[0];
          } else {
            // 搜索不到时随机匹配
            final random = Random();
            _matchedOpponent = _virtualOpponents[random.nextInt(_virtualOpponents.length)];
          }
        } else {
          // 空搜索时随机匹配
          final random = Random();
          _matchedOpponent = _virtualOpponents[random.nextInt(_virtualOpponents.length)];
        }
      });
    });
  }

  void _confirmMatch() {
    if (_matchedOpponent != null) {
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const ChallengeDetailPage()),
      );
    }
  }

  void _cancelMatch() {
    setState(() {
      _matchedOpponent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('随机匹配挑战'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索栏
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '搜索对手名字',
                hintText: '输入对手昵称',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (_) => _searchOpponent(),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isSearching ? null : _searchOpponent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: _isSearching 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                    : const Text('搜索对手'),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            
            const Text('选择挑战周期', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPeriodOption(7),
                _buildPeriodOption(30),
                _buildPeriodOption(0, isCustom: true),
              ],
            ),
            const SizedBox(height: 32),
            const Text('挑战规则', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. 系统将为你匹配真实用户或NPC对手'),
                  const Text('2. 以成长值为核心比拼指标'),
                  const Text('3. 获胜可获得经验+50、进化道具×3等奖励'),
                  const Text('4. 失败/平局均有保底奖励'),
                  const Text('5. 连续3次获胜解锁"成长先锋"称号'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            if (!_isMatching && _matchedOpponent == null)
              Center(
                child: ElevatedButton(
                  onPressed: _isMatching ? null : _startMatching,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: _isMatching
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text('匹配中...'),
                          ],
                        )
                      : const Text('开始匹配'),
                ),
              )
            else if (_isMatching)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('正在匹配对手...'),
                  ],
                ),
              )
            else if (_matchedOpponent != null)
              Column(
                children: [
                  const Text(
                    '匹配成功！',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(_matchedOpponent!.avatar),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_matchedOpponent!.nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('等级：${_matchedOpponent!.level}'),
                                Text('宠物成长值：${_matchedOpponent!.petGrowthValue}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _cancelMatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _confirmMatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text('确认挑战'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodOption(int days, {bool isCustom = false}) {
    bool isSelected = _selectedPeriod == days;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = days;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.pinkAccent : Colors.grey),
        ),
        child: Text(
          isCustom ? '自定义' : '$days天',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// 好友挑战页面
class FriendChallengePage extends StatefulWidget {
  const FriendChallengePage({Key? key}) : super(key: key);

  @override
  State<FriendChallengePage> createState() => _FriendChallengePageState();
}

class _FriendChallengePageState extends State<FriendChallengePage> {
  List<Friend> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      // 获取当前用户
      final authManager = AuthManager.instance;
      final currentUser = authManager.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 获取用户的宠物ID
      final petId = currentUser.petId?.toString() ?? '1';

      // 调用后端API获取好友列表
      final friendsResponse = await ApiManager.instance.getFriendList(
        currentUser.userId?.toString() ?? '',
        petId
      );

      setState(() {
        if (friendsResponse['code'] == 200) {
          _friends = (friendsResponse['data']['friends'] as List).map((friend) => 
            Friend(
              id: friend['userId'].toString(),
              nickname: friend['nickname'],
              level: friend['level'],
              avatar: friend['avatar'] ?? '',
              isOnline: friend['isOnline'] ?? false,
              lastOnline: friend['lastOnline'] != null ? _formatLastOnline(friend['lastOnline']) : '',
              petGrowthValue: friend['petGrowthValue'] ?? 0,
              petName: friend['petName'] ?? '未命名宠物',
              petAvatar: friend['petAvatar'] ?? '',
              petType: friend['petType'] ?? 1,
              abilityLevel: friend['abilityLevel'] ?? 'D'
            )
          ).toList();
        } else {
          _friends = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      print('加载好友数据失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatLastOnline(dynamic lastOnline) {
    if (lastOnline == null) return '';
    try {
      final dateTime = DateTime.parse(lastOnline.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return '刚刚';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}分钟前';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}小时前';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}天前';
      } else {
        return '${dateTime.month}月${dateTime.day}日';
      }
    } catch (e) {
      return '';
    }
  }

  void _challengeFriend(Friend friend) {
    // 跳转到挑战详情页面
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const ChallengeDetailPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('好友挑战'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择好友发起挑战', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _friends.isEmpty
                ? const Center(child: Text('暂无好友，先添加好友'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(friend.avatar),
                                  ),
                                  if (friend.isOnline)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(friend.nickname, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text('等级: ${friend.level}'),
                                    Text(friend.isOnline ? '在线' : '离线 ${friend.lastOnline}'),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _challengeFriend(friend),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                ),
                                child: const Text('发起挑战'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

// 挑战详情页面
class ChallengeDetailPage extends StatefulWidget {
  final String? opponentId;
  final String? opponentNickname;

  const ChallengeDetailPage({Key? key, this.opponentId, this.opponentNickname}) : super(key: key);

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  bool _isStarted = false;
  bool _isCompleted = false;
  int _challengeDay = 0;
  int _totalDays = 7;

  // 宠物养成进度数据
  final Map<String, dynamic> _myPet = {
    'name': '我的宠物',
    'level': 10,
    'exp': 65,
    'nutrition': 85,
    'happiness': 90,
    'growthValue': 1250,
    'form': '成年期',
  };

  final Map<String, dynamic> _opponentPet = {
    'name': '小明的宠物',
    'level': 12,
    'exp': 45,
    'nutrition': 78,
    'happiness': 82,
    'growthValue': 1180,
    'form': '成年期',
  };

  // 挑战进度数据
  final List<Map<String, dynamic>> _challengeProgress = [
    {'day': 1, 'myGrowth': 150, 'opponentGrowth': 130, 'status': 'completed'},
    {'day': 2, 'myGrowth': 120, 'opponentGrowth': 140, 'status': 'completed'},
    {'day': 3, 'myGrowth': 180, 'opponentGrowth': 120, 'status': 'completed'},
    {'day': 4, 'myGrowth': 0, 'opponentGrowth': 0, 'status': 'pending'},
    {'day': 5, 'myGrowth': 0, 'opponentGrowth': 0, 'status': 'pending'},
    {'day': 6, 'myGrowth': 0, 'opponentGrowth': 0, 'status': 'pending'},
    {'day': 7, 'myGrowth': 0, 'opponentGrowth': 0, 'status': 'pending'},
  ];

  void _startChallenge() {
    setState(() {
      _isStarted = true;
    });
  }

  void _completeChallenge() async {
    setState(() {
      _isCompleted = true;
    });

    try {
      // 模拟挑战完成后的积分奖励逻辑
      // 在实际应用中，这应该由后端在结算时自动处理
      // 这里为了演示前端发送请求，我们调用一个同步接口
      final authManager = AuthManager.instance;
      final currentUser = authManager.currentUser;
      if (currentUser != null) {
        final userId = (currentUser.userId ?? currentUser.id).toString();
        
        // 模拟发送挑战完成数据
        final response = await ApiManager.instance.syncChallengeData(
          widget.opponentId ?? 'CH' + DateTime.now().millisecondsSinceEpoch.toString(),
          1, // 已完成
          30, // 耗时
          85, // 任务得分
        );

        if (response['code'] == 200) {
          // 挑战数据同步成功，通常结算会异步进行或在另一个接口触发
          // 这里我们手动刷新一下全局积分，以确保 UI 同步
          if (mounted) {
            await Provider.of<AppStateProvider>(context, listen: false).loadUserPoints();
          }
        }
      }
    } catch (e) {
      print('同步挑战数据失败: $e');
    }

    // 显示完成提示
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('挑战完成！'),
          content: const Text('挑战数据已同步，等待对手完成挑战后进行结算。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('挑战详情'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 对手信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      child: const Text('明', style: TextStyle(fontSize: 20)),
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('小明', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text('等级：15'),
                          const Text('挑战周期：7天'),
                        ],
                      ),
                    ),
                    Chip(
                      label: const Text('匹配成功'),
                      backgroundColor: Colors.green[100],
                      labelStyle: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 宠物养成进度对比
            const Text('宠物养成进度', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 表头
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('属性')),
                        Expanded(flex: 3, child: Text(_myPet['name'], textAlign: TextAlign.center)),
                        Expanded(flex: 3, child: Text(_opponentPet['name'], textAlign: TextAlign.center)),
                      ],
                    ),
                    const Divider(),
                    // 数据行
                    _buildStatRow('等级', _myPet['level'], _opponentPet['level']),
                    _buildStatRow('经验', '${_myPet['exp']}%', '${_opponentPet['exp']}%'),
                    _buildStatRow('营养值', '${_myPet['nutrition']}%', '${_opponentPet['nutrition']}%'),
                    _buildStatRow('快乐度', '${_myPet['happiness']}%', '${_opponentPet['happiness']}%'),
                    _buildStatRow('形态', _myPet['form'], _opponentPet['form']),
                    _buildStatRow('成长值', _myPet['growthValue'], _opponentPet['growthValue'], isHighlight: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 挑战进度
            const Text('挑战进度', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('当前进度'),
                        Text('$_challengeDay/$_totalDays 天'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _challengeDay / _totalDays,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                    ),
                    const SizedBox(height: 24),
                    // 每日进度
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _challengeProgress.length,
                      itemBuilder: (context, index) {
                        final day = _challengeProgress[index];
                        return _buildDayProgress(day);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 挑战规则
            const Text('挑战规则', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. 比拼期间，双方宠物的成长值变化'),
                  const Text('2. 成长值 = 经验增量得分 + 营养值稳定得分 + 技能点增量得分 + 形态进阶加分'),
                  const Text('3. 获胜奖励：经验+50、进化道具×3'),
                  const Text('4. 失败/平局：经验+20、进化道具×1'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 操作按钮
            if (!_isStarted)
              Center(
                child: ElevatedButton(
                  onPressed: _startChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('开始挑战'),
                ),
              )
            else if (!_isCompleted)
              Center(
                child: ElevatedButton(
                  onPressed: _completeChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('完成挑战'),
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    const Text('挑战已完成，等待对手...', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic myValue, dynamic opponentValue, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 3,
            child: Text(
              '$myValue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? Colors.pinkAccent : Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '$opponentValue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? Colors.pinkAccent : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayProgress(Map<String, dynamic> day) {
    Color color;
    String statusText;

    switch (day['status']) {
      case 'completed':
        color = Colors.green;
        statusText = '已完成';
        break;
      case 'pending':
        color = Colors.grey;
        statusText = '待完成';
        break;
      default:
        color = Colors.grey;
        statusText = '待完成';
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text('第${day['day']}天', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text('我: ${day['myGrowth']}', style: TextStyle(fontSize: 10, color: color)),
          Text('对: ${day['opponentGrowth']}', style: TextStyle(fontSize: 10, color: color)),
          const SizedBox(height: 4),
          Text(statusText, style: TextStyle(fontSize: 8, color: color)),
        ],
      ),
    );
  }
}

// 数据模型
class Friend {
  final String id;
  final String nickname;
  final int level;
  final String avatar;
  final bool isOnline;
  final String? lastOnline;
  final bool isNPC;
  final int petGrowthValue;
  final String petName;
  final String petAvatar;
  final int petType;
  final String abilityLevel;

  Friend({
    required this.id,
    required this.nickname,
    required this.level,
    required this.avatar,
    this.isOnline = false,
    this.lastOnline,
    this.isNPC = false,
    required this.petGrowthValue,
    this.petName = '未命名宠物',
    this.petAvatar = '',
    this.petType = 1,
    this.abilityLevel = 'D',
  });
}

class FriendRequest {
  final String id;
  final String nickname;
  final int level;
  final String avatar;

  FriendRequest({
    required this.id,
    required this.nickname,
    required this.level,
    required this.avatar,
  });
}

// 用户详情对话框
class UserDetailDialog extends StatelessWidget {
  final Map<String, dynamic> userDetail;

  const UserDetailDialog({Key? key, required this.userDetail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = userDetail['user'];
    final pet = userDetail['pet'];
    final social = userDetail['social'];
    final incentive = userDetail['incentive'];
    final evaluationCalc = userDetail['evaluationCalc'];

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头部
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: user['avatar'] != null && user['avatar'].isNotEmpty ? NetworkImage(user['avatar']) : null,
                    child: user['avatar'] == null || user['avatar'].isEmpty ? Text(user['nickname'] != null && user['nickname'].isNotEmpty ? user['nickname'][0] : '?', style: const TextStyle(fontSize: 24, color: Colors.white)) : null,
                    backgroundColor: user['avatar'] == null || user['avatar'].isEmpty ? Colors.grey : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['nickname'] ?? '未知用户',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: user['isOnline'] ? Colors.green : Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user['isOnline'] ? '在线' : '离线',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '挑战积分: ${user['challengeScore'] ?? 0}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 挑战记录
                    _buildSectionTitle('挑战记录'),
                    _buildChallengeStats(user),
                    const SizedBox(height: 20),

                    // 宠物信息
                    if (pet != null) ...[
                      _buildSectionTitle('宠物信息'),
                      _buildPetInfo(pet),
                      const SizedBox(height: 20),
                    ],

                    // 社交数据
                    if (social != null) ...[
                      _buildSectionTitle('社交数据'),
                      _buildSocialStats(social),
                      const SizedBox(height: 20),
                    ],

                    // 成就信息
                    if (incentive != null) ...[
                      _buildSectionTitle('成就信息'),
                      _buildAchievementInfo(incentive, evaluationCalc),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.pinkAccent,
        ),
      ),
    );
  }

  Widget _buildChallengeStats(Map<String, dynamic> user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('胜利', '${user['challengeWin'] ?? 0}', Colors.green),
            _buildStatItem('失败', '${user['challengeLose'] ?? 0}', Colors.red),
            _buildStatItem('积分', '${user['challengeScore'] ?? 0}', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPetInfo(Map<String, dynamic> pet) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: pet['petAvatar'] != null && pet['petAvatar'].isNotEmpty
                      ? NetworkImage(pet['petAvatar'])
                      : null,
                  child: pet['petAvatar'] == null || pet['petAvatar'].isEmpty
                      ? const Icon(Icons.pets, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet['petName'] ?? '未命名宠物',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '等级 ${pet['level'] ?? 1} | ${pet['abilityLevel'] ?? 'D'}级能力',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar('经验', pet['exp'] ?? 0, pet['expThreshold'] ?? 100),
            const SizedBox(height: 8),
            _buildProgressBar('营养', pet['nutrition'] ?? 0, 100),
            const SizedBox(height: 8),
            _buildProgressBar('快乐', pet['happiness'] ?? 0, 100),
            const SizedBox(height: 8),
            _buildProgressBar('亲密度', pet['intimacy'] ?? 0, 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int max) {
    final percentage = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text('$value/$max', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 0.7 ? Colors.green : percentage > 0.3 ? Colors.orange : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialStats(Map<String, dynamic> social) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSocialItem('点赞', social['likeNum'] ?? 0, Icons.thumb_up, Colors.pink),
            _buildSocialItem('助力', social['helpNum'] ?? 0, Icons.handshake, Colors.blue),
            _buildSocialItem('被赞', social['beLikedNum'] ?? 0, Icons.favorite, Colors.red),
            _buildSocialItem('被助', social['beHelpedNum'] ?? 0, Icons.people, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAchievementInfo(Map<String, dynamic> incentive, Map<String, dynamic>? evaluationCalc) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAchievementItem('积分', '${incentive['integral'] ?? 0}', Icons.stars, Colors.amber),
                _buildAchievementItem('任务', '${evaluationCalc?['taskCompletionCount'] ?? 0}', Icons.task_alt, Colors.blue),
                _buildAchievementItem('总分', '${evaluationCalc?['totalScore'] ?? 0}', Icons.emoji_events, Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            const Text('已解锁宝箱', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (incentive['chestUnlock'] as List? ?? []).map((chest) => 
                Chip(
                  label: Text(
                    chest == 'exclusive' ? '专属' : chest == 'elite' ? '精英' : '基础',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: chest == 'exclusive' 
                    ? Colors.purple[100] 
                    : chest == 'elite' 
                      ? Colors.blue[100] 
                      : Colors.grey[100],
                )
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
