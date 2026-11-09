import 'package:flutter/material.dart';
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
  String _selectedStatusFilter = 'all'; // 'all', 'active', 'temporary_blocked', 'permanently_suspended'
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
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
        await AdminFirestoreService.instance.sendPasswordReset(user.email);
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
  void _showUserDetailsDialog(AdminUserModel user) {
    bool isRateLimited = false;
    int remainingDays = 0;
    if (user.lastProfileUpdate != null) {
      final daysSinceUpdate = DateTime.now().difference(user.lastProfileUpdate!).inDays;
      if (daysSinceUpdate < 30) {
        isRateLimited = true;
        remainingDays = 30 - daysSinceUpdate;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
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
                        backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                        child: user.photoUrl.isEmpty
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AdminColors.primaryDark),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                            const SizedBox(height: 3),
                            Text(user.phone.isNotEmpty ? user.phone : 'ফোন নেই', style: const TextStyle(fontSize: 12.5, color: AdminColors.textSecondary)),
                          ],
                        ),
                      ),
                      _buildStatusBadge(user.status),
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

                  // Information Grid (Compact)
                  _buildDetailRow(Icons.email_outlined, 'ইমেইল এড্রেস', user.email.isNotEmpty ? user.email : 'নিবন্ধিত ইমেইল নেই'),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.location_on_outlined, 'ঠিকানা / এলাকা', [
                    if (user.village.isNotEmpty) 'গ্রাম: ${user.village}',
                    if (user.upazila.isNotEmpty) 'উপজেলা: ${user.upazila}',
                    if (user.district.isNotEmpty) 'জেলা: ${user.district}',
                  ].join(', ').ifEmpty('ঠিকানা অনুল্লিখিত')),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.work_outline_rounded, 'পেশা', user.occupation.isNotEmpty ? user.occupation : 'কৃষক'),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.calendar_today_outlined, 'যোগদানের তারিখ', _formatDateBn(user.createdAt)),
                  const SizedBox(height: 8),

                  // Last Profile Update Date
                  _buildDetailRow(
                    Icons.update_rounded,
                    'শেষ প্রোফাইল আপডেট',
                    user.lastProfileUpdate != null
                        ? _formatDateBn(user.lastProfileUpdate)
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
                  if (user.status == 'temporary_blocked') ...[
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
                          Text('কারণ: ${user.blockReason.ifEmpty("অনির্দিষ্ট")}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF5D4037))),
                          if (user.unblockAt != null) ...[
                            const SizedBox(height: 2),
                            Text('আনলক হওয়ার সময়: ${_formatDateBn(user.unblockAt)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
                          ],
                        ],
                      ),
                    ),
                  ] else if (user.status == 'permanently_suspended') ...[
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
                          Text('কারণ: ${user.suspendReason.ifEmpty("নীতিমালা লঙ্ঘনের কারণে")}', style: const TextStyle(fontSize: 12.5, color: Color(0xFFB71C1C))),
                        ],
                      ),
                    ),
                  ],

                  // Password Lock Security Alert (if locked due to failed attempts)
                  if (user.isPasswordLocked) ...[
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
                                  'ব্যর্থ চেষ্টা: ${_toBn(user.failedAttempts.toString())} বার • স্বয়ংক্রিয় আনলক হতে বাকি: ${_toBn(user.lockUntil != null ? (user.lockUntil!.difference(DateTime.now()).inMinutes + 1).toString() : '১')} মিনিট',
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
                            onPressed: () => _handleResetLoginLock(user, dialogCtx: ctx),
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
                        onPressed: () => _handleResetLoginLock(user, dialogCtx: ctx),
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
                        onPressed: () => _handleDirectPasswordSet(user, dialogCtx: ctx),
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
                        onPressed: () => _handlePasswordReset(user, dialogCtx: ctx),
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
                        onPressed: () => _handleProfileLimitReset(user, dialogCtx: ctx),
                      ),

                      // 3. Status Change Buttons
                      if (user.status != 'active')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            backgroundColor: AdminColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                          label: const Text('একাউন্ট একটিভ করুন', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          onPressed: () => _handleActivateUser(user, dialogCtx: ctx),
                        ),

                      if (user.status != 'temporary_blocked')
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            foregroundColor: const Color(0xFFE65100),
                            side: const BorderSide(color: Color(0xFFFFCC80)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.timer_outlined, size: 16),
                          label: const Text('অস্থায়ী ব্লক', style: TextStyle(fontSize: 12.5)),
                          onPressed: () => _handleTemporaryBlock(user, dialogCtx: ctx),
                        ),

                      if (user.status != 'permanently_suspended')
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            foregroundColor: AdminColors.alertCritical,
                            side: const BorderSide(color: Color(0xFFFFCDD2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.block_rounded, size: 16),
                          label: const Text('স্থায়ী সাসপেন্ড', style: TextStyle(fontSize: 12.5)),
                          onPressed: () => _handlePermanentSuspend(user, dialogCtx: ctx),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
      body: StreamBuilder<List<AdminUserModel>>(
        stream: AdminFirestoreService.instance.getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AdminColors.primary));
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

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
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
            ),
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
