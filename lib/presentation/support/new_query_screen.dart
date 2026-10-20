import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/district_data.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';

class NewQueryScreen extends StatefulWidget {
  const NewQueryScreen({super.key});

  @override
  State<NewQueryScreen> createState() => _NewQueryScreenState();
}

class _NewQueryScreenState extends State<NewQueryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  String _selectedDistrict = 'বগুড়া';
  String _selectedUpazila = 'শেরপুর';

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      _selectedDistrict = auth.user!.district;
      _selectedUpazila = auth.user!.upazila.isNotEmpty ? auth.user!.upazila : 'সদর';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final support = Provider.of<SupportProvider>(context, listen: false);

      final user = auth.user;
      final authorId = user?.uid ?? 'guest_user';
      final authorName = user?.name ?? 'কৃষক ভাই';
      final authorPhone = user?.phone ?? '';

      final success = await support.submitTicket(
        authorId: authorId,
        authorName: authorName,
        authorPhone: authorPhone,
        district: _selectedDistrict,
        upazila: _selectedUpazila,
        subject: _subjectController.text.trim(),
        details: _detailsController.text.trim(),
        imageFile: _selectedImage,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('আপনার প্রশ্ন সফলভাবে পাঠানো হয়েছে। কর্মকর্তা শীঘ্রই উত্তর দেবেন।'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final support = Provider.of<SupportProvider>(context);
    final upazilas = BangladeshLocationData.getUpazilas(_selectedDistrict);
    if (!upazilas.contains(_selectedUpazila) && upazilas.isNotEmpty) {
      _selectedUpazila = upazilas.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'কৃষি কর্মকর্তার কাছে প্রশ্ন'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.secondaryContainer),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'আক্রান্ত পাতা বা ফসলের স্পষ্ট ছবি ও লক্ষণের বিবরণ দিলে সঠিক ঔষধ ও সমাধান নির্ধারণ সহজ হয়।',
                        style: TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subject Field
              const Text(
                AppStrings.querySubject,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  hintText: 'উদা: বেগুনের ডগায় পোকা আক্রমণ করেছে',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'বিষয় লিখুন' : null,
              ),
              const SizedBox(height: 16),

              // Details Field
              const Text(
                AppStrings.queryDetails,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _detailsController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'কবে থেকে সমস্যা দেখা দিয়েছে এবং কী কী লক্ষণ দেখতে পাচ্ছেন লিখুন...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'বিস্তারিত বিবরণ লিখুন' : null,
              ),
              const SizedBox(height: 16),

              // District & Upazila Selectors
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      decoration: const InputDecoration(labelText: 'জেলা'),
                      items: BangladeshLocationData.districts.map((d) {
                        return DropdownMenuItem(value: d, child: Text(d));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDistrict = val;
                            final n = BangladeshLocationData.getUpazilas(val);
                            _selectedUpazila = n.isNotEmpty ? n.first : 'সদর';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUpazila,
                      decoration: const InputDecoration(labelText: 'উপজেলা'),
                      items: upazilas.map((u) {
                        return DropdownMenuItem(value: u, child: Text(u));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUpazila = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Image Attachment
              if (_selectedImage != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_selectedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('ফসলের ছবি তুলুন'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: AppStrings.submitQuery,
                onPressed: _submit,
                isLoading: support.isSubmitting,
                icon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
