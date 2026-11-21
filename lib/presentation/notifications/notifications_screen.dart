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
import '../../core/utils/bangla_number_converter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/firestore_service.dart';

/// Formats DateTime into exact Bengali date-time format: e.g. "১৫ নভেম্বর ২০২৬ | ০৬:১৯ PM"
String formatFullDateTimeWithBar(DateTime dt) {
  final day = BanglaNumberConverter.toBangla(dt.day);
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
  final year = BanglaNumberConverter.toBangla(dt.year);
  final timeStr = DateFormat('hh:mm a').format(dt);
  final timeBn = BanglaNumberConverter.toBangla(timeStr);
  return '$day $month $year | $timeBn';
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

  @override
  void initState() {
    super.initState();
    _service = widget.firestoreService ?? FirestoreService();
    _notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData;

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
          } else {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              bodyContent = Center(
                child: EmptyStateWidget(
                  icon: Icons.notifications_none_rounded,
                  message: 'বর্তমানে কোনো নোটিফিকেশন নেই',
                  subtitle:
                      'নতুন কোনো বিজ্ঞপ্তি বা সতর্কতা এলে এখানে প্রদর্শিত হবে',
                  action: ElevatedButton.icon(
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
                  debugPrint(
                      'NotificationModel parse error for doc ${doc.id}: $e');
                }
              }
              notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              // 1. Notification List UI with ListView.separated and light grey Divider
              bodyContent = ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return _buildNotificationItem(context, item);
                },
              );
            }
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Scaffold(
                backgroundColor: Colors.white,
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
                      icon: const Icon(Icons.done_all_rounded,
                          color: Colors.white),
                      tooltip: 'সব পঠিত হিসেবে চিহ্নিত করুন',
                      onPressed: () async {
                        await _service.markAllNotificationsAsSeen();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'সকল নোটিফিকেশন পঠিত হিসেবে চিহ্নিত করা হয়েছে'),
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
          // Navigate to NotificationDetailScreen with complete document data
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificationDetailScreen(notification: item),
            ),
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

/// ==================== NOTIFICATION DETAILS PAGE ====================
class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  String _getCategoryLabel(NotificationModel item) {
    final t = item.type.toLowerCase();
    if (t == 'weather' || t.contains('সতর্কতা') || t.contains('আবহাওয়া')) {
      return 'আবহাওয়া বার্তা';
    } else if (t == 'crop' || t.contains('ফসল') || t.contains('বালাই')) {
      return 'ফসল ও রোগবালাই';
    } else if (t == 'market' || t.contains('বাজার') || t.contains('দর')) {
      return 'বাজার দর আপডেট';
    }
    return 'সাধারণ বিজ্ঞপ্তি';
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = notification.iconColor;
    final categoryLabel = _getCategoryLabel(notification);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'ফিরে যান',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'বিজ্ঞপ্তির বিবরণ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ১. একেবারে উপরে স্ক্রিনের প্রস্থ অনুযায়ী বড় করে ব্যানার ছবি (Image)
            if (notification.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: notification.imageUrl,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade50,
                  child: Container(
                    width: double.infinity,
                    height: 240,
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _buildDefaultBanner(categoryColor),
              )
            else
              _buildDefaultBanner(categoryColor),

            // Content Container
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Pill Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(notification.icon,
                            size: 14, color: categoryColor),
                        const SizedBox(width: 6),
                        Text(
                          categoryLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ২. ছবির নিচে বড় ও বোল্ড ফন্টে হেডলাইন (Title)
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ৩. হেডলাইনের নিচে সম্পূর্ণ তারিখ ও সময় (যেমন: "১৫ নভেম্বর ২০২৬ | ০৬:১৯ PM")
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatFullDateTimeWithBar(notification.timestamp),
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

                  // ৪. সম্পূর্ণ বিস্তারিত লেখা (Full Description)
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

      // ৫. পেজের নিচের দিকে বড় কালারফুল অ্যাকশন বাটন (রেড কালার)
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
                backgroundColor:
                    const Color(0xFFD32F2F), // Vibrant Red like reference
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'এই বিজ্ঞপ্তির সকল বিস্তারিত তথ্য এখানে দেওয়া হয়েছে।'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
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
