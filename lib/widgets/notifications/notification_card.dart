import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// One row in the notifications list.
///
/// Swipe-to-delete is handled by the parent (wraps this in a Dismissible).
/// Tap is delegated to [onTap]; we don't navigate from here.
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = !notification.isViewed;
    final unreadBg = isDark
        ? AppColors.teal.withValues(alpha: 0.12)
        : AppColors.tealLight;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread ? unreadBg : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Icon(category: notification.category),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.subject ?? 'Notification',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if ((notification.message ?? '').isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      notification.message!,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 6.h),
                  Text(
                    _relative(notification.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _relative(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _Icon extends StatelessWidget {
  final String? category;
  const _Icon({this.category});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (category) {
      case 'new_announcement':
        icon = Icons.campaign_outlined;
        break;
      case 'proposal':
      case 'new_proposal':
        icon = Icons.handshake_outlined;
        break;
      case 'chat':
      case 'new_message':
        icon = Icons.chat_bubble_outline_rounded;
        break;
      default:
        icon = Icons.notifications_none_rounded;
    }
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20.sp, color: AppColors.teal),
    );
  }
}
