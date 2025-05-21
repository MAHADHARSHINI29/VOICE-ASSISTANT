import 'package:flutter/material.dart';

class ThreeDots extends StatefulWidget {
  const ThreeDots({super.key});

  @override
  ThreeDotsState createState() => ThreeDotsState();
}

class ThreeDotsState extends State<ThreeDots> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
        final progress = _animationController.value;
        final newIndex = (progress * 3).floor();
        if (newIndex != _currentIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
        }
      });
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.all(2.0),
          child: CircleAvatar(
            radius: 4,
            backgroundColor:
                _currentIndex == index ? Colors.blue : Colors.blue.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}
