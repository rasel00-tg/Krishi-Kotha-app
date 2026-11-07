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
    fontSize: 16.0,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const StrutStyle _inputStrutStyle = StrutStyle(
    fontFamily: 'Roboto',
    fontSize: 16.0,
    height: 1.25,
    forceStrutHeight: true,
  );

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

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

    // ৩. মোবাইল নম্বর ভ্যালিডেশন
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty || cleanPhone.length != 11 || !cleanPhone.startsWith('01')) {
      showErrorPopup(context, "অনুগ্রহ করে ১১ ডিজিটের সঠিক মোবাইল নম্বর লিখুন!");
      return;
    }

    // ৪. জেলা ও উপজেলা ড্রপডাউন ভ্যালিডেশন (ড্রপডাউন সিলেক্ট না থাকলে ওয়ার্নিং পপ-আপ)
    if (_selectedDistrict == null ||
        _selectedDistrict!.trim().isEmpty ||
        _selectedUpazila == null ||
        _selectedUpazila!.trim().isEmpty) {
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
      // ১. Auth একাউন্ট তৈরি
      UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? uid = credential.user?.uid;
      if (uid == null) throw Exception("User UID not found");

      try {
        await credential.user?.updateDisplayName(name);
      } catch (_) {}

      // ২. সরাসরি ফায়ারস্টোরে আসল ফিল্ডগুলো ডক্যুমেন্ট আকারে সেট করা
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': cleanPhone,
        'district': _selectedDistrict ?? '',
        'upazila': _selectedUpazila ?? '',
        'occupation': _selectedOccupation,
        'createdAt': FieldValue.serverTimestamp(),
        'isDeletedByUser': false,
      });

      // লোকাল স্টেট ও ক্যাশ সিঙ্ক
      final userModel = UserModel(
        uid: uid,
        name: name,
        email: email,
        phone: cleanPhone,
        district: _selectedDistrict ?? '',
        upazila: _selectedUpazila ?? '',
        village: '',
        occupation: _selectedOccupation,
        preferredCrops: [],
        createdAt: DateTime.now(),
      );
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.setUser(userModel);
      } catch (_) {}

      // ৩. সফল পপ-আপ প্রদর্শন
      if (!context.mounted) return;
      showSuccessPopup(
        context,
        "আপনার একাউন্ট সফলভাবে তৈরি হয়েছে!",
        title: "সফল হয়েছে!",
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
      if (!context.mounted) return;
      String message = "একাউন্ট তৈরিতে ব্যর্থ হয়েছে!";
      if (e.code == 'email-already-in-use') message = "এই জিমেইল দিয়ে ইতোমধ্যে একাউন্ট খোলা আছে!";
      if (e.code == 'weak-password') message = "কমপক্ষে ৬ সংখ্যার শক্তিশালী পাসওয়ার্ড দিন!";
      if (e.code == 'invalid-email') message = "জিমেইল এড্রেসটি সঠিক নয়!";
      if (e.code == 'network-request-failed') message = "ইন্টারনেট সংযোগ চেক করুন এবং পুনরায় চেষ্টা করুন।";
      showErrorPopup(context, message);
    } catch (e) {
      if (!context.mounted) return;
      showErrorPopup(context, "ত্রুটি ঘটেছে: ${e.toString().replaceFirst('Exception: ', '')}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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

                const SizedBox(height: 14),

                // ================= ২. সমস্ত ফিল্ডসমূহ (কমপ্যাক্ট ১২-১৪px স্পেসিং সহ ফুল-স্ক্রিন) =================
                // ১. জিমেইল এড্রেস (সহজ ও পরিচ্ছন্ন লেবেল)
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
                          const Text(
                            'জেলা *',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                          const Text(
                            'উপজেলা *',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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

                // ৭. নতুন পাসওয়ার্ড
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
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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

                const SizedBox(height: 13),

                // ৮. পাসওয়ার্ড নিশ্চিত করুন (কনফার্ম পাসওয়ার্ড)
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
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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

                const SizedBox(height: 10),

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

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
