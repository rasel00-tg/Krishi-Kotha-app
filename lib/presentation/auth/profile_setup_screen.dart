import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/district_data.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weather_provider.dart';
import '../navigation/main_navigation_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  String _selectedDistrict = 'বগুড়া';
  String _selectedUpazila = 'শেরপুর';
  final List<String> _selectedCrops = ['বোরো ধান', 'আলু'];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null && auth.user!.name != 'কৃষক ভাই' && auth.user!.name != 'শ্রদ্ধেয় কৃষক ভাই') {
      _nameController.text = auth.user!.name;
      _selectedDistrict = auth.user!.district;
      _selectedUpazila = auth.user!.upazila;
      if (auth.user!.preferredCrops.isNotEmpty) {
        _selectedCrops.clear();
        _selectedCrops.addAll(auth.user!.preferredCrops);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);

      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        district: _selectedDistrict,
        upazila: _selectedUpazila,
        preferredCrops: _selectedCrops,
      );

      weatherProvider.updateDistrict(_selectedDistrict);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final upazilas = BangladeshLocationData.getUpazilas(_selectedDistrict);
    if (!upazilas.contains(_selectedUpazila) && upazilas.isNotEmpty) {
      _selectedUpazila = upazilas.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: AppStrings.profileSetup,
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Prompt
                Card(
                  color: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.secondaryContainer),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.person_pin_circle_rounded, color: AppColors.primary, size: 36),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'আপনার এলাকা ও ফসলের তথ্য দিলে সঠিক আবহাওয়া ও পরামর্শ পাওয়া সহজ হবে।',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name Field
                const Text(
                  AppStrings.fullName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                    hintText: 'উদা: মো: রফিকুল ইসলাম',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'আপনার নাম লিখুন';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // District Dropdown
                const Text(
                  AppStrings.selectDistrict,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
                  ),
                  items: BangladeshLocationData.districts.map((d) {
                    return DropdownMenuItem(value: d, child: Text(d));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDistrict = val;
                        final newUpazilas = BangladeshLocationData.getUpazilas(val);
                        _selectedUpazila = newUpazilas.isNotEmpty ? newUpazilas.first : 'সদর';
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Upazila Dropdown
                const Text(
                  AppStrings.selectUpazila,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedUpazila,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.maps_home_work_outlined, color: AppColors.primary),
                  ),
                  items: upazilas.map((u) {
                    return DropdownMenuItem(value: u, child: Text(u));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedUpazila = val);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Preferred Crops
                const Text(
                  AppStrings.preferredCrops,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'যে ফসলগুলো আপনি সাধারণত চাষ করেন সেগুলো বেছে নিন:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: BangladeshLocationData.availableCrops.map((crop) {
                    final isSelected = _selectedCrops.contains(crop);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(
                        crop,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCrops.add(crop);
                          } else {
                            _selectedCrops.remove(crop);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 36),
                CustomButton(
                  text: AppStrings.saveAndContinue,
                  onPressed: _saveProfile,
                  icon: Icons.check_circle_outline,
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
