import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Standard top app bar (UI_DESIGN.md 1.3): hamburger / logo "StudyFlow" /
/// notification bell. Override [leading], [title] or [actions] per screen.
class StudyFlowTopBar extends StatelessWidget implements PreferredSizeWidget {
  const StudyFlowTopBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
  });

  final Widget? leading;
  final String? title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading ??
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
            tooltip: 'Menu',
          ),
      title: title != null
          ? Text(title!)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.menu_book, color: AppColors.accent, size: 22),
                SizedBox(width: 8),
                Text(
                  'StudyFlow',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
      actions: actions ??
          [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
              tooltip: 'Notifikasi',
            ),
          ],
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const Border(
        bottom: BorderSide(color: AppColors.surfaceBorder, width: 1),
      ),
    );
  }
}
