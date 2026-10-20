import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/widgets/premium_loading_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/firestore_service.dart';

class NotificationsScreen extends StatelessWidget {
  final FirestoreService? firestoreService;

  const NotificationsScreen({
    super.key,
    this.firestoreService,
  });

  FirestoreService get _service => firestoreService ?? FirestoreService();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notifications').snapshots().timeout(
          const Duration(seconds: 4),
          onTimeout: (sink) async {
            try {
              final snap = await FirebaseFirestore.instance.collection('notifications').get();
              sink.add(snap);
            } catch (e) {
              sink.addError(e);
            }
          },
        ),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

          Widget bodyContent;
          if (isLoading) {
            bodyContent = const SizedBox.shrink();
          } else if (snapshot.hasError) {
          final errStr = snapshot.error.toString();
          final isPermissionDenied = errStr.toLowerCase().contains('permission-denied') ||
              errStr.toLowerCase().contains('permission_denied') ||
              errStr.toLowerCase().contains('permission denied');

          bodyContent = Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPermissionDenied ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPermissionDenied
                        ? 'ফায়ারবেস পারমিশন এরর (Permission Denied)'
                        : 'Firestore ত্রুটি',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPermissionDenied
                        ? 'ফায়ারবেস কনসোলের Firestore Database -> Rules ট্যাবে গিয়ে\n"allow read, write: if true;" সক্রিয় করুন।'
                        : errStr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isPermissionDenied ? Colors.black87 : Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      (context as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('পুনরায় চেষ্টা করুন'),
                  ),
                ],
              ),
            ),
          );
        } else {
          final docs = snapshot.data?.docs ?? [];
          // 3. কালেকশন খালি থাকলে মার্জিত এম্পটি স্টেট
          if (docs.isEmpty) {
            bodyContent = Center(
              child: EmptyStateWidget(
                icon: Icons.notifications_none_rounded,
                message: 'বর্তমানে কোনো নোটিফিকেশন নেই',
                subtitle: 'নতুন কোনো বিজ্ঞপ্তি বা সতর্কতা এলে এখানে প্রদর্শিত হবে',
                action: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    (context as Element).markNeedsBuild();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('রিফ্রেশ করুন'),
                ),
              ),
            );
          } else {

            final List<NotificationModel> notifications = [];
            for (final doc in docs) {
              try {
                notifications.add(NotificationModel.fromFirestore(doc));
              } catch (e) {
                debugPrint('NotificationModel parse error for doc ${doc.id}: $e');
              }
            }
            notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            bodyContent = ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _buildNotificationCard(context, item);
              },
            );
          }
        }

        return Stack(
            fit: StackFit.expand,
            children: [
              Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'ফিরে যান',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text(
                    'নোটিফিকেশন',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                      tooltip: 'সব পঠিত হিসেবে চিহ্নিত করুন',
                      onPressed: () async {
                        await _service.markAllNotificationsAsSeen();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('সকল নোটিফিকেশন পঠিত হিসেবে চিহ্নিত করা হয়েছে'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                body: bodyContent,
              ),
              if (isLoading)
                const Positioned.fill(
                  child: PremiumLoadingWidget(topic: 'নোটিফিকেশন'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel item) {
    // Visual differentiation between Unseen and Seen without explicit text tags
    final isUnseen = !item.isSeen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isUnseen) {
            _service.markNotificationAsSeen(item.id);
          }
          _showNotificationDetailDialog(context, item);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Unseen: Soft light mint-green highlight; Seen: Pure white
            color: isUnseen ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnseen
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.border,
              width: isUnseen ? 1.2 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnseen
                    ? AppColors.primary.withOpacity(0.08)
                    : AppColors.cardShadow,
                blurRadius: isUnseen ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Category Icon with contextual background
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isUnseen
                      ? item.iconColor.withOpacity(0.18)
                      : const Color(0xFFF1F3F4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    color: item.iconColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Message, and Relative Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15,
                              // Unseen has bolder typography
                              fontWeight: isUnseen ? FontWeight.bold : FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.25,
                            ),
                          ),
                        ),
                        // Small glowing dot for unread status
                        if (isUnseen)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        // Unseen message text is slightly darker and denser
                        fontWeight: isUnseen ? FontWeight.w500 : FontWeight.normal,
                        color: isUnseen
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    if (item.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: isUnseen
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.formattedTime,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isUnseen ? FontWeight.w600 : FontWeight.normal,
                            color: isUnseen
                                ? AppColors.primaryDark
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetailDialog(BuildContext context, NotificationModel item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.iconColor, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 20),
            Text(
              item.message,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
            if (item.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl,
                  maxHeight: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  item.formattedTime,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'ঠিক আছে',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
