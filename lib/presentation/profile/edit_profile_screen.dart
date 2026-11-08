import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/utils/district_data.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/r2_storage_service.dart';
import '../../core/widgets/app_unified_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weather_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();

  String _selectedDistrict = 'বগুড়া';
  String _selectedUpazila = 'শেরপুর';

  bool _isInitialized = false;
  bool _isSubmitting = false;
  Uint8List? _pickedImageBytes;
  String _pickedImageName = '';
  String _currentPhotoUrl = '';

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _villageController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  void _populateInitialData(Map<String, dynamic>? data, dynamic authUser) {
    if (_isInitialized) return;

    final name = data?['name']?.toString() ?? authUser?.name ?? '';
    final phone = data?['phone']?.toString() ?? authUser?.phone ?? '';
    final email = data?['email']?.toString() ?? authUser?.email ?? '';
    final district = data?['district']?.toString() ?? authUser?.district ?? '';
    final upazila = data?['upazila']?.toString() ?? authUser?.upazila ?? '';
    final village = data?['village']?.toString() ?? data?['village_name']?.toString() ?? authUser?.village ?? '';
    final occupation = data?['occupation']?.toString() ?? authUser?.occupation ?? 'কৃষক';
    final photo = data?['photo_url']?.toString() ?? data?['photoUrl']?.toString() ?? data?['image_url']?.toString() ?? '';

    _nameController.text = name != 'কৃষক ভাই' && name != 'শ্রদ্ধেয় কৃষক ভাই' ? name : '';
    _phoneController.text = phone;
    _emailController.text = email;
    _villageController.text = village;
    _occupationController.text = occupation;
    _currentPhotoUrl = photo;

    if (district.isNotEmpty && BangladeshLocationData.districts.contains(district)) {
      _selectedDistrict = district;
    } else {
      _selectedDistrict = BangladeshLocationData.districts.first;
    }

    final upazilas = BangladeshLocationData.getUpazilas(_selectedDistrict);
    if (upazila.isNotEmpty && upazilas.contains(upazila)) {
      _selectedUpazila = upazila;
    } else if (upazilas.isNotEmpty) {
      _selectedUpazila = upazilas.first;
    }

    _isInitialized = true;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (pickedFile != null && mounted) {
        final rawBytes = await pickedFile.readAsBytes();

        // 1:1 Square Image Cropper Interface
        final croppedBytes = await Navigator.of(context, rootNavigator: true).push<Uint8List>(
          MaterialPageRoute(
            builder: (_) => SquareImageCropperScreen(
              imageBytes: rawBytes,
            ),
          ),
        );

        if (croppedBytes != null && mounted) {
          setState(() {
            _pickedImageBytes = croppedBytes;
            _pickedImageName = pickedFile.name;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  void _showRateLimitDialog(int remainingDays) {
    final remainingDaysBangla = BanglaNumberConverter.toBangla(remainingDays.toString());
    AppUnifiedDialog.showWarning(
      context,
      title: 'প্রোফাইল আপডেট সীমাবদ্ধতা',
      message: 'আপনি প্রতি ১ মাসে একবার প্রোফাইল আপডেট করতে পারবেন। পরবর্তী আপডেটের জন্য আর $remainingDaysBangla দিন অপেক্ষা করুন।',
      buttonText: 'বুঝেছি',
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'প্রোফাইল ছবি পরিবর্তন করুন',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                  ),
                  title: const Text('ক্যামেরা দিয়ে ছবি তুলুন', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Color(0xFF1565C0)),
                  ),
                  title: const Text('গ্যালারি থেকে নির্বাচন করুন', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitProfileUpdate(String activeUid) async {
    // 1. Prevent multiple parallel submissions
    if (_isSubmitting) return;

    // 2. Validate form fields BEFORE showing any dialog
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard immediately
    FocusScope.of(context).unfocus();

    // 3. Rate-Limit Check: 30 days (1 month) BEFORE showing any loading dialog
    if (FirebaseService.isFirebaseInitialized && activeUid.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(activeUid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          final dynamic rawTimestamp = data['lastProfileUpdate'] ?? data['last_profile_update'];
          DateTime? lastUpdateDate;
          if (rawTimestamp is Timestamp) {
            lastUpdateDate = rawTimestamp.toDate();
          } else if (rawTimestamp is String) {
            lastUpdateDate = DateTime.tryParse(rawTimestamp);
          }

          if (lastUpdateDate != null) {
            final now = DateTime.now();
            final difference = now.difference(lastUpdateDate);
            const int limitDays = 30;
            if (difference.inDays < limitDays) {
              final remainingDays = limitDays - difference.inDays;
              if (mounted) {
                _showRateLimitDialog(remainingDays > 0 ? remainingDays : 1);
              }
              return; // Cancel update immediately before loading dialog
            }
          }
        }
      } catch (checkErr) {
        debugPrint('Rate limit check error: $checkErr');
      }
    }

    if (!mounted) return;

    // 4. Set submitting state to safely block duplicates without screen freezing
    setState(() {
      _isSubmitting = true;
    });

    // 5. Guaranteed Dismissal Architecture with AppUnifiedDialog
    final loading = AppUnifiedDialog.showLoading(context, message: 'প্রোফাইল আপডেট হচ্ছে....');

    bool isSuccess = false;

    try {
      String? uploadedUrl;

      // Silent Background Cloudflare R2 Upload (Zero Orphan Safety - uploaded ONLY upon submit)
      if (_pickedImageBytes != null) {
        uploadedUrl = await R2StorageService.uploadProfileImage(
          bytes: _pickedImageBytes!,
          fileName: _pickedImageName.isNotEmpty ? _pickedImageName : 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // Prepare Firestore update map
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'district': _selectedDistrict,
        'upazila': _selectedUpazila,
        'village': _villageController.text.trim(),
        'village_name': _villageController.text.trim(),
        'occupation': _occupationController.text.trim().isNotEmpty ? _occupationController.text.trim() : 'কৃষক',
        'updated_at': FieldValue.serverTimestamp(),
        'lastProfileUpdate': FieldValue.serverTimestamp(),
        'last_profile_update': FieldValue.serverTimestamp(),
      };

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        updateData['photo_url'] = uploadedUrl;
        updateData['photoUrl'] = uploadedUrl;
        updateData['image_url'] = uploadedUrl;
      }

      // Update Firestore Document
      if (FirebaseService.isFirebaseInitialized && activeUid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(activeUid)
            .set(updateData, SetOptions(merge: true));
      }

      // Update weather provider location
      if (mounted) {
        final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
        weatherProvider.updateDistrict(_selectedDistrict);
      }

      isSuccess = true;
    } catch (err) {
      debugPrint("Profile update error: $err");
      isSuccess = false;
    } finally {
      // GUARANTEED 100% DISMISSAL of loading dialog
      loading.dismiss();

      // Always reset submitting state to instantly restore touch interactivity
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }

    // 6. Show Success or Non-blocking Failure Dialog
    if (isSuccess && mounted) {
      await AppUnifiedDialog.showSuccess(
        context,
        title: 'সফল হয়েছে!',
        message: 'আপনার প্রোফাইল তথ্য সফলভাবে আপডেট হয়েছে!',
        onConfirm: () {
          if (mounted) {
            Navigator.of(context).pop(); // Safely return to menu screen
          }
        },
      );
    } else if (mounted) {
      await AppUnifiedDialog.showError(
        context,
        title: 'আপডেট ব্যর্থ হয়েছে',
        message: 'প্রোফাইল আপডেট ব্যর্থ হয়েছে। অনুগ্রহ করে ইন্টারনেট সংযোগ চেক করে আবার চেষ্টা করুন।',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final activeUid = FirebaseAuth.instance.currentUser?.uid ?? user?.uid ?? '';

    final upazilas = BangladeshLocationData.getUpazilas(_selectedDistrict);
    if (!upazilas.contains(_selectedUpazila) && upazilas.isNotEmpty) {
      _selectedUpazila = upazilas.first;
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: (FirebaseService.isFirebaseInitialized && activeUid.isNotEmpty)
          ? FirebaseFirestore.instance.collection('users').doc(activeUid).snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.exists == true) {
          _populateInitialData(snapshot.data!.data(), user);
        } else if (!_isInitialized) {
          _populateInitialData(null, user);
        }

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFFF7FAF7),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 19),
              onPressed: () {
                if (!_isSubmitting) {
                  Navigator.pop(context);
                }
              },
              tooltip: 'ফিরে যান',
            ),
            title: const Text(
              'প্রোফাইল সম্পাদনা',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Avatar with Camera Picker Button
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE8F5E9), Color(0xFFA5D6A7), Color(0xFF69F0AE), Color(0xFF00E676)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF69F0AE).withOpacity(0.40),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(3.5),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.all(2.5),
                                child: ClipOval(
                                  child: _pickedImageBytes != null
                                      ? Image.memory(
                                          _pickedImageBytes!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        )
                                      : (_currentPhotoUrl.trim().isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: _currentPhotoUrl.trim(),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              placeholder: (_, __) => Container(
                                                color: const Color(0xFFE8F5E9),
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (_, __, ___) => _buildAvatarFallback(),
                                            )
                                          : _buildAvatarFallback()),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'ছবি পরিবর্তন করতে ট্যাপ করুন',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Card Container with Editable Form Fields
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2EBE2), width: 1.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Full Name
                          _buildFieldLabel('পূর্ণ নাম *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            style: _uniformInputStyle,
                            strutStyle: _uniformStrutStyle,
                            decoration: _buildInputDecoration(
                              hint: 'আপনার নাম লিখুন',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'আপনার নাম প্রদান করুন';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // Phone Number
                          _buildFieldLabel('মোবাইল নম্বর *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: _phoneInputStyle,
                            strutStyle: _phoneStrutStyle,
                            decoration: _buildInputDecoration(
                              hint: '০১৭১২XXXXXX',
                              prefixIcon: Icons.phone_android_rounded,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'মোবাইল নম্বর প্রদান করুন';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // Email
                          _buildFieldLabel('ইমেইল অ্যাড্রেস (ঐচ্ছিক)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: _uniformInputStyle,
                            strutStyle: _uniformStrutStyle,
                            decoration: _buildInputDecoration(
                              hint: 'example@gmail.com',
                              prefixIcon: Icons.email_outlined,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // District Dropdown
                          _buildFieldLabel('জেলা *'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedDistrict,
                            style: _uniformInputStyle,
                            decoration: _buildInputDecoration(
                              hint: 'জেলা নির্বাচন করুন',
                              prefixIcon: Icons.location_on_outlined,
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                            items: BangladeshLocationData.districts.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(d, style: _uniformInputStyle),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDistrict = val;
                                  final newUpz = BangladeshLocationData.getUpazilas(val);
                                  _selectedUpazila = newUpz.isNotEmpty ? newUpz.first : 'সদর';
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 18),

                          // Upazila Dropdown
                          _buildFieldLabel('উপজেলা *'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedUpazila,
                            style: _uniformInputStyle,
                            decoration: _buildInputDecoration(
                              hint: 'উপজেলা নির্বাচন করুন',
                              prefixIcon: Icons.holiday_village_outlined,
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                            items: upazilas.map((u) {
                              return DropdownMenuItem(
                                value: u,
                                child: Text(u, style: _uniformInputStyle),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedUpazila = val);
                              }
                            },
                          ),

                          const SizedBox(height: 18),

                          // Village / Union
                          _buildFieldLabel('গ্রাম / ইউনিয়ন / পোস্ট অফিস'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _villageController,
                            style: _uniformInputStyle,
                            strutStyle: _uniformStrutStyle,
                            decoration: _buildInputDecoration(
                              hint: 'উদা: চকগোবিন্দপুর, শেরপুর',
                              prefixIcon: Icons.home_outlined,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Occupation
                          _buildFieldLabel('পেশা'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _occupationController,
                            style: _uniformInputStyle,
                            strutStyle: _uniformStrutStyle,
                            decoration: _buildInputDecoration(
                              hint: 'উদা: কৃষক / কৃষি উদ্যোক্তা',
                              prefixIcon: Icons.work_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Update Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : () => _submitProfileUpdate(activeUid),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_upload_outlined, size: 20),
                        label: Text(
                          _isSubmitting ? 'আপডেট হচ্ছে....' : 'আপডেট সাবমিট করুন',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  static const TextStyle _phoneInputStyle = TextStyle(
    fontSize: 15.0,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    color: AppColors.textPrimary,
    fontFeatures: [
      ui.FontFeature.tabularFigures(),
      ui.FontFeature.liningFigures(),
    ],
  );

  static const StrutStyle _phoneStrutStyle = StrutStyle(
    fontSize: 15.0,
    height: 1.25,
    leading: 0,
    forceStrutHeight: true,
  );

  static const TextStyle _uniformInputStyle = TextStyle(
    fontFamily: 'HindSiliguri',
    fontFamilyFallback: ['Roboto', 'sans-serif'],
    fontSize: 15.0,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    fontFeatures: [
      ui.FontFeature.tabularFigures(),
      ui.FontFeature.liningFigures(),
    ],
  );

  static const StrutStyle _uniformStrutStyle = StrutStyle(
    fontFamily: 'HindSiliguri',
    fontSize: 15.0,
    height: 1.3,
    leading: 0,
    forceStrutHeight: true,
  );

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14.0,
        height: 1.3,
        color: AppColors.textMuted,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF9FBF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCE5DC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCE5DC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    final char = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim().substring(0, 1)
        : 'ক';
    return Container(
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Text(
          char,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      ),
    );
  }
}

/// 1:1 Aspect Ratio Square Image Cropper Screen
class SquareImageCropperScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const SquareImageCropperScreen({super.key, required this.imageBytes});

  @override
  State<SquareImageCropperScreen> createState() => _SquareImageCropperScreenState();
}

class _SquareImageCropperScreenState extends State<SquareImageCropperScreen> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _controller = TransformationController();
  bool _isCropping = false;

  Future<void> _performCrop() async {
    if (_isCropping) return;
    setState(() => _isCropping = true);
    try {
      final boundary = _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Navigator.pop(context);
        return;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List croppedBytes = byteData.buffer.asUint8List();
        if (mounted) {
          Navigator.pop(context, croppedBytes);
        }
        return;
      }
    } catch (e) {
      debugPrint('Error cropping profile image: $e');
    } finally {
      if (mounted) setState(() => _isCropping = false);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double cropBoxSize = (size.width - 48).clamp(240.0, 360.0);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ছবি ক্রপ করুন (১:১)',
          style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isCropping ? null : _performCrop,
            child: _isCropping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E676)),
                  )
                : const Text(
                    'সম্পন্ন',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'ছবিটি ড্র্যাগ ও জুম করে ফ্রেমের ভেতরে সাজান',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Center(
              child: Container(
                width: cropBoxSize,
                height: cropBoxSize,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00E676), width: 2.2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: RepaintBoundary(
                    key: _cropKey,
                    child: Container(
                      color: Colors.black,
                      child: InteractiveViewer(
                        transformationController: _controller,
                        minScale: 1.0,
                        maxScale: 4.5,
                        boundaryMargin: const EdgeInsets.all(200),
                        child: Center(
                          child: Image.memory(
                            widget.imageBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('বাতিল', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isCropping ? null : _performCrop,
                      icon: const Icon(Icons.crop_rounded, size: 18),
                      label: const Text('ক্রপ সম্পন্ন করুন', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

