import 'package:flutter/material.dart';
import '../models/task_model.dart';

class FeedbackWidget extends StatefulWidget {
  final TaskModel task;
  final double efficiencyMultiplier;
  final bool isConsecutive;
  final VoidCallback? onDismissed;

  const FeedbackWidget({
    Key? key,
    required this.task,
    this.efficiencyMultiplier = 1.0,
    this.isConsecutive = false,
    this.onDismissed,
  }) : super(key: key);

  @override
  State<FeedbackWidget> createState() => _FeedbackWidgetState();

  // 静态方法：显示反馈
  static void showFeedback(
    BuildContext context,
    TaskModel task,
    {double efficiencyMultiplier = 1.0, bool isConsecutive = false}
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: FeedbackWidget(
          task: task,
          efficiencyMultiplier: efficiencyMultiplier,
          isConsecutive: isConsecutive,
        ),
      ),
    );
  }
}

class _FeedbackWidgetState extends State<FeedbackWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // 1秒后自动关闭反馈
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
        if (widget.onDismissed != null) {
          widget.onDismissed!();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getBenefitTypeName(PetBenefitType type) {
    switch (type) {
      case PetBenefitType.nutrition:
        return '营养值';
      case PetBenefitType.happiness:
        return '快乐度';
      case PetBenefitType.intimacy:
        return '亲密度';
      case PetBenefitType.exp:
        return '经验值';
    }
  }

  String _getTaskDifficultyName(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return '日常任务';
      case TaskDifficulty.medium:
        return '高优先级任务';
      case TaskDifficulty.hard:
        return '连续任务';
    }
  }

  Color _getDifficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.yellow;
      case TaskDifficulty.hard:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 计算最终奖励值
    final int finalBenefitValue = (widget.task.benefitValue * widget.efficiencyMultiplier).toInt();
    
    // 构建反馈文本
    final List<String> feedbackLines = [
      '完成${_getTaskDifficultyName(widget.task.difficulty)}！',
      '宠物${_getBenefitTypeName(widget.task.benefitType)} +$finalBenefitValue',
    ];
    
    // 添加效率加成反馈
    if (widget.efficiencyMultiplier > 1.0) {
      feedbackLines.add('效率加成：${((widget.efficiencyMultiplier - 1.0) * 100).toInt()}%');
    }
    
    // 添加连续完成反馈
    if (widget.isConsecutive) {
      feedbackLines.add('连续完成奖励：营养值 +2');
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(widget.task.difficulty),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '任务完成！',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...feedbackLines.map((line) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      line,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: line.contains('加成') || line.contains('奖励') 
                            ? Colors.orange 
                            : Colors.black54,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}