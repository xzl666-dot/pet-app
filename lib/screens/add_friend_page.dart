import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../managers/auth_manager.dart';
import '../providers/app_state_provider.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({Key? key}) : super(key: key);

  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  // 搜索用户
  Future<void> _searchUser() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final token = AuthManager.instance.currentUser?.token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/social/search-user?keyword=$keyword'),
        headers: {
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          setState(() {
            _searchResults = (data['data']['users'] ?? []) as List;
            _isSearching = false;
          });
        } else {
          setState(() {
            _isSearching = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['msg'] ?? '搜索失败')),
          );
        }
      } else {
        throw Exception('网络请求失败');
      }
    } catch (e) {
      print('搜索用户失败: $e');
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('搜索失败，请重试')),
      );
    }
  }

  // 发送好友申请
  Future<void> _sendFriendRequest(String targetNickname) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = AuthManager.instance.currentUser?.token;
      if (token == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/social/add-friend'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: json.encode({
          'userId': AuthManager.instance.currentUser?.userId?.toString() ?? '',
          'petId': AppStateProvider.instance.currentUser?.petId?.toString() ?? '1', 
          'targetNickname': targetNickname,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('好友申请已发送')),
          );
          // 跳转回好友列表页面
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['msg'])),
          );
        }
      }
    } catch (e) {
      print('发送好友申请失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发送好友申请失败')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加好友'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 搜索栏
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200] ?? Colors.grey)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索好友（昵称/账号）',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: _searchUser,
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[200] ?? Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (value) => _searchUser(),
              ),
            ),
            const SizedBox(height: 24),
            
            // 搜索结果
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '请输入关键词搜索',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '支持搜索好友昵称或账号',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    // 头像
                                    CircleAvatar(
                                      radius: 28,
                                      child: Icon(Icons.person, size: 32, color: Colors.grey[600]),
                                      backgroundColor: Colors.grey[50],
                                      foregroundColor: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 20),
                                    // 信息
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user['nickname'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "${user['major']} ${user['grade']}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 添加按钮
                                    _isLoading
                                        ? const CircularProgressIndicator()
                                        : ElevatedButton(
                                            onPressed: () => _sendFriendRequest(user['nickname']),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text('添加好友'),
                                          ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
