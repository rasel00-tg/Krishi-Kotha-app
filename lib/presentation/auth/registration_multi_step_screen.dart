import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/district_data.dart';
import '../../core/widgets/app_warning_dialog.dart';
import '../../providers/auth_provider.dart';
import '../navigation/main_navigation_screen.dart';

class RegistrationMultiStepScreen extends StatefulWidget {
  const RegistrationMultiStepScreen({super.key});

  @override
  State<RegistrationMultiStepScreen> createState() => _RegistrationMultiStepScreenState();
}

class _RegistrationMultiStepScreenState extends State<RegistrationMultiStepScreen> {
  final _formKey = GlobalKey<FormState>();

  // ৮টি প্রয়োজনীয় ইনপুট কন্ট্রোলার
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _upazilaController = TextEditingController(text: 'সদর');
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _selectedDistrict = 'বগুড়া';
  String _selectedOccupation = 'কৃষক';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    fontSize: 15.0,
    height: 1.2,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const StrutStyle _inputStrutStyle = StrutStyle(
    fontSize: 15.0,
    height: 1.2,
    forceStrutHeight: true,
  );

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _upazilaController.dispose();
    _villageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final district = _selectedDistrict;
    final upazila = _upazilaController.text.trim().isEmpty ? 'সদর' : _upazilaController.text.trim();
    final village = _villageController.text.trim();
    final occupation = _selectedOccupation;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // ১. জিমেইল ভ্যালিডেশন ডায়ালগ
    if (email.isEmpty) {
      showAppWarningDialog(
        context,
        message: 'অনুগ্রহ করে একটি সঠিক @gmail.com জিমেইল এড্রেস লিখুন!',
      );
      return;
    }
    if (!email.endsWith('@gmail.com') ||
        !RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$', caseSensitive: false).hasMatch(email)) {
      showAppWarningDialog(
        context,
        message: 'শুধুমাত্র বৈধ @gmail.com জিমেইল এড্রেস গ্রহণযোগ্য (যেমন: user@gmail.com)!',
      );
      return;
    }

    // ২. মোবাইল নম্বর ভ্যালিডেশন ডায়ালগ
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length != 11 || !cleanPhone.startsWith('01')) {
      showAppWarningDialog(
        context,
        message: 'অনুগ্রহ করে সঠিক ১১ ডিজিটের বাংলাদেশী মোবাইল নম্বর দিন (যেমন: 017XXXXXXXX)!',
      );
      return;
    }

    // ৩. নাম ভ্যালিডেশন ডায়ালগ
    if (name.isEmpty) {
      showAppWarningDialog(
        context,
        message: 'অনুগ্রহ করে আপনার পূর্ণ নাম লিখুন!',
      );
      return;
    }

    // ৪. পাসওয়ার্ড ভ্যালিডেশন ডায়ালগ
    if (password.length < 6) {
      showAppWarningDialog(
        context,
        message: 'পাসওয়ার্ড কমপক্ষে ৬ সংখ্যার বা অক্ষরের হতে হবে!',
      );
      return;
    }

    // ৫. কনফার্ম পাসওয়ার্ড ভ্যালিডেশন ডায়ালগ
    if (password != confirmPassword) {
      showAppWarningDialog(
        context,
        message: 'পাসওয়ার্ড এবং পাসওয়ার্ড নিশ্চিতকরণ মিলছে না!',
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.registerWithEmailAndPassword(
      email: email,
      password: password,
      phone: phone,
      name: name,
      district: district,
      upazila: upazila,
      village: village,
      occupation: occupation,
    );

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: Image.asset('assets/icons/pnglogo.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 12),
              const Text(
                'অভিনন্দন!',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              const Text(
                'আপনার অ্যাকাউন্ট সফলভাবে তৈরি হয়েছে। "কৃষি কথা"-এ আপনাকে স্বাগতম!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, color: AppColors.textPrimary, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 4)),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('এগিয়ে যান', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      showAppWarningDialog(
        context,
        message: authProvider.errorMessage ?? 'অ্যাকাউন্ট তৈরি করতে সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'ফিরে যান',
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
                // ================= ১. লোগো (NO CONTAINER, NO BORDER, NO SHADOW) =================
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.asset(
                      'assets/icons/pnglogo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded,
                        size: 70,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // অ্যাপের নাম: "কৃষি কথা"
                const Center(
                  child: Text(
                    'কৃষি কথা',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                const Center(
                  child: Text(
                    'সকল প্রয়োজনীয় তথ্য দিয়ে আপনার প্রোফাইল তৈরি করুন',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ================= ২. সমস্ত ৮টি ফিল্ড ধারাবাহিকভাবে দৃশ্যমান (FULL-SCREEN EDGE-TO-EDGE) =================
                // ১. জিমেইল এড্রেস (@gmail.com বাধ্যতামূলক)
                const Text(
                  '১. জিমেইল এড্রেস (@gmail.com বাধ্যতামূলক) *',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
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
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 22),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

                const SizedBox(height: 16),

                // ২. মোবাইল নম্বর (১১ ডিজিট, ০১ দিয়ে শুরু)
                const Text(
                  '২. মোবাইল নম্বর (১১ ডিজিট, ০১ দিয়ে শুরু) *',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
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
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 22),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

                const SizedBox(height: 16),

                // ৩. পূর্ণ নাম
                const Text(
                  '৩. পূর্ণ নাম *',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: _inputTextStyle,
                  strutStyle: _inputStrutStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'আপনার পূর্ণ নাম লিখুন',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 22),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

                const SizedBox(height: 16),

                // ৪ ও ৫. জেলা ও উপজেলা (সমান্তরাল গ্রিড)
                Row(
                  children: [
                    // ৪. জেলা নির্বাচন
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '৪. জেলা *',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedDistrict,
                            style: _inputTextStyle,
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
                              return DropdownMenuItem(value: d, child: Text(d, style: _inputTextStyle));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDistrict = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ৫. উপজেলা / থানা
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '৫. উপজেলা *',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _upazilaController,
                            style: _inputTextStyle,
                            strutStyle: _inputStrutStyle,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'উপজেলা',
                              hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.normal),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ৬. পেশা / ক্যাটাগরি
                const Text(
                  '৬. পেশা / ক্যাটাগরি *',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedOccupation,
                  style: _inputTextStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 22),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

                const SizedBox(height: 16),

                // ৭. নতুন পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)
                const Text(
                  '৭. নতুন পাসওয়ার্ড (কমপক্ষে ৬ ডিজিট/অক্ষর) *',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: _inputTextStyle,
                  strutStyle: _inputStrutStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'পাসওয়ার্ড নির্ধারণ করুন...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 22),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

                const SizedBox(height: 16),

                // ৮. পাসওয়ার্ড নিশ্চিত করুন (কনফার্ম পাসওয়ার্ড)
                const Text(
                  '৮. পাসওয়ার্ড নিশ্চিত করুন (কনফার্ম পাসওয়ার্ড) *',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: _inputTextStyle,
                  strutStyle: _inputStrutStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'একই পাসওয়ার্ড পুনরায় লিখুন...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 22),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

                const SizedBox(height: 28),

                // নিচে স্পষ্ট ও চওড়া "একাউন্ট তৈরি করুন" সাবমিট বাটন
                Container(
                  width: double.infinity,
                  height: 50,
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
                    onPressed: authProvider.isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: authProvider.isLoading
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

                const SizedBox(height: 22),

                // Back to Login Prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'ইতিমধ্যে অ্যাকাউন্ট আছে?',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'লগইন করুন',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
