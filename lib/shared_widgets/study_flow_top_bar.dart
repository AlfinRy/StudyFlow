import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'app_logo.dart';

/// Standard top app bar (UI_DESIGN.md 1.3): hamburger / logo "StudyFlow" /
/// notification bell. Override [leading], [title] or [actions] per screen.
class StudyFlowTopBar extends StatelessWidget implements PreferredSizeWidget {
  const StudyFlowTopBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.onNotificationsPressed,
  });

  final Widget? leading;
  final String? title;
  final List<Widget>? actions;

  /// Aksi saat ikon lonceng ditekan (mis. membuka panel pengingat).
  final VoidCallback? onNotificationsPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading ??
          IconButton(
            icon: const Icon(Icons.menu),
            // Top bar berada di dalam subtree Scaffold, jadi
            // Scaffold.maybeOf(context) menemukan Scaffold yang menaunginya.
            onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
            tooltip: 'Menu',
          ),
      title: title != null
          ? Text(title!)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLogo(),
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
              onPressed: onNotificationsPressed,
              tooltip: 'Notifikasi',
            ),
          ],
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(
        bottom: BorderSide(color: AppColors.surfaceBorder, width: 1),
      ),
    );
  }
}
