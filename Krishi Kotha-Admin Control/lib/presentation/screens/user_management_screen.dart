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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AdminColors.alertCritical : AdminColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ================= 1. PASSWORD RESET =================
  Future<void> _handlePasswordReset(AdminUserModel user) async {
    if (user.email.isEmpty) {
      _showSnackBar('এই ইউজারের কোনো নিবন্ধিত ইমেইল নেই।', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.lock_reset_rounded, color: AdminColors.primary),
            SizedBox(width: 10),
            Text('পাসওয়ার্ড রিসেট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'আপনি কি "${user.name}" (${user.email})-এর একাউন্টের জন্য অফিসিয়াল পাসওয়ার্ড রিসেট ইমেইল পাঠাতে চান?',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ইমেইল পাঠান'),
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

  // ================= 2. PROFILE EDIT LIMIT RESET =================
  Future<void> _handleProfileLimitReset(AdminUserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.restart_alt_rounded, color: AdminColors.alertWarning),
            SizedBox(width: 10),
            Text('এডিট লিমিট রিসেট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'আপনি কি "${user.name}"-এর ৩০ দিনের প্রোফাইল এডিট লিমিট রিসেট করতে চান? রিসেট করার সাথে সাথে তিনি প্রোফাইল সংশোধন করতে পারবেন।',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.alertWarning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('লিমিট রিসেট করুন'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await AdminFirestoreService.instance.resetProfileUpdateLimit(user.uid);
        _showSnackBar('প্রোফাইল এডিট লিমিট সফলভাবে রিসেট করা হয়েছে।');
      } catch (e) {
        _showSnackBar(AdminErrorHandler.getFriendlyErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ================= 3. TEMPORARY BLOCK =================
  Future<void> _handleTemporaryBlock(AdminUserModel user) async {
    int selectedDays = 3;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.timer_outlined, color: AdminColors.alertWarning),
              SizedBox(width: 10),
              Text('সাময়িক স্থগিত (Temporary Block)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ইউজার: ${user.name} (${user.phone})', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                const Text('স্থগিতের মেয়াদ:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedDays,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('১ দিন (২৪ ঘণ্টা)')),
                    DropdownMenuItem(value: 3, child: Text('৩ দিন (৭২ ঘণ্টা)')),
                    DropdownMenuItem(value: 7, child: Text('৭ দিন (১ সপ্তাহ)')),
                    DropdownMenuItem(value: 14, child: Text('১৪ দিন (২ সপ্তাহ)')),
                    DropdownMenuItem(value: 30, child: Text('৩০ দিন (১ মাস)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedDays = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text('ব্লকের কারণ:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'ব্লক করার সুনির্দিষ্ট কারণ লিখুন...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.alertWarning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              child: const Text('সাময়িক ব্লক করুন'),
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
        _showSnackBar('ইউজারকে $selectedDays দিনের জন্য সাময়িক ব্লক করা হয়েছে।');
      } catch (e) {
        _showSnackBar(AdminErrorHandler.getFriendlyErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ================= 4. PERMANENT SUSPEND =================
  Future<void> _handlePermanentSuspend(AdminUserModel user) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.block_rounded, color: AdminColors.alertCritical),
            SizedBox(width: 10),
            Text('স্থায়ী সাসপেন্ড (Permanent Suspend)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AdminColors.alertCritical)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ইউজার: ${user.name} (${user.phone})', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            const Text(
              'সতর্কবার্তা: স্থায়ী সাসপেন্ড করলে ইউজার কখনোই আর এই একাউন্টে লগইন করতে পারবেন না।',
              style: TextStyle(color: AdminColors.alertCritical, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            const Text('সাসপেন্ডের কারণ:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'নীতিমালা লঙ্ঘনের বিস্তারিত বিবরণ লিখুন...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.alertCritical,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            child: const Text('স্থায়ী সাসপেন্ড করুন'),
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
        _showSnackBar('ইউজারকে স্থায়ীভাবে সাসপেন্ড করা হয়েছে।', isError: true);
      } catch (e) {
        _showSnackBar(AdminErrorHandler.getFriendlyErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ================= 5. ACTIVATE / UNBLOCK =================
  Future<void> _handleActivateUser(AdminUserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AdminColors.primary),
            SizedBox(width: 10),
            Text('একাউন্ট সক্রিয় করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'আপনি কি "${user.name}"-এর একাউন্টের সমস্ত ব্লক/সাসপেন্ড প্রত্যাহার করে পুনরায় "সক্রিয় (Active)" করতে চান?',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('সক্রিয় করুন'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await AdminFirestoreService.instance.activateUser(user.uid);
        _showSnackBar('ইউজার একাউন্ট সফলভাবে সক্রিয় করা হয়েছে।');
      } catch (e) {
        _showSnackBar(AdminErrorHandler.getFriendlyErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top KPI Summary Cards
                _buildSummaryStats(totalCount, activeCount, blockedCount, suspendedCount),

                const SizedBox(height: 24),

                // Main Controls Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminColors.border),
                    boxShadow: const [
                      BoxShadow(color: AdminColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Search Filter Row
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'নিবন্ধিত ব্যবহারকারী ও একাউন্ট কন্ট্রোল',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'রিয়েল-টাইম ফায়ারস্টোর ডেটাবেজ থেকে মোট ${allUsers.length} জন ইউজার লোড হয়েছে',
                                style: const TextStyle(fontSize: 12.5, color: AdminColors.textSecondary),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 320,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'নাম, ফোন, ইমেইল বা জেলা দিয়ে খুঁজুন...',
                                hintStyle: const TextStyle(fontSize: 12.5),
                                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AdminColors.primary),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Status Filter Chips
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip('all', 'সকল ইউজার ($totalCount)'),
                          _buildFilterChip('active', 'সক্রিয় ($activeCount)'),
                          _buildFilterChip('temporary_blocked', 'সাময়িক স্থগিত ($blockedCount)'),
                          _buildFilterChip('permanently_suspended', 'স্থায়ী সাসপেন্ড ($suspendedCount)'),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Users List / Table
                      if (filteredUsers.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Column(
                            children: const [
                              Icon(Icons.person_search_rounded, size: 48, color: AdminColors.textMuted),
                              SizedBox(height: 12),
                              Text('কোনো ব্যবহারকারী পাওয়া যায়নি', style: TextStyle(fontWeight: FontWeight.bold, color: AdminColors.textMuted)),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredUsers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AdminColors.divider),
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return _buildUserTile(user);
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

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatusFilter = key),
      selectedColor: AdminColors.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AdminColors.primaryDark : AdminColors.textSecondary,
      ),
    );
  }

  Widget _buildSummaryStats(int total, int active, int blocked, int suspended) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildStatCard('মোট ইউজার', total.toString(), Icons.people_alt_rounded, AdminColors.primary, AdminColors.primaryContainer, isWide),
          _buildStatCard('সক্রিয় একাউন্ট', active.toString(), Icons.check_circle_rounded, const Color(0xFF2E7D32), const Color(0xFFE8F5E9), isWide),
          _buildStatCard('সাময়িক ব্লক', blocked.toString(), Icons.timer_outlined, AdminColors.alertWarning, AdminColors.alertWarningBg, isWide),
          _buildStatCard('স্থায়ী সাসপেন্ড', suspended.toString(), Icons.block_rounded, AdminColors.alertCritical, AdminColors.alertCriticalBg, isWide),
        ],
      );
    });
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, Color bg, bool isWide) {
    return Container(
      width: isWide ? 220 : double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
        boxShadow: const [
          BoxShadow(color: AdminColors.cardShadow, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(AdminUserModel user) {
    // 30 days profile rate limit check
    bool isRateLimited = false;
    if (user.lastProfileUpdate != null) {
      final daysSinceUpdate = DateTime.now().difference(user.lastProfileUpdate!).inDays;
      if (daysSinceUpdate < 30) {
        isRateLimited = true;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AdminColors.primaryContainer,
            backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                ? NetworkImage(user.photoUrl!)
                : null,
            child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                ? Text(user.name.isNotEmpty ? user.name[0] : 'ক', style: const TextStyle(color: AdminColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 18))
                : null,
          ),
          const SizedBox(width: 14),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AdminColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(user),
                    if (isRateLimited) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFB74D)),
                        ),
                        child: const Text('এডিট লিমিটেড (৩০ দিন)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (user.phone.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_rounded, size: 13, color: AdminColors.textMuted),
                          const SizedBox(width: 4),
                          Text(user.phone, style: const TextStyle(fontSize: 12.5, color: AdminColors.textSecondary)),
                        ],
                      ),
                    if (user.email.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.email_outlined, size: 13, color: AdminColors.textMuted),
                          const SizedBox(width: 4),
                          Text(user.email, style: const TextStyle(fontSize: 12.5, color: AdminColors.textSecondary)),
                        ],
                      ),
                    if (user.district.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AdminColors.textMuted),
                          const SizedBox(width: 4),
                          Text('${user.village.isNotEmpty ? "${user.village}, " : ""}${user.upazila.isNotEmpty ? "${user.upazila}, " : ""}${user.district}',
                              style: const TextStyle(fontSize: 12.5, color: AdminColors.textSecondary)),
                        ],
                      ),
                  ],
                ),

                // Specific Reason display if blocked or suspended
                if (user.status == 'temporary_blocked' && user.blockReason != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      'ব্লকের কারণ: ${user.blockReason} | আনলক হবে: ${user.unblockAt != null ? "${user.unblockAt!.day}-${user.unblockAt!.month}-${user.unblockAt!.year}" : ""}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFF57F17), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                if (user.status == 'permanently_suspended' && user.suspendReason != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      'সাসপেন্ডের কারণ: ${user.suspendReason}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFC62828), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons
          PopupMenuButton<String>(
            tooltip: 'এডমিন অ্যাকশন মেনু',
            icon: const Icon(Icons.more_vert_rounded, color: AdminColors.textPrimary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (action) {
              if (action == 'reset_password') _handlePasswordReset(user);
              if (action == 'reset_limit') _handleProfileLimitReset(user);
              if (action == 'temp_block') _handleTemporaryBlock(user);
              if (action == 'perm_suspend') _handlePermanentSuspend(user);
              if (action == 'activate') _handleActivateUser(user);
            },
            itemBuilder: (context) => [
              if (user.email.isNotEmpty)
                const PopupMenuItem(
                  value: 'reset_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset_rounded, size: 18, color: AdminColors.primary),
                      SizedBox(width: 10),
                      Text('পাসওয়ার্ড রিসেট লিংক পাঠান'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'reset_limit',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt_rounded, size: 18, color: Color(0xFFE65100)),
                    SizedBox(width: 10),
                    Text('প্রোফাইল এডিট লিমিট রিসেট'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              if (user.status != 'active')
                const PopupMenuItem(
                  value: 'activate',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 18, color: AdminColors.primary),
                      SizedBox(width: 10),
                      Text('একাউন্ট সক্রিয় করুন (Active)'),
                    ],
                  ),
                ),
              if (user.status != 'temporary_blocked')
                const PopupMenuItem(
                  value: 'temp_block',
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: AdminColors.alertWarning),
                      SizedBox(width: 10),
                      Text('সাময়িক স্থগিত (Temporary Block)'),
                    ],
                  ),
                ),
              if (user.status != 'permanently_suspended')
                const PopupMenuItem(
                  value: 'perm_suspend',
                  child: Row(
                    children: [
                      Icon(Icons.block_rounded, size: 18, color: AdminColors.alertCritical),
                      SizedBox(width: 10),
                      Text('স্থায়ী সাসপেন্ড (Permanent Suspend)'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AdminUserModel user) {
    if (user.status == 'permanently_suspended') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AdminColors.alertCriticalBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AdminColors.alertCritical.withOpacity(0.4)),
        ),
        child: const Text('স্থায়ী সাসপেন্ড', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.alertCritical)),
      );
    }
    if (user.status == 'temporary_blocked') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AdminColors.alertWarningBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AdminColors.alertWarning.withOpacity(0.4)),
        ),
        child: const Text('সাময়িক স্থগিত', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.alertWarning)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AdminColors.successBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.success.withOpacity(0.4)),
      ),
      child: const Text('সক্রিয় (Active)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.success)),
    );
  }
}
