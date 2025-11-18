import 'package:flutter/material.dart';

class SectionWrapper extends StatelessWidget {
   final Widget child;
   final bool alt;

  const SectionWrapper({
    super.key,
    required this.child,
    this.alt = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: alt ? const Color(0xFF131316) : Colors.transparent,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: child,
        ),
      ),
    );
  }
}
