import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/utils/admin_error_handler.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_firestore_service.dart';
import '../widgets/admin_loading_indicator.dart';

class UsersFeedbackScreen extends StatefulWidget {
  const UsersFeedbackScreen({super.key});

  @override
  State<UsersFeedbackScreen> createState() => _UsersFeedbackScreenState();
}

class _UsersFeedbackScreenState extends State<UsersFeedbackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for Contact Settings
  final TextEditingController _hotlineTitleCtrl = TextEditingController();
  final TextEditingController _hotlinePhoneCtrl = TextEditingController();
  final TextEditingController _whatsappTitleCtrl = TextEditingController();
  final TextEditingController _whatsappPhoneCtrl = TextEditingController();
  final TextEditingController _emailTitleCtrl = TextEditingController();
  final TextEditingController _emailAddressCtrl = TextEditingController();
  bool _isSavingSettings = false;
  bool _isSettingsLoaded = false;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _faqsStream;
  late final Stream<List<AdminUserModel>> _usersStream;
  late final Stream<List<AdminSupportTicketModel>> _ticketsStream;

  @override
  void initState() {
    super.initState();
    _faqsStream = FirebaseFirestore.instance.collection('faqs').snapshots();
    _usersStream = AdminFirestoreService.instance.getUsersStream();
    _ticketsStream = AdminFirestoreService.instance.getSupportTicketsStream();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hotlineTitleCtrl.dispose();
    _hotlinePhoneCtrl.dispose();
    _whatsappTitleCtrl.dispose();
    _whatsappPhoneCtrl.dispose();
    _emailTitleCtrl.dispose();
    _emailAddressCtrl.dispose();
    super.dispose();
  }

  void _openReplyDialog(AdminSupportTicketModel ticket) {
    showDialog(
      context: context,
      builder: (context) => _TicketReplyDialog(ticket: ticket),
    );
  }

  Future<void> _saveContactSettings() async {
    setState(() => _isSavingSettings = true);
    try {
      await AdminFirestoreService.instance.saveSupportContactSettings(
        hotlineTitle: _hotlineTitleCtrl.text.trim(),
        hotlinePhone: _hotlinePhoneCtrl.text.trim(),
        whatsappTitle: _whatsappTitleCtrl.text.trim(),
        whatsappPhone: _whatsappPhoneCtrl.text.trim(),
        emailTitle: _emailTitleCtrl.text.trim(),
        emailAddress: _emailAddressCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('সাপোর্ট ও যোগাযোগ চ্যানেল সফলভাবে সংরক্ষণ হয়েছে!'),
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
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSettings = false);
    }
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
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            tabs: const [
              Tab(icon: Icon(Icons.contact_phone_rounded), text: 'লাইভ সাপোর্ট চ্যানেল (Contact Channels)'),
              Tab(icon: Icon(Icons.quiz_rounded), text: 'FAQs সেটিংস (FAQ Management)'),
              Tab(icon: Icon(Icons.support_agent_rounded), text: 'সহায়তা টিকিট ও মতামত (Support Tickets)'),
              Tab(icon: Icon(Icons.people_alt_rounded), text: 'নিবন্ধিত কৃষক তালিকা (Users)'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildContactChannelsTab(),
              _buildFaqsSettingsTab(),
              _buildSupportTicketsTab(),
              _buildUsersTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== TAB 1: LIVE CONTACT CHANNELS ====================
  Widget _buildContactChannelsTab() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('app_settings').doc('support_contact').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.data() != null && !_isSettingsLoaded) {
          final d = snapshot.data!.data()!;
          _hotlineTitleCtrl.text = d['hotline_title']?.toString() ?? '';
          _hotlinePhoneCtrl.text = d['hotline_phone']?.toString() ?? '';
          _whatsappTitleCtrl.text = d['whatsapp_title']?.toString() ?? '';
          _whatsappPhoneCtrl.text = d['whatsapp_phone']?.toString() ?? '';
          _emailTitleCtrl.text = d['email_title']?.toString() ?? '';
          _emailAddressCtrl.text = d['email_address']?.toString() ?? '';
          _isSettingsLoaded = true;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    const Text(
                      'অ্যাপের লাইভ সাপোর্ট চ্যানেল কনফিগারেশন',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ইউজার অ্যাপের সাপোর্ট পেজে প্রদর্শিত হটলাইন, হোয়াটসঅ্যাপ এবং ইমেইল তথ্য রিয়েল-টাইমে আপডেট করুন।',
                      style: TextStyle(fontSize: 13, color: AdminColors.textMuted),
                    ),
                    const SizedBox(height: 20),

                    // Grid of 3 Channels
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 800;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            // Hotline
                            SizedBox(
                              width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                              child: _buildChannelCard(
                                title: 'হটলাইন / কল সেন্টার',
                                icon: Icons.phone_in_talk_rounded,
                                iconColor: const Color(0xFF00A86B),
                                iconBg: const Color(0xFFE8F5E9),
                                titleController: _hotlineTitleCtrl,
                                valueController: _hotlinePhoneCtrl,
                                valueLabel: 'হটলাইন ফোন নম্বর',
                                valueHint: 'যেমন: 16123 বা 017XXXXXXXX',
                              ),
                            ),
                            // WhatsApp
                            SizedBox(
                              width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                              child: _buildChannelCard(
                                title: 'হোয়াটসঅ্যাপ সাপোর্ট',
                                icon: Icons.chat_bubble_rounded,
                                iconColor: const Color(0xFF25D366),
                                iconBg: const Color(0xFFE8F8F0),
                                titleController: _whatsappTitleCtrl,
                                valueController: _whatsappPhoneCtrl,
                                valueLabel: 'হোয়াটসঅ্যাপ নম্বর (আন্তর্জাতিক ফরম্যাট)',
                                valueHint: 'যেমন: +88017XXXXXXXX',
                              ),
                            ),
                            // Email
                            SizedBox(
                              width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                              child: _buildChannelCard(
                                title: 'ইমেইল ডেস্ক',
                                icon: Icons.email_rounded,
                                iconColor: const Color(0xFF00897B),
                                iconBg: const Color(0xFFE0F2F1),
                                titleController: _emailTitleCtrl,
                                valueController: _emailAddressCtrl,
                                valueLabel: 'ইমেইল অ্যাড্রেস',
                                valueHint: 'যেমন: support@krishikotha.gov.bd',
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFFFFA000), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'সতর্কতা: কোনো যোগাযোগ চ্যানেল বা নম্বর ফাঁকা রাখা হলে ইউজার অ্যাপে সেই অপশনে ট্যাপ করলে প্রদর্শিত হবে: "এই ফিচারটি এখনো চালু হয়নি"।',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF795548), height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSavingSettings ? null : _saveContactSettings,
                        icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                        label: Text(
                          _isSavingSettings ? 'সংরক্ষণ হচ্ছে...' : 'কন্টাক্ট সেটিংস সংরক্ষণ করুন',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChannelCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required TextEditingController titleController,
    required TextEditingController valueController,
    required String valueLabel,
    required String valueHint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'শিরোনাম / হেডলাইন',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: valueController,
            decoration: InputDecoration(
              labelText: valueLabel,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB: FAQS SETTINGS ====================
  Widget _buildFaqsSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card with Action Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AdminColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.quiz_rounded, color: AdminColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'সাধারণ জিজ্ঞাসা (FAQs) ব্যবস্থাপনা',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'ইউজার অ্যাপের সাধারণ জিজ্ঞাসা পেজে প্রদর্শিত প্রশ্নোত্তর যোগ, পরিবর্তন বা মুছে ফেলুন।',
                        style: TextStyle(
                          fontSize: 13,
                          color: AdminColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openFaqDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('নতুন FAQ যোগ করুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Real-time FAQs List via StreamBuilder
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _faqsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const AdminLoadingIndicator(message: 'তথ্য লোডিং হচ্ছে.....');
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.alertCritical),
                  ),
                  child: Center(
                    child: Text(
                      'FAQs লোড করতে ত্রুটি: ${snapshot.error}',
                      style: const TextStyle(color: AdminColors.alertCritical),
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AdminColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.help_outline_rounded, color: AdminColors.primary, size: 36),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'কোনো FAQ যুক্ত নেই',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'উপরের "নতুন FAQ যোগ করুন" বাটনে ক্লিক করে প্রথম সাধারণ জিজ্ঞাসা যুক্ত করুন।',
                        style: TextStyle(fontSize: 13, color: AdminColors.textMuted),
                      ),
                    ],
                  ),
                );
              }

              // Sort in memory by order or createdAt
              final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
              sortedDocs.sort((a, b) {
                final dataA = a.data();
                final dataB = b.data();
                final orderA = (dataA['order'] is num) ? (dataA['order'] as num) : 99999;
                final orderB = (dataB['order'] is num) ? (dataB['order'] as num) : 99999;
                if (orderA != orderB) return orderA.compareTo(orderB);
                final timeA = dataA['createdAt'];
                final timeB = dataB['createdAt'];
                if (timeA is Timestamp && timeB is Timestamp) {
                  return timeB.compareTo(timeA);
                }
                return 0;
              });

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedDocs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = sortedDocs[index];
                  final data = doc.data();
                  final docId = doc.id;
                  final question = (data['question'] ?? '').toString();
                  final answer = (data['answer'] ?? '').toString();

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AdminColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AdminColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AdminColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AdminColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                answer,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: AdminColors.textMuted,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AdminColors.primary, size: 20),
                              tooltip: 'এডিট করুন',
                              onPressed: () => _openFaqDialog(
                                docId: docId,
                                currentQuestion: question,
                                currentAnswer: answer,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.alertCritical, size: 20),
                              tooltip: 'মুছে ফেলুন',
                              onPressed: () => _confirmDeleteFaq(docId, question),
                            ),
                          ],
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

  void _openFaqDialog({
    String? docId,
    String? currentQuestion,
    String? currentAnswer,
  }) {
    final questionCtrl = TextEditingController(text: currentQuestion ?? '');
    final answerCtrl = TextEditingController(text: currentAnswer ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    docId == null ? Icons.add_circle_outline_rounded : Icons.edit_note_rounded,
                    color: AdminColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    docId == null ? 'নতুন FAQ যোগ করুন' : 'FAQ এডিট ও আপডেট',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: questionCtrl,
                          maxLines: 2,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'প্রশ্ন বা শিরোনাম লিখুন' : null,
                          decoration: const InputDecoration(
                            labelText: 'প্রশ্ন / হেডলাইন *',
                            hintText: 'যেমন: কৃষি কথা অ্যাপে কীভাবে একাউন্ট খুলবো?',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: answerCtrl,
                          maxLines: 5,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'উত্তর বা সমাধান লিখুন' : null,
                          decoration: const InputDecoration(
                            labelText: 'বিস্তারিত উত্তর *',
                            hintText: 'প্রশ্নের বিস্তারিত উত্তর বা সমাধানের ধাপসমূহ লিখুন...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          try {
                            final q = questionCtrl.text.trim();
                            final a = answerCtrl.text.trim();
                            if (docId == null) {
                              await FirebaseFirestore.instance.collection('faqs').add({
                                'question': q,
                                'answer': a,
                                'createdAt': FieldValue.serverTimestamp(),
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                            } else {
                              await FirebaseFirestore.instance.collection('faqs').doc(docId).update({
                                'question': q,
                                'answer': a,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                            }
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('FAQ সফলভাবে সংরক্ষণ করা হয়েছে!'),
                                  backgroundColor: AdminColors.primary,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('সংরক্ষণে ত্রুটি: $e'),
                                  backgroundColor: AdminColors.alertCritical,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(docId == null ? 'সংরক্ষণ করুন' : 'আপডেট করুন'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteFaq(String docId, String question) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AdminColors.alertCritical),
            SizedBox(width: 8),
            Text('FAQ মুছে ফেলতে চান?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'আপনি কি নিশ্চিত যে এই প্রশ্নটি স্থায়ীভাবে মুছে ফেলতে চান?\n\n"$question"',
          style: const TextStyle(fontSize: 13.5, color: AdminColors.textPrimary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('বাতিল', style: TextStyle(color: AdminColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.alertCritical,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await FirebaseFirestore.instance.collection('faqs').doc(docId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('FAQ সফলভাবে মুছে ফেলা হয়েছে!'),
                      backgroundColor: AdminColors.alertCritical,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('মুছে ফেলতে ত্রুটি: $e'),
                      backgroundColor: AdminColors.alertCritical,
                    ),
                  );
                }
              }
            },
            child: const Text('হ্যাঁ, মুছুন'),
          ),
        ],
      ),
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
                  'কৃষক তালিকা (সরাসরি সংযুক্ত)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                ),
                StreamBuilder<List<AdminUserModel>>(
                  stream: _usersStream,
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
              stream: _usersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const AdminLoadingIndicator(message: 'তথ্য লোডিং হচ্ছে.....');
                }

                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('কোনো তথ্য পাওয়া যায়নি', style: TextStyle(color: AdminColors.textMuted, fontWeight: FontWeight.w600)),
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
        stream: _ticketsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const AdminLoadingIndicator(message: 'তথ্য লোডিং হচ্ছে.....');
          }

          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('কোনো তথ্য পাওয়া যায়নি', style: TextStyle(color: AdminColors.textMuted, fontWeight: FontWeight.w600)),
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

  Future<void> _handleDecision(String decision) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await AdminFirestoreService.instance.updateTicketDecision(
        ticketId: widget.ticket.ticketId,
        status: decision,
        reasonOrReply: _replyCtrl.text.trim(),
        officerName: _officerNameCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decision == 'resolved' ? 'টিকিট সফলভাবে গ্রহণ ও সমাধান সম্পন্ন হয়েছে!' : 'টিকিটটি বাতিল করা হয়েছে।'),
            backgroundColor: decision == 'resolved' ? AdminColors.primary : AdminColors.alertCritical,
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('টিকিট সিদ্ধান্ত ও উত্তর: ${widget.ticket.subject}'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBF9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('কৃষক: ${widget.ticket.farmerName} (${widget.ticket.farmerPhone})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('বার্তা: ${widget.ticket.details}', style: const TextStyle(fontSize: 12.5, color: AdminColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
                  labelText: 'পরামর্শ, সমাধান বা বাতিলের কারণ',
                  hintText: 'কৃষকের জন্য পরামর্শ লিখুন বা বাতিলের সুনির্দিষ্ট কারণ উল্লেখ করুন',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'মন্তব্য/পরামর্শ আবশ্যক' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('বন্ধ করুন')),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.alertCritical),
          onPressed: _saving ? null : () => _handleDecision('rejected'),
          icon: const Icon(Icons.cancel_rounded, size: 16, color: Colors.white),
          label: const Text('বাতিল করুন', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
          onPressed: _saving ? null : () => _handleDecision('resolved'),
          icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
          label: Text(_saving ? 'সংরক্ষণ হচ্ছে...' : 'গ্রহণ করুন', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
