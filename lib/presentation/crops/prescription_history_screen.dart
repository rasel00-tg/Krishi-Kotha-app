import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../data/models/disease_diagnosis_result.dart';
import '../../data/services/disease_detection_service.dart';
import '../auth/phone_login_screen.dart';
import 'disease_prescription_result_screen.dart';

class PrescriptionHistoryScreen extends StatefulWidget {
  const PrescriptionHistoryScreen({super.key});

  @override
  State<PrescriptionHistoryScreen> createState() => _PrescriptionHistoryScreenState();
}

class _PrescriptionHistoryScreenState extends State<PrescriptionHistoryScreen> {
  bool _isLoggedIn = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// ব্যবহারকারীর লগইন অবস্থা যাচাই (FirebaseAuth ও SharedPreferences চেক)
  Future<bool> _isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('krishi_kotha_cached_user');
      if (userJson != null) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        final uid = map['uid'] as String?;
        if (uid != null && !uid.startsWith('guest_')) {
          return true;
        }
      }
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && !fbUser.isAnonymous) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _checkLoginStatus({bool showSuccessOnLogin = false}) async {
    final loggedIn = await _isUserLoggedIn();
    if (mounted) {
      if (showSuccessOnLogin && !_isLoggedIn && loggedIn) {
        setState(() {
          _isLoggedIn = true;
        });
        _showSetupSuccessDialog();
      } else {
        setState(() {
          _isLoggedIn = loggedIn;
        });
      }
    }
  }

  /// "লগইন করুন" বাটনে ক্লিক করলে সরাসরি লগইন স্ক্রিনে নিয়ে যাবে
  Future<void> _navigateToLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
    );
    // লগইন স্ক্রিন থেকে ফিরে এলে স্ট্যাটাস পুনর্যাচাই এবং সফল হলে পপ-আপ প্রদর্শন
    await _checkLoginStatus(showSuccessOnLogin: true);
  }

  /// ৪. সফল লগইন ফিডব্যাক পপ-আপ: "সেটআপ সম্পন্ন হয়েছে!"
  void _showSetupSuccessDialog() {
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
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 46,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'সেটআপ সম্পন্ন হয়েছে!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'আপনার একাউন্ট সফলভাবে যুক্ত হয়েছে। আপনার সকল রোগ শনাক্তকরণ হিস্ট্রি ও প্রেসক্রিপশন এখন ক্লাউডে স্থায়ীভাবে সংরক্ষিত থাকবে।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF455A64),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ঠিক আছে',
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

  String _formatBanglaDate(DateTime date) {
    const months = [
      '',
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর'
    ];
    final day = BanglaNumberConverter.toBangla(date.day.toString());
    final month = months[date.month];
    final year = BanglaNumberConverter.toBangla(date.year.toString());
    return '$day $month $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF6),
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            // ১. শীর্ষ হেডার (Clean Top Bar: ব্যাক বাটন ও পরিচ্ছন্ন টাইটেল)
            _buildTopHeader(),

            // ৩. ফিক্সড স্টিকি লগইন সতর্কবার্তা ব্যানার (Sticky Non-Scrolling Banner)
            if (!_isLoggedIn)
              _buildStickyLoginBanner(),

            // ২. ডাইনামিক ডেটা লোড এবং রিয়েল-টাইম ডিসপ্লে: Firestore StreamBuilder
            Expanded(
              child: StreamBuilder<List<DiseaseDiagnosisResult>>(
                stream: DiseaseDetectionService.instance.getRecentPrescriptionsStream(limit: 50),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                      ),
                    );
                  }

                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    // কোনো হিস্ট্রি না থাকলে কেন্দ্রে সাধারণ টেক্সট (Requirement 4)
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'পূর্বে কোনো হিস্ট্রি পাওয়া যায়নি',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  // সংরক্ষিত তালিকাটি স্ক্রলেবল ListView.builder দিয়ে প্রদর্শন (কিনারায় ফিট করা এজ-টু-এজ লেআউট)
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final String summary = item.userSymptoms?.isNotEmpty == true
                          ? item.userSymptoms!
                          : (item.causesAndSymptoms.isNotEmpty
                              ? item.causesAndSymptoms.first
                              : (item.organicCures.isNotEmpty ? item.organicCures.first : item.diseaseName));

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DiseasePrescriptionResultScreen(result: item),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // তারিখ ও তীর
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF558B2F)),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatBanglaDate(item.createdAt),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF558B2F),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF81C784)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // ফসলের নাম
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFA5D6A7), width: 0.8),
                                        ),
                                        child: Text(
                                          item.plantName,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1B5E20),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.diseaseName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1B5E20),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // সমস্যার সংক্ষিপ্ত বিবরণ
                                  Text(
                                    summary,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF37474F),
                                      height: 1.35,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ১. ক্লিন টপ হেডার
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE8F5E9), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'ফিরে যান',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text(
            'হিস্ট্রি',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  /// ৩. ফিক্সড স্টিকি সতর্কবার্তা ব্যানার (Sticky Non-Scrolling Banner)
  Widget _buildStickyLoginBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFFFE082), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFE65100),
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'আপনার হিস্ট্রি স্থায়ীভাবে সংরক্ষণ করতে হলে অবশ্যই একাউন্ট লগইন থাকতে হবে।',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5D4037),
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _navigateToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'লগইন করুন',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
