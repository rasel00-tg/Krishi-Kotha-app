import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/utils/platform_file_picker/platform_file_picker.dart';
import '../../core/utils/admin_loading_controller.dart';
import '../../data/services/admin_firestore_service.dart';
import '../../data/services/r2_storage_service.dart';
import '../widgets/admin_delete_dialog.dart';
import '../widgets/admin_loading_indicator.dart';

class FarmingCalendarManagementScreen extends StatefulWidget {
  const FarmingCalendarManagementScreen({super.key});

  @override
  State<FarmingCalendarManagementScreen> createState() => _FarmingCalendarManagementScreenState();
}

class _FarmingCalendarManagementScreenState extends State<FarmingCalendarManagementScreen> {
  String _selectedMonth = 'সব মাস';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = false;
  BuildContext? _loadingDialogCtx;

  final List<String> _months = [
    'সব মাস',
    'বৈশাখ',
    'জ্যৈষ্ঠ',
    'আষাঢ়',
    'শ্রাবণ',
    'ভাদ্র',
    'আশ্বিন',
    'কার্তিক',
    'অগ্রহায়ণ',
    'পৌষ',
    'মাঘ',
    'ফাল্গুন',
    'চৈত্র',
  ];

  final List<String> _categories = [
    'দানা জাতীয় ফসল',
    'শাকসবজি',
    'ডাল ও তৈলবীজ',
    'অর্থকরী ফসল',
    'ফলমূল ও ফসল',
    'মসলা জাতীয়',
  ];

  final List<String> _seasons = [
    'রবি মৌসুম',
    'খরিপ-১ মৌসুম',
    'খরিপ-২ মৌসুম',
  ];

  Stream<List<Map<String, dynamic>>>? _calendarStream;

  @override
  void initState() {
    super.initState();
    _initCalendarStream();
  }

  void _initCalendarStream() {
    _calendarStream = AdminFirestoreService.instance.getFarmingCalendarStream(
      month: _selectedMonth != 'সব মাস' ? _selectedMonth : null,
    );
  }

  @override
  void dispose() {
    _safeDismissLoading();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showLoading(String message) {
    if (!mounted) return;
    _safeDismissLoading();
    showGlobalAdminLoading(message: message);
  }

  void _safeDismissLoading() {
    safeDismissAdminLoading();
    if (_loadingDialogCtx != null) {
      try {
        if (Navigator.canPop(_loadingDialogCtx!)) {
          Navigator.pop(_loadingDialogCtx!);
        }
      } catch (_) {}
      _loadingDialogCtx = null;
    }
  }

  Future<void> _showAdminActionSuccessDialog({
    required String title,
    required String message,
    bool isDanger = false,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isDanger ? AdminColors.alertCritical : AdminColors.primary).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDanger ? Icons.cancel_rounded : Icons.check_circle_rounded,
                color: isDanger ? AdminColors.alertCritical : AdminColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13.5, height: 1.4, color: AdminColors.textPrimary),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AdminColors.alertCritical : AdminColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ঠিক আছে', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? item}) async {
    final isEditing = item != null;
    final formKey = GlobalKey<FormState>();

    final cropNameCtrl = TextEditingController(text: item?['cropName']?.toString() ?? '');
    String selectedCategory = item?['cropCategory']?.toString() ?? _categories.first;
    String selectedMonth = item?['month']?.toString() ?? 'বৈশাখ';
    String selectedSeason = item?['season']?.toString() ?? _seasons.first;
    final sowingCtrl = TextEditingController(text: item?['sowingTime']?.toString() ?? '');
    final harvestingCtrl = TextEditingController(text: item?['harvestingTime']?.toString() ?? '');
    final descCtrl = TextEditingController(text: item?['description']?.toString() ?? '');
    final careTipsCtrl = TextEditingController(text: item?['careTips']?.toString() ?? '');

    Uint8List? selectedImageBytes;
    String? selectedImageName;
    int selectedImageSize = 0;
    String existingImageUrl = item?['imageUrl']?.toString() ?? '';
    bool isImageRemoved = false;

    if (!_categories.contains(selectedCategory)) selectedCategory = _categories.first;
    if (!_months.contains(selectedMonth) || selectedMonth == 'সব মাস') selectedMonth = 'বৈশাখ';
    if (!_seasons.contains(selectedSeason)) selectedSeason = _seasons.first;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDlgState) {
          bool isSaving = false;

          final hasActiveImage = (selectedImageBytes != null) || (existingImageUrl.isNotEmpty && !isImageRemoved);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_calendar_rounded : Icons.add_chart_rounded,
                    color: AdminColors.primaryDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEditing ? 'চাষ ক্যালেন্ডার তথ্য সম্পাদনা' : 'নতুন ফসলের চাষ ক্যালেন্ডার যোগ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AdminColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ফসল রোপণ, পরিচর্যা ও সময়সূচি বিবরণী সংরক্ষণ করুন',
                        style: TextStyle(fontSize: 12, color: AdminColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AdminColors.textMuted),
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 320,
                maxWidth: 720,
              ),
              child: SizedBox(
                width: 720,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ১. ফসলের নাম
                        const Text('ফসলের নাম *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: cropNameCtrl,
                          decoration: InputDecoration(
                            hintText: 'ফসলের নাম লিখুন (যেমন: বোরো ধান, আলু, তোষা পাট)',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'অনুগ্রহ করে ফসলের নাম লিখুন' : null,
                        ),
                        const SizedBox(height: 14),

                        // ২. মাস ও মৌসুম রো
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('উপযুক্ত মাস *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: selectedMonth,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    items: _months.where((m) => m != 'সব মাস').map((m) {
                                      return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setDlgState(() => selectedMonth = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('মৌসুম *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: selectedSeason,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    items: _seasons.map((s) {
                                      return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setDlgState(() => selectedSeason = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ৩. ক্যাটাগরি
                        const Text('ফসলের ধরণ / বিভাগ *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _categories.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDlgState(() => selectedCategory = val);
                          },
                        ),
                        const SizedBox(height: 14),

                        // ৪. বপন ও ফসল তোলার সময়
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('বপন / রোপণের সময়', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: sowingCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'বপন বা রোপণের সময় লিখুন (যেমন: মধ্য-কার্তিক থেকে অগ্রহায়ণ)',
                                      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ফসল তোলার সময়', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: harvestingCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'ফসল তোলার সময় লিখুন (যেমন: চৈত্র থেকে বৈশাখ)',
                                      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ৫. বিবরণ
                        const Text('চাষের সংক্ষিপ্ত বিবরণ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'ফসলের জাত ও চাষাবাদ সম্পর্কে সংক্ষিপ্ত বিবরণ লিখুন...',
                            hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ৬. পরিচর্যা পরামর্শ
                        const Text('পরিচর্যা ও সার প্রয়োগ পরামর্শ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: careTipsCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'সার প্রয়োগ, সেচ ও নিড়ানির গুরুত্বপূর্ণ টিপস লিখুন...',
                            hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ৭. লোকাল ইমেজ পিকার ও প্রিভিউ (ইমেজ URL টেক্সট ফিল্ড বাতিল)
                        const Text('ফসলের ছবি', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AdminColors.primaryDark,
                                side: const BorderSide(color: AdminColors.primary, width: 1.2),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                backgroundColor: const Color(0xFFF4FBF4),
                              ),
                              icon: const Icon(Icons.file_upload_outlined, size: 18),
                              label: Text(
                                hasActiveImage ? 'ছবি পরিবর্তন করুন' : 'ছবি নির্বাচন করুন',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final picked = await pickLocalImageFile();
                                      if (picked != null) {
                                        setDlgState(() {
                                          selectedImageBytes = picked.bytes;
                                          selectedImageName = picked.name;
                                          selectedImageSize = picked.size;
                                          isImageRemoved = false;
                                        });
                                      }
                                    },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedImageBytes != null
                                    ? 'ছবি নির্বাচিত (${(selectedImageSize / 1024).toStringAsFixed(1)} KB) — সংরক্ষণের সময় R2-তে আপলোড হবে'
                                    : (existingImageUrl.isNotEmpty && !isImageRemoved)
                                        ? 'বর্তমান ছবি সংযুক্ত রয়েছে'
                                        : 'ডিভাইস থেকে লোকাল ছবি নির্বাচন করুন',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selectedImageBytes != null ? const Color(0xFF2E7D32) : AdminColors.textMuted,
                                  fontWeight: selectedImageBytes != null ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ইমেজ প্রিভিউ বক্স
                        if (hasActiveImage) ...[
                          const SizedBox(height: 12),
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 140,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                  color: Colors.grey.shade50,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: selectedImageBytes != null
                                      ? Image.memory(
                                          selectedImageBytes!,
                                          width: double.infinity,
                                          height: 140,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          existingImageUrl,
                                          width: double.infinity,
                                          height: 140,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Text('ছবি প্রিভিউ করা সম্ভব হচ্ছে না', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () {
                                    setDlgState(() {
                                      selectedImageBytes = null;
                                      selectedImageName = null;
                                      selectedImageSize = 0;
                                      isImageRemoved = true;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD32F2F),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  isSaving ? 'সংরক্ষণ হচ্ছে...' : (isEditing ? 'আপডেট করুন' : 'সংরক্ষণ করুন'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDlgState(() => isSaving = true);

                        try {
                          _showLoading(isEditing ? 'তথ্য আপডেট হচ্ছে...' : 'নতুন ফসল সংরক্ষণ হচ্ছে...');

                          String finalImageUrl = existingImageUrl;
                          if (isImageRemoved) {
                            finalImageUrl = '';
                          }

                          // ধাপ ৫: ফর্ম ভ্যালিডেশন সফল হওয়ার পর Deferred Cloudflare R2 আপলোড
                          if (selectedImageBytes != null) {
                            _safeDismissLoading();
                            _showLoading('ছবি স্বয়ংক্রিয় অপ্টিমাইজ ও Cloudflare R2-তে আপলোড হচ্ছে...');

                            final cleanExt = (selectedImageName?.split('.').last ?? 'jpg').toLowerCase();
                            final uniqueFileName = 'fc_${DateTime.now().millisecondsSinceEpoch}_${(selectedImageName ?? 'crop').replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}.$cleanExt';

                            final uploadedUrl = await R2StorageService.uploadImageBytes(
                              bytes: selectedImageBytes!,
                              fileName: uniqueFileName,
                              contentType: cleanExt == 'png' ? 'image/png' : 'image/jpeg',
                            );
                            finalImageUrl = uploadedUrl;
                          }

                          if (finalImageUrl.isEmpty && !isEditing) {
                            finalImageUrl = 'https://images.unsplash.com/photo-1598971861713-54ad16a7e72e?w=600';
                          }

                          final monthIdx = _months.indexOf(selectedMonth);

                          final data = <String, dynamic>{
                            'cropName': cropNameCtrl.text.trim(),
                            'cropCategory': selectedCategory,
                            'month': selectedMonth,
                            'monthIndex': monthIdx > 0 ? monthIdx : 1,
                            'season': selectedSeason,
                            'sowingTime': sowingCtrl.text.trim(),
                            'harvestingTime': harvestingCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'careTips': careTipsCtrl.text.trim(),
                            'imageUrl': finalImageUrl,
                          };

                          if (isEditing) {
                            final docId = item['id'].toString();
                            await AdminFirestoreService.instance.updateFarmingCalendarItem(docId, data);
                          } else {
                            await AdminFirestoreService.instance.addFarmingCalendarItem(data);
                          }

                          _safeDismissLoading();
                          if (mounted && Navigator.canPop(dialogCtx)) {
                            Navigator.pop(dialogCtx);
                          }

                          await _showAdminActionSuccessDialog(
                            title: 'সফল হয়েছে!',
                            message: isEditing
                                ? 'ফসল সফলভাবে আপডেট করা হয়েছে।'
                                : 'ফসল সফলভাবে যুক্ত করা হয়েছে।',
                            isDanger: false,
                          );
                        } catch (e) {
                          _safeDismissLoading();
                          await _showAdminActionSuccessDialog(
                            title: 'সংরক্ষণে ত্রুটি',
                            message: 'তথ্য সংরক্ষণ করা যায়নি: $e',
                            isDanger: true,
                          );
                        } finally {
                          _safeDismissLoading();
                          if (mounted) setDlgState(() => isSaving = false);
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final docId = item['id']?.toString() ?? '';
    final cropName = item['cropName']?.toString() ?? 'ফসল';

    final confirmed = await AdminDeleteDialog.show(
      context,
      title: 'আপনি কি নিশ্চিত মুছে ফেলতে চান?',
      subtitle: 'এই ফসলের চাষ ক্যালেন্ডার তথ্যটি মুছে ফেললে অ্যাপ থেকেও স্থায়ীভাবে মুছে যাবে। আপনি কি এগিয়ে যেতে চান?',
      itemName: 'ফসল: $cropName',
    );

    if (confirmed) {
      try {
        _showLoading('মুছে ফেলা হচ্ছে...');
        await AdminFirestoreService.instance.deleteFarmingCalendarItem(docId);
        _safeDismissLoading();
        await _showAdminActionSuccessDialog(
          title: 'মুছে ফেলা সম্পন্ন',
          message: '"$cropName" সফলভাবে চাষ ক্যালেন্ডার থেকে মুছে ফেলা হয়েছে।',
          isDanger: true,
        );
      } catch (e) {
        _safeDismissLoading();
        await _showAdminActionSuccessDialog(
          title: 'মুছে ফেলতে ব্যর্থ',
          message: 'তথ্য মুছে ফেলা সম্ভব হয়নি: $e',
          isDanger: true,
        );
      } finally {
        _safeDismissLoading();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ১. হেডার ব্যানার ও অ্যাকশন বাটন
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'হোমপেইজ – চাষ ক্যালেন্ডার মনিটরিং',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '১২ মাসের কৃষিভিত্তিক রোপণ ও পরিচর্যা ক্যালেন্ডার ডেটাবেজ কন্ট্রোল',
                        style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('নতুন ফসল যোগ করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ২. ফিল্টার ও সার্চ বার
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAF7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'ফসলের নাম, মৌসুম বা ধরণ দিয়ে খুঁজুন...',
                            hintStyle: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AdminColors.primary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // মাসভিত্তিক চিপস
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _months.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, idx) {
                      final m = _months[idx];
                      final isSel = _selectedMonth == m;
                      return ChoiceChip(
                        label: Text(
                          m,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? Colors.white : AdminColors.textPrimary,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: AdminColors.primary,
                        backgroundColor: const Color(0xFFF1F8E9),
                        onSelected: (_) {
                          setState(() {
                            _selectedMonth = m;
                            _initCalendarStream();
                          });
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ৩. রিয়েল-টাইম ডেটাবেজ ভিউ (StreamBuilder)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _calendarStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const AdminLoadingIndicator(message: 'তথ্য লোডিং হচ্ছে.....');
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('ত্রুটি: ${snapshot.error}', style: const TextStyle(color: AdminColors.alertCritical)),
                  );
                }

                var items = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  items = items.where((it) {
                    final name = (it['cropName']?.toString() ?? '').toLowerCase();
                    final cat = (it['cropCategory']?.toString() ?? '').toLowerCase();
                    final season = (it['season']?.toString() ?? '').toLowerCase();
                    final desc = (it['description']?.toString() ?? '').toLowerCase();
                    return name.contains(q) || cat.contains(q) || season.contains(q) || desc.contains(q);
                  }).toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 48, color: AdminColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          _selectedMonth == 'সব মাস'
                              ? 'চাষ ক্যালেন্ডারে কোনো তথ্য পাওয়া যায়নি।'
                              : '$_selectedMonth মাসে কোনো ফসলের তথ্য নেই।',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditDialog(),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('নতুন ফসল যোগ করুন'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final it = items[idx];
                    return _buildAdminCalendarItemCard(it);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCalendarItemCard(Map<String, dynamic> item) {
    final cropName = item['cropName']?.toString() ?? 'ফসল';
    final month = item['month']?.toString() ?? '';
    final season = item['season']?.toString() ?? '';
    final category = item['cropCategory']?.toString() ?? '';
    final sowing = item['sowingTime']?.toString() ?? '';
    final harvesting = item['harvestingTime']?.toString() ?? '';
    final desc = item['description']?.toString() ?? '';
    final care = item['careTips']?.toString() ?? '';
    final img = item['imageUrl']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // থাম্বনেইল
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: img.isNotEmpty
                ? Image.network(
                    img,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: const Color(0xFFF1F8F1),
                      child: const Icon(Icons.eco_rounded, color: AdminColors.primary, size: 30),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFF1F8F1),
                    child: const Icon(Icons.eco_rounded, color: AdminColors.primary, size: 30),
                  ),
          ),
          const SizedBox(width: 14),

          // তথ্য কন্টেন্ট
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      cropName,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Text(
                        month.isNotEmpty ? '$month মাস' : '',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (season.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFB74D)),
                        ),
                        child: Text(
                          season,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'বিভাগ: $category',
                  style: const TextStyle(fontSize: 11.5, color: AdminColors.textMuted),
                ),
                const SizedBox(height: 6),

                // বপন ও ফসল তোলার সময়
                Row(
                  children: [
                    if (sowing.isNotEmpty)
                      Expanded(
                        child: Text(
                          'বপন: $sowing',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF1B5E20)),
                        ),
                      ),
                    if (harvesting.isNotEmpty)
                      Expanded(
                        child: Text(
                          'তোলা: $harvesting',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFE65100)),
                        ),
                      ),
                  ],
                ),

                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: AdminColors.textSecondary, height: 1.3),
                  ),
                ],
              ],
            ),
          ),

          // অ্যাকশন বাটনস
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AdminColors.primary, size: 20),
                tooltip: 'সম্পাদনা',
                onPressed: () => _showAddEditDialog(item: item),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.alertCritical, size: 20),
                tooltip: 'মুছে ফেলুন',
                onPressed: () => _deleteItem(item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

