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

class _AdminSidebarState extends State<AdminSidebar> {
  late bool _settingsExpanded;

  @override
  void initState() {
    super.initState();
    _settingsExpanded = widget.selectedIndex == 8;
  }

  @override
  void didUpdateWidget(covariant AdminSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex == 8 && !_settingsExpanded) {
      _settingsExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AdminColors.sidebarBg,
      child: Column(
        children: [
          // Brand Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0x22FFFFFF), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x25000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'কৃষি কথা',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'এডমিন কন্ট্রোল প্যানেল',
                        style: TextStyle(
                          color: AdminColors.sidebarTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _buildMenuItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: 'ড্যাশবোর্ড',
                  subtitle: 'ওভারভিউ ও সারাংশ',
                ),
                _buildMenuItem(
                  index: 1,
                  icon: Icons.manage_accounts_rounded,
                  label: 'ইউজার কন্ট্রোল',
                  subtitle: 'ব্যবহারকারী একাউন্ট ও স্ট্যাটাস',
                ),
                _buildMenuItem(
                  index: 2,
                  icon: Icons.notifications_active_rounded,
                  label: 'নোটিফিকেশন কন্ট্রোল',
                  subtitle: 'লাইভ পুশ ও সতর্কতা',
                ),
                _buildMenuItem(
                  index: 3,
                  icon: Icons.storefront_rounded,
                  label: 'বাজার দর আপডেট',
                  subtitle: 'পণ্যের মূল্য ইনপুট ও ট্রেন্ড',
                ),
                _buildMenuItem(
                  index: 4,
                  icon: Icons.eco_rounded,
                  label: 'ফসলের তথ্য',
                  subtitle: 'ফসল ব্যবস্থাপনা (Crops)',
                ),
                _buildMenuItem(
                  index: 5,
                  icon: Icons.bug_report_rounded,
                  label: 'রোগবালাই ও দমন',
                  subtitle: 'বালাই নির্দেশিকা (Pests)',
                ),
                _buildMenuItem(
                  index: 6,
                  icon: Icons.people_alt_rounded,
                  label: 'কৃষক ও সহায়তা',
                  subtitle: 'ব্যবহারকারী ও ফিডব্যাক',
                ),
                _buildMenuItem(
                  index: 7,
                  icon: Icons.smart_toy_rounded,
                  label: 'KrishiMate AI',
                  subtitle: 'এআই প্রেসক্রিপশন ও হিস্ট্রি',
                ),

                const SizedBox(height: 8),

                // Settings Parent Menu Item with Sub-menu
                _buildSettingsParentItem(),
                if (_settingsExpanded) _buildSettingsSubItem(),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x22FFFFFF), width: 1),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AdminColors.primary,
                  child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'এডমিন ইউজার',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'সুপার এডমিনিস্ট্রেটর',
                        style: TextStyle(color: AdminColors.sidebarTextMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onItemSelected(index),
          hoverColor: AdminColors.sidebarHover,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AdminColors.sidebarActive : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AdminColors.sidebarTextMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AdminColors.sidebarText,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isSelected ? const Color(0xDDFFFFFF) : AdminColors.sidebarTextMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
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
    );
  }

  Widget _buildSettingsParentItem() {
    final isSettingsActive = widget.selectedIndex == 8;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _settingsExpanded = !_settingsExpanded;
            });
            if (!isSettingsActive) {
              widget.onItemSelected(8);
            }
          },
          hoverColor: AdminColors.sidebarHover,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSettingsActive && !_settingsExpanded ? AdminColors.sidebarActive : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings_applications_rounded,
                  color: isSettingsActive ? Colors.white : AdminColors.sidebarTextMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'অ্যাপস সেটিংস',
                        style: TextStyle(
                          color: isSettingsActive ? Colors.white : AdminColors.sidebarText,
                          fontSize: 14,
                          fontWeight: isSettingsActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const Text(
                        'কনফিগারেশন ও পলিসি',
                        style: TextStyle(
                          color: AdminColors.sidebarTextMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _settingsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AdminColors.sidebarTextMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSubItem() {
    const isSelected = true; // when expanded under settings, Privacy Policy is the active sub-menu

    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 2, bottom: 4, right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onItemSelected(8),
          hoverColor: AdminColors.sidebarHover,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.selectedIndex == 8 ? AdminColors.sidebarActive : const Color(0x18FFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.selectedIndex == 8 ? const Color(0x44FFFFFF) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.policy_rounded,
                  color: widget.selectedIndex == 8 ? Colors.white : AdminColors.sidebarTextMuted,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'গোপনীয় নীতি',
                        style: TextStyle(
                          color: widget.selectedIndex == 7 ? Colors.white : AdminColors.sidebarText,
                          fontSize: 13.5,
                          fontWeight: widget.selectedIndex == 7 ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const Text(
                        'Privacy Policy এডিটর',
                        style: TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.selectedIndex == 7)
                  Container(
                    width: 4,
                    height: 16,
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
    );
  }
}
