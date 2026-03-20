import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../screens/npc_challenge_page.dart';
import '../screens/social_challenge_page.dart';

class PetCenterPage extends StatefulWidget {
  const PetCenterPage({Key? key}) : super(key: key);

  @override
  State<PetCenterPage> createState() => _PetCenterPageState();
}

class _PetCenterPageState extends State<PetCenterPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('挑战中心'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // 挑战功能入口
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      // NPC挑战
                      _buildFeatureCard(
                        context,
                        icon: Icons.computer,
                        title: 'NPC挑战',
                        description: '与电脑AI进行对战',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NPCChallengePage()),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // 社交挑战
                      _buildFeatureCard(
                        context,
                        icon: Icons.people,
                        title: '社交挑战',
                        description: '与好友进行对战',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SocialChallengePage()),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // 挑战排行榜
                      _buildFeatureCard(
                        context,
                        icon: Icons.leaderboard,
                        title: '挑战排行榜',
                        description: '查看挑战排名和积分',
                        onTap: () {
                          // 导航到排行榜页面
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('排行榜功能开发中')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建功能卡片
  Widget _buildFeatureCard(
    BuildContext context,
    {required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(28.0),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 36,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.displayLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          softWrap: true,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: Theme.of(context).primaryColor.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
