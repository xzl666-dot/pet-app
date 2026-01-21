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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  Widget _getPetImage() {
    // 根据宠物种类和形态返回不同的图像
    Color petColor;
    String petEmoji;

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
            petEmoji = '🐈‍⬛';
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: petColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  petEmoji,
                  style: const TextStyle(fontSize: 60),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _getPetImage(),
          const SizedBox(height: 16),
          Text(
            widget.pet.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.pet.form.getFormName(),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildStatusBars(),
        ],
      ),
    );
  }

  Widget _buildStatusBars() {
    return Column(
      children: [
        _buildStatusBar('营养值', widget.pet.nutrition, Colors.green),
        const SizedBox(height: 8),
        _buildStatusBar('快乐度', widget.pet.happiness, Colors.blue),
        const SizedBox(height: 8),
        _buildStatusBar('技能点', widget.pet.skillPoint, Colors.purple),
      ],
    );
  }

  Widget _buildStatusBar(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                '$value/100',
                style: TextStyle(fontSize: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey[200],
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}