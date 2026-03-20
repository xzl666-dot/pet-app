import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import '../models/pet_model.dart';

class PetInteractionWidget extends StatefulWidget {
  final PetModel pet;
  final bool isAnimating;
  final VoidCallback? onTap;

  const PetInteractionWidget({
    Key? key,
    required this.pet,
    this.isAnimating = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<PetInteractionWidget> createState() => _PetInteractionWidgetState();
}

class _PetInteractionWidgetState extends State<PetInteractionWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _floatAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _statusController;
  late Animation<double> _nutritionAnimation;
  late Animation<double> _happinessAnimation;

  @override
  void initState() {
    super.initState();
    
    // 主动画控制器
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: 0.0, end: -5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 淡入动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // 状态条动画控制器
    _statusController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _nutritionAnimation = Tween<double>(begin: 0.0, end: widget.pet.nutrition / 100).animate(
      CurvedAnimation(parent: _statusController, curve: Curves.easeOutCubic),
    );

    _happinessAnimation = Tween<double>(begin: 0.0, end: widget.pet.happiness / 100).animate(
      CurvedAnimation(parent: _statusController, curve: Curves.easeOutCubic),
    );



    if (widget.isAnimating) {
      _playAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant PetInteractionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _playAnimation();
    }
  }

  void _playAnimation() {
    _controller.reset();
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Widget _getPetImage() {
    // 根据宠物种类和形态返回不同的图像
    Color petColor = Colors.grey;
    String petEmoji = '🐶';

    // 根据宠物种类和形态确定外观
    switch (widget.pet.type) {
      case PetType.chick:
        // 小鸡
        switch (widget.pet.form) {
          case PetForm.baby:
            petColor = Colors.yellow;
            petEmoji = '🐣';
            break;
          case PetForm.adolescent:
            petColor = Colors.orange;
            petEmoji = '🐥';
            break;
          case PetForm.adult:
            petColor = Colors.red;
            petEmoji = '🐔';
            break;
          case PetForm.advanced:
            petColor = Colors.purple;
            petEmoji = '🦚';
            break;
        }
        break;
      case PetType.puppy:
        // 小狗
        switch (widget.pet.form) {
          case PetForm.baby:
            petColor = Colors.brown.shade200;
            petEmoji = '🐶';
            break;
          case PetForm.adolescent:
            petColor = Colors.brown;
            petEmoji = '🐕';
            break;
          case PetForm.adult:
            petColor = Colors.brown.shade800;
            petEmoji = '🦮';
            break;
          case PetForm.advanced:
            petColor = Colors.amber;
            petEmoji = '🐺';
            break;
        }
        break;
      case PetType.kitten:
        // 小猫
        switch (widget.pet.form) {
          case PetForm.baby:
            petColor = Colors.grey;
            petEmoji = '🐱';
            break;
          case PetForm.adolescent:
            petColor = Colors.blueGrey;
            petEmoji = '🐈';
            break;
          case PetForm.adult:
            petColor = Colors.grey.shade800;
            petEmoji = '🐈';
            break;
          case PetForm.advanced:
            petColor = Colors.pink;
            petEmoji = '🦁';
            break;
        }
        break;
      case PetType.bunny:
        // 小兔
        switch (widget.pet.form) {
          case PetForm.baby:
            petColor = Colors.pink.shade200;
            petEmoji = '🐰';
            break;
          case PetForm.adolescent:
            petColor = Colors.pink;
            petEmoji = '🐇';
            break;
          case PetForm.adult:
            petColor = Colors.pink.shade800;
            petEmoji = '🐇';
            break;
          case PetForm.advanced:
            petColor = Colors.white;
            petEmoji = '🐇';
            break;
        }
        break;
    }

    // 根据屏幕尺寸动态调整宠物大小
    double petSize = 150;
    double emojiSize = 60;
    MediaQueryData mediaQuery = MediaQuery.of(context);
    double screenWidth = mediaQuery.size.width;
    double screenHeight = mediaQuery.size.height;
    
    // 基于屏幕高度进一步限制宠物大小
    double maxPetSize = screenHeight * 0.3;
    petSize = petSize.clamp(100.0, maxPetSize);
    emojiSize = petSize * 0.4;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: Container(
                width: petSize,
                height: petSize,
                decoration: BoxDecoration(
                  color: petColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: petColor.withOpacity(0.3),
                      spreadRadius: 8,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      petColor.withOpacity(1.0),
                      petColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    petEmoji,
                    style: TextStyle(fontSize: emojiSize),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _playAnimation();
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      child: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getPetImage(),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    widget.pet.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Lv.${widget.pet.level}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.pet.form.getFormName(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildExpBar(),
                const SizedBox(height: 16),
                _buildStatusBars(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBars() {
    return Column(
      children: [
        _buildStatusBar('营养值', widget.pet.nutrition, Colors.green, _nutritionAnimation),
        const SizedBox(height: 8),
        _buildStatusBar('快乐度', widget.pet.happiness, Colors.blue, _happinessAnimation),
        const SizedBox(height: 8),

      ],
    );
  }

  Widget _buildExpBar() {
    final progress = widget.pet.expThreshold > 0 
        ? (widget.pet.exp / widget.pet.expThreshold).clamp(0.0, 1.0)
        : 0.0;
    
    MediaQueryData mediaQuery = MediaQuery.of(context);
    double screenWidth = mediaQuery.size.width;
    double maxBarWidth = screenWidth * 0.8;
    double expBarWidth = maxBarWidth.clamp(200.0, 350.0);
    double progressBarWidth = expBarWidth - 40; // 减去padding

    return Container(
      width: expBarWidth,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '经验值',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Text(
                '${widget.pet.exp}/${widget.pet.expThreshold}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _statusController,
                  builder: (context, child) {
                    return Container(
                      width: progress * progressBarWidth,
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade300,
                            Colors.amber.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String label, int value, Color color, Animation<double> animation) {
    MediaQueryData mediaQuery = MediaQuery.of(context);
    double screenWidth = mediaQuery.size.width;
    double maxBarWidth = screenWidth * 0.8;
    double statusBarWidth = maxBarWidth.clamp(200.0, 350.0);
    double progressBarWidth = statusBarWidth - 40; // 减去padding

    return Container(
      width: statusBarWidth,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '$value/100',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Container(
                      width: animation.value * progressBarWidth,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}