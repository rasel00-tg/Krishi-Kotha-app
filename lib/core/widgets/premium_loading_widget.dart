import 'dart:ui';
import 'package:flutter/material.dart';

/// প্রিমিয়াম ইউনিফাইড লোডিং উইজেট (Unified Premium Vibrant Gradient Loading Dialog Card)
///
/// পুরো অ্যাপ্লিকেশনের প্রতিটি ফিচারের লোডিং অবস্থায় স্ক্রিনের ঠিক কেন্দ্রস্থলে (True Vertical & Horizontal Center)
/// একটি সম্পূর্ণ কালারফুল ভাইব্রেন্ট গ্র্যাডিয়েন্ট ফ্লোটিং মডাল কার্ড হিসেবে প্রদর্শিত হয়।
/// পেছনের সমস্ত উইজেটকে ডিমড ব্যারিয়ার এবং ব্লার ওভারলে দিয়ে আবৃত রাখে।
class PremiumLoadingWidget extends StatelessWidget {
  /// লোডিং বিষয়ের নাম (যেমন: 'বাজার দর', 'ফসলের তথ্য', 'রোগবালাইয়ের তথ্য', 'নোটিফিকেশন')
  final String topic;

  /// সাব-টেক্সট (ডিফল্ট: 'অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করুন')
  final String? subtitle;

  const PremiumLoadingWidget({
    super.key,
    required this.topic,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = topic.endsWith('লোড হচ্ছে...')
        ? topic
        : '$topic লোড হচ্ছে...';
    final subText = subtitle ?? 'অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করুন';

    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: Container(
          // ১. পেছনের সম্পূর্ণ ব্যাকগ্রাউন্ড একটি হালকা গাঢ় বা ব্লার ডিম ওভারলে (Dimmed Barrier)
          color: const Color(0xFF041208).withOpacity(0.55),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Center(
              // ২. স্ক্রিনের নিখুঁত কেন্দ্রে অবস্থান (True Vertical & Horizontal Center)
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                constraints: const BoxConstraints(maxWidth: 315),
                decoration: BoxDecoration(
                  // ৩. কালারফুল প্রিমিয়াম কার্ড ডিজাইন (No Plain White): সম্পূর্ণ ব্যাকগ্রাউন্ডে চমৎকার প্রাণবন্ত উজ্জ্বল এগ্রিকালচারাল গ্রিন গ্র্যাডিয়েন্ট
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF059669), // Vivid Emerald Sea-Green
                      Color(0xFF1B5E20), // Deep Agricultural Forest Green
                      Color(0xFF064E3B), // Deep Emerald Green
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28), // বর্ডার রেডিয়াস ২৮px
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withOpacity(0.45),
                      blurRadius: 36,
                      spreadRadius: 2,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAlignment.center,
                  children: [
                    // ৪. উজ্জ্বল কন্ট্রাস্ট ফ্রেমের ভেতর অ্যাপের লোগো আইকন
                    Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/icons/pnglogo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.eco_rounded,
                            size: 38,
                            color: Color(0xFF1B5E20),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ৫. মূল শিরোনাম: স্পষ্ট বড় বোল্ড টেক্সট উজ্জ্বল সাদা রঙে
                    Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ৬. সাব-টাইটেল: মার্জিত ও পরিচ্ছন্ন কনট্রাস্টে
                    Text(
                      subText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.92),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ৭. লোডিং নির্দেশক: মসৃণ এবং কালারফুল থিমের সাথে সম্পূর্ণ মানানসই হোয়াইট স্পিনার
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        backgroundColor: Colors.white.withOpacity(0.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
