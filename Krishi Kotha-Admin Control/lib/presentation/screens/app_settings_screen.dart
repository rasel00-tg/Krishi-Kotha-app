import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/utils/admin_error_handler.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_firestore_service.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _lastUpdatedController = TextEditingController();
  final _bannerTextController = TextEditingController();
  final _policyContentController = TextEditingController();

  bool _isSaving = false;
  bool _isInitialized = false;
  int _activeSubTab = 0; // 0: এডিটর, 1: লাইভ প্রিভিউ

  @override
  void dispose() {
    _lastUpdatedController.dispose();
    _bannerTextController.dispose();
    _policyContentController.dispose();
    super.dispose();
  }

  void _populateForm(AdminPrivacyPolicyModel policy) {
    if (!_isInitialized) {
      _lastUpdatedController.text = policy.lastUpdated;
      _bannerTextController.text = policy.bannerText;
      _policyContentController.text = policy.content;
      _isInitialized = true;
    }
  }

  Future<void> _savePrivacyPolicy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await AdminFirestoreService.instance.updatePrivacyPolicy(
        content: _policyContentController.text.trim(),
        bannerText: _bannerTextController.text.trim(),
        lastUpdated: _lastUpdatedController.text.trim(),
        updatedBy: 'সুপার এডমিন',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'গোপনীয় নীতি সফলভাবে আপডেট ও সংরক্ষিত হয়েছে! সকল ইউজার অ্যাপে তাৎক্ষণিক সিঙ্ক হয়েছে।',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AdminColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(AdminErrorHandler.getFriendlyErrorMessage(e))),
              ],
            ),
            backgroundColor: AdminColors.alertCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restore_rounded, color: AdminColors.alertWarning),
            SizedBox(width: 10),
            Text('ডিফল্ট নীতিমালায় ফিরে যাবেন?'),
          ],
        ),
        content: const Text(
          'এটি বর্তমান এডিটর বক্সের টেক্সট ডিফল্ট নীতিমালায় প্রতিস্থাপন করবে। পরবর্তীতে "সংরক্ষণ করুন" চাপলে ডেটাবেজে তা আপডেট হবে।',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final defaultPolicy = AdminPrivacyPolicyModel.defaultPolicy();
              setState(() {
                _lastUpdatedController.text = defaultPolicy.lastUpdated;
                _bannerTextController.text = defaultPolicy.bannerText;
                _policyContentController.text = defaultPolicy.content;
              });
              Navigator.pop(ctx);
            },
            child: const Text('ডিফল্ট লোড করুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return StreamBuilder<AdminPrivacyPolicyModel>(
      stream: AdminFirestoreService.instance.getPrivacyPolicyStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          _populateForm(snapshot.data!);
        }

        return Scaffold(
          backgroundColor: AdminColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info Banner
                  _buildHeaderBanner(),

                  const SizedBox(height: 20),

                  // Mobile Tab Switcher (Editor vs Live Preview)
                  if (!isDesktop) ...[
                    _buildSubTabBar(),
                    const SizedBox(height: 16),
                  ],

                  // Content Layout: Side-by-side on Desktop, Toggled on Mobile
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Multi-line Editor & Fields
                        Expanded(
                          flex: 3,
                          child: _buildEditorCard(),
                        ),

                        const SizedBox(width: 24),

                        // Right Column: Live User App Preview
                        Expanded(
                          flex: 2,
                          child: _buildLivePreviewCard(),
                        ),
                      ],
                    )
                  else
                    // Mobile / Tablet view: show selected tab
                    _activeSubTab == 0 ? _buildEditorCard() : _buildLivePreviewCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.policy_rounded, color: AdminColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'অ্যাপস সেটিংস • গোপনীয়তা নীতি (Privacy Policy)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'এখানে যেকোনো ধারা বা টেক্সট এডিট করে আপডেট করলে তা সাথে সাথে ক্লাউড ফায়ারস্টোরে সেভ হবে এবং ইউজার অ্যাপে রিয়েল-টাইমে প্রদর্শিত হবে।',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Live Cloud Sync Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ফায়ারস্টোর লাইভ সিঙ্ক',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeSubTab = 0),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeSubTab == 0 ? AdminColors.primary : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: Text(
                  'এডিটর মোড',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _activeSubTab == 0 ? Colors.white : AdminColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeSubTab = 1),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeSubTab == 1 ? AdminColors.primary : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: Text(
                  'লাইভ ইউজার প্রিভিউ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _activeSubTab == 1 ? Colors.white : AdminColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: AdminColors.primary, size: 24),
              SizedBox(width: 10),
              Text(
                'গোপনীয়তা নীতি এডিটর (Privacy Policy Editor)',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Last Updated Field
          const Text(
            'সর্বশেষ হালনাগাদ ও সংস্করণ তথ্য',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _lastUpdatedController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'উদা: সর্বশেষ হালনাগাদ: নভেম্বর ২০২৬ • সংস্করণ ১.১.০',
              prefixIcon: const Icon(Icons.history_toggle_off_rounded, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9FBF9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.primary, width: 1.5)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'সংস্করণ তথ্য প্রদান করুন' : null,
          ),

          const SizedBox(height: 18),

          // 2. Banner Text Field
          const Text(
            'নিরাপত্তা হাইলাইট ব্যানার বার্তা',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _bannerTextController,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'কৃষকদের আস্থার প্ল্যাটফর্ম সংক্রান্ত ব্যানার বার্তা...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(Icons.verified_user_outlined, size: 20),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FBF9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.primary, width: 1.5)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'ব্যানার বার্তা প্রদান করুন' : null,
          ),

          const SizedBox(height: 18),

          // 3. Multi-line Policy Content Editor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'গোপনীয় নীতি সম্পূর্ণ বিবরণ (মাল্টি-লাইন এডিটর)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
              ),
              Text(
                'লাইন সংখ্যা: ${_policyContentController.text.split('\n').length}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _policyContentController,
            maxLines: null,
            minLines: 16,
            keyboardType: TextInputType.multiline,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AdminColors.textPrimary,
              fontFamily: 'Roboto',
            ),
            decoration: InputDecoration(
              hintText: 'এখানে ধারা অনুযায়ী পূর্ণ গোপনীয় নীতি টেক্সট লিখুন...',
              filled: true,
              fillColor: const Color(0xFFFAFCFA),
              contentPadding: const EdgeInsets.all(18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.primary, width: 1.8)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'গোপনীয় নীতির বিবরণ ফাঁকা রাখা যাবে না' : null,
          ),

          const SizedBox(height: 24),

          // Action Buttons Bar
          Row(
            children: [
              // Save / Update Action Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _savePrivacyPolicy,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 20),
                label: Text(
                  _isSaving ? 'সংরক্ষণ হচ্ছে...' : 'সংরক্ষণ করুন / আপডেট করুন',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),

              const SizedBox(width: 14),

              // Reset to Default Template Button
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _resetToDefault,
                icon: const Icon(Icons.restore_rounded, size: 18, color: AdminColors.textSecondary),
                label: const Text(
                  'ডিফল্ট টেমপ্লেট লোড',
                  style: TextStyle(fontSize: 14, color: AdminColors.textSecondary),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  side: const BorderSide(color: AdminColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard() {
    final lastUpdated = _lastUpdatedController.text.trim().isEmpty
        ? 'সর্বশেষ হালনাগাদ: নভেম্বর ২০২৬ • সংস্করণ ১.০.০'
        : _lastUpdatedController.text.trim();

    final bannerText = _bannerTextController.text.trim().isEmpty
        ? 'কৃষি কথা অ্যাপ কৃষকদের আস্থার প্ল্যাটফর্ম।'
        : _bannerTextController.text.trim();

    final content = _policyContentController.text.trim().isEmpty
        ? AdminPrivacyPolicyModel.defaultContentText()
        : _policyContentController.text.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E3D6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Preview Title
          Row(
            children: [
              const Icon(Icons.phone_android_rounded, color: AdminColors.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                'ইউজার অ্যাপ লাইভ প্রিভিউ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.primaryDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AdminColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('রিয়েল-টাইম', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // User App Mock Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo mockup
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded, color: AdminColors.primary, size: 28),
                ),
                const SizedBox(height: 10),
                const Text(
                  'কৃষি কথা – গোপনীয়তা ও সুরক্ষা নীতিমালা',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  lastUpdated,
                  style: const TextStyle(fontSize: 11.5, color: AdminColors.textMuted),
                ),
                const SizedBox(height: 14),

                // Banner Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AdminColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bannerText,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Policy Content Scrollable Box
                Container(
                  constraints: const BoxConstraints(maxHeight: 460),
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Text(
                        content,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF37474F),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Footer Box Preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'কৃষি কথা – Krishi Kotha',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.primaryDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'স্মার্ট কৃষিতে কৃষকের সাথে সবসময় • কপিরাইট © ২০২৬',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
