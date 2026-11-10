import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// System Control Gate: Root-level real-time listener on `app_settings/system_control`.
/// Dynamically presents centered non-dismissible dialogs for:
/// 1. System Maintenance (maintenance mode locks app, exit via SystemNavigator.pop)
/// 2. System Update (force/recommended update via Play Store if currentVersion < targetVersion)
class SystemControlGate extends StatelessWidget {
  final Widget child;

  /// Current user app version (matches pubspec.yaml version 1.0.0+1)
  static const String currentAppVersion = '1.0.0';

  const SystemControlGate({super.key, required this.child});

  /// Semantic version comparator: returns true if currentVer < targetVer
  static bool isUpdateRequired(String currentVer, String targetVer) {
    try {
      final curClean = currentVer.replaceAll(RegExp(r'[^0-9.]'), '').trim();
      final targetClean = targetVer.replaceAll(RegExp(r'[^0-9.]'), '').trim();

      if (curClean.isEmpty || targetClean.isEmpty) return false;

      final curParts = curClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final targetParts = targetClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = curParts.length > targetParts.length ? curParts.length : targetParts.length;
      for (int i = 0; i < maxLen; i++) {
        final curVal = i < curParts.length ? curParts[i] : 0;
        final targetVal = i < targetParts.length ? targetParts[i] : 0;
        if (curVal < targetVal) return true;
        if (curVal > targetVal) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Evaluates active status considering optional schedule
  static bool _evaluateIsActive(Map<String, dynamic> data) {
    final bool masterActive = data['is_active'] == true;
    if (!masterActive) return false;

    final bool scheduleEnabled = data['schedule_enabled'] == true;
    if (!scheduleEnabled) return true;

    final now = DateTime.now();
    DateTime? startTime;
    DateTime? endTime;

    if (data['start_time'] != null) {
      if (data['start_time'] is Timestamp) {
        startTime = (data['start_time'] as Timestamp).toDate();
      } else if (data['start_time'] is String) {
        startTime = DateTime.tryParse(data['start_time']);
      }
    }

    if (data['end_time'] != null) {
      if (data['end_time'] is Timestamp) {
        endTime = (data['end_time'] as Timestamp).toDate();
      } else if (data['end_time'] is String) {
        endTime = DateTime.tryParse(data['end_time']);
      }
    }

    if (startTime != null && now.isBefore(startTime)) return false;
    if (endTime != null && now.isAfter(endTime)) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('app_settings')
          .doc('system_control')
          .snapshots(),
      builder: (context, snapshot) {
        // ফায়ারস্টোরে কোনো মেইন্টেনেন্স বা আপডেট সক্রিয় না থাকলে অথবা কোনো ত্রুটি/নাল থাকলে
        // কোনো Stack, ModalBarrier বা IgnorePointer ছাড়াই সরাসরি মূল child উইজেট রিটার্ন করা
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
          return child;
        }

        final data = snapshot.data!.data();
        if (data == null || data.isEmpty) {
          return child;
        }

        final bool isActive = _evaluateIsActive(data);
        if (!isActive) {
          return child;
        }

        final String type = data['type']?.toString().toLowerCase() ?? 'maintenance';
        final String headline = data['headline']?.toString().trim() ??
            (type == 'maintenance' ? 'অ্যাপ মেইন্টেনেন্স চলছে' : 'নতুন আপডেট এসেছে!');
        final String message = data['message']?.toString().trim() ??
            (type == 'maintenance'
                ? 'সম্মানিত কৃষক ভাই, অ্যাপের কারিগরি উন্নয়ন কাজ চলছে। সাময়িক অসুবিধার জন্য আমরা আন্তরিকভাবে দুঃখিত। কিছুক্ষণ পর আবার চেষ্টা করুন।'
                : 'কৃষি কথা অ্যাপের নতুন সংস্করণ প্রকাশিত হয়েছে। নিরবচ্ছিন্ন সেবা ও নতুন ফিচার উপভোগ করতে এখনই আপডেট করুন।');
        final String buttonText = data['button_text']?.toString().trim() ??
            (type == 'maintenance' ? 'অ্যাপ বন্ধ করুন' : 'প্লে স্টোরে যান');
        final String playStoreUrl = data['play_store_url']?.toString().trim() ??
            'https://play.google.com/store/apps/details?id=com.krishikotha.app';
        final String targetVersion = data['target_version']?.toString().trim() ?? '1.0.5';

        // Update mode check: only show if user's current version is older than targetVersion
        if (type == 'update') {
          final bool needsUpdate = isUpdateRequired(currentAppVersion, targetVersion);
          if (!needsUpdate) {
            return child; // User has updated or equal version, do not block
          }
        }

        // Render Centered Premium Non-Dismissible Dialog Overlay
        return Stack(
          textDirection: TextDirection.ltr,
          children: [
            // Underlying application
            child,

            // Semi-transparent blurred modal barrier
            Positioned.fill(
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {},
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.65),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: _SystemControlCard(
                      type: type,
                      headline: headline,
                      message: message,
                      buttonText: buttonText,
                      targetVersion: targetVersion,
                      playStoreUrl: playStoreUrl,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Center Dialog Card Component
class _SystemControlCard extends StatefulWidget {
  final String type;
  final String headline;
  final String message;
  final String buttonText;
  final String targetVersion;
  final String playStoreUrl;

  const _SystemControlCard({
    required this.type,
    required this.headline,
    required this.message,
    required this.buttonText,
    required this.targetVersion,
    required this.playStoreUrl,
  });

  @override
  State<_SystemControlCard> createState() => _SystemControlCardState();
}

class _SystemControlCardState extends State<_SystemControlCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isActionExecuting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleAction() async {
    if (_isActionExecuting) return;
    setState(() => _isActionExecuting = true);

    try {
      if (widget.type == 'maintenance') {
        // Close or exit the application
        await SystemNavigator.pop();
      } else {
        // Open Play Store link
        final uri = Uri.parse(widget.playStoreUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          // Fallback to standard web URL
          await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        }
      }
    } catch (e) {
      debugPrint('System control action execution notice: $e');
    } finally {
      if (mounted) setState(() => _isActionExecuting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMaintenance = widget.type == 'maintenance';
    final Color badgeBg = isMaintenance ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE);
    final Color badgeIconColor = isMaintenance ? const Color(0xFFD97706) : const Color(0xFF1D4ED8);
    final Color btnBg = isMaintenance ? const Color(0xFFD97706) : const Color(0xFF1D4ED8);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: (isMaintenance ? const Color(0xFFD97706) : const Color(0xFF1D4ED8))
                    .withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Glowing Badge Icon
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: badgeIconColor.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  isMaintenance
                      ? Icons.build_circle_rounded
                      : Icons.cloud_download_rounded,
                  size: 32,
                  color: badgeIconColor,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Headline
              Text(
                widget.headline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),

              // 3. Message Body
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 14),

              // 4. Target Version Pill (For update mode)
              if (!isMaintenance) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: Color(0xFF1D4ED8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'নতুন সংস্করণ: ${widget.targetVersion}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 5. Full-width Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isActionExecuting ? null : _handleAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnBg,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: btnBg.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _isActionExecuting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isMaintenance
                                  ? Icons.power_settings_new_rounded
                                  : Icons.open_in_new_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.buttonText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // 6. Security & Non-dismissible Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 11,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'বাধ্যতামূলক সিস্টেম ডায়ালগ • কৃষি কথা',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

