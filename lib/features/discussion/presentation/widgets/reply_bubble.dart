import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../shared_widgets/app_avatar.dart';
import '../../domain/forum_reply.dart';

/// Bubble balasan forum (UI_DESIGN.md §9.2): avatar kecil + nama + waktu, lalu
/// isi balasan dalam container surface.
class ReplyBubble extends StatelessWidget {
  const ReplyBubble({super.key, required this.reply});

  final ForumReply reply;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(
            name: reply.authorName, photoUrl: reply.authorPhoto, radius: 14),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reply.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    timeAgo(reply.createdAt),
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  reply.content,
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
