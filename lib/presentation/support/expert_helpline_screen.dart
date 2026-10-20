import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/widgets/premium_loading_widget.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../data/models/support_ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';
import 'new_query_screen.dart';

class ExpertHelplineScreen extends StatelessWidget {
  const ExpertHelplineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supportProvider = Provider.of<SupportProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final currentUserId = user?.uid ?? 'guest_user';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: AppStrings.helplineTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Govt Call Center 16123 Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B1FA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x306A1B9A),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.govtCallCenterTitle,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'টোল-ফ্রি সরাসরি কৃষি কল সেন্টার',
                              style: TextStyle(color: Color(0xFFE1BEE7), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    AppStrings.govtCallCenterSubtitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CustomButton(
                    text: AppStrings.callNow,
                    onPressed: () => supportProvider.callAgriCallCenter(),
                    icon: Icons.call,
                    backgroundColor: Colors.white,
                    textColor: const Color(0xFF4A148C),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 2. Ask Local Officer In-App Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'কৃষি কর্মকর্তার কাছে প্রশ্ন',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewQueryScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('নতুন প্রশ্ন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // User's tickets list (Real-time Stream)
            StreamBuilder<List<SupportTicketModel>>(
              stream: supportProvider.getUserTicketsStream(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const PremiumLoadingWidget(topic: 'জিজ্ঞাসার তথ্য');
                }

                final tickets = snapshot.data ?? [];
                if (tickets.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.contact_support_outlined, size: 48, color: AppColors.primary),
                        const SizedBox(height: 12),
                        const Text(
                          'আপনার কোনো প্রশ্ন বা পরামর্শ বার্তা নেই',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ফসলের সমস্যা নিয়ে উপজেলা কৃষি কর্মকর্তার কাছে সরাসরি প্রশ্ন পাঠাতে "নতুন প্রশ্ন" বাটনে ট্যাপ করুন।',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NewQueryScreen()),
                            );
                          },
                          icon: const Icon(Icons.help_outline),
                          label: const Text('পরামর্শের জন্য প্রশ্ন পাঠান'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return _buildTicketCard(ticket);
                  },
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicketModel ticket) {
    final isAnswered = ticket.status == 'answered';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAnswered ? AppColors.successBg : AppColors.alertWarningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAnswered ? 'উত্তর দেওয়া হয়েছে' : 'অপেক্ষমান',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isAnswered ? AppColors.success : AppColors.alertWarning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ticket.details,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.35),
          ),
          if (ticket.officerReply != null && ticket.officerReply!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.secondaryContainer),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        ticket.officerName ?? 'উপসহকারী কৃষি কর্মকর্তা',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.officerReply!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            BanglaDateFormatter.formatRelative(ticket.timestamp),
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
