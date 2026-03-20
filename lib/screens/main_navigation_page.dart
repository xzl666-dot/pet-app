import 'package:flutter/material.dart';
import 'home_page.dart';
import 'task_center_page.dart';
import 'challenge_center_page.dart';
import 'incentive_page.dart';
import 'user_center_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const TaskCenterPage(),
    const ChallengeCenterPage(),
    const IncentivePage(),
    const UserCenterPage(),
  ];

  final List<BottomNavigationBarItem> _items = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: '宠物养成',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.task),
      label: '任务中心',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.emoji_events),
      label: '挑战中心',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.card_giftcard),
      label: '激励',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: '我的',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _items,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        elevation: 8,
        showUnselectedLabels: true,
      ),
    );
  }
}
