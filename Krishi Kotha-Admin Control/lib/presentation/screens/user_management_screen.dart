import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/utils/admin_error_handler.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_firestore_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _requestSearchController = TextEditingController();
  String _selectedStatusFilter = 'all'; // 'all', 'active', 'temporary_blocked', 'permanently_suspended'
  String _activeMainTab = 'users'; // 'users' or 'login_requests'
  String _requestStatusFilter = 'pending'; // 'pending', 'accepted', 'rejected'
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _requestSearchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AdminColors.alertCritical : AdminColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

  String _toBn(String s) {
    const eng = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bng = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < eng.length; i++) {
      s = s.replaceAll(eng[i], bng[i]);
    }
    return s;
  }

  String _formatDateBn(DateTime? dt) {
    if (dt == null) return 'অনুপলব্ধ';
    final months = ['জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'];
    final d = _toBn(dt.day.toString().padLeft(2, '0'));
    final m = months[dt.month - 1];
    final y = _toBn(dt.year.toString());
    final hr = _toBn((dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0'));
    final min = _toBn(dt.minute.toString().padLeft(2, '0'));
    final ampm = dt.hour >= 12 ? 'বিকাল' : 'সকাল';
    return '$d $m $y, $hr:$min $ampm';
  }

  String _formatPasswordResetDateBn(DateTime? dt) {
    if (dt == null) return 'এখনো পরিবর্তন করা হয়নি';
    final months = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    final d = _toBn(dt.day.toString().padLeft(2, '0'));
    final m = months[dt.month - 1];
    final y = _toBn(dt.year.toString());
    final hr = _toBn((dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0'));
    final min = _toBn(dt.minute.toString().padLeft(2, '0'));
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$d $m, $y - $hr:$min $ampm';
  }

  String _formatApplicationDate(dynamic rawDate) {
    if (rawDate == null) return 'অনুপলব্ধ';
    DateTime? dt;
    if (rawDate is Timestamp) {
      dt = rawDate.toDate();
    } else if (rawDate is DateTime) {
      dt = rawDate;
    } else if (rawDate is String) {
      dt = DateTime.tryParse(rawDate);
    }
    if (dt == null) return 'অনুপলব্ধ';

    final day = _toBn(DateFormat('dd').format(dt));
    final month = _toBn(DateFormat('MM').format(dt));
    final year = _toBn(DateFormat('yyyy').format(dt));
    final hour = _toBn(DateFormat('hh').format(dt));
    final minute = _toBn(DateFormat('mm').format(dt));
    final period = dt.hour < 12 ? 'সকাল' : (dt.hour < 15 ? 'দুপুর' : (dt.hour < 18 ? 'বিকাল' : 'রাত'));

    return 'আবেদনের তারিখ: $day/$month/$year, $period $hour:$minute';
  }

  // ================= 1. PASSWORD RESET =================
  Future<void> _handlePasswordReset(AdminUserModel user, {BuildContext? dialogCtx}) async {
    if (user.email.isEmpty) {
      _showSnackBar('এই ইউজারের কোনো নিবন্ধিত ইমেইল নেই।', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AdminColors.primary, size: 22),
            SizedBox(width: 8),
            Text('পাসওয়ার্ড রিসেট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'আপনি কি "${user.name}" (${user.email})-এর ইমেইলে অফিশিয়াল পাসওয়ার্ড রিসেট লিংক পাঠাতে চান?',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ইমেইল পাঠান', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await AdminFirestoreService.instance.sendPasswordReset(user.email, uid: user.uid);
        _showSnackBar('পাসওয়ার্ড রিসেট লিংক সফলভাবে ${user.email} এ পাঠানো হয়েছে।');
      } catch (e) {
        _showSnackBar(AdminErrorHandler.getFriendlyErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ================= 1.2 DIRECT PASSWORD SET =================
  Future<void> _handleDirectPasswordSet(AdminUserModel user, {BuildContext? dialogCtx}) async {
    final passController = TextEditingController();
    bool obscure = true;

    final newPassword = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.password_rounded, color: Color(0xFF1565C0), size: 22),
              SizedBox(width: 8),
              Text('সরাসরি নতুন পাসওয়ার্ড নির্ধারণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ইউজার "${user.name}"-এর জন্য নতুন পাসওয়ার্ড লিখুন:',
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'নতুন পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setDlgState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final p = passController.text.trim();
                if (p.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।')),
                  );
                  return;
                }
                Navigator.pop(ctx, p);
              },
              child: const Text('পাসওয়ার্ড সেট করুন', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (newPassword != null && newPassword.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await AdminFirestoreService.instance.setUserPasswordDirect(user.id, newPassword);
        _showSnackBar('${user.name} এর জন্য নতুন পাসওয়ার্ড সফলভাবে নির্ধারণ করা হয়েছে।');
      } catch (e) {
        _showSnackBar(AdminErrorHandler.getFriendlyErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ================= 1.2 DIRECT LOGIN CREDENTIALS EDIT (ফোন ও ইমেইল সরাসরি এডিট) =================
  String _normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('880')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('88') && digits.length > 11) {
      digits = digits.substring(2);
    }
    return digits;
  }

  bool _isSamePhone(String p1, String p2) {
    final n1 = _normalizePhone(p1);
    final n2 = _normalizePhone(p2);
    if (n1.isEmpty || n2.isEmpty) return false;
    return n1 == n2;
  }

  Future<void> _handleDirectEditUserCredentials(
    AdminUserModel user, {
    BuildContext? dialogCtx,
    String? initialField,
  }) async {
    final phoneCtrl = TextEditingController(text: user.phone);
    final emailCtrl = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (editCtx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.manage_accounts_rounded, color: AdminColors.primaryDark, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('লগইন তথ্য সরাসরি সম্পাদনা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                      Text('ফোন নম্বর ও ইমেইল অ্যাড্রেস পরিবর্তন', style: TextStyle(fontSize: 11.5, color: AdminColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 16, color: AdminColors.primaryDark),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${user.name} (UID: ${user.uid})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Phone Input
                    const Text('মোবাইল নম্বর:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      autofocus: initialField == 'phone',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: '01XXXXXXXXX',
                        hintStyle: const TextStyle(fontSize: 12.5, color: AdminColors.textMuted),
                        prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: AdminColors.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                      ),
                      validator: (val) {
                        final trimmed = val?.trim() ?? '';
                        if (trimmed.isNotEmpty && !RegExp(r'^01[3-9]\d{8}$').hasMatch(trimmed)) {
                          return 'সঠিক ১১ ডিজিটের মোবাইল নম্বর লিখুন (যেমন: 017XXXXXXXX)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Email Input
                    const Text('ইমেইল অ্যাড্রেস:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: initialField == 'email',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'example@email.com',
                        hintStyle: const TextStyle(fontSize: 12.5, color: AdminColors.textMuted),
                        prefixIcon: const Icon(Icons.email_rounded, size: 18, color: AdminColors.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                      ),
                      validator: (val) {
                        final trimmed = val?.trim() ?? '';
                        if (trimmed.isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed)) {
                          return 'সঠিক ইমেইল অ্যাড্রেস লিখুন';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'সংরক্ষণের পূর্বে ফায়ারস্টোর ডেটাবেজে ইউনিক চেক করা হবে। ইতিমধ্যে অন্য কারো একাউন্টে যুক্ত থাকা ফোন বা ইমেইল গ্রহণযোগ্য হবে না।',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(editCtx, false),
                child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('যাচাই ও সংরক্ষণ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final newPhone = phoneCtrl.text.trim();
                  final newEmail = emailCtrl.text.trim().toLowerCase();

                  final isPhoneUnchanged = _isSamePhone(newPhone, user.phone);
                  final isEmailUnchanged = newEmail == user.email.toLowerCase();

                  // স্টেপ ১ (নো-চেঞ্জ চেক): যদি newPhone == currentPhone এবং newEmail == currentEmail হয়
                  if (isPhoneUnchanged && isEmailUnchanged) {
                    _showSnackBar('আপনি বর্তমান তথ্যই প্রদান করেছেন। কোনো পরিবর্তন শনাক্ত হয়নি।');
                    return;
                  }

                  // স্টেপ ২ ও ৩: কঠোর ইউনিকনেস চেক
                  setState(() => _isLoading = true);
                  Map<String, dynamic> checkResult = {'isPhoneTaken': false, 'isEmailTaken': false};
                  try {
                    checkResult = await AdminFirestoreService.instance.checkLoginCredentialsAvailability(
                      userId: user.uid,
                      newPhone: !isPhoneUnchanged ? newPhone : '',
                      newEmail: !isEmailUnchanged ? newEmail : '',
                    );
                  } catch (e) {
                    _showSnackBar('যাচাইয়ে ত্রুটি: $e', isError: true);
                    return;
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }

                  final isPhoneTaken = checkResult['isPhoneTaken'] == true;
                  final isEmailTaken = checkResult['isEmailTaken'] == true;

                  if (isPhoneTaken || isEmailTaken) {
                    if (!mounted) return;
                    String conflictText = '';
                    if (isPhoneTaken && isEmailTaken) {
                      conflictText = 'এই মোবাইল নম্বরটি এবং ইমেইলটি ইতিমধ্যে অন্য একটি একাউন্টে ব্যবহৃত হচ্ছে। দয়া করে সম্পূর্ণ নতুন ও ইউনিক তথ্য দিন।';
                    } else if (isPhoneTaken) {
                      conflictText = 'এই মোবাইল নম্বরটি ইতিমধ্যে অন্য একটি একাউন্টে ব্যবহৃত হচ্ছে। দয়া করে সম্পূর্ণ নতুন ও ইউনিক নম্বর দিন।';
                    } else {
                      conflictText = 'এই ইমেইলটি ইতিমধ্যে অন্য একটি একাউন্টে ব্যবহৃত হচ্ছে। দয়া করে নতুন ইমেইল দিন।';
                    }
                    await showDialog(
                      context: editCtx,
                      builder: (c) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        title: const Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: AdminColors.alertCritical, size: 22),
                            SizedBox(width: 8),
                            Text('তথ্য ইতিমধ্যে ব্যবহৃত', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                          ],
                        ),
                        content: Text(
                          conflictText,
                          style: const TextStyle(fontSize: 13.5, height: 1.4),
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.alertCritical,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.pop(c),
                            child: const Text('ঠিক আছে', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  // 2. Confirmation Dialog
                  if (!mounted) return;
                  final confirm = await showDialog<bool>(
                    context: editCtx,
                    builder: (c) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Row(
                        children: [
                          Icon(Icons.help_outline_rounded, color: AdminColors.primary, size: 22),
                          SizedBox(width: 8),
                          Text('আপডেট নিশ্চিতকরণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      content: const Text(
                        'আপনি কি নিশ্চিত যে এই ইউজারের লগইন তথ্য আপডেট করতে চান?',
                        style: TextStyle(fontSize: 13.5, height: 1.4),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('না', style: TextStyle(color: AdminColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('হ্যাঁ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  // 3. Save updates in try-catch-finally
                  Navigator.pop(editCtx, true);
                  setState(() => _isLoading = true);
                  try {
                    await AdminFirestoreService.instance.updateDirectUserLoginCredentials(
                      userId: user.uid,
                      newPhone: newPhone,
                      newEmail: newEmail,
                    );
                    _showSnackBar('লগইন তথ্য সফলভাবে আপডেট হয়েছে!');
                    await _showAdminActionSuccessDialog(
                      title: 'আপডেট সম্পন্ন',
                      message: 'ইউজারের লগইন তথ্য সফলভাবে আপডেট হয়েছে। ইউজার তার নতুন তথ্য ও পূর্বের পাসওয়ার্ড দিয়ে তাৎক্ষণিকভাবে লগইন করতে পারবেন।',
                      isDanger: false,
                    );
                  } catch (e) {
                    _showSnackBar('আপডেট ব্যর্থ: $e', isError: true);
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= 1.3 LOGIN LOCK RESET =================
  Future<void> _handleResetLoginLock(AdminUserModel user, {BuildContext? dialogCtx}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_open_rounded, color: Color(0xFFE65100), size: 22),
            SizedBox(width: 8),
            Text('লগইন লক রিসেট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'আপনি কি "${user.name}"-এর ভুল পাসওয়ার্ডের কারণে সৃষ্ট লগইন লক রিসেট করতে চান? রিসেট করলে তিনি ১ ঘণ্টা অপেক্ষা না করে তৎক্ষণাৎ পুনরায় লগইন করতে পারবেন।',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('লক রিসেট করুন', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await AdminFirestoreService.instance.resetLoginLock(user.uid);
        _showSnackBar('লগইন লক সফলভাবে রিসেট করা হয়েছে!');
        if (dialogCtx != null && dialogCtx.mounted) {
          Navigator.pop(dialogCtx);
        }
      } catch (e) {
        _showSnackBar(AdminErrorHandler.getFriendlyErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ================= 2. PROFILE EDIT LIMIT RESET =================
  Future<void> _handleProfileLimitReset(AdminUserModel user, {BuildContext? dialogCtx}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: AdminColors.alertWarning, size: 22),
            SizedBox(width: 8),
            Text('এডিট লিমিট রিসেট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'আপনি কি "${user.name}"-এর ৩০ দিনের প্রোফাইল এডিট সীমাবদ্ধতা রিসেট করতে চান? রিসেট করলে তিনি অবিলম্বে তার তথ্য সম্পাদনা করতে পারবেন।',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.alertWarning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('রিসেট করুন', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await AdminFirestoreService.instance.resetProfileUpdateLimit(user.uid);
        _showSnackBar('ইউজারের প্রোফাইল এডিট লিমিট সফলভাবে রিসেট করা হয়েছে।');
        if (dialogCtx != null && dialogCtx.mounted) {
          Navigator.pop(dialogCtx);
        }
      } catch (e) {
        _showSnackBar(AdminErrorHandler.getFriendlyErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ================= 3. TEMPORARY BLOCK =================
  Future<void> _handleTemporaryBlock(AdminUserModel user, {BuildContext? dialogCtx}) async {
    int selectedDays = 7;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.timer_outlined, color: AdminColors.alertWarning, size: 22),
              SizedBox(width: 8),
              Text('সাময়িক ব্লক (Temporary Block)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ইউজার: ${user.name} (${user.phone})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 12),
              const Text('ব্লকের মেয়াদ নির্ধারণ করুন:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: selectedDays,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('১ দিন', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 3, child: Text('৩ দিন', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 7, child: Text('৭ দিন', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 15, child: Text('১৫ দিন', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 30, child: Text('৩০ দিন', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedDays = val);
                },
              ),
              const SizedBox(height: 12),
              const Text('ব্লক করার সুনির্দিষ্ট কারণ:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'ব্লক করার কারণ বিস্তারিত লিখুন...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.alertWarning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('অনুগ্রহ করে ব্লকের কারণ লিখুন')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('ব্লক কার্যকর করুন', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await AdminFirestoreService.instance.temporaryBlockUser(
          uid: user.uid,
          days: selectedDays,
          reason: reasonController.text.trim(),
        );
        _showSnackBar('ইউজারকে ${_toBn(selectedDays.toString())} দিনের জন্য অস্থায়ী ব্লক করা হয়েছে।');
        if (dialogCtx != null && dialogCtx.mounted) {
          Navigator.pop(dialogCtx);
        }
      } catch (e) {
        _showSnackBar(AdminErrorHandler.getFriendlyErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ================= 4. PERMANENT SUSPEND =================
  Future<void> _handlePermanentSuspend(AdminUserModel user, {BuildContext? dialogCtx}) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: AdminColors.alertCritical, size: 22),
            SizedBox(width: 8),
            Text('স্থায়ী সাসপেন্ড সতর্কতা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AdminColors.alertCritical)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ইউজার: ${user.name} (${user.phone})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminColors.alertCriticalBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: const Text(
                'সতর্কবার্তা: স্থায়ী সাসপেন্ড কার্যকর হলে ইউজার কখনোই আর অ্যাপে লগইন করতে পারবেন না।',
                style: TextStyle(color: AdminColors.alertCritical, fontSize: 11.5, height: 1.3),
              ),
            ),
            const SizedBox(height: 12),
            const Text('সাসপেন্ডের কারণ:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
            const SizedBox(height: 6),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'নীতিমালা লঙ্ঘনের বিবরণ লিখুন...',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.alertCritical,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('অনুগ্রহ করে সাসপেন্ডের কারণ লিখুন')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('স্থায়ী সাসপেন্ড করুন', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await AdminFirestoreService.instance.permanentlySuspendUser(
          uid: user.uid,
          reason: reasonController.text.trim(),
        );
        _showSnackBar('ইউজারকে স্থায়ীভাবে সাসপেন্ড করা হয়েছে।', isError: true);
        if (dialogCtx != null && dialogCtx.mounted) {
          Navigator.pop(dialogCtx);
        }
      } catch (e) {
        _showSnackBar(AdminErrorHandler.getFriendlyErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ================= 5. ACTIVATE / UNBLOCK =================
  Future<void> _handleActivateUser(AdminUserModel user, {BuildContext? dialogCtx}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AdminColors.primary, size: 22),
            SizedBox(width: 8),
            Text('একাউন্ট একটিভ করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'আপনি কি "${user.name}"-এর একাউন্টের সমস্ত বিধিনিষেধ প্রত্যাহার করে পুনরায় "একটিভ (Active)" করতে চান?',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('একটিভ করুন', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await AdminFirestoreService.instance.activateUser(user.uid);
        _showSnackBar('ইউজার একাউন্ট সফলভাবে একটিভ করা হয়েছে।');
        if (dialogCtx != null && dialogCtx.mounted) {
          Navigator.pop(dialogCtx);
        }
      } catch (e) {
        _showSnackBar(AdminErrorHandler.getFriendlyErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ================= 6. USER DETAILS DIALOG (বিস্তারিত মডাল) =================
  void _showUserDetailsDialog(AdminUserModel initialUser) {
    showDialog(
      context: context,
      builder: (ctx) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(initialUser.uid).snapshots(),
        builder: (ctx, userSnapshot) {
          final liveUser = (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists)
              ? AdminUserModel.fromFirestore(userSnapshot.data!)
              : initialUser;

          bool isRateLimited = false;
          int remainingDays = 0;
          if (liveUser.lastProfileUpdate != null) {
            final daysSinceUpdate = DateTime.now().difference(liveUser.lastProfileUpdate!).inDays;
            if (daysSinceUpdate < 30) {
              isRateLimited = true;
              remainingDays = 30 - daysSinceUpdate;
            }
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('support_tickets').snapshots(),
            builder: (ctx, ticketSnapshot) {
              int totalTickets = 0;
              if (ticketSnapshot.hasData && ticketSnapshot.data != null) {
                totalTickets = ticketSnapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final uid = data['userId']?.toString() ?? data['authorId']?.toString() ?? '';
                  return uid == liveUser.uid;
                }).length;
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('login_update_requests')
                    .where('userId', isEqualTo: liveUser.uid)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (ctx, loginReqSnap) {
                  QueryDocumentSnapshot<Map<String, dynamic>>? pendingDoc;
                  if (loginReqSnap.hasData && loginReqSnap.data != null && loginReqSnap.data!.docs.isNotEmpty) {
                    pendingDoc = loginReqSnap.data!.docs.first;
                  }
                  final hasPendingRequest = pendingDoc != null;
                  final pendingRequestData = pendingDoc != null
                      ? ({...pendingDoc.data(), 'id': pendingDoc.id})
                      : null;

                  return Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          // Dialog Header with Avatar & Status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AdminColors.primaryContainer,
                                backgroundImage: (liveUser.photoUrl != null && liveUser.photoUrl!.isNotEmpty)
                                    ? NetworkImage(liveUser.photoUrl!)
                                    : null,
                                child: (liveUser.photoUrl == null || liveUser.photoUrl!.isEmpty)
                                    ? Text(
                                        liveUser.name.isNotEmpty ? liveUser.name[0].toUpperCase() : 'U',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AdminColors.primaryDark),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(liveUser.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                                    const SizedBox(height: 3),
                                    Text(liveUser.phone.isNotEmpty ? liveUser.phone : 'ফোন নেই', style: const TextStyle(fontSize: 12.5, color: AdminColors.textSecondary)),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(liveUser.status),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20, color: AdminColors.textMuted),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),
                          const Divider(color: AdminColors.divider),
                          const SizedBox(height: 14),

                          // 5 Info Cards Grid
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final cardWidth = (constraints.maxWidth - 12) / 2 > 160
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  // 1. Mobile Number
                                  _buildUserMetricInfoCard(
                                    title: 'মোবাইল নম্বর',
                                    value: liveUser.phone.isNotEmpty ? liveUser.phone : 'ফোন নেই',
                                    icon: Icons.phone_outlined,
                                    iconColor: const Color(0xFF2E7D32),
                                    iconBg: const Color(0xFFE8F5E9),
                                    subtext: hasPendingRequest ? 'আপডেট রিকোয়েস্ট অপেক্ষমাণ' : 'নিবন্ধিত প্রাইমারি নম্বর',
                                    width: cardWidth,
                                    isPending: hasPendingRequest,
                                    onPendingTap: () {
                                      if (pendingRequestData != null) {
                                        _showCheckRequestModal(pendingRequestData);
                                      }
                                    },
                                    onEdit: () => _handleDirectEditUserCredentials(liveUser, dialogCtx: ctx, initialField: 'phone'),
                                  ),

                                  // 2. Email Address
                                  _buildUserMetricInfoCard(
                                    title: 'ইমেইল অ্যাড্রেস',
                                    value: liveUser.email.isNotEmpty ? liveUser.email : 'নিবন্ধিত ইমেইল নেই',
                                    icon: Icons.email_outlined,
                                    iconColor: const Color(0xFF1565C0),
                                    iconBg: const Color(0xFFE3F2FD),
                                    subtext: hasPendingRequest ? 'আপডেট রিকোয়েস্ট অপেক্ষমাণ' : 'অফিশিয়াল যোগাযোগ',
                                    width: cardWidth,
                                    isPending: hasPendingRequest,
                                    onPendingTap: () {
                                      if (pendingRequestData != null) {
                                        _showCheckRequestModal(pendingRequestData);
                                      }
                                    },
                                    onEdit: () => _handleDirectEditUserCredentials(liveUser, dialogCtx: ctx, initialField: 'email'),
                                  ),

                                  // 3. Current Password
                                  _buildUserPasswordInfoCard(
                                    password: liveUser.password,
                                    width: cardWidth,
                                  ),

                                  // 4. Last Password Update Date
                                  _buildUserMetricInfoCard(
                                    title: 'পাসওয়ার্ড আপডেট তারিখ',
                                    value: _formatPasswordResetDateBn(liveUser.lastPasswordReset),
                                    icon: Icons.history_toggle_off_rounded,
                                    iconColor: const Color(0xFFE65100),
                                    iconBg: const Color(0xFFFFF3E0),
                                    subtext: liveUser.lastPasswordReset != null ? 'সর্বশেষ রিসেটের রেকর্ড' : 'ডিফল্ট পাসওয়ার্ড বহাল',
                                    width: cardWidth,
                                  ),

                                  // 5. Total Support Contact Tickets Count Badge Card
                                  _buildUserSupportTicketsCard(
                                    count: totalTickets,
                                    width: constraints.maxWidth,
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 18),
                          const Divider(color: AdminColors.divider),
                          const SizedBox(height: 14),

                          // Personal & Geographic Details
                          _buildDetailRow(Icons.location_on_outlined, 'ঠিকানা / এলাকা', [
                            if (liveUser.village.isNotEmpty) 'গ্রাম: ${liveUser.village}',
                            if (liveUser.upazila.isNotEmpty) 'উপজেলা: ${liveUser.upazila}',
                            if (liveUser.district.isNotEmpty) 'জেলা: ${liveUser.district}',
                          ].join(', ').ifEmpty('ঠিকানা অনুল্লিখিত')),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.work_outline_rounded, 'পেশা', liveUser.occupation.isNotEmpty ? liveUser.occupation : 'কৃষক'),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.calendar_today_outlined, 'যোগদানের তারিখ', _formatDateBn(liveUser.createdAt)),
                          const SizedBox(height: 8),

                          // Last Profile Update Date
                          _buildDetailRow(
                            Icons.update_rounded,
                            'শেষ প্রোফাইল আপডেট',
                            liveUser.lastProfileUpdate != null
                                ? _formatDateBn(liveUser.lastProfileUpdate)
                                : 'এখনো আপডেট করা হয়নি',
                          ),
                          const SizedBox(height: 8),

                          // Profile Edit Rate-Limit Status
                          _buildDetailRow(
                            Icons.history_rounded,
                            'প্রোফাইল লিমিট',
                            isRateLimited
                                ? 'লকড (${_toBn(remainingDays.toString())} দিন বাকি)'
                                : 'লিমিট নেই (এডিট সচল)',
                            highlightColor: isRateLimited ? AdminColors.alertWarning : AdminColors.primary,
                          ),

                          // Block / Suspend Details Notice (if any)
                          if (liveUser.status == 'temporary_blocked') ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AdminColors.alertWarningBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFE0B2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: AdminColors.alertWarning, size: 18),
                                      SizedBox(width: 6),
                                      Text('অস্থায়ী ব্লকের বিবরণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE65100))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('কারণ: ${liveUser.blockReason.ifEmpty("অনির্দিষ্ট")}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF5D4037))),
                                  if (liveUser.unblockAt != null) ...[
                                    const SizedBox(height: 2),
                                    Text('আনলক হওয়ার সময়: ${_formatDateBn(liveUser.unblockAt)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
                                  ],
                                ],
                              ),
                            ),
                          ] else if (liveUser.status == 'permanently_suspended') ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AdminColors.alertCriticalBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFCDD2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.block_rounded, color: AdminColors.alertCritical, size: 18),
                                      SizedBox(width: 6),
                                      Text('স্থায়ী সাসপেন্ডের বিবরণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminColors.alertCritical)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('কারণ: ${liveUser.suspendReason.ifEmpty("নীতিমালা লঙ্ঘনের কারণে")}', style: const TextStyle(fontSize: 12.5, color: Color(0xFFB71C1C))),
                                ],
                              ),
                            ),
                          ],

                          // Password Lock Security Alert (if locked due to failed attempts)
                          if (liveUser.isPasswordLocked) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFB74D)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_clock_rounded, color: Color(0xFFE65100), size: 24),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('১০ বার ভুল পাসওয়ার্ডে একাউন্ট সাময়িক লক', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE65100))),
                                        const SizedBox(height: 3),
                                        Text(
                                          'ব্যর্থ চেষ্টা: ${_toBn(liveUser.failedAttempts.toString())} বার • স্বয়ংক্রিয় আনলক হতে বাকি: ${_toBn(liveUser.lockUntil != null ? (liveUser.lockUntil!.difference(DateTime.now()).inMinutes + 1).toString() : '১')} মিনিট',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE65100),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.lock_open_rounded, size: 16),
                                    label: const Text('লগইন লক রিসেট', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    onPressed: () => _handleResetLoginLock(liveUser, dialogCtx: ctx),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
                          const Divider(color: AdminColors.divider),
                          const SizedBox(height: 14),

                          // Admin Action Buttons inside Details Dialog
                          const Text('প্রশাসনিক অ্যাকশন কন্ট্রোলস:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminColors.textPrimary)),
                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // 0. Direct Login Credentials Edit Button or Pending Action Button
                              if (hasPendingRequest)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    backgroundColor: const Color(0xFFE65100),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.pending_actions_rounded, size: 16),
                                  label: const Text('লগইন রিকোয়েস্ট অপেক্ষমাণ (যাচাই করুন)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    if (pendingRequestData != null) {
                                      _showCheckRequestModal(pendingRequestData);
                                    }
                                  },
                                )
                              else
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    backgroundColor: const Color(0xFF1B5E20),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                                  label: const Text('লগইন আইডি এডিট (ফোন/ইমেইল)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                  onPressed: () => _handleDirectEditUserCredentials(liveUser, dialogCtx: ctx),
                                ),

                              // Login Lock Reset Button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  backgroundColor: const Color(0xFFE65100),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.lock_open_rounded, size: 16),
                                label: const Text('লগইন লক রিসেট', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                onPressed: () => _handleResetLoginLock(liveUser, dialogCtx: ctx),
                              ),

                              // 1.1 Direct Password Set Button
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  foregroundColor: const Color(0xFF1565C0),
                                  side: const BorderSide(color: Color(0xFF90CAF9)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.password_rounded, size: 16),
                                label: const Text('সরাসরি পাসওয়ার্ড সেট', style: TextStyle(fontSize: 12.5)),
                                onPressed: () => _handleDirectPasswordSet(liveUser, dialogCtx: ctx),
                              ),

                              // 1.2 Password Reset Link Button
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  foregroundColor: const Color(0xFF1976D2),
                                  side: const BorderSide(color: Color(0xFF90CAF9)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.lock_reset_rounded, size: 16),
                                label: const Text('পাসওয়ার্ড রিসেট লিংক', style: TextStyle(fontSize: 12.5)),
                                onPressed: () => _handlePasswordReset(liveUser, dialogCtx: ctx),
                              ),

                              // 2. Profile Limit Reset Button
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  foregroundColor: const Color(0xFF5E35B1),
                                  side: const BorderSide(color: Color(0xFFD1C4E9)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                                label: const Text('এডিট লিমিট রিসেট', style: TextStyle(fontSize: 12.5)),
                                onPressed: () => _handleProfileLimitReset(liveUser, dialogCtx: ctx),
                              ),

                              // 3. Status Change Buttons
                              if (liveUser.status != 'active')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    backgroundColor: AdminColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                  label: const Text('একাউন্ট একটিভ করুন', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                  onPressed: () => _handleActivateUser(liveUser, dialogCtx: ctx),
                                ),

                              if (liveUser.status != 'temporary_blocked')
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    foregroundColor: const Color(0xFFE65100),
                                    side: const BorderSide(color: Color(0xFFFFCC80)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.timer_outlined, size: 16),
                                  label: const Text('অস্থায়ী ব্লক', style: TextStyle(fontSize: 12.5)),
                                  onPressed: () => _handleTemporaryBlock(liveUser, dialogCtx: ctx),
                                ),

                              if (liveUser.status != 'permanently_suspended')
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    foregroundColor: AdminColors.alertCritical,
                                    side: const BorderSide(color: Color(0xFFFFCDD2)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.block_rounded, size: 16),
                                  label: const Text('স্থায়ী সাসপেন্ড', style: TextStyle(fontSize: 12.5)),
                                  onPressed: () => _handlePermanentSuspend(liveUser, dialogCtx: ctx),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  ),
);
  }

  // ================= 6.1 HELPER METRIC CARDS FOR USER DETAILS =================
  Widget _buildUserMetricInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String subtext,
    required double width,
    VoidCallback? onEdit,
    bool isPending = false,
    VoidCallback? onPendingTap,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E5E0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.textMuted),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPending && onPendingTap != null) ...[
                    InkWell(
                      onTap: onPendingTap,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFB74D)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_top_rounded, size: 11, color: Color(0xFFE65100)),
                            SizedBox(width: 3),
                            Text(
                              'পেন্ডিং',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ] else if (onEdit != null) ...[
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: iconColor.withOpacity(0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded, size: 11, color: iconColor),
                            const SizedBox(width: 3),
                            Text('এডিট', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: iconColor)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(7)),
                    child: Icon(icon, size: 15, color: iconColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(fontSize: 11, color: iconColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPasswordInfoCard({
    required String? password,
    required double width,
  }) {
    final hasPass = password != null && password.isNotEmpty;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1BEE7)),
        boxShadow: const [
          BoxShadow(color: Color(0x046A1B9A), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'বর্তমান পাসওয়ার্ড',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A)),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.key_rounded, size: 15, color: Color(0xFF7B1FA2)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCE93D8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    hasPass ? password : 'সংরক্ষিত নেই',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: hasPass ? 'monospace' : null,
                      color: hasPass ? const Color(0xFF4A148C) : Colors.grey,
                    ),
                  ),
                ),
                if (hasPass)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: password));
                      _showSnackBar('পাসওয়ার্ড ক্লিপবোর্ডে কপি করা হয়েছে!');
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7F6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD1C4E9)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded, size: 12, color: Color(0xFF4A148C)),
                          SizedBox(width: 3),
                          Text('কপি', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ফায়ারস্টোর ডাটাবেজ পাসওয়ার্ড',
            style: TextStyle(fontSize: 11, color: Color(0xFF7B1FA2), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSupportTicketsCard({
    required int count,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04059669), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.headset_mic_rounded, size: 18, color: Color(0xFF059669)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('টোটাল সাপোর্ট যোগাযোগ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                  const SizedBox(height: 2),
                  const Text('ইউজারের লাইভ সাপোর্ট হিস্ট্রি কাউন্ট', style: TextStyle(fontSize: 11, color: Color(0xFF059669))),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6EE7B7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_chat_read_rounded, size: 14, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Text(
                  'টোটাল যোগাযোগ: ${_toBn(count.toString())} টি',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? highlightColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AdminColors.textMuted),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: highlightColor != null ? FontWeight.bold : FontWeight.normal,
              color: highlightColor ?? AdminColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Main Sub-tabs: User List vs Login Update Requests
            _buildMainSubTabs(),
            const SizedBox(height: 16),
            if (_activeMainTab == 'users')
              _buildUsersTableView()
            else
              _buildLoginRequestsView(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSubTabs() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminFirestoreService.instance.getLoginUpdateRequestsStream(),
      builder: (context, reqSnap) {
        final pendingCount = (reqSnap.data ?? []).where((r) => r['status'] == 'pending').length;
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _buildMainTabButton('users', 'ইউজার তালিকা', Icons.people_alt_rounded),
            _buildMainTabButton(
              'login_requests',
              'লগইন তথ্য হালনাগাদ রিকোয়েস্ট',
              Icons.update_rounded,
              badgeCount: pendingCount,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainTabButton(String tabKey, String title, IconData icon, {int badgeCount = 0}) {
    final isSelected = _activeMainTab == tabKey;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _activeMainTab = tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AdminColors.primary : AdminColors.border),
          boxShadow: isSelected
              ? [const BoxShadow(color: Color(0x202E7D32), blurRadius: 6, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AdminColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AdminColors.textPrimary,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AdminColors.alertCritical,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _toBn(badgeCount.toString()),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AdminColors.primaryDark : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTableView() {
    return StreamBuilder<List<AdminUserModel>>(
      stream: AdminFirestoreService.instance.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(color: AdminColors.primary)));
        }

        final allUsers = snapshot.data ?? [];
        final query = _searchController.text.trim().toLowerCase();

        // Filtering
        final filteredUsers = allUsers.where((u) {
          final matchesStatus = _selectedStatusFilter == 'all' || u.status == _selectedStatusFilter;
          final matchesQuery = query.isEmpty ||
              u.name.toLowerCase().contains(query) ||
              u.phone.toLowerCase().contains(query) ||
              u.email.toLowerCase().contains(query) ||
              u.district.toLowerCase().contains(query) ||
              u.upazila.toLowerCase().contains(query);
          return matchesStatus && matchesQuery;
        }).toList();

        // Stats
        final totalCount = allUsers.length;
        final activeCount = allUsers.where((u) => u.status == 'active').length;
        final blockedCount = allUsers.where((u) => u.status == 'temporary_blocked').length;
        final suspendedCount = allUsers.where((u) => u.status == 'permanently_suspended').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Compact KPI Summary Cards
            _buildCompactSummaryStats(totalCount, activeCount, blockedCount, suspendedCount),

            const SizedBox(height: 16),

            // Main Controls & Table Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header & Search Filter Row
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ইউজার তালিকা ও অ্যাকশন',
                            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AdminColors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'মোট ${_toBn(filteredUsers.length.toString())} জন',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AdminColors.primaryDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _activeMainTab = 'login_requests'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8F1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFC8E6C9)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.update_rounded, size: 14, color: AdminColors.primaryDark),
                                  SizedBox(width: 5),
                                  Text(
                                    'লগইন তথ্য হালনাগাদ রিকোয়েস্ট',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AdminColors.primaryDark),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 280,
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'নাম, ফোন বা জেলা দিয়ে খুঁজুন...',
                            hintStyle: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AdminColors.primary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Status Filter Pills
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildFilterPill('all', 'সকল (${_toBn(totalCount.toString())})'),
                      _buildFilterPill('active', 'একটিভ (${_toBn(activeCount.toString())})'),
                      _buildFilterPill('temporary_blocked', 'অস্থায়ী ব্লক (${_toBn(blockedCount.toString())})'),
                      _buildFilterPill('permanently_suspended', 'স্থায়ী সাসপেন্ড (${_toBn(suspendedCount.toString())})'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Compact Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7F4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('নাম', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                        Expanded(flex: 2, child: Text('মোবাইল নম্বর', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                        Expanded(flex: 2, child: Text('জেলা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                        Expanded(flex: 2, child: Center(child: Text('স্ট্যাটাস', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary)))),
                        SizedBox(width: 80, child: Center(child: Text('অ্যাকশন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary)))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Compact Table Rows
                  if (filteredUsers.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(Icons.person_search_rounded, size: 36, color: AdminColors.textMuted),
                          SizedBox(height: 8),
                          Text('কোনো ইউজার পাওয়া যায়নি', style: TextStyle(fontSize: 13, color: AdminColors.textMuted)),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return _buildCompactUserRow(user);
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ==================== LOGIN ID UPDATE REQUESTS VIEW ====================
  Widget _buildLoginRequestsView() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminFirestoreService.instance.getLoginUpdateRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: AdminColors.primary),
            ),
          );
        }

        final allRequests = snapshot.data ?? [];
        final query = _requestSearchController.text.trim().toLowerCase();

        final totalCount = allRequests.length;
        final pendingCount = allRequests.where((r) => r['status'] == 'pending').length;
        final acceptedCount = allRequests.where((r) => r['status'] == 'accepted').length;
        final rejectedCount = allRequests.where((r) => r['status'] == 'rejected').length;

        final filteredRequests = allRequests.where((r) {
          final matchesStatus = r['status'] == _requestStatusFilter;
          final matchesQuery = query.isEmpty ||
              (r['userName']?.toString().toLowerCase().contains(query) ?? false) ||
              (r['currentPhone']?.toString().toLowerCase().contains(query) ?? false) ||
              (r['newPhone']?.toString().toLowerCase().contains(query) ?? false) ||
              (r['currentEmail']?.toString().toLowerCase().contains(query) ?? false) ||
              (r['newEmail']?.toString().toLowerCase().contains(query) ?? false);
          return matchesStatus && matchesQuery;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards for Login Requests
            _buildLoginRequestsKPI(totalCount, pendingCount, acceptedCount, rejectedCount),
            const SizedBox(height: 16),

            // Main Requests Table Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search & Sub-tabs Header
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'লগইন তথ্য হালনাগাদ আবেদন তালিকা',
                            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AdminColors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'মোট ${_toBn(filteredRequests.length.toString())} টি',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AdminColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 280,
                        height: 38,
                        child: TextField(
                          controller: _requestSearchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'নাম, মোবাইল বা ইমেইল দিয়ে খুঁজুন...',
                            hintStyle: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AdminColors.primary),
                            suffixIcon: _requestSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _requestSearchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Filter Pills: Pending / Accepted / Rejected
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildRequestFilterPill('pending', 'পেন্ডিং রিকোয়েস্ট (${_toBn(pendingCount.toString())})'),
                      _buildRequestFilterPill('accepted', 'গৃহীত হিস্ট্রি (${_toBn(acceptedCount.toString())})'),
                      _buildRequestFilterPill('rejected', 'বাতিল হিস্ট্রি (${_toBn(rejectedCount.toString())})'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7F4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('আবেদনকারী', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                        Expanded(flex: 3, child: Text('বর্তমান তথ্য', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                        Expanded(flex: 3, child: Text('আবেদনকৃত নতুন তথ্য', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                        Expanded(flex: 3, child: Text('আবেদনের তারিখ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary))),
                        Expanded(flex: 2, child: Center(child: Text('স্ট্যাটাস', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary)))),
                        SizedBox(width: 90, child: Center(child: Text('অ্যাকশন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AdminColors.textPrimary)))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  if (filteredRequests.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            _requestStatusFilter == 'pending'
                                ? Icons.pending_actions_rounded
                                : (_requestStatusFilter == 'accepted' ? Icons.check_circle_outline_rounded : Icons.cancel_outlined),
                            size: 36,
                            color: AdminColors.textMuted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _requestStatusFilter == 'pending'
                                ? 'কোনো নতুন পেন্ডিং রিকোয়েস্ট নেই'
                                : (_requestStatusFilter == 'accepted' ? 'কোনো গৃহীত রিকোয়েস্ট পাওয়া যায়নি' : 'কোনো বাতিল রিকোয়েস্ট নেই'),
                            style: const TextStyle(fontSize: 13, color: AdminColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredRequests.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      itemBuilder: (context, index) {
                        final req = filteredRequests[index];
                        return _buildLoginRequestRow(req);
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginRequestsKPI(int total, int pending, int accepted, int rejected) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

      return Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          _buildCompactStatCard('মোট আবেদন', _toBn(total.toString()), Icons.all_inbox_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD), cardWidth),
          _buildCompactStatCard('পেন্ডিং রিকোয়েস্ট', _toBn(pending.toString()), Icons.pending_actions_rounded, const Color(0xFFE65100), const Color(0xFFFFF3E0), cardWidth),
          _buildCompactStatCard('অনুমোদিত (গৃহীত)', _toBn(accepted.toString()), Icons.check_circle_rounded, const Color(0xFF2E7D32), const Color(0xFFE8F5E9), cardWidth),
          _buildCompactStatCard('বাতিলকৃত আবেদন', _toBn(rejected.toString()), Icons.cancel_rounded, AdminColors.alertCritical, AdminColors.alertCriticalBg, cardWidth),
        ],
      );
    });
  }

  Widget _buildRequestFilterPill(String key, String label) {
    final isSelected = _requestStatusFilter == key;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _requestStatusFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AdminColors.primary : AdminColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AdminColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRequestRow(Map<String, dynamic> req) {
    final userName = req['userName']?.toString() ?? 'ইউজার';
    final currentPhone = req['currentPhone']?.toString() ?? 'ফোন নেই';
    final currentEmail = req['currentEmail']?.toString() ?? 'ইমেইল নেই';
    final newPhone = req['newPhone']?.toString() ?? '';
    final newEmail = req['newEmail']?.toString() ?? '';
    final status = req['status']?.toString() ?? 'pending';

    DateTime? createdAt;
    final rawDate = req['createdAt'];
    if (rawDate is Timestamp) {
      createdAt = rawDate.toDate();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // 1. Applicant
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AdminColors.primaryContainer,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminColors.primaryDark),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          // 2. Current Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(currentPhone, style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary)),
                Text(currentEmail, style: const TextStyle(fontSize: 11, color: AdminColors.textMuted)),
              ],
            ),
          ),

          // 3. New Requested Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  newPhone.isNotEmpty ? newPhone : 'ফোন অপরিবর্তিত',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: newPhone.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                    color: newPhone.isNotEmpty ? AdminColors.primaryDark : AdminColors.textMuted,
                  ),
                ),
                Text(
                  newEmail.isNotEmpty ? newEmail : 'ইমেইল অপরিবর্তিত',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: newEmail.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                    color: newEmail.isNotEmpty ? AdminColors.primaryDark : AdminColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // 4. Requested Date
          Expanded(
            flex: 3,
            child: Text(
              _formatApplicationDate(req['createdAt'] ?? req['timestamp']),
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
            ),
          ),

          // 5. Status Badge
          Expanded(
            flex: 2,
            child: Center(
              child: _buildRequestStatusBadge(status),
            ),
          ),

          // 6. Action
          SizedBox(
            width: 90,
            child: Center(
              child: status == 'pending'
                  ? SizedBox(
                      height: 28,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.rule_folder_rounded, size: 14),
                        label: const Text('চেক', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        onPressed: () => _showCheckRequestModal(req),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status == 'accepted' ? Icons.lock_outline_rounded : Icons.lock_outline_rounded,
                            size: 11,
                            color: AdminColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status == 'accepted' ? 'লকড' : 'লকড',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.textMuted),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;
    IconData icon;

    switch (status) {
      case 'accepted':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        text = 'গৃহীত';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        text = 'বাতিল';
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        text = 'পেন্ডিং';
        icon = Icons.pending_actions_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }

  // ==================== CHECK & VERIFICATION MODAL ====================
  Future<void> _showCheckRequestModal(Map<String, dynamic> request) async {
    final requestId = request['id']?.toString() ?? '';
    final userId = request['userId']?.toString() ?? '';
    final userName = request['userName']?.toString() ?? 'ইউজার';
    final currentPhone = request['currentPhone']?.toString() ?? 'অনুপলব্ধ';
    final currentEmail = request['currentEmail']?.toString() ?? 'অনুপলব্ধ';
    final newPhone = request['newPhone']?.toString() ?? '';
    final newEmail = request['newEmail']?.toString() ?? '';
    final rejectReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return FutureBuilder<Map<String, dynamic>>(
            future: AdminFirestoreService.instance.checkLoginCredentialsAvailability(
              userId: userId,
              newPhone: newPhone,
              newEmail: newEmail,
            ),
            builder: (context, checkSnap) {
              final isChecking = checkSnap.connectionState == ConnectionState.waiting;
              final checkResult = checkSnap.data;
              final isPhoneTaken = checkResult?['isPhoneTaken'] == true;
              final isEmailTaken = checkResult?['isEmailTaken'] == true;
              final phoneTakenBy = checkResult?['phoneTakenBy']?.toString() ?? '';
              final emailTakenBy = checkResult?['emailTakenBy']?.toString() ?? '';
              final isConflict = isPhoneTaken || isEmailTaken;

              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                insetPadding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AdminColors.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.rule_folder_rounded, color: AdminColors.primaryDark, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('লগইন তথ্য ভেরিফিকেশন ও অনুমোদন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('রিয়েল-টাইম ডাটাবেজ ইউনিকনেস ও অ্যাকশন কনসোল', style: TextStyle(fontSize: 11.5, color: AdminColors.textMuted)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.pop(modalCtx),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // User Info & Request Comparison
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAF8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_rounded, size: 16, color: AdminColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('আবেদনকারী: $userName (UID: $userId)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 14, color: AdminColors.textMuted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _formatApplicationDate(request['createdAt'] ?? request['timestamp']),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.primaryDark),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('বর্তমান তথ্য:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AdminColors.textMuted)),
                                        const SizedBox(height: 3),
                                        Text('ফোন: $currentPhone', style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary)),
                                        Text('ইমেইল: $currentEmail', style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    child: Icon(Icons.arrow_forward_rounded, color: AdminColors.textMuted, size: 18),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('আবেদনকৃত নতুন তথ্য:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AdminColors.primaryDark)),
                                        const SizedBox(height: 3),
                                        Text(
                                          'নতুন ফোন: ${newPhone.isNotEmpty ? newPhone : 'অপরিবর্তিত'}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.primaryDark),
                                        ),
                                        Text(
                                          'নতুন ইমেইল: ${newEmail.isNotEmpty ? newEmail : 'অপরিবর্তিত'}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.primaryDark),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Real-time Database Check Status Box
                        if (isChecking)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB))),
                                SizedBox(width: 10),
                                Expanded(child: Text('ফায়ারস্টোর ডেটাবেজে ইউনিকনেস যাচাই করা হচ্ছে...', style: TextStyle(fontSize: 12.5, color: Color(0xFF1E40AF)))),
                              ],
                            ),
                          )
                        else if (isConflict)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                                    SizedBox(width: 8),
                                    Text('সতর্কবার্তা: তথ্য ইতিমধ্যেই বিদ্যমান!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (isPhoneTaken)
                                  Text('• এই মোবাইল নম্বরটি ইতিমধ্যে অন্য একটি একাউন্টে ব্যবহৃত হচ্ছে। দয়া করে সম্পূর্ণ নতুন ও ইউনিক নম্বর দিন। (${phoneTakenBy.isNotEmpty ? 'ব্যবহারকারী: "$phoneTakenBy"' : newPhone})', style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
                                if (isEmailTaken)
                                  Text('• এই ইমেইলটি ইতিমধ্যে অন্য একটি একাউন্টে ব্যবহৃত হচ্ছে। দয়া করে নতুন ইমেইল দিন। (${emailTakenBy.isNotEmpty ? 'ব্যবহারকারী: "$emailTakenBy"' : newEmail})', style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
                                const SizedBox(height: 4),
                                const Text('কনফ্লিক্টের কারণে এই রিকোয়েস্টটি "গ্রহণ" করা যাবে না। অনুগ্রহ করে কারণ উল্লেখপূর্বক বাতিল করুন।', style: TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D), fontStyle: FontStyle.italic)),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('তথ্য উপলব্ধ (Available) ও নিরাপদ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                                      Text('এই নতুন মোবাইল নম্বর ও ইমেইল দিয়ে অন্য কোনো ইউজারের সক্রিয় অ্যাকাউন্ট নেই। আপনি নিশ্চিন্তে অনুমোদন করতে পারেন।', style: TextStyle(fontSize: 11.5, color: Color(0xFF166534))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 14),

                        // Admin Note / Reason
                        TextField(
                          controller: rejectReasonController,
                          style: const TextStyle(fontSize: 12.5),
                          decoration: InputDecoration(
                            labelText: 'এডমিন মন্তব্য / বাতিলের কারণ (ঐচ্ছিক)',
                            labelStyle: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AdminColors.alertCritical,
                                side: const BorderSide(color: AdminColors.alertCritical),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.cancel_rounded, size: 16),
                              label: const Text('বাতিল করুন', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              onPressed: isChecking
                                  ? null
                                  : () async {
                                      final confirm = await showDialog<bool>(
                                        context: modalCtx,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: const Row(
                                            children: [
                                              Icon(Icons.warning_amber_rounded, color: AdminColors.alertCritical, size: 22),
                                              SizedBox(width: 8),
                                              Text('বাতিলের নিশ্চিতকরণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            ],
                                          ),
                                          content: const Text(
                                            'আপনি কি নিশ্চিত যে এই রিকোয়েস্টটি বাতিল করতে চান?',
                                            style: TextStyle(fontSize: 13.5, height: 1.4),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('না', style: TextStyle(color: AdminColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AdminColors.alertCritical,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('হ্যাঁ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        final reason = rejectReasonController.text.trim();
                                        Navigator.pop(modalCtx);
                                        setState(() => _isLoading = true);
                                        try {
                                          await AdminFirestoreService.instance.rejectLoginUpdateRequest(
                                            requestId: requestId,
                                            reason: reason.isNotEmpty ? reason : 'তথ্য সঠিক নয় বা এডমিন কর্তৃক প্রত্যাখ্যাত।',
                                          );
                                          _showSnackBar('রিকোয়েস্টটি সফলভাবে বাতিল করা হয়েছে।');
                                          await _showAdminActionSuccessDialog(
                                            title: 'বাতিল সম্পন্ন',
                                            message: 'রিকোয়েস্টটি সফলভাবে বাতিল হয়েছে।',
                                            isDanger: true,
                                          );
                                        } catch (e) {
                                          _showSnackBar('ত্রুটি: $e', isError: true);
                                        } finally {
                                          if (mounted) setState(() => _isLoading = false);
                                        }
                                      }
                                    },
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.check_circle_rounded, size: 16),
                              label: const Text('গ্রহণ করুন', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              onPressed: (isChecking || isConflict)
                                  ? null
                                  : () async {
                                      final confirm = await showDialog<bool>(
                                        context: modalCtx,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: const Row(
                                            children: [
                                              Icon(Icons.check_circle_outline_rounded, color: AdminColors.primary, size: 22),
                                              SizedBox(width: 8),
                                              Text('অনুমোদনের নিশ্চিতকরণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            ],
                                          ),
                                          content: const Text(
                                            'আপনি কি নিশ্চিত যে এই রিকোয়েস্টটি গ্রহণ করতে চান?',
                                            style: TextStyle(fontSize: 13.5, height: 1.4),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('না', style: TextStyle(color: AdminColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AdminColors.primary,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('হ্যাঁ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        Navigator.pop(modalCtx);
                                        setState(() => _isLoading = true);
                                        try {
                                          await AdminFirestoreService.instance.acceptLoginUpdateRequest(
                                            requestId: requestId,
                                            userId: userId,
                                            newPhone: newPhone,
                                            newEmail: newEmail,
                                          );
                                          _showSnackBar('রিকোয়েস্টটি সফলভাবে গৃহীত হয়েছে এবং ইউজারের লগইন তথ্য আপডেট হয়েছে!');
                                          await _showAdminActionSuccessDialog(
                                            title: 'অনুমোদন সম্পন্ন',
                                            message: 'রিকোয়েস্টটি সফলভাবে গৃহীত হয়েছে।',
                                            isDanger: false,
                                          );
                                        } catch (e) {
                                          _showSnackBar('ত্রুটি: $e', isError: true);
                                        } finally {
                                          if (mounted) setState(() => _isLoading = false);
                                        }
                                      }
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterPill(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedStatusFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AdminColors.primary : AdminColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AdminColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSummaryStats(int total, int active, int blocked, int suspended) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

      return Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          _buildCompactStatCard('মোট ইউজার', _toBn(total.toString()), Icons.people_alt_rounded, AdminColors.primary, AdminColors.primaryContainer, cardWidth),
          _buildCompactStatCard('একটিভ একাউন্ট', _toBn(active.toString()), Icons.check_circle_rounded, const Color(0xFF2E7D32), const Color(0xFFE8F5E9), cardWidth),
          _buildCompactStatCard('অস্থায়ী ব্লক', _toBn(blocked.toString()), Icons.timer_outlined, const Color(0xFFE65100), const Color(0xFFFFF3E0), cardWidth),
          _buildCompactStatCard('স্থায়ী সাসপেন্ড', _toBn(suspended.toString()), Icons.block_rounded, AdminColors.alertCritical, AdminColors.alertCriticalBg, cardWidth),
        ],
      );
    });
  }

  Widget _buildCompactStatCard(String title, String count, IconData icon, Color color, Color bg, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, height: 1.1)),
                Text(title, style: const TextStyle(fontSize: 11, color: AdminColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactUserRow(AdminUserModel user) {
    final districtName = user.district.isNotEmpty ? user.district : (user.upazila.isNotEmpty ? user.upazila : 'অনুল্লিখিত');

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // 1. Name & Avatar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AdminColors.primaryContainer,
                  backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                  child: user.photoUrl.isEmpty
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminColors.primaryDark),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          // 2. Phone
          Expanded(
            flex: 2,
            child: Text(
              user.phone.isNotEmpty ? user.phone : 'ফোন নেই',
              style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary),
            ),
          ),

          // 3. District
          Expanded(
            flex: 2,
            child: Text(
              districtName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary),
            ),
          ),

          // 4. Status Badge
          Expanded(
            flex: 2,
            child: Center(
              child: _buildStatusBadge(user.status),
            ),
          ),

          // 5. "বিস্তারিত" Button
          SizedBox(
            width: 80,
            child: Center(
              child: SizedBox(
                height: 28,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: const BorderSide(color: AdminColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    foregroundColor: AdminColors.primaryDark,
                  ),
                  onPressed: () => _showUserDetailsDialog(user),
                  child: const Text('বিস্তারিত', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;
    IconData icon;

    switch (status) {
      case 'temporary_blocked':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        text = 'অস্থায়ী ব্লক';
        icon = Icons.timer_outlined;
        break;
      case 'permanently_suspended':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        text = 'স্থায়ী সাসপেন্ড';
        icon = Icons.block_rounded;
        break;
      default:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        text = 'একটিভ';
        icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
