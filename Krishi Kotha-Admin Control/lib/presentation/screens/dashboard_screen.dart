import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_firestore_service.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_delete_dialog.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AdminColors.primaryDark, AdminColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'স্বাগতম! কৃষি কথা অ্যাডমিন কন্ট্রোল সেন্টারে',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'এখান থেকে আপনি মোবাইল অ্যাপের নোটিফিকেশন, বাজার দর, ফসল ডেটা ও কৃষকদের রিয়েল-টাইম পরিচালনা করতে পারবেন।',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.hub_rounded, color: Colors.white, size: 36),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Real-time StreamBuilder Stat Cards Grid
          _buildMetricsGrid(context),
          const SizedBox(height: 28),

          // Quick Action Shortcuts
          const Text(
            'দ্রুত অ্যাকশন (Quick Actions)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AdminColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActions(context),
          const SizedBox(height: 28),

          // Real-time Lists Grid (Recent Notifications & Recent Market Prices)
          if (isMobile) ...[
            _buildLiveNotificationsCard(),
            const SizedBox(height: 20),
            _buildLiveMarketPricesCard(),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildLiveNotificationsCard()),
                const SizedBox(width: 20),
                Expanded(child: _buildLiveMarketPricesCard()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = isDesktop
          ? (constraints.maxWidth - 48) / 4
          : (isTablet ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          // 1. Total Registered Farmers / Users (StreamBuilder)
          SizedBox(
            width: cardWidth,
            child: StreamBuilder<List<AdminUserModel>>(
              stream: AdminFirestoreService.instance.getUsersStream(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return AdminStatCard(
                  title: 'মোট নিবন্ধিত কৃষক',
                  value: count.toString(),
                  icon: Icons.people_alt_rounded,
                  iconBgColor: AdminColors.primaryContainer,
                  iconColor: AdminColors.primary,
                  subtitle: snapshot.hasData ? 'রিয়েল-টাইম সিঙ্ক হচ্ছে' : 'লোড হচ্ছে...',
                );
              },
            ),
          ),

          // 2. Active Market Commodities (StreamBuilder)
          SizedBox(
            width: cardWidth,
            child: StreamBuilder<List<AdminMarketPriceModel>>(
              stream: AdminFirestoreService.instance.getMarketPricesStream(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return AdminStatCard(
                  title: 'সক্রিয় বাজার দর পণ্য',
                  value: count.toString(),
                  icon: Icons.storefront_rounded,
                  iconBgColor: AdminColors.secondaryContainer,
                  iconColor: AdminColors.secondary,
                  subtitle: snapshot.hasData ? 'বিভিন্ন হাট ও বাজার' : 'লোড হচ্ছে...',
                );
              },
            ),
          ),

          // 3. Crops Catalog Items (StreamBuilder)
          SizedBox(
            width: cardWidth,
            child: StreamBuilder<List<AdminCropModel>>(
              stream: AdminFirestoreService.instance.getCropsStream(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return AdminStatCard(
                  title: 'নথিভুক্ত ফসল ও জাত',
                  value: count.toString(),
                  icon: Icons.grass_rounded,
                  iconBgColor: const Color(0xFFFFF3E0),
                  iconColor: AdminColors.earthyGold,
                  subtitle: snapshot.hasData ? 'জাত ও চাষাবাদ গাইড' : 'লোড হচ্ছে...',
                );
              },
            ),
          ),

          // 4. Live Notifications Broadcasted (StreamBuilder)
          SizedBox(
            width: cardWidth,
            child: StreamBuilder<List<AdminNotificationModel>>(
              stream: AdminFirestoreService.instance.getNotificationsStream(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return AdminStatCard(
                  title: 'সক্রিয় নোটিফিকেশন',
                  value: count.toString(),
                  icon: Icons.notifications_active_rounded,
                  iconBgColor: AdminColors.alertCriticalBg,
                  iconColor: AdminColors.alertCritical,
                  subtitle: snapshot.hasData ? 'লাইভ পুশ সতর্কবার্তা' : 'লোড হচ্ছে...',
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: () => onNavigate(1),
          icon: const Icon(Icons.add_alert_rounded, size: 18),
          label: const Text('নতুন নোটিফিকেশন পাঠান'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => onNavigate(2),
          icon: const Icon(Icons.price_change_rounded, size: 18),
          label: const Text('বাজার দর আপডেট করুন'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => onNavigate(3),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
          label: const Text('নতুন ফসল / রোগবালাই যুক্ত করুন'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.earthyBrown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => onNavigate(5),
          icon: const Icon(Icons.contact_support_rounded, size: 18),
          label: const Text('কৃষক ও সহায়তা টিকিট দেখুন'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminColors.textPrimary,
            side: const BorderSide(color: AdminColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _handleSeedDatabase(context),
          icon: const Icon(Icons.cloud_upload_rounded, size: 18),
          label: const Text('ডেটাবেজ সিড করুন (Seed Database)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryLight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSeedDatabase(BuildContext context) async {
    final confirmed = await AdminDeleteDialog.show(
      context,
      title: 'ডেটাবেজ সিড করতে চান?',
      subtitle: 'খালি কালেকশনগুলোতে স্বয়ংক্রিয়ভাবে বাস্তবসম্মত প্রাথমিক তথ্য (ফসল, রোগবালাই, বাজার দর, নোটিফিকেশন) আপলোড করা হবে। আপনি কি এগিয়ে যেতে চান?',
      itemName: 'প্রাথমিক ডেমো ডাটা সিডিং',
    );

    if (confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ডেটাবেজ সিডিং চলছে... অনুগ্রহ করে অপেক্ষা করুন।'),
          duration: Duration(seconds: 2),
        ),
      );

      try {
        final count = await AdminFirestoreService.instance.seedDatabaseIfEmpty(force: false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(count > 0
                  ? '$count টি প্রাথমিক তথ্য সফলভাবে ফায়ারবেসে যুক্ত হয়েছে!'
                  : 'ডেটাবেজে ইতিমধ্যে পর্যাপ্ত তথ্য বিদ্যমান রয়েছে।'),
              backgroundColor: AdminColors.primary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AdminColors.alertCritical,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Widget _buildLiveNotificationsCard() {
    return Container(
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
                'সাম্প্রতিক নোটিফিকেশন (রিয়েল-টাইম)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => onNavigate(1),
                child: const Text('সব দেখুন'),
              ),
            ],
          ),
          const Divider(color: AdminColors.divider),
          StreamBuilder<List<AdminNotificationModel>>(
            stream: AdminFirestoreService.instance.getNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ));
              }

              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('কোনো নোটিফিকেশন পাওয়া যায়নি।'),
                );
              }

              final displayList = list.take(4).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (context, index) => const Divider(color: AdminColors.divider, height: 1),
                itemBuilder: (context, index) {
                  final notif = displayList[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AdminColors.primaryContainer,
                      child: Icon(
                        notif.type == 'weather'
                            ? Icons.thunderstorm_rounded
                            : (notif.type == 'crop' ? Icons.grass_rounded : Icons.campaign_rounded),
                        color: AdminColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notif.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      notif.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                    ),
                    trailing: Text(
                      _formatDate(notif.timestamp),
                      style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
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

  Widget _buildLiveMarketPricesCard() {
    return Container(
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
                'লাইভ বাজার দর আপডেট',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => onNavigate(2),
                child: const Text('সব আপডেট'),
              ),
            ],
          ),
          const Divider(color: AdminColors.divider),
          StreamBuilder<List<AdminMarketPriceModel>>(
            stream: AdminFirestoreService.instance.getMarketPricesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ));
              }

              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('কোনো বাজার দর তথ্য পাওয়া যায়নি।'),
                );
              }

              final displayList = list.take(4).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (context, index) => const Divider(color: AdminColors.divider, height: 1),
                itemBuilder: (context, index) {
                  final item = displayList[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.cropName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${item.marketName}, ${item.district}',
                      style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳${item.price.toStringAsFixed(0)} / ${item.unit}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AdminColors.primaryDark,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.trend == 'up'
                                  ? Icons.trending_up_rounded
                                  : (item.trend == 'down' ? Icons.trending_down_rounded : Icons.trending_flat_rounded),
                              size: 14,
                              color: item.trend == 'up'
                                  ? AdminColors.alertCritical
                                  : (item.trend == 'down' ? AdminColors.primary : AdminColors.textMuted),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.trend == 'up' ? 'উর্ধ্বমুখী' : (item.trend == 'down' ? 'নিম্নমুখী' : 'স্থিতিশীল'),
                              style: TextStyle(
                                fontSize: 11,
                                color: item.trend == 'up'
                                    ? AdminColors.alertCritical
                                    : (item.trend == 'down' ? AdminColors.primary : AdminColors.textMuted),
                              ),
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

  String _formatDate(DateTime dt) {
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
