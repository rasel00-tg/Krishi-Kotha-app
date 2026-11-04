import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/district_data.dart';
import '../../providers/auth_provider.dart';
import '../navigation/main_navigation_screen.dart';

class RegistrationMultiStepScreen extends StatefulWidget {
  const RegistrationMultiStepScreen({super.key});

  @override
  State<RegistrationMultiStepScreen> createState() => _RegistrationMultiStepScreenState();
}

class _RegistrationMultiStepScreenState extends State<RegistrationMultiStepScreen> {
  final _formKey = GlobalKey<FormState>();

  // 8 Required Input Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _upazilaController = TextEditingController();
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

  // Constant font styling to fix font stability & digit jumping
  static const TextStyle _inputTextStyle = TextStyle(
    fontSize: 15.0,
    height: 1.2,
    fontWeight: FontWeight.w500,
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
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final district = _selectedDistrict;
    final upazila = _upazilaController.text.trim().isEmpty ? 'সদর' : _upazilaController.text.trim();
    final village = _villageController.text.trim();
    final occupation = _selectedOccupation;
    final password = _passwordController.text;

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

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অভিনন্দন! আপনার অ্যাকাউন্ট সফলভাবে তৈরি হয়েছে।'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 4)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: const Text(
          'নতুন একাউন্ট তৈরি করুন',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ================= ১. লোগো (NO CONTAINER, NO BORDER, NO SHADOW) =================
                SizedBox(
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

                const SizedBox(height: 10),

                // অ্যাপের নাম: "কৃষি কথা"
                const Text(
                  'কৃষি কথা',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'সকল প্রয়োজনীয় তথ্য দিয়ে আপনার প্রোফাইল তৈরি করুন',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                // ================= ২. সমস্ত ফিল্ড সহ পূর্ণাঙ্গ ফর্ম কার্ড =================
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8E2), width: 1.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 18,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          hintText: 'example@gmail.com',
                          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
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
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'অনুগ্রহ করে জিমেইল এড্রেস লিখুন';
                          }
                          final email = val.trim().toLowerCase();
                          final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
                          if (!email.endsWith('@gmail.com') || !gmailRegex.hasMatch(email)) {
                            return 'শুধুমাত্র @gmail.com ইমেইল গ্রহণযোগ্য (যেমন: user@gmail.com)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ২. মোবাইল নম্বর (১১ ডিজিট)
                      const Text(
                        '২. মোবাইল নম্বর (১১ ডিজিট) *',
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
                          hintText: '01XXXXXXXXX',
                          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
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
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'অনুগ্রহ করে মোবাইল নম্বর লিখুন';
                          }
                          final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                          if (clean.length != 11 || !clean.startsWith('01')) {
                            return 'সঠিক ১১ ডিজিটের বাংলাদেশী নম্বর দিন (যেমন: 017XXXXXXXX)';
                          }
                          return null;
                        },
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
                          hintText: 'যেমন: মো: রফিকুল ইসলাম',
                          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 22),
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
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'অনুগ্রহ করে আপনার নাম লিখুন';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ৪ ও ৫. জেলা ও উপজেলা সারি
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ৪. জেলা
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
                                  isExpanded: true,
                                  style: _inputTextStyle,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                                    ),
                                  ),
                                  items: BangladeshLocationData.districts.map((d) {
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

                          // ৫. উপজেলা
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
                                    hintText: 'উপজেলার নাম',
                                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
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
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'উপজেলা লিখুন';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // গ্রাম / পাড়া (ঐচ্ছিক)
                      const Text(
                        'গ্রাম / পাড়া / ঠিকানা',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _villageController,
                        style: _inputTextStyle,
                        strutStyle: _inputStrutStyle,
                        decoration: InputDecoration(
                          hintText: 'যেমন: শেরপুর গ্রাম বা রোড নম্বর',
                          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.home_outlined, color: AppColors.primary, size: 22),
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

                      // ৬. পেশা
                      const Text(
                        '৬. পেশা / ক্যাটাগরি *',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedOccupation,
                        isExpanded: true,
                        style: _inputTextStyle,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 22),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
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

                      // ৭. পাসওয়ার্ড (কমপক্ষে ৬ ডিজিট)
                      const Text(
                        '৭. পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর) *',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: _inputTextStyle,
                        strutStyle: _inputStrutStyle,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
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
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ৮. পাসওয়ার্ড নিশ্চিত করুন (কনফার্ম পাসওয়ার্ড)
                      const Text(
                        '৮. পাসওয়ার্ড নিশ্চিত করুন *',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: _inputTextStyle,
                        strutStyle: _inputStrutStyle,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
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
                        validator: (val) {
                          if (val != _passwordController.text) {
                            return 'পাসওয়ার্ড দুটি মিলছে না';
                          }
                          return null;
                        },
                      ),

                      if (authProvider.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.alertCritical, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authProvider.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.alertCritical,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 26),

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
                    ],
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
