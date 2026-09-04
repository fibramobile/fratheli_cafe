import 'package:flutter/material.dart';

import '../../theme/fratheli_colors.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const PremiumAppBar({super.key, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 86,
      backgroundColor: const Color(0xFA15100D),
      foregroundColor: FratheliColors.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: FratheliColors.cream),
      title: Image.asset(
        'assets/premium/logo-fratheli.png',
        width: 112,
        height: 82,
        fit: BoxFit.contain,
      ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(2),
        child: Divider(height: 2, thickness: 1, color: Color(0x4DE2B85C)),
      ),
    );
  }
}
