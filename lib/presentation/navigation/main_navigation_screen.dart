import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/services/firestore_service.dart';
import '../home/home_screen.dart';
import '../crops/crop_list_screen.dart';
import '../market/market_price_screen.dart';
import '../calculator/fertilizer_calculator_screen.dart';
import '../community/community_feed_screen.dart';
import '../menu/app_menu_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // রুট লেভেল সেফটি গার্ডিয়ান: অ্যাপ ওপেন বা রুট ভিউ লোড হওয়ার সময় আটকে থাকা
    // কোনো অনাথ (orphaned) ModalBarrier বা লোডিং ডায়ালগ অবিলম্বে ফ্লাশ করা
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final nav = Navigator.of(context, rootNavigator: true);
        while (nav.canPop()) {
          nav.pop();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _firestoreService.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    // ট্যাব সুইচের সময় কোনো ঝুলন্ত মোডাল বা ডায়ালগ থাকলে তা নিরাপদভাবে ডিসমিস করা
    try {
      final nav = Navigator.of(context, rootNavigator: true);
      while (nav.canPop()) {
        nav.pop();
      }
    } catch (_) {}

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onNavigateTab: _onTabSelected,
        firestoreService: _firestoreService,
      ),
      CropListScreen(onNavigateTab: _onTabSelected),
      const MarketPriceScreen(),
      const FertilizerCalculatorScreen(),
      const AppMenuScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildAnimatedGradientNavBar(),
    );
  }

  Widget _buildAnimatedGradientNavBar() {
    final navItems = [
      _NavMenuConfig(
        label: AppStrings.navHome,
        unselectedIcon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        gradient: const [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        glowColor: const Color(0x662E7D32),
      ),
      _NavMenuConfig(
        label: AppStrings.navCrops,
        unselectedIcon: Icons.eco_outlined,
        selectedIcon: Icons.eco_rounded,
        gradient: const [Color(0xFF00A86B), Color(0xFF00695C)],
        glowColor: const Color(0x6600A86B),
      ),
      _NavMenuConfig(
        label: AppStrings.navMarket,
        unselectedIcon: Icons.storefront_outlined,
        selectedIcon: Icons.storefront_rounded,
        gradient: const [Color(0xFFFF9800), Color(0xFFE65100)],
        glowColor: const Color(0x66FF9800),
      ),
      _NavMenuConfig(
        label: AppStrings.navCalculator,
        unselectedIcon: Icons.calculate_outlined,
        selectedIcon: Icons.calculate_rounded,
        gradient: const [Color(0xFF0288D1), Color(0xFF01579B)],
        glowColor: const Color(0x660288D1),
      ),
      _NavMenuConfig(
        label: AppStrings.navMenu,
        unselectedIcon: Icons.grid_view_outlined,
        selectedIcon: Icons.grid_view_rounded,
        gradient: const [Color(0xFF8E24AA), Color(0xFF4A148C)],
        glowColor: const Color(0x668E24AA),
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).padding.bottom > 0
              ? MediaQuery.of(context).padding.bottom + 4
              : 12,
          top: 6,
        ),
        child: Container(
          height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(navItems.length, (index) {
            final item = navItems[index];
            final isSelected = _currentIndex == index;

            return Expanded(
              child: GestureDetector(
                onTap: () => _onTabSelected(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 64,
                  alignment: Alignment.center,
                  color: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    padding: isSelected
                        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
                        : const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: item.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFFF1F5F2),
                      borderRadius: BorderRadius.circular(isSelected ? 24 : 50),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: item.glowColor,
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                                spreadRadius: 1,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.selectedIcon : item.unselectedIcon,
                          size: 20,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                        AnimatedCrossFade(
                          firstChild: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              item.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          secondChild: const SizedBox.shrink(),
                          crossFadeState: isSelected
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 250),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavMenuConfig {
  final String label;
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final List<Color> gradient;
  final Color glowColor;

  const _NavMenuConfig({
    required this.label,
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.gradient,
    required this.glowColor,
  });
}
