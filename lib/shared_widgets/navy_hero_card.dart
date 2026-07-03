import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';

/// Navy gradient hero card used at the top of most screens (UI_DESIGN.md 1.3).
class NavyHeroCard extends StatelessWidget {
  const NavyHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.navyGradient,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      padding: padding,
      child: child,
    );
  }
}
