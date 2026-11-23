import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/premium_loading_widget.dart';
import '../../core/utils/date_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/firestore_service.dart';
import '../../global_popup/global_popup.dart';

/// Formats DateTime into Bengali month name with English digits: e.g. "15 নভেম্বর 2026 | 06:19 PM"
String formatFullDateTimeWithBar(DateTime dt) {
  final day = dt.day.toString();
  const monthNames = {
    '1': 'জানুয়ারি',
    '2': 'ফেব্রুয়ারি',
    '3': 'মার্চ',
    '4': 'এপ্রিল',
    '5': 'মে',
    '6': 'জুন',
    '7': 'জুলাই',
    '8': 'আগস্ট',
    '9': 'সেপ্টেম্বর',
    '10': 'অক্টোবর',
    '11': 'নভেম্বর',
    '12': 'ডিসেম্বর',
  };
  final month = monthNames[dt.month.toString()] ?? '';
  final year = dt.year.toString();
  final timeStr = DateFormat('hh:mm a').format(dt);
  return '$day $month $year | $timeStr';
}

/// ==================== NOTIFICATIONS SCREEN (INBOX) ====================
class NotificationsScreen extends StatefulWidget {
  final FirestoreService? firestoreService;

  const NotificationsScreen({
    super.key,
    this.firestoreService,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final FirestoreService _service;
  late final Stream<QuerySnapshot> _notificationsStream;

  // ক্যাটাগরি ফিল্টার: 'all' (সব), 'unread' (আনরিড), 'read' (রিড)
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _service = widget.firestoreService ?? FirestoreService();
    // Read Optimization: Cache stream once in initState with .limit(50)
    _notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData;

          final docs = snapshot.data?.docs ?? [];
          final List<NotificationModel> allNotifications = [];
          for (final doc in docs) {
            try {
              allNotifications.add(NotificationModel.fromFirestore(doc));
            } catch (e) {
              debugPrint('NotificationModel parse error for doc ${doc.id}: $e');
            }
          }
          allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          // Calculate counts (English digits)
          final int totalCount = allNotifications.length;
          final int unreadCount = allNotifications.where((n) => !n.isSeen).length;
          final int readCount = allNotifications.where((n) => n.isSeen).length;

          // Client-side filtering (Zero extra Firestore reads)
          final List<NotificationModel> filteredNotifications;
          if (_activeFilter == 'unread') {
            filteredNotifications =
                allNotifications.where((n) => !n.isSeen).toList();
          } else if (_activeFilter == 'read') {
            filteredNotifications =
                allNotifications.where((n) => n.isSeen).toList();
          } else {
            filteredNotifications = allNotifications;
          }

          Widget bodyContent;
          if (isLoading) {
            bodyContent = const SizedBox.shrink();
          } else if (snapshot.hasError) {
            final errStr = snapshot.error.toString();
            final isPermissionDenied = errStr
                    .toLowerCase()
                    .contains('permission-denied') ||
                errStr.toLowerCase().contains('permission_denied') ||
                errStr.toLowerCase().contains('permission denied');

            bodyContent = Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPermissionDenied
                          ? Icons.lock_outline_rounded
                          : Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPermissionDenied
                          ? 'ফায়ারবেস পারমিশন এরর (Permission Denied)'
                          : 'Firestore ত্রুটি',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPermissionDenied
                          ? 'ফায়ারবেস কনসোলের Firestore Database -> Rules ট্যাবে গিয়ে\n"allow read, write: if true;" সক্রিয় করুন।'
                          : errStr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isPermissionDenied
                            ? Colors.black87
                            : Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
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
          } else if (filteredNotifications.isEmpty) {
            IconData emptyIcon = Icons.notifications_none_rounded;
            String emptyMessage = 'বর্তমানে কোনো নোটিফিকেশন নেই';
            String emptySubtitle = 'নতুন কোনো বিজ্ঞপ্তি বা সতর্কতা এলে এখানে প্রদর্শিত হবে';

            if (_activeFilter == 'unread') {
              emptyIcon = Icons.mark_email_read_rounded;
              emptyMessage = 'কোনো আনরিড নোটিফিকেশন নেই';
              emptySubtitle = 'আপনার সকল নোটিফিকেশন পড়া সম্পন্ন হয়েছে';
            } else if (_activeFilter == 'read') {
              emptyIcon = Icons.drafts_rounded;
              emptyMessage = 'কোনো রিড নোটিফিকেশন নেই';
              emptySubtitle = 'পঠিত নোটিফিকেশনগুলো এখানে সংরক্ষিত থাকবে';
            }

            bodyContent = Center(
              child: EmptyStateWidget(
                icon: emptyIcon,
                message: emptyMessage,
                subtitle: emptySubtitle,
              ),
            );
          } else {
            bodyContent = ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: filteredNotifications.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final item = filteredNotifications[index];
                return _buildNotificationItem(context, item);
              },
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Scaffold(
                backgroundColor: const Color(0xFFF7FAF7),
                appBar: AppBar(
                  backgroundColor: const Color(0xFF1B5E20),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 19),
                    tooltip: 'ফিরে যান',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Column(
                    children: [
                      const Text(
                        'নোটিফিকেশন',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'সকল আপডেট ও জরুরি বার্তা',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.done_all_rounded,
                          color: Colors.white, size: 21),
                      tooltip: 'সব পঠিত হিসেবে চিহ্নিত করুন',
                      onPressed: () async {
                        final confirm = await GlobalPopup.showConfirm(
                          context,
                          title: 'সব পঠিত করবেন?',
                          message:
                              'আপনি কি সকল নোটিফিকেশন পঠিত হিসেবে চিহ্নিত করতে চান?',
                          confirmText: 'হ্যাঁ, চিহ্নিত করুন',
                          cancelText: 'বাতিল',
                          confirmColor: GlobalPopup.primaryTeal,
                        );
                        if (confirm == true) {
                          await _service.markAllNotificationsAsSeen();
                          if (context.mounted) {
                            GlobalPopup.showNotice(
                              context,
                              title: 'সফল',
                              message:
                                  'সকল নোটিফিকেশন সফলভাবে পঠিত হিসেবে চিহ্নিত করা হয়েছে।',
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                body: SafeArea(
                  child: Column(
                    children: [
                      // ১. কালারিং টপবার (Colored Top Bar with Category Filter Chips)
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B5E20).withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                        child: Row(
                          children: [
                            _buildFilterChip(
                              'all',
                              'সব',
                              totalCount,
                              Icons.notifications_none_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'unread',
                              'আনরিড',
                              unreadCount,
                              Icons.mark_email_unread_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'read',
                              'রিড',
                              readCount,
                              Icons.mark_email_read_rounded,
                            ),
                          ],
                        ),
                      ),

                      // ২. নোটিফিকেশন লিস্ট
                      Expanded(child: bodyContent),
                    ],
                  ),
                ),
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

  /// Category Filter Chip (সব, আনরিড, রিড with English badge counts)
  Widget _buildFilterChip(
    String key,
    String label,
    int count,
    IconData icon,
  ) {
    final isSelected = _activeFilter == key;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (_activeFilter != key) {
            setState(() => _activeFilter = key);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.32),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1B5E20)
                      : Colors.white.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count', // English digit
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Notification List Item (Square Thumbnail + Bold Colorful Title + Grey Description + Timestamp)
  Widget _buildNotificationItem(BuildContext context, NotificationModel item) {
    final isUnseen = !item.isSeen;

    return Material(
      color: isUnseen ? const Color(0xFFF7FCF7) : Colors.white,
      child: InkWell(
        onTap: () {
          if (isUnseen) {
            _service.markNotificationAsSeen(item.id);
          }
          if (!mounted) return;
          // Open Topmost Unified Master Global Popup with complete document data
          GlobalPopup.showNotificationDetail(
            context,
            title: item.title,
            message: item.message,
            timeText: formatFullDateTimeWithBar(item.timestamp),
            imageUrl: item.imageUrl,
            actionUrl: item.actionUrl,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Square Thumbnail with rounded corners and light background
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.iconColor.withOpacity(0.2),
                      width: 0.8,
                    ),
                  ),
                  child: item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade200,
                            highlightColor: Colors.grey.shade50,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              item.icon,
                              color: item.iconColor,
                              size: 28,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            item.icon,
                            color: item.iconColor,
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Right Content (Title, Short Description, Timestamp)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Bold Colorful Headline (Title)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: item.iconColor,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnseen) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.alertCritical,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Short Description: Light grey
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Timestamp (e.g. "৪ ঘণ্টা আগে")
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          BanglaDateFormatter.formatRelative(item.timestamp),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
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
}

/// ==================== NOTIFICATION DETAILS PAGE (LEGACY COMPATIBILITY) ====================
class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  String _getCategoryLabel(NotificationModel item) {
    switch (item.type.toLowerCase()) {
      case 'weather':
      case 'alert':
        return 'আবহাওয়া সতর্কবার্তা';
      case 'fertilizer':
      case 'dealer':
        return 'সার ও ডিলার আপডেট';
      case 'disease':
      case 'pest':
        return 'রোগবালাই সতর্কতা';
      case 'market':
      case 'price':
        return 'বাজার দর আপডেট';
      case 'farming':
      case 'crop':
        return 'ফসল ও চাষাবাদ';
      case 'general':
      default:
        return 'সাধারণ বিজ্ঞপ্তি';
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = notification.iconColor;
    final catLabel = _getCategoryLabel(notification);
    final fullDateTime = formatFullDateTimeWithBar(notification.timestamp);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          catLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: notification.imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade50,
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _buildDefaultBanner(catColor),
              )
            else
              _buildDefaultBanner(catColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: catColor.withOpacity(0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(notification.icon, size: 14, color: catColor),
                        const SizedBox(width: 5),
                        Text(
                          catLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: catColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: catColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        fullDateTime,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 15.5,
                      height: 1.65,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final link = notification.actionUrl.trim();
                if (link.isNotEmpty) {
                  final uri = Uri.tryParse(link);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                    return;
                  }
                }
                if (context.mounted) {
                  GlobalPopup.showNotice(
                    context,
                    title: 'বিজ্ঞপ্তি তথ্য',
                    message:
                        'এই বিজ্ঞপ্তির সকল বিস্তারিত তথ্য এখানে দেওয়া হয়েছে।',
                  );
                }
              },
              icon: Icon(
                notification.actionUrl.isNotEmpty
                    ? Icons.open_in_new_rounded
                    : Icons.check_circle_outline_rounded,
                size: 20,
              ),
              label: Text(
                notification.actionUrl.isNotEmpty
                    ? 'লিংকে যান'
                    : 'বিস্তারিত দেখুন',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBanner(Color categoryColor) {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor.withOpacity(0.85),
            categoryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.icon,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getCategoryLabel(notification),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
