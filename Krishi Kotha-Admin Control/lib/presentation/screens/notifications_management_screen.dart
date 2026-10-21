import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/utils/admin_error_handler.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_firestore_service.dart';
import '../widgets/admin_delete_dialog.dart';

class NotificationsManagementScreen extends StatefulWidget {
  const NotificationsManagementScreen({super.key});

  @override
  State<NotificationsManagementScreen> createState() => _NotificationsManagementScreenState();
}

class _NotificationsManagementScreenState extends State<NotificationsManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'general';
  bool _isSubmitting = false;

  final Map<String, String> _typeLabels = {
    'general': 'সাধারণ নোটিশ',
    'weather': 'আবহাওয়া সতর্কতা',
    'crop': 'ফসল ও রোগবালাই পরামর্শ',
    'market': 'বাজার দর বিজ্ঞপ্তি',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await AdminFirestoreService.instance.sendNotification(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: _selectedType,
      );

      _titleController.clear();
      _messageController.clear();
      setState(() => _selectedType = 'general');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('বিজ্ঞপ্তি সফলভাবে প্রচার করা হয়েছে! মূল মোবাইল অ্যাপে সাথে সাথে সিঙ্ক হয়েছে।'),
            backgroundColor: AdminColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AdminErrorHandler.getFriendlyErrorMessage(e)),
            backgroundColor: AdminColors.alertCritical,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmDelete(String id, String title) async {
    final confirmed = await AdminDeleteDialog.show(
      context,
      title: 'আপনি কি নিশ্চিত মুছে ফেলতে চান?',
      subtitle: 'এই নোটিফিকেশনটি মুছে ফেললে অ্যাপ থেকেও স্থায়ীভাবে মুছে যাবে। আপনি কি এগিয়ে যেতে চান?',
      itemName: 'বিজ্ঞপ্তি: $title',
    );

    if (confirmed) {
      try {
        await AdminFirestoreService.instance.deleteNotification(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('বিজ্ঞপ্তি সফলভাবে মুছে ফেলা হয়েছে।'), backgroundColor: AdminColors.primary),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AdminErrorHandler.getFriendlyErrorMessage(e)),
              backgroundColor: AdminColors.alertCritical,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Info
          const Text(
            'লাইভ নোটিফিকেশন ম্যানেজমেন্ট',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AdminColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'অ্যাপ ব্যবহারকারী ও কৃষকদের জন্য জরুরি নোটিশ, আবহাওয়ার সতর্কবার্তা বা পরামর্শ লাইভ প্রচার করুন।',
            style: TextStyle(fontSize: 13, color: AdminColors.textMuted),
          ),
          const SizedBox(height: 24),

          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _buildNotificationForm()),
                const SizedBox(width: 24),
                Expanded(flex: 7, child: _buildNotificationsList()),
              ],
            )
          else ...[
            _buildNotificationForm(),
            const SizedBox(height: 24),
            _buildNotificationsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: const [
          BoxShadow(color: AdminColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AdminColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.send_rounded, color: AdminColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'নতুন নোটিশ প্রচার করুন',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(color: AdminColors.divider, height: 28),

            // Notification Type Dropdown
            const Text('বিজ্ঞপ্তির ধরন', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: _typeLabels.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 16),

            // Title
            const Text('শিরোনাম', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'বিজ্ঞপ্তির শিরোনাম লিখুন',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'শিরোনাম আবশ্যক' : null,
            ),
            const SizedBox(height: 16),

            // Message
            const Text('বিস্তারিত বার্তা', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'বিস্তারিত বার্তা লিখুন',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(14),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'বার্তা আবশ্যক' : null,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitNotification,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.broadcast_on_personal_rounded, size: 20),
                label: Text(
                  _isSubmitting ? 'প্রেরণ হচ্ছে...' : 'লাইভ প্রচার করুন (Broadcast)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'প্রচারিত নোটিফিকেশন তালিকা',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              // StreamBuilder count badge
              StreamBuilder<List<AdminNotificationModel>>(
                stream: AdminFirestoreService.instance.getNotificationsStream(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'মোট: $count',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.primaryDark,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(color: AdminColors.divider, height: 28),

          // Real-time StreamBuilder List
          StreamBuilder<List<AdminNotificationModel>>(
            stream: AdminFirestoreService.instance.getNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ));
              }

              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('বর্তমানে কোনো তথ্য নেই'),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (context, index) => const Divider(color: AdminColors.divider, height: 16),
                itemBuilder: (context, index) {
                  final notif = list[index];
                  final typeBadge = _getTypeBadge(notif.type);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeBadge.bgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                typeBadge.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: typeBadge.textColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTime(notif.timestamp),
                              style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _confirmDelete(notif.id, notif.title),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AdminColors.alertCriticalBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AdminColors.alertCritical.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_outline_rounded, color: AdminColors.alertCritical, size: 14),
                                    SizedBox(width: 4),
                                    Text('মুছুন', style: TextStyle(fontSize: 11, color: AdminColors.alertCritical, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notif.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.message,
                          style: const TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  _TypeBadge _getTypeBadge(String type) {
    switch (type) {
      case 'weather':
        return _TypeBadge('আবহাওয়া সতর্কতা', AdminColors.alertWarningBg, AdminColors.alertWarning);
      case 'crop':
        return _TypeBadge('ফসল ও রোগবালাই', AdminColors.primaryContainer, AdminColors.primaryDark);
      case 'market':
        return _TypeBadge('বাজার দর', AdminColors.alertInfoBg, AdminColors.alertInfo);
      default:
        return _TypeBadge('সাধারণ নোটিশ', const Color(0xFFF3E5F5), const Color(0xFF7B1FA2));
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} মিনিট আগে';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ঘণ্টা আগে';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}

class _TypeBadge {
  final String label;
  final Color bgColor;
  final Color textColor;

  _TypeBadge(this.label, this.bgColor, this.textColor);
}
