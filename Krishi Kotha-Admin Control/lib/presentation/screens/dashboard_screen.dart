import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/constants/bangladesh_locations.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_firestore_service.dart';
import '../widgets/admin_loading_indicator.dart';

/// Model representing a slice in the interactive Circular/Doughnut Chart
class _ChartSliceData {
  final String label;
  final int count;
  final Color color;
  final List<Color> gradient;
  final IconData icon;

  const _ChartSliceData({
    required this.label,
    required this.count,
    required this.color,
    required this.gradient,
    required this.icon,
  });
}

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final Stream<List<AdminUserModel>> _usersStream;
  late final Stream<List<AdminMarketPriceModel>> _marketPricesStream;
  late final Stream<List<AdminCropModel>> _cropsStream;
  late final Stream<List<AdminNotificationModel>> _notificationsStream;
  late final Stream<List<AdminSupportTicketModel>> _supportTicketsStream;

  late final ScrollController _scrollController;
  late final AnimationController _animController;
  late final Animation<double> _chartAnimation;

  // Topbar scroll fade effect opacity
  double _topbarOpacity = 1.0;

  // District filter for Active Accounts
  String _selectedDistrict = 'সকল জেলা';

  // Interactive tooltip tracking for circular chart
  int? _hoveredSliceIndex;
  Offset? _hoverPosition;

  @override
  void initState() {
    super.initState();
    _usersStream = AdminFirestoreService.instance.getUsersStream();
    _marketPricesStream = AdminFirestoreService.instance.getMarketPricesStream();
    _cropsStream = AdminFirestoreService.instance.getCropsStream();
    _notificationsStream = AdminFirestoreService.instance.getNotificationsStream();
    _supportTicketsStream = AdminFirestoreService.instance.getSupportTicketsStream();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _chartAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    // Fade out Topbar smoothly as user scrolls down between 0 and 120 pixels
    final newOpacity = (1.0 - (offset / 120.0)).clamp(0.0, 1.0);
    if ((newOpacity - _topbarOpacity).abs() > 0.01) {
      setState(() {
        _topbarOpacity = newOpacity;
      });
    }
  }

  String _toBn(dynamic value) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var s = value.toString();
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(en[i], bn[i]);
    }
    return s;
  }

  /// Robust district matcher supporting unicode variants and suffixes
  bool _isUserInDistrict(AdminUserModel user, String selectedDistrict) {
    if (selectedDistrict == 'সকল জেলা') return true;

    String clean(String s) => s
        .replaceAll('জেলা', '')
        .replaceAll('বিভাগ', '')
        .replaceAll(' ', '')
        .replaceAll('য়', 'য়')
        .replaceAll('ড়', 'ড়')
        .replaceAll('ঢ়', 'ঢ়')
        .toLowerCase()
        .trim();

    final target = clean(selectedDistrict);
    final userDist = clean(user.district);
    final userUpazila = clean(user.upazila);

    if (target.isEmpty) return true;
    return userDist.contains(target) ||
        target.contains(userDist) ||
        userUpazila.contains(target);
  }

  List<String> _getAvailableDistricts(List<AdminUserModel> users) {
    final Set<String> districtsSet = {'সকল জেলা'};
    districtsSet.addAll(BangladeshLocations.allDistricts);
    for (final u in users) {
      final d = u.district.trim();
      if (d.isNotEmpty && d != 'অনুল্লিখিত' && !districtsSet.contains(d)) {
        districtsSet.add(d);
      }
    }
    return districtsSet.toList();
  }

  /// Calculates dynamic slices for the animated circular doughnut chart
  List<_ChartSliceData> _calculateSliceData(List<AdminUserModel> users) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final activeCount = users.where((u) {
      final s = u.status.toLowerCase().trim();
      return s == 'active' || s.isEmpty;
    }).length;

    final newUsersCount = users.where((u) {
      return u.createdAt.isAfter(thirtyDaysAgo);
    }).length;

    final blockedCount = users.where((u) {
      return u.status.toLowerCase().trim() == 'temporary_blocked';
    }).length;

    final suspendedCount = users.where((u) {
      return u.status.toLowerCase().trim() == 'permanently_suspended';
    }).length;

    final slices = <_ChartSliceData>[];

    if (activeCount > 0) {
      slices.add(_ChartSliceData(
        label: 'সক্রিয় একাউন্ট',
        count: activeCount,
        color: const Color(0xFF2E7D32),
        gradient: const [Color(0xFF1B5E20), Color(0xFF4CAF50)],
        icon: Icons.check_circle_rounded,
      ));
    }

    if (newUsersCount > 0) {
      slices.add(_ChartSliceData(
        label: 'নতুন নিবন্ধন (৩০ দিন)',
        count: newUsersCount,
        color: const Color(0xFF1976D2),
        gradient: const [Color(0xFF0D47A1), Color(0xFF42A5F5)],
        icon: Icons.person_add_alt_1_rounded,
      ));
    }

    if (blockedCount > 0) {
      slices.add(_ChartSliceData(
        label: 'সাময়িক স্থগিত',
        count: blockedCount,
        color: const Color(0xFFE65100),
        gradient: const [Color(0xFFBF360C), Color(0xFFFF9800)],
        icon: Icons.lock_clock_rounded,
      ));
    }

    if (suspendedCount > 0) {
      slices.add(_ChartSliceData(
        label: 'স্থায়ী স্থগিত',
        count: suspendedCount,
        color: const Color(0xFFC62828),
        gradient: const [Color(0xFFB71C1C), Color(0xFFEF5350)],
        icon: Icons.block_rounded,
      ));
    }

    if (slices.isEmpty) {
      slices.add(_ChartSliceData(
        label: 'মোট ব্যবহারকারী',
        count: math.max(users.length, 1),
        color: const Color(0xFF2E7D32),
        gradient: const [Color(0xFF1B5E20), Color(0xFF4CAF50)],
        icon: Icons.group_rounded,
      ));
    }

    return slices;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ১. Topbar with Scroll Fade Effect
          if (_topbarOpacity > 0.01) ...[
            Opacity(
              opacity: _topbarOpacity,
              child: _buildWelcomeBanner(context, isMobile),
            ),
            SizedBox(height: 24 * _topbarOpacity),
          ],

          // ২. Merged Single View: Vibrant Summary Cards with District Filter
          // ("একটিভ একাউন্ট" ও "নিবন্ধিত কৃষক" কোনো ট্যাব ছাড়া একত্রিত একক ভিউতে পাশাপাশি)
          StreamBuilder<List<AdminUserModel>>(
            stream: _usersStream,
            builder: (context, userSnap) {
              final users = userSnap.data ?? [];
              final isUsersLoading = userSnap.connectionState == ConnectionState.waiting && !userSnap.hasData;

              return _buildVibrantSummaryCardsRow(context, users, isUsersLoading);
            },
          ),
          const SizedBox(height: 26),

          // ৪ & ৫. Middle Section: Animated Circular Chart & Support & Communication Card
          StreamBuilder<List<AdminUserModel>>(
            stream: _usersStream,
            builder: (context, userSnapshot) {
              final users = userSnapshot.data ?? [];
              final isUsersLoading = userSnapshot.connectionState == ConnectionState.waiting && !userSnapshot.hasData;

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ৪. Animated Circular/Doughnut Chart with Interactive Tooltips
                    Expanded(
                      flex: 7,
                      child: _buildAnimatedCircularChartCard(users, isUsersLoading, isMobile),
                    ),
                    const SizedBox(width: 22),
                    // ৫. Support & Communication Card (onTap routes to index 6)
                    Expanded(
                      flex: 5,
                      child: _buildSupportCommunicationCard(context),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimatedCircularChartCard(users, isUsersLoading, isMobile),
                    const SizedBox(height: 22),
                    _buildSupportCommunicationCard(context),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 28),

          // ৬. গোছানো টেবিল লেআউট (Neat Table Layout - Recent Notifications & Live Market Prices)
          if (isMobile) ...[
            _buildLiveNotificationsTableCard(),
            const SizedBox(height: 22),
            _buildLiveMarketPricesTableCard(),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildLiveNotificationsTableCard()),
                const SizedBox(width: 22),
                Expanded(child: _buildLiveMarketPricesTableCard()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==================== ১. TOPBAR (SCROLL FADE EFFECT) ====================
  Widget _buildWelcomeBanner(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 18 : 28,
        vertical: isMobile ? 18 : 22,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF162D1A), Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x351B5E20),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live system badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF69F0AE),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'লাইভ সিস্টেম কানেক্টেড',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  'কৃষি কথা এডমিন ড্যাশবোর্ডে স্বাগতম',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'কৃষি কথা ডিজিটাল কৃষি প্ল্যাটফর্মের সামগ্রিক কার্যক্রম, কৃষক একাউন্ট মনিটরিং ও রিয়েল-টাইম তথ্য নিয়ন্ত্রণ কেন্দ্র।',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: isMobile ? 12.5 : 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.dashboard_customize_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== ২. MERGED SINGLE VIEW: VIBRANT SUMMARY CARDS ====================
  Widget _buildVibrantSummaryCardsRow(BuildContext context, List<AdminUserModel> allUsers, bool isLoading) {
    final districts = _getAvailableDistricts(allUsers);

    // Filter users by selected district
    final filteredUsers = _selectedDistrict == 'সকল জেলা'
        ? allUsers
        : allUsers.where((u) => _isUserInDistrict(u, _selectedDistrict)).toList();

    // Active accounts count in the filtered set
    final activeCount = filteredUsers.where((u) {
      final status = u.status.toLowerCase().trim();
      return status == 'active' || status.isEmpty;
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        int crossAxisCount = 4;
        if (availableWidth < 680) {
          crossAxisCount = 1;
        } else if (availableWidth < 1080) {
          crossAxisCount = 2;
        }

        final itemWidth = (availableWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Card 1: একটিভ একাউন্ট (Royal Indigo/Blue Gradient with Expanded District Dropdown)
            SizedBox(
              width: itemWidth,
              child: _buildActiveAccountSummaryCard(
                context: context,
                activeCount: activeCount,
                totalFiltered: filteredUsers.length,
                totalAll: allUsers.length,
                districts: districts,
                isLoading: isLoading,
              ),
            ),

            // Card 2: নিবন্ধিত কৃষক (Mint / Emerald Green Gradient) - Merged in single view alongside Card 1
            SizedBox(
              width: itemWidth,
              child: _buildVibrantCard(
                title: 'নিবন্ধিত কৃষক',
                subtitle: 'সারাদেশে মোট কৃষক ডাটাবেজ',
                icon: Icons.people_alt_rounded,
                gradientColors: const [Color(0xFF0F9D58), Color(0xFF34A853)],
                shadowColor: const Color(0x400F9D58),
                stream: _usersStream.map((list) => list.length),
                unit: 'জন',
                onTap: () => widget.onNavigate(1), // Navigates to User Management
              ),
            ),

            // Card 3: বাজার দর পণ্য (Warm Amber / Orange Gradient)
            SizedBox(
              width: itemWidth,
              child: _buildVibrantCard(
                title: 'বাজার দর পণ্য',
                subtitle: 'বিভিন্ন হাট ও বাজারের লাইভ দর',
                icon: Icons.store_rounded,
                gradientColors: const [Color(0xFFE65100), Color(0xFFFF8F00)],
                shadowColor: const Color(0x40E65100),
                stream: _marketPricesStream.map((list) => list.length),
                unit: 'টি',
                onTap: () => widget.onNavigate(3), // Navigates to Market Prices
              ),
            ),

            // Card 4: ক্যাটালগ ফসল (Deep Purple / Violet Gradient)
            SizedBox(
              width: itemWidth,
              child: _buildVibrantCard(
                title: 'ক্যাটালগ ফসল',
                subtitle: 'নথিভুক্ত ফসল ও রোগবালাই',
                icon: Icons.eco_rounded,
                gradientColors: const [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                shadowColor: const Color(0x404A148C),
                stream: _cropsStream.map((list) => list.length),
                unit: 'টি',
                onTap: () => widget.onNavigate(4), // Navigates to Crops
              ),
            ),
          ],
        );
      },
    );
  }

  /// Card 1: Active Accounts with District Filter Dropdown (menuMaxHeight expanded)
  Widget _buildActiveAccountSummaryCard({
    required BuildContext context,
    required int activeCount,
    required int totalFiltered,
    required int totalAll,
    required List<String> districts,
    required bool isLoading,
  }) {
    final activePercentage = totalFiltered > 0
        ? ((activeCount / totalFiltered) * 100).round()
        : 0;

    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D1E3C72),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background soft watermark icon
          Positioned(
            right: -6,
            bottom: -8,
            child: Icon(
              Icons.check_circle_rounded,
              size: 72,
              color: Colors.white.withOpacity(0.12),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top line: Label + Expanded District Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'একটিভ একাউন্ট',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // District dropdown button with expanded menuMaxHeight
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: districts.contains(_selectedDistrict)
                            ? _selectedDistrict
                            : 'সকল জেলা',
                        dropdownColor: const Color(0xFF1E3C72),
                        menuMaxHeight: 520, // Requirement 3: Expanded menu height for easy view
                        borderRadius: BorderRadius.circular(12),
                        elevation: 8,
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                        isDense: true,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _selectedDistrict = value;
                            });
                          }
                        },
                        items: districts.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Metric count
              isLoading
                  ? const SizedBox(
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _toBn(activeCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'জন',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 6),

              // Filter info subtitle
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 11.5,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      _selectedDistrict == 'সকল জেলা'
                          ? 'সারাদেশে সক্রিয় (${_toBn(activePercentage)}%)'
                          : '$_selectedDistrict জেলায় (${_toBn(activePercentage)}%)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.90),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedDistrict != 'সকল জেলা') ...[
                    InkWell(
                      onTap: () => setState(() => _selectedDistrict = 'সকল জেলা'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'রিসেট',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Generic vibrant summary card
  Widget _buildVibrantCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    required Stream<int> stream,
    required String unit,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 140),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Soft background watermark icon
              Positioned(
                right: -6,
                bottom: -8,
                child: Icon(
                  icon,
                  size: 72,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title + Icon badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Value from stream
                  StreamBuilder<int>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const SizedBox(
                          height: 36,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }

                      final val = snapshot.data ?? 0;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _toBn(val),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unit,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ৪. ANIMATED CIRCULAR / DOUGHNUT CHART WITH TOOLTIPS ====================
  Widget _buildAnimatedCircularChartCard(List<AdminUserModel> users, bool isLoading, bool isMobile) {
    final slices = _calculateSliceData(users);
    final totalUsers = users.length;

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: AdminColors.cardShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AdminColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.donut_large_rounded,
                            size: 18,
                            color: AdminColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'ব্যবহারকারী একাউন্ট বিশ্লেষণ (Circular Chart)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'সক্রিয়তা, নতুন নিবন্ধন ও একাউন্ট স্ট্যাটাসের সুবিন্যস্ত পাই/ডোনাট চার্ট',
                      style: TextStyle(
                        fontSize: 12,
                        color: AdminColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Total Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 4),
                    Text(
                      'মোট: ${_toBn(totalUsers)} জন',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Chart + Legend Area
          isLoading
              ? const SizedBox(
                  height: 220,
                  child: Center(child: AdminLoadingIndicator(message: 'চার্ট প্রস্তুত হচ্ছে...')),
                )
              : AnimatedBuilder(
                  animation: _chartAnimation,
                  builder: (context, _) {
                    return isMobile
                        ? Column(
                            children: [
                              _buildCircularChartWidget(slices, totalUsers),
                              const SizedBox(height: 18),
                              _buildChartLegend(slices, totalUsers),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildCircularChartWidget(slices, totalUsers),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 6,
                                child: _buildChartLegend(slices, totalUsers),
                              ),
                            ],
                          );
                  },
                ),
        ],
      ),
    );
  }

  /// Interactive Animated Circular Doughnut Chart with Hover / Tap Tooltip
  Widget _buildCircularChartWidget(List<_ChartSliceData> slices, int total) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 200.0);

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: MouseRegion(
              onHover: (event) {
                final local = event.localPosition;
                final center = Offset(size / 2, size / 2);
                final dx = local.dx - center.dx;
                final dy = local.dy - center.dy;
                final distance = math.sqrt(dx * dx + dy * dy);

                final outerRadius = size / 2;
                final strokeWidth = outerRadius * 0.38;
                final innerRadius = outerRadius - strokeWidth;

                if (distance >= innerRadius - 6 && distance <= outerRadius + 8) {
                  double angle = math.atan2(dy, dx);
                  // Normalize angle to start at top (12 o'clock, -pi/2)
                  angle += (math.pi / 2);
                  if (angle < 0) angle += 2 * math.pi;

                  final sliceAngleTotal = total > 0 ? total : 1;
                  double cur = 0;
                  int? found;

                  for (int i = 0; i < slices.length; i++) {
                    final sweep = (slices[i].count / sliceAngleTotal) * 2 * math.pi;
                    if (angle >= cur && angle <= (cur + sweep)) {
                      found = i;
                      break;
                    }
                    cur += sweep;
                  }

                  if (_hoveredSliceIndex != found || _hoverPosition != local) {
                    setState(() {
                      _hoveredSliceIndex = found;
                      _hoverPosition = local;
                    });
                  }
                } else {
                  if (_hoveredSliceIndex != null) {
                    setState(() {
                      _hoveredSliceIndex = null;
                      _hoverPosition = null;
                    });
                  }
                }
              },
              onExit: (_) {
                if (_hoveredSliceIndex != null) {
                  setState(() {
                    _hoveredSliceIndex = null;
                    _hoverPosition = null;
                  });
                }
              },
              child: GestureDetector(
                onTapDown: (details) {
                  final local = details.localPosition;
                  final center = Offset(size / 2, size / 2);
                  final dx = local.dx - center.dx;
                  final dy = local.dy - center.dy;
                  double angle = math.atan2(dy, dx) + (math.pi / 2);
                  if (angle < 0) angle += 2 * math.pi;

                  final sliceAngleTotal = total > 0 ? total : 1;
                  double cur = 0;
                  int? found;
                  for (int i = 0; i < slices.length; i++) {
                    final sweep = (slices[i].count / sliceAngleTotal) * 2 * math.pi;
                    if (angle >= cur && angle <= (cur + sweep)) {
                      found = i;
                      break;
                    }
                    cur += sweep;
                  }
                  setState(() {
                    _hoveredSliceIndex = found;
                    _hoverPosition = local;
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Canvas painting the animated doughnut
                    CustomPaint(
                      size: Size(size, size),
                      painter: _DoughnutChartPainter(
                        slices: slices,
                        total: total > 0 ? total : 1,
                        animationProgress: _chartAnimation.value,
                        hoveredIndex: _hoveredSliceIndex,
                      ),
                    ),

                    // Center Content Info
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_hoveredSliceIndex != null && _hoveredSliceIndex! < slices.length) ...[
                          Icon(
                            slices[_hoveredSliceIndex!].icon,
                            size: 18,
                            color: slices[_hoveredSliceIndex!].color,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_toBn(slices[_hoveredSliceIndex!].count)} জন',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: slices[_hoveredSliceIndex!].color,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            '${_toBn(((slices[_hoveredSliceIndex!].count / (total > 0 ? total : 1)) * 100).toStringAsFixed(0))}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: slices[_hoveredSliceIndex!].color.withOpacity(0.9),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'সর্বমোট',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AdminColors.textMuted,
                            ),
                          ),
                          Text(
                            _toBn(total),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AdminColors.textPrimary,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'কৃষক একাউন্ট',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Interactive Tooltip Pop-up Badge
                    if (_hoveredSliceIndex != null &&
                        _hoverPosition != null &&
                        _hoveredSliceIndex! < slices.length) ...[
                      Positioned(
                        left: (_hoverPosition!.dx - 80).clamp(0.0, size - 120),
                        top: (_hoverPosition!.dy - 56).clamp(-10.0, size - 45),
                        child: IgnorePointer(
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF1E293B),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: slices[_hoveredSliceIndex!].color,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    slices[_hoveredSliceIndex!].label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_toBn(slices[_hoveredSliceIndex!].count)} জন (${_toBn(((slices[_hoveredSliceIndex!].count / (total > 0 ? total : 1)) * 100).toStringAsFixed(1))}%)',
                                    style: const TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Modern Legend showing slices with colors, counts, percentages and hover state
  Widget _buildChartLegend(List<_ChartSliceData> slices, int total) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: slices.asMap().entries.map((entry) {
        final idx = entry.key;
        final slice = entry.value;
        final percentage = total > 0 ? ((slice.count / total) * 100).toStringAsFixed(1) : '0.0';
        final isHovered = _hoveredSliceIndex == idx;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredSliceIndex = idx),
          onExit: (_) => setState(() => _hoveredSliceIndex = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: isHovered ? slice.color.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isHovered ? slice.color.withOpacity(0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // Color Dot with Icon
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: slice.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: slice.color.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Slice Name
                Expanded(
                  child: Text(
                    slice.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isHovered ? FontWeight.w800 : FontWeight.w600,
                      color: isHovered ? slice.color : AdminColors.textPrimary,
                    ),
                  ),
                ),

                // Count & Percentage
                Text(
                  '${_toBn(slice.count)} জন',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: slice.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_toBn(percentage)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: slice.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==================== ৫. SUPPORT & COMMUNICATION CARD ====================
  Widget _buildSupportCommunicationCard(BuildContext context) {
    return StreamBuilder<List<AdminSupportTicketModel>>(
      stream: _supportTicketsStream,
      builder: (context, snapshot) {
        final tickets = snapshot.data ?? [];
        final pendingCount = tickets.where((t) => t.status.toLowerCase() == 'pending').length;
        final answeredCount = tickets.where((t) => t.status.toLowerCase() == 'answered').length;

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.border),
            boxShadow: const [
              BoxShadow(
                color: AdminColors.cardShadow,
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          size: 20,
                          color: Color(0xFF00897B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'সাপোর্ট ও যোগাযোগ কেন্দ্র',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          Text(
                            'কৃষকদের সমস্যা ও ইনবক্স রিয়েল-টাইম',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AdminColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Status indicator badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pendingCount > 0
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pendingCount > 0
                            ? const Color(0xFFFFB74D)
                            : const Color(0xFFA5D6A7),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: pendingCount > 0
                                ? const Color(0xFFEF6C00)
                                : const Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          pendingCount > 0 ? 'মনোযোগ প্রয়োজন' : 'সব আপডেট',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: pendingCount > 0
                                ? const Color(0xFFEF6C00)
                                : const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Metrics Row
              Row(
                children: [
                  // Pending
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFECB3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'পেন্ডিং টিকিট',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_toBn(pendingCount)} টি',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Solved / Answered
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'সমাধানকৃত বার্তা',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_toBn(answeredCount)} / ${_toBn(tickets.length)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Action button to navigate directly to Support & Communication page (index 6)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onNavigate(6);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text(
                    'সাপোর্ট ও যোগাযোগ সেন্টারে যান',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== ৬. NEAT TABLE LAYOUT: LIVE NOTIFICATIONS ====================
  Widget _buildLiveNotificationsTableCard() {
    return Container(
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
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, color: Color(0xFFD32F2F), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'সাম্প্রতিক নোটিফিকেশন (রিয়েল-টাইম)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => widget.onNavigate(2),
                  child: const Text('সব দেখুন'),
                ),
              ],
            ),
          ),
          const Divider(color: AdminColors.divider, height: 1),

          // Table Rows
          StreamBuilder<List<AdminNotificationModel>>(
            stream: _notificationsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const AdminLoadingIndicator(
                  message: 'তথ্য লোডিং হচ্ছে.....',
                  padding: 24,
                );
              }

              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('কোনো নোটিফিকেশন পাওয়া যায়নি', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.take(5).length,
                separatorBuilder: (_, __) => const Divider(color: AdminColors.divider, height: 1),
                itemBuilder: (context, index) {
                  final notif = list[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: notif.type == 'alert'
                          ? AdminColors.alertCritical.withOpacity(0.12)
                          : AdminColors.primary.withOpacity(0.12),
                      child: Icon(
                        notif.type == 'alert' ? Icons.warning_rounded : Icons.info_rounded,
                        color: notif.type == 'alert' ? AdminColors.alertCritical : AdminColors.primary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      notif.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      notif.body,
                      style: TextStyle(color: AdminColors.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatDate(notif.createdAt),
                      style: TextStyle(color: AdminColors.textMuted, fontSize: 11),
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

  // ==================== ৬ (বাকি অংশ). NEAT TABLE LAYOUT: LIVE MARKET PRICES ====================
  Widget _buildLiveMarketPricesTableCard() {
    return Container(
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
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.storefront_rounded, color: Color(0xFFF59E0B), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'লাইভ বাজার দর তালিকা (রিয়েল-টাইম)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => widget.onNavigate(3),
                  child: const Text('সব আপডেট'),
                ),
              ],
            ),
          ),
          const Divider(color: AdminColors.divider, height: 1),

          // Table Rows
          StreamBuilder<List<AdminMarketPriceModel>>(
            stream: _marketPricesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const AdminLoadingIndicator(
                  message: 'তথ্য লোডিং হচ্ছে.....',
                  padding: 24,
                );
              }

              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('কোনো বাজার দর তথ্য পাওয়া যায়নি', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.take(5).length,
                separatorBuilder: (_, __) => const Divider(color: AdminColors.divider, height: 1),
                itemBuilder: (context, index) {
                  final item = list[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.shopping_basket_rounded, color: Color(0xFFD97706), size: 18),
                      ),
                    ),
                    title: Text(
                      item.cropName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    subtitle: Text(
                      '${item.marketName} • ${item.district}',
                      style: TextStyle(color: AdminColors.textMuted, fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳${_toBn(item.price.toStringAsFixed(0))}/${item.unit}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B5E20),
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.trend == 'up'
                                  ? Icons.trending_up_rounded
                                  : (item.trend == 'down' ? Icons.trending_down_rounded : Icons.trending_flat_rounded),
                              size: 13,
                              color: item.trend == 'up'
                                  ? AdminColors.alertCritical
                                  : (item.trend == 'down' ? AdminColors.primary : AdminColors.textMuted),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              item.trend == 'up' ? 'উর্ধ্বমুখী' : (item.trend == 'down' ? 'নিম্নমুখী' : 'স্থিতিশীল'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
      return '${_toBn(diff.inMinutes <= 0 ? 1 : diff.inMinutes)} মিনিট আগে';
    } else if (diff.inHours < 24) {
      return '${_toBn(diff.inHours)} ঘণ্টা আগে';
    } else {
      return '${_toBn(dt.day)}/${_toBn(dt.month)}/${_toBn(dt.year)}';
    }
  }
}

/// Custom painter for the animated circular doughnut chart with hover glow and slice gaps
class _DoughnutChartPainter extends CustomPainter {
  final List<_ChartSliceData> slices;
  final int total;
  final double animationProgress;
  final int? hoveredIndex;

  _DoughnutChartPainter({
    required this.slices,
    required this.total,
    required this.animationProgress,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty || total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final minDim = math.min(size.width, size.height);
    final outerRadius = (minDim / 2) - 10;
    final strokeWidth = outerRadius * 0.36;

    double startAngle = -math.pi / 2; // Start from top (12 o'clock)
    final sweepTotal = 2 * math.pi * animationProgress;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweepAngle = (slice.count / total) * sweepTotal;
      if (sweepAngle <= 0.001) continue;

      final isHovered = hoveredIndex == i;
      final currentStroke = isHovered ? strokeWidth + 6 : strokeWidth;
      final currentRadius = isHovered
          ? outerRadius - (strokeWidth / 2) + 2
          : outerRadius - (strokeWidth / 2);

      final rect = Rect.fromCircle(center: center, radius: currentRadius);
      final gap = slices.length > 1 ? 0.035 : 0.0;
      final actualSweep = math.max(0.01, sweepAngle - gap);
      final actualStart = startAngle + (gap / 2);

      // Outer glow when hovered
      if (isHovered) {
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = currentStroke + 8
          ..color = slice.color.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawArc(rect, actualStart, actualSweep, false, glowPaint);
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke
        ..strokeCap = StrokeCap.butt
        ..color = slice.color;

      canvas.drawArc(rect, actualStart, actualSweep, false, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DoughnutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.slices != slices;
  }
}
