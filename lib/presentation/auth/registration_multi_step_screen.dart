import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/district_data.dart';
import '../../core/widgets/app_warning_dialog.dart';
import '../../data/models/user_model.dart';
import '../../data/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../navigation/main_navigation_screen.dart';

class RegistrationMultiStepScreen extends StatefulWidget {
  const RegistrationMultiStepScreen({super.key});

  @override
  State<RegistrationMultiStepScreen> createState() => _RegistrationMultiStepScreenState();
}

class _RegistrationMultiStepScreenState extends State<RegistrationMultiStepScreen> {
  final _formKey = GlobalKey<FormState>();

  // প্রয়োজনীয় ইনপুট কন্ট্রোলার
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedDistrict; // ডিফল্ট কোনো জেলা সিলেক্ট থাকবে না
  String? _selectedUpazila;  // জেলা সিলেক্ট হলে তবেই সক্রিয় হবে
  List<String> _upazilaOptions = [];
  String _selectedOccupation = 'কৃষক';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final List<String> _occupations = [
    'কৃষক',
    'কৃষি উদ্যোক্তা',
    'শিক্ষার্থী',
    'গবেষক',
    'কৃষি কর্মকর্তা',
    'অন্যান্য',
  ];

  // ফিক্সড ও অপরিবর্তনশীল ফন্ট স্টাইল (টাইপিংয়ের সময় কোনো ঝাঁকুনি বা আকার পরিবর্তন হবে না)
  static const TextStyle _inputTextStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15.0,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const StrutStyle _inputStrutStyle = StrutStyle(
    fontFamily: 'Roboto',
    fontSize: 15.0,
    height: 1.25,
    forceStrutHeight: true,
  );

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _nameController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _nameController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // রিয়েল-টাইম ভ্যালিডেশন গেটার্স
  bool get _isNameValid => _nameController.text.trim().length >= 2;

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    if (email.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool get _isPhoneValid {
    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanPhone.length == 11 && cleanPhone.startsWith('01');
  }

  bool get _isDistrictValid => _selectedDistrict != null && _selectedDistrict!.trim().isNotEmpty;

  bool get _isUpazilaValid => _selectedUpazila != null && _selectedUpazila!.trim().isNotEmpty;

  int get _passwordStrengthScore {
    final pass = _passwordController.text;
    if (pass.isEmpty) return 0;
    if (pass.length < 6) return 1; // দুর্বল
    final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(pass);
    final hasDigits = RegExp(r'[0-9]').hasMatch(pass);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass);
    if ((hasLetters && hasDigits) || (hasDigits && hasSpecial) || pass.length >= 8) {
      return 3; // শক্তিশালী
    }
    return 2; // মাঝারি
  }

  String get _passwordStrengthText {
    switch (_passwordStrengthScore) {
      case 1:
        return 'দুর্বল পাসওয়ার্ড (কমপক্ষে ৬ সংখ্যা বা অক্ষর দিন)';
      case 2:
        return 'মাঝারি পাসওয়ার্ড (সংখ্যা ও অক্ষরের মিশ্রণ ব্যবহার করুন)';
      case 3:
        return 'শক্তিশালী পাসওয়ার্ড';
      default:
        return '';
    }
  }

  Color get _passwordStrengthColor {
    switch (_passwordStrengthScore) {
      case 1:
        return const Color(0xFFE53935);
      case 2:
        return const Color(0xFFFB8C00);
      case 3:
        return const Color(0xFF2E7D32);
      default:
        return Colors.transparent;
    }
  }

  bool get _isPasswordMatch {
    final p1 = _passwordController.text;
    final p2 = _confirmPasswordController.text;
    return p1.isNotEmpty && p2.isNotEmpty && p1 == p2;
  }

  bool get _isPasswordMismatch {
    final p1 = _passwordController.text;
    final p2 = _confirmPasswordController.text;
    return p2.isNotEmpty && p1 != p2;
  }

  // অ্যানিমেটেড গ্লোয়িং সাকসেস টিক ব্যাজ
  Widget _buildLiveCheckBadge(bool isValid) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: isValid
          ? Container(
              key: const ValueKey('valid'),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.35),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 13,
              ),
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  // লাইভ কালারফুল পাসওয়ার্ড স্ট্রেংথ বার
  Widget _buildPasswordStrengthBar() {
    if (_passwordController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final score = _passwordStrengthScore;
    final color = _passwordStrengthColor;
    final label = _passwordStrengthText;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: score >= 1 ? color : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: score >= 2 ? color : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: score >= 3 ? color : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                score == 3
                    ? Icons.shield_rounded
                    : (score == 2 ? Icons.info_outline_rounded : Icons.warning_amber_rounded),
                size: 14,
                color: color,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // কনফার্ম পাসওয়ার্ড এক্সাক্টলি সঠিক অ্যালার্ট ব্যাজ
  Widget _buildConfirmPasswordMatchIndicator() {
    if (_confirmPasswordController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isPasswordMatch) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Container(
          key: const ValueKey('match'),
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 14.5),
              SizedBox(width: 6),
              Text(
                'এক্সাক্টলি সঠিক!',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isPasswordMismatch) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Container(
          key: const ValueKey('mismatch'),
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel_rounded, color: Color(0xFFE53935), size: 14.5),
              SizedBox(width: 6),
              Text(
                'পাসওয়ার্ড মিলছে না, পুনরায় যাচাই করুন!',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _onDistrictChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedDistrict = val;
      _selectedUpazila = null; // জেলা পরিবর্তন হলে আগের উপজেলা রিসেট
      _upazilaOptions = BangladeshLocationData.getUpazilas(val);
    });
  }

  Future<void> _submitRegistration() async {
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final district = _selectedDistrict?.trim() ?? '';
    final upazila = _selectedUpazila?.trim() ?? '';
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Ensure keyboard focus is unfocused
    FocusScope.of(context).unfocus();

    // ১. নাম ভ্যালিডেশন
    if (name.isEmpty) {
      showErrorPopup(context, "অনুগ্রহ করে আপনার পূর্ণ নাম লিখুন!");
      return;
    }

    // ২. ইমেইল ভ্যালিডেশন
    if (email.isEmpty) {
      showErrorPopup(context, "অনুগ্রহ করে একটি সঠিক জিমেইল এড্রেস লিখুন!");
      return;
    }

    // ৩. মোবাইল নম্বর ভ্যালিডেশন ডায়ালগ (১১ ডিজিট ও ০১ দিয়ে শুরু)
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length != 11 || !cleanPhone.startsWith('01')) {
      showErrorPopup(context, "অনুগ্রহ করে ১১ ডিজিটের সঠিক মোবাইল নম্বর লিখুন!");
      return;
    }

    // ৪. জেলা ও উপজেলা ড্রপডাউন ভ্যালিডেশন
    if (district.isEmpty || upazila.isEmpty) {
      showErrorPopup(context, "অনুগ্রহ করে জেলা ও উপজেলা নির্বাচন করুন!");
      return;
    }

    // ৫. পাসওয়ার্ড ভ্যালিডেশন
    if (password.isEmpty || confirmPassword.isEmpty) {
      showErrorPopup(context, "অনুগ্রহ করে পাসওয়ার্ড লিখুন!");
      return;
    }

    if (password.length < 6) {
      showErrorPopup(context, "কমপক্ষে ৬ সংখ্যার শক্তিশালী পাসওয়ার্ড দিন!");
      return;
    }

    if (password != confirmPassword) {
      showErrorPopup(context, "পাসওয়ার্ড দুটি মেলেনি, পুনরায় যাচাই করুন!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Duplicate check in Cloud Firestore users collection
      if (FirebaseService.isFirebaseInitialized) {
        try {
          final phoneQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: cleanPhone)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 8));

          if (phoneQuery.docs.isNotEmpty) {
            if (!context.mounted) return;
            if (mounted) setState(() => _isLoading = false);
            showErrorPopup(context, "এই মোবাইল নম্বর দিয়ে ইতোমধ্যে একাউন্ট খোলা রয়েছে!");
            return;
          }

          final altPhone = '+88$cleanPhone';
          final altPhoneQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: altPhone)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 8));

          if (altPhoneQuery.docs.isNotEmpty) {
            if (!context.mounted) return;
            if (mounted) setState(() => _isLoading = false);
            showErrorPopup(context, "এই মোবাইল নম্বর দিয়ে ইতোমধ্যে একাউন্ট খোলা রয়েছে!");
            return;
          }
        } catch (fsErr) {
          debugPrint('Firestore pre-check notice: $fsErr');
        }
      }

      // Step 2: FirebaseAuth createUserWithEmailAndPassword
      UserCredential? credential;
      if (FirebaseService.isFirebaseInitialized) {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 15));
      } else {
        throw Exception('সার্ভারের সাথে সংযোগ স্থাপন করা সম্ভব হয়নি। ইন্টারনেট সংযোগ চেক করুন।');
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('ব্যবহারকারী তৈরি করা সম্ভব হয়নি। আবার চেষ্টা করুন।');
      }

      try {
        await firebaseUser.updateDisplayName(name);
      } catch (_) {}

      // Step 3: Save profile in users/{uid} via .set()
      final userModel = UserModel(
        uid: firebaseUser.uid,
        name: name,
        email: email,
        phone: cleanPhone,
        district: district,
        upazila: upazila,
        village: '',
        occupation: _selectedOccupation,
        preferredCrops: [],
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'name': name,
        'email': email,
        'phone': cleanPhone,
        'district': district,
        'upazila': upazila,
        'village': '',
        'occupation': _selectedOccupation,
        'preferredCrops': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'isDeletedByUser': false,
      }).timeout(const Duration(seconds: 10));

      // Update AuthProvider and local storage cache
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.setUser(userModel);
      } catch (_) {}

      // Reset loading state BEFORE showing popup so interactive events are fully unblocked
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (!context.mounted) return;

      // Step 4: Success Popup & Redirection
      showSuccessPopup(
        context,
        'আপনার একাউন্ট সফলভাবে তৈরি হয়েছে।',
        title: 'অভিনন্দন!',
        onConfirm: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const MainNavigationScreen(initialIndex: 4),
            ),
            (route) => false,
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (!context.mounted) return;
      String message = "একাউন্ট তৈরিতে ব্যর্থ হয়েছে!";
      if (e.code == 'email-already-in-use') {
        message = "এই জিমেইল এড্রেস দিয়ে ইতোমধ্যে একটি একাউন্ট খোলা রয়েছে!";
      } else if (e.code == 'weak-password') {
        message = "পাসওয়ার্ডটি অত্যন্ত দুর্বল, আরও শক্তিশালী পাসওয়ার্ড দিন!";
      } else if (e.code == 'invalid-email') {
        message = "জিমেইল এড্রেসটি সঠিক নয়!";
      } else if (e.code == 'network-request-failed') {
        message = "ইন্টারনেট সংযোগ চেক করুন এবং পুনরায় চেষ্টা করুন।";
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      showErrorPopup(context, message);
    } on FirebaseException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (!context.mounted) return;
      showErrorPopup(
        context,
        e.message != null && e.message!.isNotEmpty
            ? e.message!
            : "সার্ভারের সাথে সংযোগ স্থাপন করা সম্ভব হয়নি। ইন্টারনেট সংযোগ চেক করুন।",
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (!context.mounted) return;
      showErrorPopup(
        context,
        e.toString().replaceFirst('Exception: ', '').isNotEmpty
            ? e.toString().replaceFirst('Exception: ', '')
            : "একাউন্ট তৈরিতে সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।",
      );
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: const Text(
          'নতুন একাউন্ট তৈরি করুন',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFF7EE), Color(0xFFFCFDFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2EBE2), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ================= ১. লোগো ও হেডার =================
                        Center(
                          child: SizedBox(
                            width: 75,
                            height: 75,
                            child: Image.asset(
                              'assets/icons/pnglogo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.eco_rounded,
                                size: 65,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // অ্যাপের নাম: "কৃষি কথা"
                        const Center(
                          child: Text(
                            'কৃষি কথা',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        const SizedBox(height: 3),

                        const Center(
                          child: Text(
                            'সকল প্রয়োজনীয় তথ্য দিয়ে আপনার প্রোফাইল তৈরি করুন',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ================= ২. সমস্ত ফিল্ডসমূহ (লাইভ চেকার ও ব্যাজ সহ) =================
                        // ১. জিমেইল এড্রেস
                        const Text(
                          'জিমেইল এড্রেস *',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: _inputTextStyle,
                          strutStyle: _inputStrutStyle,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          ],
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'example@gmail.com',
                            hintStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15.0,
                              color: AppColors.textMuted,
                              height: 1.25,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 22),
                            suffixIcon: _buildLiveCheckBadge(_isEmailValid),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                            ),
                          ),
                        ),

                        const SizedBox(height: 13),

                        // ২. মোবাইল নম্বর
                        const Text(
                          'মোবাইল নম্বর (১১ ডিজিট) *',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: _inputTextStyle,
                          strutStyle: _inputStrutStyle,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: '01XXXXXXXXX',
                            hintStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15.0,
                              color: AppColors.textMuted,
                              height: 1.25,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 22),
                            suffixIcon: _buildLiveCheckBadge(_isPhoneValid),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                            ),
                          ),
                        ),

                        const SizedBox(height: 13),

                        // ৩. পূর্ণ নাম
                        const Text(
                          'পূর্ণ নাম *',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _nameController,
                          style: _inputTextStyle,
                          strutStyle: _inputStrutStyle,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'আপনার পূর্ণ নাম লিখুন',
                            hintStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15.0,
                              color: AppColors.textMuted,
                              height: 1.25,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 22),
                            suffixIcon: _buildLiveCheckBadge(_isNameValid),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                            ),
                          ),
                        ),

                        const SizedBox(height: 13),

                        // ৪ ও ৫. জেলা ও উপজেলা (ডায়নামিক ডিপেন্ডেন্ট ড্রপডাউন)
                        Row(
                          children: [
                            // ৪. জেলা নির্বাচন
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'জেলা *',
                                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      const Spacer(),
                                      _buildLiveCheckBadge(_isDistrictValid),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  DropdownButtonFormField<String>(
                                    value: _selectedDistrict,
                                    style: _inputTextStyle,
                                    isExpanded: true,
                                    hint: const Text(
                                      'জেলা নির্বাচন করুন',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 13.5,
                                        color: AppColors.textMuted,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                                      ),
                                    ),
                                    items: DistrictData.districts.map((d) {
                                      return DropdownMenuItem(
                                        value: d,
                                        child: Text(
                                          d,
                                          style: _inputTextStyle,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _onDistrictChanged,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // ৫. উপজেলা নির্বাচন (জেলা সিলেক্ট হওয়ার পর সক্রিয়)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'উপজেলা *',
                                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      const Spacer(),
                                      _buildLiveCheckBadge(_isUpazilaValid),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  DropdownButtonFormField<String>(
                                    value: _selectedUpazila,
                                    style: _inputTextStyle,
                                    isExpanded: true,
                                    hint: Text(
                                      _selectedDistrict == null ? 'আগে জেলা বাছুন' : 'উপজেলা নির্বাচন করুন',
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 13.5,
                                        color: AppColors.textMuted,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                                      ),
                                    ),
                                    items: _upazilaOptions.map((upz) {
                                      return DropdownMenuItem(
                                        value: upz,
                                        child: Text(
                                          upz,
                                          style: _inputTextStyle,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _selectedDistrict == null
                                        ? null
                                        : (val) {
                                            if (val != null) setState(() => _selectedUpazila = val);
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 13),

                        // ৬. পেশা / ক্যাটাগরি
                        const Text(
                          'পেশা / ক্যাটাগরি *',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: _selectedOccupation,
                          style: _inputTextStyle,
                          decoration: InputDecoration(
                            isDense: true,
                            prefixIcon: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 22),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                            ),
                          ),
                          items: _occupations.map((occ) {
                            return DropdownMenuItem(value: occ, child: Text(occ, style: _inputTextStyle));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedOccupation = val);
                          },
                        ),

                        const SizedBox(height: 13),

                        // ৭. নতুন পাসওয়ার্ড (লাইভ স্ট্রেংথ মিটার সহ)
                        const Text(
                          'নতুন পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর) *',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          keyboardType: TextInputType.visiblePassword,
                          style: _inputTextStyle,
                          strutStyle: _inputStrutStyle,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'পাসওয়ার্ড নির্ধারণ করুন...',
                            hintStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15.0,
                              color: AppColors.textMuted,
                              height: 1.25,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 22),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLiveCheckBadge(_passwordStrengthScore >= 2),
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                            ),
                          ),
                        ),
                        _buildPasswordStrengthBar(),

                        const SizedBox(height: 11),

                        // ৮. পাসওয়ার্ড নিশ্চিত করুন (কনফার্ম পাসওয়ার্ড ও এক্সাক্টলি সঠিক অ্যালার্ট সহ)
                        const Text(
                          'পাসওয়ার্ড নিশ্চিত করুন *',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          keyboardType: TextInputType.visiblePassword,
                          style: _inputTextStyle,
                          strutStyle: _inputStrutStyle,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'একই পাসওয়ার্ড পুনরায় লিখুন...',
                            hintStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15.0,
                              color: AppColors.textMuted,
                              height: 1.25,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 22),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLiveCheckBadge(_isPasswordMatch),
                                IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                            ),
                          ),
                        ),
                        _buildConfirmPasswordMatchIndicator(),

                        const SizedBox(height: 18),

                        // নিচে স্পষ্ট ও চওড়া "একাউন্ট তৈরি করুন" সাবমিট বাটন
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2E7D32).withOpacity(0.32),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'একাউন্ট তৈরি করুন',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Back to Login Prompt
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'ইতিমধ্যে অ্যাকাউন্ট আছে? ',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'লগইন করুন',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
