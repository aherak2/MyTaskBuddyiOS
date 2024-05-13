import 'package:flutter/material.dart';

class StepNumber extends StatelessWidget {
  final int stepNumber;
  final bool isCompleted;
  final bool isCurrent;

  StepNumber({
    required this.stepNumber,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 50,
          alignment: Alignment.centerLeft,
          height: 50,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : Colors.white,
            border: Border.all(
              color: isCurrent ? Colors.blue : Colors.grey,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Text(
              isCompleted ? '✓' : '$stepNumber',
              style: TextStyle(
                color: isCompleted ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
