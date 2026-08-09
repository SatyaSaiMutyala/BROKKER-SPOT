import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/conversation_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// One row on the "Announcement → Conversations" screen.
class ConversationTile extends StatelessWidget {
  final ConversationItem conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = conversation.user;
    // User-side conversations always show the broker's profile photo.
    final url = (user.brokerProfileImageUrl ?? user.profileImageUrl) ?? '';
    final nameColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final msgColor = isDark ? const Color(0xFF9E9E9E) : Colors.grey.shade600;
    final timeColor = Colors.grey.shade500;
    final hasUnread = conversation.unseenCount > 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            // Avatar with gold border
            Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldAccent, width: 1.5),
              ),
              child: ClipOval(
                child: url.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        placeholderFadeInDuration: Duration.zero,
                        errorWidget: (_, __, ___) => _avatarFallback(isDark),
                        placeholder: (_, __) => _avatarFallback(isDark),
                      )
                    : _avatarFallback(isDark),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? 'User',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: nameColor,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    conversation.lastMessage?.trim().isNotEmpty == true
                        ? conversation.lastMessage!
                        : 'Tap to start a chat',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                      color: hasUnread
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : const Color(0xFF444444))
                          : msgColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _relative(conversation.lastMessageAt),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: timeColor,
                  ),
                ),
                SizedBox(height: 5.h),
                if (hasUnread)
                  Container(
                    constraints: BoxConstraints(minWidth: 22.w),
                    height: 22.w,
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Text(
                      conversation.unseenCount > 9
                          ? '9+'
                          : '${conversation.unseenCount}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  SizedBox(height: 22.w),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(bool isDark) => Container(
        width: 54.w,
        height: 54.w,
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
        child: Icon(
          Icons.person_outline,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      );

  static String _relative(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}
