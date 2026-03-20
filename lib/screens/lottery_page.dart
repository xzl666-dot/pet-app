import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class LotteryPage extends StatefulWidget {
  final int lotteryChances;
  final Function(int) onLotteryComplete;

  const LotteryPage({Key? key, required this.lotteryChances, required this.onLotteryComplete}) : super(key: key);

  @override
  State<LotteryPage> createState() => _LotteryPageState();
}

class _LotteryPageState extends State<LotteryPage> {
  bool _isSpinning = false;
  int _currentChance = 0;
  String _result = '';
  List<LotteryReward> _rewards = [];
  int _selectedIndex = -1;
  int _consecutiveFails = 0; // 连续未抽中稀有及以上道具的次数

  @override
  void initState() {
    super.initState();
    _initializeRewards();
  }

  void _initializeRewards() {
    _rewards = [
      // 普通档
      LotteryReward(name: '普通经验丹', effect: '宠物经验+20', probability: 0.45, rarity: '普通', color: Colors.grey),
      LotteryReward(name: '普通营养丹', effect: '宠物营养值+20', probability: 0.30, rarity: '普通', color: Colors.grey),
      LotteryReward(name: '基础亲密度道具', effect: '宠物亲密度+5', probability: 0.15, rarity: '普通', color: Colors.grey),
      // 稀有档
      LotteryReward(name: '高级经验丹', effect: '宠物经验+50', probability: 0.06, rarity: '稀有', color: Colors.blue),
      LotteryReward(name: '高级营养丹', effect: '宠物营养值+50', probability: 0.02, rarity: '稀有', color: Colors.blue),
      LotteryReward(name: '进阶亲密度道具', effect: '宠物亲密度+15', probability: 0.01, rarity: '稀有', color: Colors.blue),
      // 史诗档
      LotteryReward(name: '技能书', effect: '宠物技能点+2', probability: 0.009, rarity: '史诗', color: Colors.purple),
      LotteryReward(name: '双倍积分卡', effect: '下次任务积分翻倍', probability: 0.0008, rarity: '史诗', color: Colors.purple),
      LotteryReward(name: '经验翻倍卡', effect: '24小时内宠物经验获取翻倍', probability: 0.0002, rarity: '史诗', color: Colors.purple),
      // 传说档
      LotteryReward(name: '万能道具', effect: '可兑换任意普通/稀有道具', probability: 0.0005, rarity: '传说', color: Colors.orange),
      LotteryReward(name: '技能点礼包', effect: '宠物技能点+10', probability: 0.0003, rarity: '传说', color: Colors.orange),
      LotteryReward(name: '营养值满卡', effect: '立即将宠物营养值恢复至100', probability: 0.0002, rarity: '传说', color: Colors.orange),
    ];
  }

  void _startLottery() {
    if (_isSpinning || _currentChance >= widget.lotteryChances) return;

    setState(() {
      _isSpinning = true;
      _result = '';
      _selectedIndex = -1;
    });

    // 计算概率，应用保底机制
    double rarityProbability = 0.07; // 稀有及以上的基础概率
    double epicProbability = 0.01; // 史诗及以上的基础概率

    if (_consecutiveFails >= 10) {
      rarityProbability = 0.15; // 累计10次未抽中稀有及以上，提升概率
    }
    if (_consecutiveFails >= 20) {
      epicProbability = 0.05; // 累计20次未抽中史诗及以上，提升概率
    }

    // 模拟抽奖过程
    Timer(const Duration(seconds: 3), () {
      final reward = _drawReward(rarityProbability, epicProbability);
      setState(() {
        _result = reward.name;
        _isSpinning = false;
        _currentChance++;
        widget.onLotteryComplete(_currentChance);

        // 检查是否抽中稀有及以上道具
        if (reward.rarity == '普通') {
          _consecutiveFails++;
        } else {
          _consecutiveFails = 0;
        }

        // 显示抽奖结果
        showDialog(
          context: context, 
          builder: (context) => AlertDialog(
            title: const Text('抽奖结果'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('恭喜获得：', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                const SizedBox(height: 16),
                Text(reward.name, style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: reward.color,
                )),
                const SizedBox(height: 8),
                Text(reward.effect, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('稀有度：${reward.rarity}', style: TextStyle(fontSize: 14, color: reward.color)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      });
    });
  }

  LotteryReward _drawReward(double rarityProbability, double epicProbability) {
    final random = Random();
    final chance = random.nextDouble();

    // 应用概率
    if (chance < 0.9) { // 普通档 90%
      return _rewards[random.nextInt(3)]; // 前3个是普通档
    } else if (chance < 0.9 + rarityProbability) { // 稀有档
      return _rewards[3 + random.nextInt(3)]; // 4-6是稀有档
    } else if (chance < 0.9 + rarityProbability + epicProbability) { // 史诗档
      return _rewards[6 + random.nextInt(3)]; // 7-9是史诗档
    } else { // 传说档
      return _rewards[9 + random.nextInt(3)]; // 10-12是传说档
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('幸运抽奖'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 抽奖次数信息
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('剩余抽奖次数', style: TextStyle(fontSize: 16)),
                  Text('${widget.lotteryChances - _currentChance}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 抽奖转盘
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 转盘背景
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(150),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 5,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _isSpinning
                          ? const CircularProgressIndicator(
                              strokeWidth: 10,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('点击开始抽奖', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                if (_result.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text('上次获得：$_result', style: TextStyle(color: Colors.grey[600])),
                                  ),
                              ],
                            ),
                    ),
                    // 抽奖按钮
                    ElevatedButton(
                      onPressed: _isSpinning || _currentChance >= widget.lotteryChances ? null : _startLottery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSpinning || _currentChance >= widget.lotteryChances ? Colors.grey : Colors.pinkAccent,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),
                      ),
                      child: const Text('抽奖', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 奖励说明
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('奖励概率', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._rewards.take(6).map((reward) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(reward.name, style: TextStyle(color: reward.color)),
                          Text('${(reward.probability * 100).toStringAsFixed(2)}%', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  ),
                  const SizedBox(height: 8),
                  Text('* 累计10次未抽中稀有及以上道具，下次抽奖稀有档概率提升至15%', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('* 累计20次未抽中史诗及以上道具，下次抽奖史诗档概率提升至5%', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('* 每日最多抽奖20次', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LotteryReward {
  final String name;
  final String effect;
  final double probability;
  final String rarity;
  final Color color;

  LotteryReward({required this.name, required this.effect, required this.probability, required this.rarity, required this.color});
}
