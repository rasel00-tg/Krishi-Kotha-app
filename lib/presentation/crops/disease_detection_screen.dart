import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/disease_diagnosis_result.dart';
import '../../data/services/disease_detection_service.dart';
import '../../data/services/prescription_pdf_service.dart';
import 'prescription_history_screen.dart';

enum DiseasePhase {
  idle,       // অলস অবস্থা: নিচে ফ্রস্টেড গ্লাস ইনপুট পিল, প্রম্পট চিপস ও হিস্ট্রি
  thinking,   // মরফিং ও চিন্তন অবস্থা: স্ক্রিনের কেন্দ্রে গ্লোয়িং ডটেড অরগানিক অর্ব
  unfolded,   // সমাধান উন্মোচন: প্রস্ফুটিত ফুল-স্ক্রিন প্রেসক্রিপশন রেজাল্ট কার্ড
}

class DailyPromptItem {
  final String query;
  final String category;
  final IconData icon;
  final Color color;

  const DailyPromptItem({
    required this.query,
    required this.category,
    required this.icon,
    required this.color,
  });
}

class DiseaseDetectionScreen extends StatefulWidget {
  final ImageSource? initialSource;
  const DiseaseDetectionScreen({super.key, this.initialSource});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  XFile? _selectedImage;
  Uint8List? _webImageBytes;

  DiseasePhase _currentPhase = DiseasePhase.idle;
  DiseaseDiagnosisResult? _activeResult;

  // ২. কৃষিবহির্ভূত প্রশ্নে রেট লিমিট ও ১ ঘণ্টার জন্য এআই চ্যাট লক স্টেট
  bool _isChatLocked = false;
  int _lockRemainingMinutes = 0;

  // অ্যানিমেশন কন্ট্রোলারসমূহ
  late AnimationController _orbSpinController;
  late AnimationController _orbPulseController;
  late AnimationController _morphController;
  late AnimationController _unfoldController;

  // গতিশীল প্রসঙ্গভিত্তিক স্ট্যাটাস টেক্সট (Requirement 4)
  List<String> _thinkingMessages = [];
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  // ৪টি স্মার্ট শর্টকাট প্রশ্ন যা প্রতিদিনের ঋতু ও তারিখ অনুযায়ী স্বয়ংক্রিয়ভাবে রিফ্রেশ হয় (2x2 Grid)
  List<DailyPromptItem> _getDailySeasonalPromptItems() {
    final now = DateTime.now();
    final month = now.month;
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    // ১. রবি মৌসুম (কার্তিক - ফাল্গুন / অক্টোবর - মার্চ)
    // ২. খরিফ-১ মৌসুম (চৈত্র - জ্যৈষ্ঠ / এপ্রিল - জুন)
    // ৩. খরিফ-২ মৌসুম (আষাঢ় - আশ্বিন / জুলাই - সেপ্টেম্বর)
    final bool isRabi = month >= 10 || month <= 3;
    final bool isKharif1 = month >= 4 && month <= 6;

    final List<String> cerealSlot;
    final List<String> vegSlot;
    final List<String> pestSlot;
    final List<String> cashSlot;

    if (isRabi) {
      cerealSlot = [
        'গমের পাতায় বাদামী বা হলুদ মরিচা রোগ',
        'বোরো ধানের চারা হলুদ ও ঠান্ডা জনিত ক্ষতি',
        'ভুট্টার পাতায় লম্বাটে পোড়া দাগ ও ব্লাইট',
        'বোরো বীজতলায় শিকড় পচা ও ধসা রোগ',
      ];
      vegSlot = [
        'আলুর পাতায় কালো ছোপ ও নাবি ধসা (Late Blight)',
        'শীতকালীন টমেটোর পাতা কুঁকড়ে হলুদ হয়ে যাওয়া',
        'ফুলকপি ও বাঁধাকপির পাতা পচা ও ব্লাইট রোগ',
        'বেগুনের ডগা নেতিয়ে শুকিয়ে যাওয়া ও ফল ছিদ্র',
      ];
      pestSlot = [
        'সরিষা ও শাকসবজির জাবপোকা বা এফিড দমন',
        'মরিচ ও টমেটোর পাতা কুঁকড়ানো থ্রিপস পোকা',
        'ডাল ফসলের শুঁটি ছিদ্রকারী পোকা দমন',
        'বেগুন ও আলুর কাটুই পোকা দ্বারা গোড়া কাটা',
      ];
      cashSlot = [
        'সরিষার পাতায় গোল দাগ ও অল্টারনারিয়া ব্লাইট',
        'পেঁয়াজের পাতায় বেগুনী দাগ (Purple Blotch)',
        'মসুর ও ছোলার গোড়া পচা বা উইল্ট রোগ',
        'পান ও মিষ্টি কুমড়ার ডাউনি মিলডিউ আক্রমণ',
      ];
    } else if (isKharif1) {
      cerealSlot = [
        'আউশ ধানের পাতায় বাদামী দাগ ও ব্লাস্ট রোগ',
        'গ্রীষ্মকালীন ধানের মাজরা পোকার আক্রমণ',
        'গ্রীষ্মকালীন ভুট্টায় পাতা পোড়া রোগ',
        'আউশ ধানের কান্ড পচা ও খোলপোড়া রোগ',
      ];
      vegSlot = [
        'করলা ও শসার পাতা হলুদ ও ডাউনি মিলডিউ',
        'চালকুমড়া ও লাউয়ের পাতা পোড়া অ্যানথ্রাকনোজ',
        'ঢ্যাঁড়শের হলুদ শিরা মোজাইক ভাইরাস রোগ',
        'গ্রীষ্মকালীন টমেটোর ফুল ও ফল ঝরে যাওয়া',
      ];
      pestSlot = [
        'পাটের বিছাপোকা ও ঘোড়া পোকা দমন ব্যবস্থা',
        'ঝিঙা ও করলার মাছি পোকার আক্রমণ ও সমাধান',
        'পেঁপে ও সবজির মিলিবাগ বা সাদা ছাতা পোকা',
        'লেবুর প্রজাপতি পোকা ও পাতা সুরঙ্গকারী পোকা',
      ];
      cashSlot = [
        'পাটের কান্ড পচা ও শুকিয়ে যাওয়া রোগ',
        'গ্রীষ্মকালীন তিলের পাতা মোড়ানো পোকা',
        'তরমুজের ডগা পচা ও ফিউজারিয়াম উইল্ট',
        'আখের ডগা ও কান্ড ছিদ্রকারী পোকা দমন',
      ];
    } else {
      // খরিফ-২ (আমন মৌসুম)
      cerealSlot = [
        'রোপা আমন ধানের পাতাপোড়া (BLB) ব্যাকটেরিয়াল রোগ',
        'আমন ধানের খোলপোড়া (Sheath Blight) আক্রমণ',
        'ধানের শীষ ব্লাস্ট ও চিটা হওয়া প্রতিরোধ',
        'ধানের খোলপচা ও বাদামী ঘাসফড়িং (BPH) আক্রমণ',
      ];
      vegSlot = [
        'বর্ষাকালীন বেগুনের গোড়া পচা ও ঢলে পড়া',
        'পটল ও বরবটির পাতায় হলুদাভ ছোপ মোজাইক',
        'বর্ষায় মরিচ গাছের পাতা ঝরে যাওয়া ও অ্যানথ্রাকনোজ',
        'শাকসবজির পাতা ফুটোকারী লেদা পোকা দমন',
      ];
      pestSlot = [
        'আমন ধানের মাজরা পোকা ও মৃত কুশি সমস্যা',
        'ধানের গান্ধী পোকা দ্বারা শিষের দুধ চুষে খাওয়া',
        'কলার পাতা বিছা পোকা ও পাতা পোড়া রোগ',
        'ডালিম ও পেয়ারার মাছি পোকার আক্রমণ ও ছিদ্র',
      ];
      cashSlot = [
        'কলার পানামা ও সিগাটোকা পাতার রোগ',
        'আখের লাল পচা (Red Rot) ছত্রাক রোগ',
        'আম গাছের আগা মরা (Dieback) ও ঝুল রোগ',
        'পান বরজের পাতা পচা ও গোড়া পচা রোগ',
      ];
    }

    return [
      DailyPromptItem(
        query: cerealSlot[dayOfYear % cerealSlot.length],
        category: 'খাদ্যশস্য',
        icon: Icons.grain_rounded,
        color: const Color(0xFF2E7D32),
      ),
      DailyPromptItem(
        query: vegSlot[(dayOfYear + 1) % vegSlot.length],
        category: 'শাকসবজি',
        icon: Icons.eco_rounded,
        color: const Color(0xFF388E3C),
      ),
      DailyPromptItem(
        query: pestSlot[(dayOfYear + 2) % pestSlot.length],
        category: 'বালাই দমন',
        icon: Icons.pest_control_rounded,
        color: const Color(0xFFD84315),
      ),
      DailyPromptItem(
        query: cashSlot[(dayOfYear + 3) % cashSlot.length],
        category: 'ফল ও অর্থকরী',
        icon: Icons.yard_rounded,
        color: const Color(0xFFE65100),
      ),
    ];
  }

  // প্রসঙ্গভিত্তিক ডাইনামিক লোডিং বার্তা নির্ধারণ (Requirement 4)
  List<String> _buildContextualThinkingMessages() {
    final text = _textController.text.trim().toLowerCase();
    final hasImage = _selectedImage != null;

    final isFertilizerOrPest = text.contains('সার') ||
        text.contains('পোকা') ||
        text.contains('কীট') ||
        text.contains('কীটপতঙ্গ') ||
        text.contains('ছিদ্র') ||
        text.contains('বালাই') ||
        text.contains('দমন') ||
        text.contains('কীটনাশক') ||
        text.contains('ছত্রাকনাশক');

    if (isFertilizerOrPest) {
      return [
        'কীটপতঙ্গ ও বালাইনাশক ডাটাবেজ যাচাই করা হচ্ছে...',
        'অনুমোদিত বালাই ব্যবস্থাপনা তৈরি হচ্ছে...',
        'সঠিক বালাইনাশকের মাত্রা নির্ধারণ করা হচ্ছে...',
        'KrishiMate AI পরামর্শ প্রস্তুত হচ্ছে...',
      ];
    } else if (hasImage) {
      return [
        'ছবি ও লক্ষণ বিশ্লেষণ করা হচ্ছে...',
        'উদ্ভিদের পাতার ক্ষত পর্যবেক্ষণ করা হচ্ছে...',
        'রোগের প্রকোপ ও ধরন শনাক্ত হচ্ছে...',
        'KrishiMate AI পরামর্শ প্রস্তুত হচ্ছে...',
      ];
    } else {
      return [
        'আপনার প্রশ্নের উত্তর তৈরি করা হচ্ছে...',
        'কৃষি ডাটাবেজ ও ফসলের স্বাস্থ্য বিশ্লেষণ হচ্ছে...',
        'কার্যকর জৈব ও আধুনিক সমাধান সাজানো হচ্ছে...',
        'KrishiMate AI পরামর্শ প্রস্তুত হচ্ছে...',
      ];
    }
  }

  @override
  void initState() {
    super.initState();

    // ১. অর্বের নিরবচ্ছিন্ন ঘূর্ণন অ্যানিমেশন
    _orbSpinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // ২. অর্বের পালস ও ব্রিদিং অ্যানিমেশন
    _orbPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // ৩. ইনপুট পিল থেকে সেন্ট্রাল অর্বে রূপান্তরের মরফ অ্যানিমেশন
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // ৪. অর্ব থেকে রেজাল্ট কার্ডে উন্মোচনের আনফোল্ড অ্যানিমেশন
    _unfoldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _textController.addListener(() {
      setState(() {});
    });

    // ক্যামেরা অথবা গ্যালারি সোর্স দিয়ে সরাসরি প্রবেশ করলে অটো-পিক (Requirement 1)
    if (widget.initialSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImage(widget.initialSource!);
      });
    }

    // ১. ওয়ান-টাইম ওয়েলকাম অনবোর্ডিং পপ-আপ চেক (First Image Concept)
    _checkFirstTimeWelcome();

    // ২. কৃষিবহির্ভূত প্রশ্নে রেট লিমিট ও ১ ঘণ্টার চ্যাট লক স্ট্যাটাস চেক
    _checkLockoutStatus();
  }

  // ২. কৃষিবহির্ভূত প্রশ্ন ও ১ ঘণ্টার লক স্ট্যাটাস যাচাই
  Future<void> _checkLockoutStatus() async {
    try {
      final status = await DiseaseDetectionService.instance.checkLockoutStatus();
      if (mounted) {
        setState(() {
          _isChatLocked = status['isLocked'] == true;
          _lockRemainingMinutes = status['remainingMinutes'] ?? 0;
        });
      }
    } catch (_) {}
  }

  // ২. চ্যাট লক নোটিশ ডায়ালগ/পপ-আপ
  void _showLockoutNoticeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
                ),
                child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFD32F2F), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'সেবা সাময়িকভাবে স্থগিত',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC62828),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'আপনি অতিরিক্ত কৃষিবহির্ভূত প্রশ্ন করেছেন। KrishiMate AI সেবাটি সাময়িকভাবে ১ ঘণ্টার জন্য স্থগিত রয়েছে। অনুগ্রহ করে ১ ঘণ্টা পর আবার চেষ্টা করুন।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF424242),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    'বুঝেছি',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ৩. কঠোর কৃষি প্রশ্ন যাচাই ও তাৎক্ষণিক পপ-আপ অ্যালার্ট (Strict Agro Validation Dialog)
  void _showUnauthorizedQueryDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'অননুমোদিত প্রশ্ন!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC62828),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "এটি গ্রহণযোগ্য প্রশ্ন নয়। 'কৃষি কথা' অ্যাপের এই সেবাটি শুধুমাত্র আপনার ফসল, গাছপালা ও উদ্ভিদের যাবতীয় রোগবালাই ও কৃষি সমস্যার সমাধানের জন্য নিবেদিত। অনুগ্রহ করে কৃষি বিষয়ক প্রশ্ন করার জন্য বিনীত অনুরোধ করা হচ্ছে।",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF424242),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ঠিক আছে',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ওয়ান-টাইম ওয়েলকাম অনবোর্ডিং পপ-আপ লজিক (SharedPreferences)
  Future<void> _checkFirstTimeWelcome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasSeen = prefs.getBool('has_seen_krishimate_intro') ?? false;
      if (!hasSeen && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showWelcomeOnboardingDialog();
          }
        });
      }
    } catch (e) {
      debugPrint('Welcome dialog check error: $e');
    }
  }

  // ১. প্রিমিয়াম ফুল-স্ক্রিন বা সেন্ট্রাল ওয়েলকাম ডায়ালগ/মডাল (First Image Concept)
  void _showWelcomeOnboardingDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      barrierLabel: 'KrishiMate Intro',
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (ctx, anim1, anim2) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF1F8E9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ১. শীর্ষে বোল্ড শিরোনাম: "Meet KrishiMate AI!"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFF2E7D32), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'স্মার্ট উদ্ভিদ বিশেষজ্ঞ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Meet KrishiMate AI!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 14),

                // ২. মাঝে একটি চ্যাট বাবল: "আপনার ফসলের সুরক্ষায় দরকার সঠিক পরামর্শ?"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF81C784), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF2E7D32), size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'আপনার ফসলের সুরক্ষায় দরকার সঠিক পরামর্শ?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B5E20),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ৩. নিচে কেন্দ্রে বড় করে অ্যাপের Lottie অ্যানিমেশন / 3D রোবট ক্যারেক্টার (width: 180, height: 180)
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.14),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Lottie.asset(
                      'assets/animation/AI chatbot.json',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      repeat: true,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/icons/pnglogo.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => Container(
                          width: 150,
                          height: 150,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE8F5E9),
                          ),
                          child: const Icon(Icons.psychology_rounded, size: 70, color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'আক্রান্ত পাতা বা ফসলের ছবি তুলুন অথবা সমস্যার লক্ষণ লিখে পাঠালেই কৃত্রিম বুদ্ধিমত্তা দিয়ে সেকেন্ডেই বৈজ্ঞানিক সমাধান মিলবে।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A5B4C),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // ৪. আকর্ষণীয় স্লাইড/ট্যাপ বাটন: "শুরু করুন (Get Started)"
                InkWell(
                  onTap: () async {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('has_seen_krishimate_intro', true);
                    } catch (e) {
                      debugPrint('Error saving intro flag: $e');
                    }
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'শুরু করুন (Get Started)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // মিডিয়া সোর্স শিট (প্লাস বাটন থেকে ক্যামেরা বা গ্যালারি বাছাই)
  void _showMediaSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'আক্রান্ত ফসলের ছবি যুক্ত করুন',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ছবি দিলে দ্রুত ও নির্ভুলভাবে পাতার রোগ শনাক্ত করা সম্ভব হবে',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _pickImage(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.camera_alt_rounded, size: 30, color: Color(0xFF2E7D32)),
                            SizedBox(height: 8),
                            Text(
                              'ক্যামেরা দিয়ে তুলুন',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _pickImage(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.photo_library_rounded, size: 30, color: Color(0xFF2E7D32)),
                            SizedBox(height: 8),
                            Text(
                              'গ্যালারি থেকে নিন',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _orbSpinController.dispose();
    _orbPulseController.dispose();
    _morphController.dispose();
    _unfoldController.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool get _hasValidInput {
    return _selectedImage != null || _textController.text.trim().isNotEmpty;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _selectedImage = picked;
            _webImageBytes = bytes;
          });
        } else {
          setState(() {
            _selectedImage = picked;
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ছবি বাছাইয়ে ত্রুটি হয়েছে: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      _webImageBytes = null;
    });
  }

  // ১. লঞ্চ ও চিন্তন অর্ব ফেজ শুরু (Launch & Thinking Orb Phase)
  Future<void> _launchThinkingAndAnalysis() async {
    if (!_hasValidInput || _currentPhase == DiseasePhase.thinking) return;

    // ২. কৃষিবহির্ভূত প্রশ্নে রেট লিমিট ও ১ ঘণ্টার সাময়িক লক চেক
    final lockStatus = await DiseaseDetectionService.instance.checkLockoutStatus();
    if (lockStatus['isLocked'] == true) {
      if (mounted) {
        setState(() {
          _isChatLocked = true;
          _lockRemainingMinutes = lockStatus['remainingMinutes'] ?? 0;
        });
        _showLockoutNoticeDialog();
      }
      return;
    }

    FocusScope.of(context).unfocus();

    final queryText = _textController.text.trim();
    final hasImage = _selectedImage != null || (_webImageBytes != null && _webImageBytes!.isNotEmpty);

    if (!hasImage && queryText.isEmpty) return;

    // ৩. কঠোর কৃষি প্রশ্ন যাচাই: ১০০% কৃষি, ফসল, বালাই বা উদ্ভিদ সম্পর্কিত হতে হবে
    if (!DiseaseDetectionService.isAgroQuestion(queryText, hasImage: hasImage)) {
      _showUnauthorizedQueryDialog();
      return;
    }

    _thinkingMessages = _buildContextualThinkingMessages();

    setState(() {
      _currentPhase = DiseasePhase.thinking;
      _currentMessageIndex = 0;
    });

    // ইনপুট পিল মরফ হয়ে কেন্দ্রে পৌঁছাবে
    await _morphController.forward(from: 0.0);

    // গতিশীল প্রসঙ্গভিত্তিক স্ট্যাটাস টেক্সট ট্রানজিশন টাইমার
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (mounted && _currentPhase == DiseasePhase.thinking) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _thinkingMessages.length;
        });
      }
    });

    try {
      final result = await DiseaseDetectionService.instance.analyzePlantDisease(
        imageFile: _selectedImage,
        imageBytes: _webImageBytes,
        symptomsText: _textController.text.trim(),
      );

      _messageTimer?.cancel();

      // ৩. কঠোর কৃষি প্রশ্ন যাচাই: কোনো প্রকার অ-কৃষি উত্তর বা চ্যাট বাবল তৈরি নিষিদ্ধ
      if (result.isNonAgri) {
        if (mounted) {
          setState(() {
            _currentPhase = DiseasePhase.idle;
          });
          _morphController.reverse();
          _showUnauthorizedQueryDialog();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _activeResult = result;
          _currentPhase = DiseasePhase.unfolded;
        });

        // অর্বটি প্রস্ফুটিত হয়ে কার্ডে বিস্তার লাভ করবে
        await _unfoldController.forward(from: 0.0);
      }
    } catch (e) {
      _messageTimer?.cancel();
      if (mounted) {
        setState(() {
          _currentPhase = DiseasePhase.idle;
        });
        _morphController.reverse();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('বিশ্লেষণে সমস্যা হয়েছে: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ৪. নতুন করে জানুন (Reset / New Question Flow)
  Future<void> _resetToIdle() async {
    await _unfoldController.reverse();
    await _morphController.reverse();

    // ১ ঘণ্টার লক অতিক্রান্ত হয়েছে কিনা পুনর্যাচাই
    await _checkLockoutStatus();

    if (mounted) {
      setState(() {
        _currentPhase = DiseasePhase.idle;
        _activeResult = null;
        _selectedImage = null;
        _webImageBytes = null;
        _textController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF6FAF6),
      body: Stack(
        children: [
          // ক্যানভাস ব্যাকগ্রাউন্ড ও অ্যাম্পিয়েন্ট লাইট
          Positioned.fill(
            child: CustomPaint(
              painter: _AmbientBackgroundPainter(
                spinAnimation: _orbSpinController,
                pulseAnimation: _orbPulseController,
              ),
            ),
          ),

          // ১. সম্পূর্ণ স্ক্রিন জুড়ে এজ-টু-এজ লেআউট
          SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                // ১. পরিচ্ছন্ন মিনিমাল শীর্ষ বার (হিস্ট্রি মোডে শুধুমাত্র ব্যাক ও টাইটেল, হিস্ট্রি আইকন লুপ নেই)
                _buildTopHeader(topPadding),

                // মধ্যবর্তী ফ্লুইড ট্রান্সিশন অঞ্চল
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // অলস অবস্থার কনটেন্ট (Idle suggestions)
                      if (_currentPhase == DiseasePhase.idle)
                        _buildIdleBody(),

                      // চিন্তন অর্ব ফেজ (Thinking Orb Canvas)
                      if (_currentPhase == DiseasePhase.thinking)
                        _buildThinkingOrbCanvas(size),

                      // সমাধান উন্মোচন (Unfold Result State)
                      if (_currentPhase == DiseasePhase.unfolded && _activeResult != null)
                        _buildUnfoldedResultCard(size),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ১. এআই ইনপুট বার উপরে তোলা: ফিক্সড বটম মেনুবারের উচ্চতা বিবেচনা করে ৯৬dp ওপরে এবং কিবোর্ড খুললে কিবোর্ডের ১০dp ওপরে ফ্লোটিং
          if (_currentPhase == DiseasePhase.idle)
            Positioned(
              left: 0,
              right: 0,
              bottom: isKeyboardOpen ? 10.0 : 96.0,
              child: SafeArea(
                top: false,
                bottom: !isKeyboardOpen,
                child: _buildFrostedInputCapsule(),
              ),
            ),
        ],
      ),
    );
  }

  // ১. পরিচ্ছন্ন মিনিমাল শীর্ষ বার (Clean Minimal Top Bar: আনফোল্ড বা রেজাল্ট ভিউতে হিস্ট্রি আইকন সম্পূর্ণ অপসারিত)
  Widget _buildTopHeader(double topPadding) {
    final isUnfolded = _currentPhase == DiseasePhase.unfolded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: Color(0xFFE8F5E9), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // একদম বাম পাশে পরিচ্ছন্ন ব্যাক বাটন (রেজাল্ট ভিউতে _resetToIdle আর আইডল ভিউতে Navigator.maybePop)
          IconButton(
            tooltip: 'ফিরে যান',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: () {
              if (isUnfolded) {
                _resetToIdle();
              } else {
                Navigator.maybePop(context);
              }
            },
          ),
          if (isUnfolded) ...[
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'KrishiMate AI পরামর্শ ও সমাধান',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            const Spacer(),
          ],
          // একদম ডান পাশে হিস্ট্রি আইকন বাটন: রেজাল্ট বা বিস্তারিত ভিউতে হিস্ট্রি আইকন থাকবে না
          if (!isUnfolded)
            IconButton(
              tooltip: 'হিস্ট্রি',
              icon: const Icon(Icons.history_rounded, color: Color(0xFF2E7D32), size: 26),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrescriptionHistoryScreen()),
                );
              },
            ),
        ],
      ),
    );
  }

  // ২. মূল চ্যাট স্ক্রিন ইন্টারফেস (Second Image Concept Adaption)
  Widget _buildIdleBody() {
    final dailyPromptItems = _getDailySeasonalPromptItems();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 10, right: 10, top: 12, bottom: 180),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 6),

          // হেডলাইন ও সম্ভাষণ টেক্সট (Centered Headline & Greeting)
          const Text(
            'আসসালামু আলাইকুম। আমি KrishiMate AI.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'বলুন কিভাবে সাহায্য করতে পারি?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),

          const SizedBox(height: 18),

          // কেন্দ্রে বড় অ্যানিমেটেড লোগো (Prominent Centered Lottie Orb: 160x160)
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC8E6C9).withOpacity(0.5),
                    const Color(0xFFE8F5E9).withOpacity(0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.35, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.12),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Lottie.asset(
                  'assets/animation/AI chatbot.json',
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/icons/pnglogo.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Container(
                      width: 130,
                      height: 130,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE8F5E9),
                      ),
                      child: const Icon(Icons.psychology_rounded, size: 60, color: Color(0xFF2E7D32)),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // প্রতিদিন স্বয়ংক্রিয়ভাবে আপডেট হওয়া ৪টি কুইক সাজেশন কার্ড (2x2 Grid)
          _buildSeasonalPrompts2x2Grid(dailyPromptItems),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ৪টি কুইক সাজেশন কার্ড ২-কলামের গ্রিডে (2x2 Grid)
  Widget _buildSeasonalPrompts2x2Grid(List<DailyPromptItem> items) {
    if (items.length < 4) return const SizedBox();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSeasonalPromptCard(items[0])),
            const SizedBox(width: 10),
            Expanded(child: _buildSeasonalPromptCard(items[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildSeasonalPromptCard(items[2])),
            const SizedBox(width: 10),
            Expanded(child: _buildSeasonalPromptCard(items[3])),
          ],
        ),
      ],
    );
  }

  // প্রতিটি কুইক সাজেশন কার্ড
  Widget _buildSeasonalPromptCard(DailyPromptItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _textController.text = item.query;
          _launchThinkingAndAnalysis();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, size: 18, color: item.color),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.query,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ২. আধুনিক বটম ইনপুট বার (Bottom Capsule Bar: সর্বদা দৃশ্যমান ও কীবোর্ডে রেসপনসিভ)
  Widget _buildFrostedInputCapsule() {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // যদি ছবি সিলেক্ট করা থাকে তবে পিলের ওপরে প্রিভিউ চিপ
          if (_selectedImage != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF81C784), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb && _webImageBytes != null
                        ? Image.memory(_webImageBytes!, width: 28, height: 28, fit: BoxFit.cover)
                        : Image.file(File(_selectedImage!.path), width: 28, height: 28, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'আক্রান্ত পাতার ছবি সংযুক্ত',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _removeSelectedImage,
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],

          // ২. কৃষিবহির্ভূত প্রশ্নে রেট লিমিট ও ১ ঘণ্টার সাময়িক লক নোটিশ কার্ড (Requirement 2)
          if (_isChatLocked) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock_rounded, color: Color(0xFFD32F2F), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'আপনি অতিরিক্ত কৃষিবহির্ভূত প্রশ্ন করেছেন। KrishiMate AI সেবাটি সাময়িকভাবে ১ ঘণ্টার জন্য স্থগিত রয়েছে। অনুগ্রহ করে ১ ঘণ্টা পর আবার চেষ্টা করুন।',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC62828),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // মূল ফ্রস্টেড গ্লাস পিল ক্যাপসুল (সর্বদা স্ক্রিনের নিচে দৃশ্যমান)
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: _isChatLocked ? const Color(0xFFFAFAFA) : Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isChatLocked ? const Color(0xFFFFCDD2) : const Color(0xFFC8E6C9),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isChatLocked
                          ? Colors.red.withOpacity(0.06)
                          : const Color(0xFF2E7D32).withOpacity(0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ১. বাম পাশে ক্যামেরা আইকন
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isChatLocked ? _showLockoutNoticeDialog : () async => await _pickImage(ImageSource.camera),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: _isChatLocked ? Colors.grey.shade200 : const Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: _isChatLocked ? Colors.grey : const Color(0xFF2E7D32),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // ২. পাশে গ্যালারি আইকন
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isChatLocked ? _showLockoutNoticeDialog : () async => await _pickImage(ImageSource.gallery),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: _isChatLocked ? Colors.grey.shade200 : const Color(0xFFF1F8E9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.photo_library_rounded,
                            color: _isChatLocked ? Colors.grey : const Color(0xFF2E7D32),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // মাঝে সেন্ট্রাল টেক্সট ইনপুট ফিল্ড: অটো-এক্সপ্যান্ডিং ৪ লাইন পর্যন্ত (4-Line Auto Grow)
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        enabled: !_isChatLocked,
                        minLines: 1,
                        maxLines: 4,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: _isChatLocked ? Colors.grey.shade600 : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: _isChatLocked
                              ? 'KrishiMate AI সেবাটি সাময়িকভাবে স্থগিত...'
                              : 'ফসলের সমস্যা বা প্রশ্ন লিখুন...',
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: _isChatLocked ? Colors.red.shade300 : const Color(0xFF8D99AE),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ডানে ভাইব্রেন্ট গোল সেন্ড বাটন
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: (!_isChatLocked && _hasValidInput)
                              ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
                              : [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                        boxShadow: (!_isChatLocked && _hasValidInput)
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2E7D32).withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isChatLocked ? Icons.lock_rounded : Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _isChatLocked
                            ? _showLockoutNoticeDialog
                            : (_hasValidInput ? _launchThinkingAndAnalysis : null),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ৩. লঞ্চ ও চিন্তন অর্ব ফেজ (৩. লোডিং পপ-আপে অ্যানিমেশন বড় ও ফিট করা - কমপক্ষে 110x110)
  Widget _buildThinkingOrbCanvas(Size screenSize) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // সেন্ট্রাল বড় অ্যানিমেশন ও গ্লোয়িং অ্যাম্পিয়েন্ট হ্যালো (১৩৫x১৩৫ BoxFit.contain)
          Stack(
            alignment: Alignment.center,
            children: [
              // গ্লোয়িং ডটেড অরগানিক অর্ব
              AnimatedBuilder(
                animation: Listenable.merge([_orbSpinController, _orbPulseController]),
                builder: (context, _) {
                  return SizedBox(
                    width: 220,
                    height: 220,
                    child: CustomPaint(
                      painter: _GlowingDottedOrbPainter(
                        spinProgress: _orbSpinController.value,
                        pulseProgress: _orbPulseController.value,
                      ),
                    ),
                  );
                },
              ),

              // সেন্ট্রাল বড় ও পারফেক্টলি ফিট Lottie অ্যানিমেশন
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.18),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Lottie.asset(
                    'assets/animation/AI chatbot.json',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/icons/pnglogo.png',
                      width: 95,
                      height: 95,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const SizedBox(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // সেন্ট্রাল টাইটেল
          const Text(
            'KrishiMate AI',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),

          // নিচে প্রসঙ্গভিত্তিক স্ট্যাটাস টেক্সট ক্রমান্বয়ে স্মুথলি পরিবর্তন ("লক্ষণ বিশ্লেষণ করা হচ্ছে...")
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey<int>(_currentMessageIndex),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _thinkingMessages.isNotEmpty
                        ? _thinkingMessages[_currentMessageIndex % _thinkingMessages.length]
                        : 'লক্ষণ বিশ্লেষণ করা হচ্ছে...',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ১. সমাধান উন্মোচন (Unfold Result State: Unfolded Prescription Card)
  Widget _buildUnfoldedResultCard(Size screenSize) {
    final result = _activeResult!;

    return AnimatedBuilder(
      animation: _unfoldController,
      builder: (context, child) {
        final scale = 0.85 + (_unfoldController.value * 0.15);
        final opacity = _unfoldController.value.clamp(0.0, 1.0);

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              // ৩. বাইরের অপ্রয়োজনীয় বক্স/ফ্রেম দূর ও হরিজন্টাল ৮.০ এজ-টু-এজ মার্জিন (Edge-to-Edge Margins)
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0).copyWith(bottom: 120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ২. রেজাল্ট কার্ডের উপরে KrishiMate AI অ্যানিমেটেড ব্র্যান্ড লোগো ও হেডার
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Lottie.asset(
                          'assets/animation/AI chatbot.json',
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/icons/pnglogo.png',
                            height: 40,
                            width: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const SizedBox(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KrishiMate AI – কৃষি ও উদ্ভিদ সহকারী',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              Text(
                                'উদ্ভিদ রোগ নির্ণয় ও ব্যবস্থাপনা',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                    // ৩. কঠোর কৃষি ফিল্টার হ্যান্ডলিং (Strict Domain Filter)
                    if (result.isNonAgri) ...[
                      _buildNonAgriFeedbackBox(result),
                    ] else ...[
                      // ৪. মার্জিত ফুল-পেজ প্রশ্ন ও উত্তর একীভূত প্রদর্শন (Requirement 3)
                      _buildActionableAgriPrescription(result),
                    ],

                    const SizedBox(height: 22),

                    // ৪. অ্যাকশনেবল রিসেট ও অ্যাকশন বাটনসমূহ
                    Row(
                      children: [
                        // "নতুন করে জানুন (Reset/New Question)" বাটন
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetToIdle,
                            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2E7D32), size: 18),
                            label: const Text(
                              'নতুন করে জানুন',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2E7D32), width: 1.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // "পরামর্শ শেয়ার করুন" বাটন (প্রেসক্রিপশন শব্দ অপসারিত)
                        if (!result.isNonAgri)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => PrescriptionPdfService.shareOrDownloadPrescription(context, result),
                              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 17),
                              label: const Text(
                                'পরামর্শ শেয়ার',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
            ),
          ),
        );
      },
    );
  }

  // ৩. সাবলীল অ-কৃষি হ্যান্ডলিং বক্স (Strict Domain Filter Polite Response)
  Widget _buildNonAgriFeedbackBox(DiseaseDiagnosisResult result) {
    final message = result.nonAgriMessage ??
        "প্রিয় কৃষক ভাই, 'কৃষি কথা' অ্যাপের এই সেবাটি শুধুমাত্র আপনার ফসল, শাকসবজি, ফলমূল ও উদ্ভিদের যাবতীয় রোগবালাই শনাক্তকরণ ও কৃষি পরামর্শ প্রদানের জন্য তৈরি করা হয়েছে। অনুগ্রহ করে আপনার ফসলের কোনো সমস্যা বা আক্রান্ত পাতার ছবি ও লক্ষণ নিয়ে প্রশ্ন করুন। আমরা আপনাকে সঠিক সমাধান দিতে সদা প্রস্তুত।";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFF59D), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFF57F17), size: 22),
              SizedBox(width: 8),
              Text(
                'শুধুমাত্র কৃষি ও উদ্ভিদ সংরক্ষণ সেবা',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4E342E),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ৪. মার্জিত ফুল-পেজ প্রশ্ন ও উত্তর একীভূত প্রদর্শন (Requirement 3)
  Widget _buildActionableAgriPrescription(DiseaseDiagnosisResult result) {
    final queryText = result.userSymptoms?.isNotEmpty == true
        ? result.userSymptoms!
        : (_textController.text.trim().isNotEmpty
            ? _textController.text.trim()
            : (_selectedImage != null ? 'আক্রান্ত পাতার ছবি সংযুক্ত করে পরামর্শ চাওয়া হয়েছে।' : 'লক্ষণ বিশ্লেষণ'));

    final hasPhoto = _selectedImage != null ||
        (result.localImagePath != null && File(result.localImagePath!).existsSync());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ৩.১ শীর্ষে ব্যবহারকারীর প্রশ্ন / লক্ষণ (User's Question & Image Preview)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.help_outline_rounded, size: 17, color: Color(0xFF2E7D32)),
                  SizedBox(width: 7),
                  Text(
                    'আপনার প্রশ্ন / লক্ষণ:',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (hasPhoto) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _selectedImage != null
                        ? (kIsWeb && _webImageBytes != null
                            ? Image.memory(_webImageBytes!, height: 85, width: 85, fit: BoxFit.cover)
                            : Image.file(File(_selectedImage!.path), height: 85, width: 85, fit: BoxFit.cover))
                        : Image.file(File(result.localImagePath!), height: 85, width: 85, fit: BoxFit.cover),
                  ),
                ),
              ],
              Text(
                queryText,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2E3D2F),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ৩.২ নিচে KrishiMate AI এর বিশ্লেষণ ও পরামর্শ (একীভূত মার্জিত কন্টেইনার - No fragmented small boxes)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_rounded, size: 20, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Text(
                    'KrishiMate AI এর বিশ্লেষণ ও পরামর্শ:',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE8F5E9), height: 1),
              const SizedBox(height: 12),

              // চিহ্নিত সমস্যা ও ফসল
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBF9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8F5E9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'চিহ্নিত সমস্যা ও ফসল:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'নির্ভুলতা: ${result.confidence}',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${result.plantName} — ${result.diseaseName}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // প্রধান লক্ষণসমূহ
              if (result.causesAndSymptoms.isNotEmpty) ...[
                _buildResultSectionTitle(Icons.checklist_rounded, const Color(0xFF0288D1), 'প্রধান লক্ষণ ও ক্ষতির মাত্রা:'),
                const SizedBox(height: 6),
                ...result.causesAndSymptoms.map((s) => _buildBulletPoint(s, const Color(0xFF0288D1))),
                const SizedBox(height: 14),
              ],

              // তাৎক্ষণিক সমাধান (ঘরোয়া ও জৈব উপায়)
              if (result.organicCures.isNotEmpty) ...[
                _buildResultSectionTitle(Icons.eco_rounded, const Color(0xFF2E7D32), 'তাৎক্ষণিক সমাধান (ঘরোয়া ও জৈব উপায়):'),
                const SizedBox(height: 6),
                ...result.organicCures.map((o) => _buildCheckPoint(o, const Color(0xFF2E7D32))),
                const SizedBox(height: 14),
              ],

              // অনুমোদিত বালাইনাশক ও ব্যবহারের সঠিক মাত্রা
              if (result.chemicalCures.isNotEmpty) ...[
                _buildResultSectionTitle(Icons.science_rounded, const Color(0xFFBF360C), 'অনুমোদিত বালাইনাশক ও ব্যবহারের সঠিক মাত্রা:'),
                const SizedBox(height: 6),
                ...result.chemicalCures.map((chem) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chem.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFD84315))),
                        const SizedBox(height: 3),
                        Text('প্রয়োগমাত্রা: ${chem.dosage}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF37474F))),
                        if (chem.instruction.isNotEmpty)
                          Text(chem.instruction, style: const TextStyle(fontSize: 11, color: Color(0xFF546E7A))),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              // প্রতিরোধমূলক সতর্কতা ও পরিচর্যা
              if (result.precautionAndCare.isNotEmpty) ...[
                _buildResultSectionTitle(Icons.shield_rounded, const Color(0xFF7B1FA2), 'প্রতিরোধমূলক সতর্কতা ও পরিচর্যা:'),
                const SizedBox(height: 6),
                ...result.precautionAndCare.map((p) => _buildBulletPoint(p, const Color(0xFF7B1FA2))),
              ],

              // জরুরি সতর্কতা (যদি থাকে)
              if (result.emergencyWarning != null && result.emergencyWarning!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFC62828)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.emergencyWarning!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB71C1C), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultSectionTitle(IconData icon, Color color, String title) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text, Color bulletColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Icon(Icons.circle, size: 5, color: bulletColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF37474F), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckPoint(String text, Color checkColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 15, color: checkColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF263238), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// ১. গ্লোয়িং ডটেড অরগানিক অর্ব পেইন্টার (Glowing Dotted Sphere CustomPainter)
class _GlowingDottedOrbPainter extends CustomPainter {
  final double spinProgress;   // 0.0 to 1.0 (rotation)
  final double pulseProgress;  // 0.0 to 1.0 (breathing wave)

  _GlowingDottedOrbPainter({
    required this.spinProgress,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width / 2) * 0.72;
    final breathingRadius = baseRadius + (pulseProgress * 8.0);

    // ১. ব্যাকগ্রাউন্ড সফট রেডিয়াল গ্লো
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2E7D32).withOpacity(0.25),
          const Color(0xFF81C784).withOpacity(0.12),
          const Color(0xFFC8E6C9).withOpacity(0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: breathingRadius * 1.4));

    canvas.drawCircle(center, breathingRadius * 1.35, glowPaint);

    // ২. ৩ডি ডটেড স্ফিয়ার (3D Rotating Organic Dotted Sphere)
    const int latitudeRings = 11;
    const int dotsPerRing = 18;
    final double spinAngle = spinProgress * 2 * math.pi;
    const double tiltAngle = 0.35; // ~20 degrees tilt

    final List<_DotPoint> points = [];

    for (int i = 0; i < latitudeRings; i++) {
      final double latRatio = (i / (latitudeRings - 1)) * 2 - 1; // -1 to 1
      final double phi = latRatio * (math.pi / 2); // -pi/2 to pi/2
      final double ringRadius = breathingRadius * math.cos(phi);
      final double yBase = breathingRadius * math.sin(phi);

      for (int j = 0; j < dotsPerRing; j++) {
        final double theta = (j / dotsPerRing) * 2 * math.pi + spinAngle;

        // অরগানিক হারমোনিক ওয়েভ ওয়াবল
        final double wobble = math.sin(3 * theta + spinAngle * 2) * 2.5;
        final double curRadius = ringRadius + wobble;

        final double x = curRadius * math.cos(theta);
        final double z = curRadius * math.sin(theta);

        // রোটেশন ও টিল্ট ম্যাট্রিক্স
        final double yTilted = yBase * math.cos(tiltAngle) - z * math.sin(tiltAngle);
        final double zTilted = yBase * math.sin(tiltAngle) + z * math.cos(tiltAngle);

        // ডেপথ ক্যালকুলেশন (-breathingRadius to +breathingRadius)
        final double depthFactor = (zTilted + breathingRadius) / (2 * breathingRadius);

        points.add(_DotPoint(
          offset: Offset(center.dx + x, center.dy + yTilted),
          depth: depthFactor.clamp(0.0, 1.0),
        ));
      }
    }

    // ব্যাক-টু-ফ্রন্ট ডেপথ অনুযায়ী সর্টিং
    points.sort((a, b) => a.depth.compareTo(b.depth));

    // ডটগুলো ড্রয়িং
    for (final dot in points) {
      final double radius = 1.2 + (dot.depth * 2.6);
      final double opacity = 0.15 + (dot.depth * 0.85);

      // ফ্রন্টের পার্টিকেলগুলো ভাইব্রেন্ট এমারেল্ড ও গোল্ডেন এক্সেন্ট
      Color dotColor;
      if (dot.depth > 0.85) {
        dotColor = const Color(0xFF69F0AE); // নিয়ন এমারেল্ড
      } else if (dot.depth > 0.55) {
        dotColor = const Color(0xFF2E7D32); // প্রাইমারি এগ্রো গ্রিন
      } else {
        dotColor = const Color(0xFFA5D6A7); // সফট অ্যাকসেন্ট
      }

      final paint = Paint()
        ..color = dotColor.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(dot.offset, radius, paint);
    }

    // ৩. সেন্ট্রাল হার্টবিট ও সফট এগ্রো কোর
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.85),
          const Color(0xFF81C784).withOpacity(0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: breathingRadius * 0.35));

    canvas.drawCircle(center, breathingRadius * 0.3, corePaint);
  }

  @override
  bool shouldRepaint(covariant _GlowingDottedOrbPainter oldDelegate) {
    return oldDelegate.spinProgress != spinProgress || oldDelegate.pulseProgress != pulseProgress;
  }
}

class _DotPoint {
  final Offset offset;
  final double depth;

  _DotPoint({required this.offset, required this.depth});
}

/// ব্যাকগ্রাউন্ডের সফট অ্যাম্পিয়েন্ট লাইট পেইন্টার
class _AmbientBackgroundPainter extends CustomPainter {
  final Animation<double> spinAnimation;
  final Animation<double> pulseAnimation;

  _AmbientBackgroundPainter({
    required this.spinAnimation,
    required this.pulseAnimation,
  }) : super(repaint: Listenable.merge([spinAnimation, pulseAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    final t = spinAnimation.value * 2 * math.pi;
    final pulse = pulseAnimation.value;

    // টপ-লেফট সফট এমারেল্ড অরগানিক গ্লো
    final c1 = Offset(size.width * 0.2 + math.sin(t) * 20, size.height * 0.18 + math.cos(t) * 15);
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE8F5E9).withOpacity(0.6 + (pulse * 0.15)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c1, radius: 180));
    canvas.drawCircle(c1, 180, paint1);

    // বটম-রাইট সফট লাইট গ্রিন গ্লো
    final c2 = Offset(size.width * 0.85 + math.cos(t) * 25, size.height * 0.75 + math.sin(t) * 20);
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF1F8E9).withOpacity(0.7),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c2, radius: 210));
    canvas.drawCircle(c2, 210, paint2);
  }

  @override
  bool shouldRepaint(covariant _AmbientBackgroundPainter oldDelegate) => true;
}
