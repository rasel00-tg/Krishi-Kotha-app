import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';

class AdminSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> with TickerProviderStateMixin {
  late bool _settingsExpanded;
  late bool _homepageExpanded;

  late AnimationController _homepageAnimController;
  late Animation<double> _homepageAnim;

  late AnimationController _settingsAnimController;
  late Animation<double> _settingsAnim;

  @override
  void initState() {
    super.initState();
    _settingsExpanded = widget.selectedIndex == 8;
    _homepageExpanded = widget.selectedIndex == 9 ||
        widget.selectedIndex == 10 ||
        widget.selectedIndex == 11 ||
        widget.selectedIndex == 12;

    _homepageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: _homepageExpanded ? 1.0 : 0.0,
    );
    _homepageAnim = CurvedAnimation(
      parent: _homepageAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _settingsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: _settingsExpanded ? 1.0 : 0.0,
    );
    _settingsAnim = CurvedAnimation(
      parent: _settingsAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(covariant AdminSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex == 8 && !_settingsExpanded) {
      _settingsExpanded = true;
      _settingsAnimController.forward();
    }
    if ((widget.selectedIndex == 9 ||
            widget.selectedIndex == 10 ||
            widget.selectedIndex == 11 ||
            widget.selectedIndex == 12) &&
        !_homepageExpanded) {
      _homepageExpanded = true;
      _homepageAnimController.forward();
    }
  }

  @override
  void dispose() {
    _homepageAnimController.dispose();
    _settingsAnimController.dispose();
    super.dispose();
  }

  void _toggleHomepage() {
    setState(() {
      _homepageExpanded = !_homepageExpanded;
      if (_homepageExpanded) {
        _homepageAnimController.forward();
      } else {
        _homepageAnimController.reverse();
      }
    });
    final isHomepageActive = widget.selectedIndex == 9 ||
        widget.selectedIndex == 10 ||
        widget.selectedIndex == 11 ||
        widget.selectedIndex == 12;
    if (!isHomepageActive) {
      widget.onItemSelected(9);
    }
  }

  void _toggleSettings() {
    setState(() {
      _settingsExpanded = !_settingsExpanded;
      if (_settingsExpanded) {
        _settingsAnimController.forward();
      } else {
        _settingsAnimController.reverse();
      }
    });
    if (widget.selectedIndex != 8) {
      widget.onItemSelected(8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHomepageActive = widget.selectedIndex == 9 ||
        widget.selectedIndex == 10 ||
        widget.selectedIndex == 11 ||
        widget.selectedIndex == 12;
    final isSettingsActive = widget.selectedIndex == 8;

    return Container(
      width: 264,
      color: AdminColors.sidebarBg,
      child: Column(
        children: [
          // Brand Header with Modern Glass/Shadow Accent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              border: const Border(
                bottom: BorderSide(color: Color(0x18FFFFFF), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: AdminColors.primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/icons/pnglogo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AdminColors.primary,
                      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'কৃষি কথা',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'এডমিন কন্ট্রোল প্যানেল',
                            style: TextStyle(
                              color: AdminColors.sidebarTextMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              children: [
                // 0. ড্যাশবোর্ড
                _SidebarMenuItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  iconColor: const Color(0xFF4CAF50), // Emerald Green
                  label: 'ড্যাশবোর্ড',
                  subtitle: 'ওভারভিউ ও সারাংশ',
                  isSelected: widget.selectedIndex == 0,
                  onTap: () => widget.onItemSelected(0),
                ),

                const SizedBox(height: 3),

                // Homepage Parent Menu Item (with Animated Sub-menu)
                _SidebarParentMenuItem(
                  icon: Icons.home_work_rounded,
                  iconColor: const Color(0xFF2E7D32), // Forest Green
                  label: 'হোমপেজ',
                  subtitle: 'হোমপেজ ফিচার কন্ট্রোল',
                  isParentActive: isHomepageActive,
                  isExpanded: _homepageExpanded,
                  animation: _homepageAnim,
                  onTap: _toggleHomepage,
                ),

                // ২. Sub-menu Animated Expansion
                SizeTransition(
                  sizeFactor: _homepageAnim,
                  axisAlignment: -1.0,
                  child: FadeTransition(
                    opacity: _homepageAnim,
                    child: Container(
                      margin: const EdgeInsets.only(left: 14, top: 2, bottom: 4),
                      padding: const EdgeInsets.only(left: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Color(0x334CAF50),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          _SidebarSubMenuItem(
                            index: 9,
                            icon: Icons.calendar_month_rounded,
                            iconColor: const Color(0xFF26A69A), // Teal
                            label: 'চাষ ক্যালেন্ডার মনিটরিং',
                            subtitle: '১২ মাসের চাষাবাদ গাইডলাইন',
                            isSelected: widget.selectedIndex == 9,
                            onTap: () => widget.onItemSelected(9),
                          ),
                          _SidebarSubMenuItem(
                            index: 10,
                            icon: Icons.support_agent_rounded,
                            iconColor: const Color(0xFF42A5F5), // Sky Blue
                            label: 'কৃষি বিশেষজ্ঞ',
                            subtitle: 'বিশেষজ্ঞ পরামর্শ সহায়তা',
                            isSelected: widget.selectedIndex == 10,
                            onTap: () => widget.onItemSelected(10),
                          ),
                          _SidebarSubMenuItem(
                            index: 11,
                            icon: Icons.receipt_long_rounded,
                            iconColor: const Color(0xFFFFA726), // Amber
                            label: 'কৃষি আয়-ব্যায় হিস্ট্রি কন্ট্রোল',
                            subtitle: 'আয়-ব্যয় ও ডিলিট হিস্ট্রি',
                            isSelected: widget.selectedIndex == 11,
                            onTap: () => widget.onItemSelected(11),
                          ),
                          _SidebarSubMenuItem(
                            index: 12,
                            icon: Icons.spa_rounded,
                            iconColor: const Color(0xFF66BB6A), // Sprout Green
                            label: 'বীজের তথ্য মনিটরিং',
                            subtitle: 'বীজের জাত ও রোপণ গাইডলাইন',
                            isSelected: widget.selectedIndex == 12,
                            onTap: () => widget.onItemSelected(12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 3),

                // 1. ইউজার কন্ট্রোল
                _SidebarMenuItem(
                  index: 1,
                  icon: Icons.manage_accounts_rounded,
                  iconColor: const Color(0xFF42A5F5), // Ocean Blue
                  label: 'ইউজার কন্ট্রোল',
                  subtitle: 'ব্যবহারকারী একাউন্ট ও স্ট্যাটাস',
                  isSelected: widget.selectedIndex == 1,
                  onTap: () => widget.onItemSelected(1),
                ),

                // 2. নোটিফিকেশন কন্ট্রোল
                _SidebarMenuItem(
                  index: 2,
                  icon: Icons.notifications_active_rounded,
                  iconColor: const Color(0xFFFF7043), // Warm Orange
                  label: 'নোটিফিকেশন কন্ট্রোল',
                  subtitle: 'লাইভ পুশ ও সতর্কতা',
                  isSelected: widget.selectedIndex == 2,
                  onTap: () => widget.onItemSelected(2),
                ),

                // 3. বাজার দর আপডেট
                _SidebarMenuItem(
                  index: 3,
                  icon: Icons.storefront_rounded,
                  iconColor: const Color(0xFFFFA726), // Harvest Gold
                  label: 'বাজার দর আপডেট',
                  subtitle: 'পণ্যের মূল্য ইনপুট ও ট্রেন্ড',
                  isSelected: widget.selectedIndex == 3,
                  onTap: () => widget.onItemSelected(3),
                ),

                // 4. ফসলের তথ্য
                _SidebarMenuItem(
                  index: 4,
                  icon: Icons.eco_rounded,
                  iconColor: const Color(0xFF66BB6A), // Agri Green
                  label: 'ফসলের তথ্য',
                  subtitle: 'ফসল ব্যবস্থাপনা (Crops)',
                  isSelected: widget.selectedIndex == 4,
                  onTap: () => widget.onItemSelected(4),
                ),

                // 5. রোগবালাই ও দমন
                _SidebarMenuItem(
                  index: 5,
                  icon: Icons.bug_report_rounded,
                  iconColor: const Color(0xFFEF5350), // Alert Rose Red
                  label: 'রোগবালাই ও দমন',
                  subtitle: 'বালাই নির্দেশিকা (Pests)',
                  isSelected: widget.selectedIndex == 5,
                  onTap: () => widget.onItemSelected(5),
                ),

                // 6. সাপোর্ট ও যোগাযোগ
                _SidebarMenuItem(
                  index: 6,
                  icon: Icons.headset_mic_rounded,
                  iconColor: const Color(0xFFAB47BC), // Vibrant Violet
                  label: 'সাপোর্ট ও যোগাযোগ',
                  subtitle: 'কন্টাক্ট সেটিংস ও টিকিট',
                  isSelected: widget.selectedIndex == 6,
                  onTap: () => widget.onItemSelected(6),
                ),

                // 7. KrishiMate AI
                _SidebarMenuItem(
                  index: 7,
                  icon: Icons.smart_toy_rounded,
                  iconColor: const Color(0xFF26C6DA), // Cyan / Tech Teal
                  label: 'KrishiMate AI',
                  subtitle: 'এআই প্রেসক্রিপশন ও হিস্ট্রি',
                  isSelected: widget.selectedIndex == 7,
                  onTap: () => widget.onItemSelected(7),
                ),

                const SizedBox(height: 6),

                // Settings Parent Menu Item (with Animated Sub-menu)
                _SidebarParentMenuItem(
                  icon: Icons.settings_applications_rounded,
                  iconColor: const Color(0xFF7E57C2), // Slate Purple
                  label: 'অ্যাপস সেটিংস',
                  subtitle: 'কনফিগারেশন ও পলিসি',
                  isParentActive: isSettingsActive,
                  isExpanded: _settingsExpanded,
                  animation: _settingsAnim,
                  onTap: _toggleSettings,
                ),

                // Settings Sub-menu Animated Expansion
                SizeTransition(
                  sizeFactor: _settingsAnim,
                  axisAlignment: -1.0,
                  child: FadeTransition(
                    opacity: _settingsAnim,
                    child: Container(
                      margin: const EdgeInsets.only(left: 14, top: 2, bottom: 4),
                      padding: const EdgeInsets.only(left: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Color(0x337E57C2),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          _SidebarSubMenuItem(
                            index: 8,
                            icon: Icons.policy_rounded,
                            iconColor: const Color(0xFF29B6F6), // Light Blue
                            label: 'গোপনীয় নীতি',
                            subtitle: 'Privacy Policy এডিটর',
                            isSelected: widget.selectedIndex == 8,
                            onTap: () => widget.onItemSelected(8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer Profile with Glass Card Finish
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              border: const Border(
                top: BorderSide(color: Color(0x18FFFFFF), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'এডমিন অফিসার',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'সুপার এডমিনিস্ট্রেটর',
                        style: TextStyle(
                          color: AdminColors.sidebarTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ১. Icon Coloring & Active State & ৩. Modern Hover/Tap Effects for Standard Menu Items
class _SidebarMenuItem extends StatefulWidget {
  final int index;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.index,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered && !isSelected ? 1.018 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              splashColor: widget.iconColor.withOpacity(0.18),
              highlightColor: widget.iconColor.withOpacity(0.08),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : _isHovered
                          ? AdminColors.sidebarHover
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0x55FFFFFF)
                        : _isHovered
                            ? widget.iconColor.withOpacity(0.28)
                            : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.42),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : _isHovered
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                ),
                child: Row(
                  children: [
                    // ১. Colorful Icon Badge
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.22)
                            : _isHovered
                                ? widget.iconColor.withOpacity(0.24)
                                : widget.iconColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        widget.icon,
                        color: isSelected ? Colors.white : widget.iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AdminColors.sidebarText,
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xDDFFFFFF)
                                  : AdminColors.sidebarTextMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Active Right Indicator Pill
                    if (isSelected)
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Parent Menu Item with Smooth Rotating Arrow and Active/Hover Styling
class _SidebarParentMenuItem extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool isParentActive;
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _SidebarParentMenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.isParentActive,
    required this.isExpanded,
    required this.animation,
    required this.onTap,
  });

  @override
  State<_SidebarParentMenuItem> createState() => _SidebarParentMenuItemState();
}

class _SidebarParentMenuItemState extends State<_SidebarParentMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isParentActive = widget.isParentActive;
    final isExpanded = widget.isExpanded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered && !(isParentActive && !isExpanded) ? 1.018 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              splashColor: widget.iconColor.withOpacity(0.18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isParentActive && !isExpanded
                      ? const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isParentActive && !isExpanded
                      ? null
                      : isExpanded
                          ? const Color(0x1AFFFFFF)
                          : _isHovered
                              ? AdminColors.sidebarHover
                              : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isParentActive && !isExpanded
                        ? const Color(0x55FFFFFF)
                        : isExpanded
                            ? widget.iconColor.withOpacity(0.35)
                            : _isHovered
                                ? widget.iconColor.withOpacity(0.25)
                                : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: isParentActive && !isExpanded
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.42),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isParentActive && !isExpanded
                            ? Colors.white.withOpacity(0.22)
                            : widget.iconColor.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        color: isParentActive && !isExpanded ? Colors.white : widget.iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: isParentActive ? Colors.white : AdminColors.sidebarText,
                              fontSize: 13.5,
                              fontWeight: isParentActive ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: isParentActive && !isExpanded
                                  ? const Color(0xDDFFFFFF)
                                  : AdminColors.sidebarTextMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ২. Animated Rotating Caret
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(widget.animation),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AdminColors.sidebarTextMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sub-menu Item with Tree Indicator Dot, Scale Animation & Vibrant Icons
class _SidebarSubMenuItem extends StatefulWidget {
  final int index;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarSubMenuItem({
    required this.index,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarSubMenuItem> createState() => _SidebarSubMenuItemState();
}

class _SidebarSubMenuItemState extends State<_SidebarSubMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 3, right: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered && !isSelected ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: widget.onTap,
              splashColor: widget.iconColor.withOpacity(0.18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : _isHovered
                          ? AdminColors.sidebarHover
                          : const Color(0x12FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0x55FFFFFF)
                        : _isHovered
                            ? widget.iconColor.withOpacity(0.35)
                            : const Color(0x10FFFFFF),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Tree Branch Dot Indicator
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : widget.iconColor,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 4,
                                )
                              ]
                            : null,
                      ),
                    ),
                    Icon(
                      widget.icon,
                      color: isSelected ? Colors.white : widget.iconColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AdminColors.sidebarText,
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: isSelected ? const Color(0xCCFFFFFF) : AdminColors.sidebarTextMuted,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 3.5,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

