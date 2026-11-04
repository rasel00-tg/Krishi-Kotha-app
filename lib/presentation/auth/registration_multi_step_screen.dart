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
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
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

    // ৪. জেলা ভ্যালিডেশন ডায়ালগ
    if (_selectedDistrict == null || _selectedDistrict!.trim().isEmpty) {
      showAppWarningDialog(
        context,
        message: 'অনুগ্রহ করে আপনার জেলা নির্বাচন করুন!',
      );
      return;
    }

    // ৫. উপজেলা ভ্যালিডেশন ডায়ালগ
    if (_selectedUpazila == null || _selectedUpazila!.trim().isEmpty) {
      showAppWarningDialog(
        context,
        message: 'অনুগ্রহ করে আপনার উপজেলা নির্বাচন করুন!',
      );
      return;
    }

    // ৬. পাসওয়ার্ড ভ্যালিডেশন ডায়ালগ
    if (password.length < 6) {
      showAppWarningDialog(
        context,
        message: 'পাসওয়ার্ড কমপক্ষে ৬ সংখ্যার বা অক্ষরের হতে হবে!',
      );
      return;
    }

    // ৭. কনফার্ম পাসওয়ার্ড ভ্যালিডেশন ডায়ালগ
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
      district: _selectedDistrict!,
      upazila: _selectedUpazila!,
      village: '',
      occupation: _selectedOccupation,
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
