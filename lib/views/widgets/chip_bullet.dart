import 'package:flutter/material.dart';

class ChipBullet extends StatelessWidget {
  final String label;

  const ChipBullet(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF191A1F),
        border: Border.all(color: const Color(0xFF2A2B32)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD4D4D4),
          fontSize: 13,
        ),
      ),
    );
  }
}
