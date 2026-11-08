import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/district_data.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/r2_storage_service.dart';
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
      // Client-side background auto-compression: maxWidth 1024, imageQuality 82 (Target ~200-350 KB)
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageName = pickedFile.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 18),
                Expanded(
                  child: Text(
                    'তথ্য আপডেট করা হচ্ছে....',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      String? uploadedUrl;

      // 1. Silent Background Cloudflare R2 Upload (Zero Orphan Safety - uploaded ONLY upon submit)
      if (_pickedImageBytes != null) {
        uploadedUrl = await R2StorageService.uploadProfileImage(
          bytes: _pickedImageBytes!,
          fileName: _pickedImageName.isNotEmpty ? _pickedImageName : 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // 2. Prepare Firestore update map
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
      };

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        updateData['photo_url'] = uploadedUrl;
        updateData['photoUrl'] = uploadedUrl;
        updateData['image_url'] = uploadedUrl;
      }

      // 3. Update Firestore Document
      if (FirebaseService.isFirebaseInitialized && activeUid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(activeUid)
            .set(updateData, SetOptions(merge: true));
      }

      // 4. Update weather provider location
      if (mounted) {
        final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
        weatherProvider.updateDistrict(_selectedDistrict);
      }

      // 5. Close Loading Dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // 6. Show Animated Success Dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF81C784), width: 2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Color(0xFF2E7D32),
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'সফল হয়েছে!',
                    style: TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'আপনার প্রোফাইল তথ্য সফলভাবে আপডেট হয়েছে!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF455A64),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Close dialog
                        Navigator.pop(context); // Return to menu screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ঠিক আছে',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (err) {
      debugPrint("Profile update error: $err");
      // Close Loading Dialog if open
      if (mounted) {
        Navigator.pop(context);
      }

      // Show Animated Failure Dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE57373), width: 2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFFD32F2F),
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'আপডেট ব্যর্থ হয়েছে',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'প্রোফাইল আপডেট ব্যর্থ হয়েছে। অনুগ্রহ করে ইন্টারনেট সংযোগ চেক করে আবার চেষ্টা করুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF455A64),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ঠিক আছে',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
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

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAF7),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 19),
              onPressed: () => Navigator.pop(context),
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
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
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
                            decoration: _buildInputDecoration(
                              hint: 'জেলা নির্বাচন করুন',
                              prefixIcon: Icons.location_on_outlined,
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                            items: BangladeshLocationData.districts.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(d, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                            decoration: _buildInputDecoration(
                              hint: 'উপজেলা নির্বাচন করুন',
                              prefixIcon: Icons.holiday_village_outlined,
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                            items: upazilas.map((u) {
                              return DropdownMenuItem(
                                value: u,
                                child: Text(u, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
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
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
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
                        onPressed: () => _submitProfileUpdate(activeUid),
                        icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                        label: const Text(
                          'আপডেট সাবমিট করুন',
                          style: TextStyle(
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

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted, fontWeight: FontWeight.normal),
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF9FBF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
