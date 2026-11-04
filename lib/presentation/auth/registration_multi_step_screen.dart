import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/district_data.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../navigation/main_navigation_screen.dart';

class RegistrationMultiStepScreen extends StatefulWidget {
  const RegistrationMultiStepScreen({super.key});

  @override
  State<RegistrationMultiStepScreen> createState() => _RegistrationMultiStepScreenState();
}

class _RegistrationMultiStepScreenState extends State<RegistrationMultiStepScreen> {
  int _currentStep = 0; // 0 = Step 1, 1 = Step 2

  // Controllers Step 1
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _step1FormKey = GlobalKey<FormState>();

  // Controllers Step 2
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _upazilaController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _step2FormKey = GlobalKey<FormState>();

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

  void _goToStep2() {
    if (_step1FormKey.currentState!.validate()) {
      setState(() {
        _currentStep = 1;
      });
    }
  }

  void _goToStep1() {
    setState(() {
      _currentStep = 0;
    });
  }

  Future<void> _submitRegistration() async {
    if (!_step2FormKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
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
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
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
          'নতুন একাউন্ট নিবন্ধন',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (_currentStep == 1) {
              _goToStep1();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Wizard Indicator
              _buildStepIndicator(),

              const SizedBox(height: 20),

              // Animated Form Step
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == 0
                    ? _buildStep1Card(authProvider)
                    : _buildStep2Card(authProvider),
              ),

              const SizedBox(height: 24),

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
    );
  }

  /// Modern Step Indicator (Step 1 of 2 -> Step 2 of 2)
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E2), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStepBadge(
                stepIndex: 0,
                title: 'ধাপ ১',
                subtitle: 'যোগাযোগের তথ্য',
                isActive: _currentStep == 0,
                isCompleted: _currentStep > 0,
              ),
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _currentStep > 0 ? AppColors.primary : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _buildStepBadge(
                stepIndex: 1,
                title: 'ধাপ ২',
                subtitle: 'প্রোফাইল ও পাসওয়ার্ড',
                isActive: _currentStep == 1,
                isCompleted: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepBadge({
    required int stepIndex,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
  }) {
    final Color badgeColor = (isActive || isCompleted) ? AppColors.primary : const Color(0xFF9E9E9E);
    final Color bgColor = (isActive || isCompleted) ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: badgeColor, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 18, color: AppColors.primary)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: (isActive || isCompleted) ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Step 1: Communication Info (Email + Mobile)
  Widget _buildStep1Card(AuthProvider authProvider) {
    return Container(
      key: const ValueKey('step_1_card'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E2), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22.0),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mail_outline_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'প্রাথমিক যোগাযোগ তথ্য',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'আপনার বৈধ ইমেইল ও সচল মোবাইল নম্বর দিন',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Email Address
            const Text(
              'ইমেইল অ্যাড্রেস *',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'example@gmail.com',
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 22),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'অনুগ্রহ করে ইমেইল ঠিকানা প্রদান করুন';
                }
                final email = val.trim();
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(email)) {
                  return 'সঠিক ও কার্যকর ইমেইল ফরম্যাট লিখুন (যেমন: user@gmail.com)';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            // Mobile Number (11 digits)
            const Text(
              'মোবাইল নম্বর (১১ ডিজিট) *',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.8),
              decoration: InputDecoration(
                hintText: '01XXXXXXXXX',
                prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 22),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'অনুগ্রহ করে মোবাইল নম্বর প্রদান করুন';
                }
                final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                if (clean.length != 11 || !clean.startsWith('01')) {
                  return 'সঠিক ১১ ডিজিটের বাংলাদেশী নম্বর দিন (যেমন: 017XXXXXXXX)';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // Next Step Button
            CustomButton(
              text: 'পরবর্তী ধাপ (ধাপ ২)',
              onPressed: _goToStep2,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  /// Step 2: Personal Profile + Security
  Widget _buildStep2Card(AuthProvider authProvider) {
    return Container(
      key: const ValueKey('step_2_card'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E2), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22.0),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ব্যক্তিগত ও কৃষি প্রোফাইল',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'আপনার নাম, এলাকা ও পাসওয়ার্ড নির্ধারণ করুন',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Full Name
            const Text(
              'আপনার পূর্ণ নাম *',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'যেমন: মো: রফিকুল ইসলাম',
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 22),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'অনুগ্রহ করে আপনার নাম লিখুন';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // District & Upazila Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // District Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'জেলা *',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        isExpanded: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: BangladeshLocationData.districts.map((d) {
                          return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDistrict = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Upazila Text Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'উপজেলা *',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _upazilaController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'উপজেলার নাম',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

            // Village / Street Address
            const Text(
              'গ্রাম / ঠিকানা',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _villageController,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'যেমন: শিবগঞ্জ গ্রাম বা রোড নম্বর',
                prefixIcon: const Icon(Icons.home_outlined, color: AppColors.primary, size: 22),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            // Occupation / Category Dropdown
            const Text(
              'পেশা / ক্যাটাগরি *',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedOccupation,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 22),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _occupations.map((occ) {
                return DropdownMenuItem(value: occ, child: Text(occ, style: const TextStyle(fontSize: 14)));
              }).toList>,
              onChanged: (val) {
                if (val != null) setState(() => _selectedOccupation = val);
              },
            ),

            const SizedBox(height: 16),

            // Password Field
            const Text(
              'নতুন পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর) *',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: '••••••••',
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.length < 6) {
                  return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Confirm Password Field
            const Text(
              'পাসওয়ার্ড নিশ্চিত করুন *',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: '••••••••',
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

            // Buttons: Back & Submit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _goToStep1,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('পূর্ববর্তী'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: CustomButton(
                    text: 'একাউন্ট তৈরি করুন',
                    onPressed: _submitRegistration,
                    isLoading: authProvider.isLoading,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

