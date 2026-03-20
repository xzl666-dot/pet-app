import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/api_manager.dart';
import '../managers/auth_manager.dart';
import '../managers/pet_state_manager.dart';
import '../providers/app_state_provider.dart';

class PointsMallPage extends StatefulWidget {
  final int userPoints;
  final Function(int) onPointsUpdated;

  const PointsMallPage({Key? key, required this.userPoints, required this.onPointsUpdated}) : super(key: key);

  @override
  State<PointsMallPage> createState() => _PointsMallPageState();
}

class _PointsMallPageState extends State<PointsMallPage> {
  List<MallItem> _mallItems = [];
  int _monthlyExchangePoints = 0;

  @override
  void initState() {
    super.initState();
    _initializeMallItems();
  }

  void _initializeMallItems() {
    _mallItems = [
      MallItem(id: 'exp_dan', name: '普通经验丹', price: 10, effect: '宠物经验+20', dailyLimit: 10, stock: 9999),
      MallItem(id: 'advanced_exp_dan', name: '高级经验丹', price: 30, effect: '宠物经验+50', dailyLimit: 5, stock: 9999),
      MallItem(id: 'nutrition_dan', name: '普通营养丹', price: 10, effect: '宠物营养值+20', dailyLimit: 10, stock: 9999),
      MallItem(id: 'advanced_nutrition_dan', name: '高级营养丹', price: 30, effect: '宠物营养值+50', dailyLimit: 5, stock: 9999),
      MallItem(id: 'intimacy_prop', name: '基础亲密度道具', price: 15, effect: '宠物亲密度+10', dailyLimit: 8, stock: 9999),
      MallItem(id: 'advanced_intimacy_prop', name: '进阶亲密度道具', price: 40, effect: '宠物亲密度+20', dailyLimit: 3, stock: 9999),
      MallItem(id: 'skill_book', name: '技能书', price: 20, effect: '宠物技能点+2', dailyLimit: 5, stock: 9999),
      MallItem(id: 'exp_double_card', name: '经验翻倍卡', price: 50, effect: '24小时经验翻倍', dailyLimit: 1, stock: 9999),
      MallItem(id: 'universal_prop', name: '万能道具', price: 100, effect: '兑换任意普通/稀有道具', dailyLimit: 1, stock: 9999),
      MallItem(id: 'growth_package', name: '成长礼包', price: 80, effect: '普通经验丹×3+普通营养丹×3+基础亲密度道具×2', dailyLimit: 1, stock: 9999),
    ];
  }

  Future<void> _exchangeItem(MallItem item) async {
    if (widget.userPoints < item.price) {
      showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          title: const Text('积分不足'),
          content: const Text('您的积分不足，无法兑换此道具'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }

    if (item.dailyLimit <= 0) {
      showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          title: const Text('兑换上限'),
          content: const Text('今日兑换已达到上限'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }

    // 调用后端API进行真实兑换 ( 问题2-2: 积分商城购买后积分变动)
    try {
      final authManager = AuthManager.instance;
      final userId = authManager.currentUser?.userId?.toString() ?? '';
      
      // 获取当前选中的宠物ID
      final petResponse = await ApiManager.instance.getUserInfo();
      final petId = petResponse['data']['petId']?.toString() ?? '1';

      final response = await ApiManager.instance.exchangeItem(userId, petId, item.id, 1);
      
      if (response['code'] == 200) {
        setState(() {
          item.dailyLimit--;
          item.stock--;
          _monthlyExchangePoints += item.price;
        });

        // 更新全局状态中的积分
        widget.onPointsUpdated(widget.userPoints - item.price);
        
        // 刷新用户信息以同步积分
        await AppStateProvider.instance.refreshState();

        // 显示兑换成功提示
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('兑换成功'),
              content: Text('成功兑换${item.name}，积分已扣除'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception(response['msg'] ?? '兑换失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('兑换失败: $e')),
        );
      }
      return;
    }

    // 检查月度福利
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('兑换成功'),
        content: Text('成功兑换${item.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    // 检查月度福利
    if (_monthlyExchangePoints >= 500) {
      showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          title: const Text('月度福利'),
          content: const Text('恭喜您本月累计兑换≥500积分，获得"进化助力礼包"（高级经验丹×2+经验翻倍卡×1）'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('领取'),
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
        title: const Text('积分商城'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 积分信息
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('我的积分', style: TextStyle(fontSize: 16)),
                  Text('${widget.userPoints}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 月度福利提示
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '月度福利：每月累计兑换≥500积分，免费领取"进化助力礼包"（高级经验丹×2+经验翻倍卡×1）',
                      style: TextStyle(color: Colors.orange[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 道具列表
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: _mallItems.length,
                itemBuilder: (context, index) {
                  final item = _mallItems[index];
                  return _buildMallItemCard(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMallItemCard(MallItem item) {
    final canExchange = widget.userPoints >= item.price && item.dailyLimit > 0;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.pink[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 48),
            alignment: Alignment.center,
          ),
          const SizedBox(height: 12),
          Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(item.effect, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${item.price}积分', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
              Text('每日限${item.dailyLimit}个', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: canExchange ? () => _exchangeItem(item) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canExchange ? Colors.pinkAccent : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text('兑换'),
          ),
        ],
      ),
    );
  }
}

class MallItem {
  final String id;
  final String name;
  final int price;
  final String effect;
  int dailyLimit;
  int stock;

  MallItem({required this.id, required this.name, required this.price, required this.effect, required this.dailyLimit, required this.stock});
}
