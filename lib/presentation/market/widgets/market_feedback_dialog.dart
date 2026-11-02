import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

/// প্রিমিয়াম সেন্ট্রালাইজড অ্যানিমেটেড ফিডব্যাক ডায়ালগ
class MarketFeedbackDialog extends StatefulWidget {
  final bool isAdded;
  final String? customMessage;

  const MarketFeedbackDialog({
    super.key,
    required this.isAdded,
    this.customMessage,
  });

  /// ডায়ালগ প্রদর্শন ও ১.৫ সেকেন্ড পর স্বয়ংক্রিয়ভাবে অদৃশ্য করার স্ট্যাটিক মেথড
  static Future<void> show(
    BuildContext context, {
    required bool isAdded,
    String? customMessage,
  }) async {
    if (!context.mounted) return;
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'MarketFeedbackDialog',
      barrierColor: Colors.black.withOpacity(0.42),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, anim1, anim2) {
        return MarketFeedbackDialog(
          isAdded: isAdded,
          customMessage: customMessage,
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedValue = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInQuad,
        ).value;
        return Transform.scale(
          scale: curvedValue.clamp(0.0, 1.0),
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<MarketFeedbackDialog> createState() => _MarketFeedbackDialogState();
}

class _MarketFeedbackDialogState extends State<MarketFeedbackDialog>
    with SingleTickerProviderStateMixin {
  Timer? _dismissTimer;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.15).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_pulseController);

    _pulseController.forward();

    // ১.৫ সেকেন্ড (1500ms) পর ডায়ালগটি স্মুথলি নিজে থেকেই বন্ধ হবে
    _dismissTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String defaultMsg = widget.isAdded
        ? 'পছন্দের তালিকায় সফলভাবে যুক্ত হয়েছে!'
        : 'পছন্দের তালিকা থেকে সরানো হয়েছে!';
    final String displayMsg = widget.customMessage ?? defaultMsg;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: widget.isAdded
                      ? const Color(0xFFFFCDD2).withOpacity(0.8)
                      : Colors.grey.shade300,
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isAdded ? const Color(0xFFE53935) : Colors.black)
                        .withOpacity(0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // অ্যানিমেটেড হার্ট বা লোগো আইকন
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.isAdded
                              ? [
                                  const Color(0xFFFFEBEE),
                                  const Color(0xFFFFCDD2),
                                ]
                              : [
                                  const Color(0xFFF5F5F5),
                                  const Color(0xFFEEEEEE),
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.isAdded
                                ? const Color(0xFFE53935).withOpacity(0.22)
                                : Colors.black.withOpacity(0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          widget.isAdded
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: widget.isAdded
                              ? const Color(0xFFE53935)
                              : const Color(0xFF758577),
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // মার্জিত শিরোনাম
                  Text(
                    widget.isAdded ? 'যুক্ত হয়েছে!' : 'সরানো হয়েছে',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: widget.isAdded
                          ? const Color(0xFFB71C1C)
                          : const Color(0xFF37474F),
                      fontFamily: 'HindSiliguri',
                    ),
                  ),
                  const SizedBox(height: 6),

                  // বিস্তারিত বার্তা
                  Text(
                    displayMsg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                      height: 1.35,
                      fontFamily: 'HindSiliguri',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

