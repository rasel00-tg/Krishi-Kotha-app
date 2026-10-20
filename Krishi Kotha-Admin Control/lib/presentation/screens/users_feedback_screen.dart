import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/utils/admin_error_handler.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_firestore_service.dart';

class UsersFeedbackScreen extends StatefulWidget {
  const UsersFeedbackScreen({super.key});

  @override
  State<UsersFeedbackScreen> createState() => _UsersFeedbackScreenState();
}

class _UsersFeedbackScreenState extends State<UsersFeedbackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openReplyDialog(AdminSupportTicketModel ticket) {
    showDialog(
      context: context,
      builder: (context) => _TicketReplyDialog(ticket: ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AdminColors.primary,
            unselectedLabelColor: AdminColors.textMuted,
            indicatorColor: AdminColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            tabs: const [
              Tab(icon: Icon(Icons.people_alt_rounded), text: 'নিবন্ধিত কৃষক ও ব্যবহারকারী (Users)'),
              Tab(icon: Icon(Icons.support_agent_rounded), text: 'সহায়তা টিকিট ও মতামত (Support Tickets)'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUsersTab(),
              _buildSupportTicketsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== TAB 1: USERS ====================
  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'কৃষক তালিকা (Firestore লাইভ স্ট্রীম)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                ),
                StreamBuilder<List<AdminUserModel>>(
                  stream: AdminFirestoreService.instance.getUsersStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AdminColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('মোট: $count জন', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.primaryDark)),
                    );
                  },
                ),
              ],
            ),
            const Divider(color: AdminColors.divider, height: 28),
            StreamBuilder<List<AdminUserModel>>(
              stream: AdminFirestoreService.instance.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ));
                }

                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('বর্তমানে কোনো তথ্য নেই'),
                  ));
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(color: AdminColors.divider, height: 16),
                  itemBuilder: (context, index) {
                    final u = users[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AdminColors.primary,
                            child: Text(
                              u.name.isNotEmpty ? u.name[0] : 'ক',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                Text('ফোন: ${u.phone}', style: const TextStyle(fontSize: 12, color: AdminColors.textMuted)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${u.upazila.isNotEmpty ? "${u.upazila}, " : ""}${u.district}',
                              style: const TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Wrap(
                              spacing: 4,
                              children: u.preferredCrops.map((crop) => Chip(
                                label: Text(crop, style: const TextStyle(fontSize: 10)),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              )).toList(),
                            ),
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
      ),
    );
  }

  // ==================== TAB 2: SUPPORT TICKETS ====================
  Widget _buildSupportTicketsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<List<AdminSupportTicketModel>>(
        stream: AdminFirestoreService.instance.getSupportTicketsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ));
          }

          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('বর্তমানে কোনো তথ্য নেই'),
            ));
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tickets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final t = tickets[index];
              final isAnswered = t.status == 'answered';

              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                  boxShadow: const [
                    BoxShadow(color: AdminColors.cardShadow, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAnswered ? AdminColors.successBg : AdminColors.alertWarningBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAnswered ? 'উত্তর দেওয়া হয়েছে' : 'পেন্ডিং / অপেক্ষারত',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isAnswered ? AdminColors.primaryDark : AdminColors.alertWarning,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${t.authorName} (${t.authorPhone}) • ${t.upazila}, ${t.district}',
                          style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _openReplyDialog(t),
                          icon: const Icon(Icons.reply_rounded, size: 16),
                          label: Text(isAnswered ? 'পুনরায় উত্তর দিন' : 'উত্তর প্রদান করুন'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAnswered ? AdminColors.secondary : AdminColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AdminColors.divider, height: 20),
                    Text(
                      t.subject,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.details,
                      style: const TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                    ),
                    if (isAnswered && t.officerReply != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'কর্মকর্তার পরামর্শ (${t.officerName ?? "কৃষি কর্মকর্তা"}):',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AdminColors.primaryDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.officerReply!,
                              style: const TextStyle(fontSize: 13, color: AdminColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TicketReplyDialog extends StatefulWidget {
  final AdminSupportTicketModel ticket;

  const _TicketReplyDialog({required this.ticket});

  @override
  State<_TicketReplyDialog> createState() => _TicketReplyDialogState();
}

class _TicketReplyDialogState extends State<_TicketReplyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _officerNameCtrl;
  late TextEditingController _replyCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _officerNameCtrl = TextEditingController(text: widget.ticket.officerName ?? '');
    _replyCtrl = TextEditingController(text: widget.ticket.officerReply ?? '');
  }

  @override
  void dispose() {
    _officerNameCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await AdminFirestoreService.instance.replyToTicket(
        ticketId: widget.ticket.ticketId,
        reply: _replyCtrl.text.trim(),
        officerName: _officerNameCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('পরামর্শ উত্তর সফলভাবে প্রদান করা হয়েছে! কৃষকের অ্যাপে আপডেট হয়েছে।'), backgroundColor: AdminColors.primary),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('টিকিটের উত্তর দিন: ${widget.ticket.subject}'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _officerNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'উত্তরদাতার নাম ও পদবি',
                  hintText: 'উত্তরদাতার নাম ও পদবি লিখুন',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'নাম আবশ্যক' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _replyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'পরামর্শ ও সমাধান',
                  hintText: 'পরামর্শ ও সমাধান লিখুন',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'পরামর্শ আবশ্যক' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'পাঠানো হচ্ছে...' : 'উত্তর পাঠান', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
