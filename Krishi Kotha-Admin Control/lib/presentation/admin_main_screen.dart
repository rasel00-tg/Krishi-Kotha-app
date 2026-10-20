import 'package:flutter/material.dart';
import '../core/constants/admin_colors.dart';
import '../core/responsive/responsive_layout.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_header.dart';
import 'screens/dashboard_screen.dart';
import 'screens/notifications_management_screen.dart';
import 'screens/market_prices_management_screen.dart';
import 'screens/crops_management_screen.dart';
import 'screens/users_feedback_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'ড্যাশবোর্ড ওভারভিউ',
    'লাইভ নোটিফিকেশন ম্যানেজমেন্ট',
    'বাজার দর ইনপুট ও আপডেট',
    'ফসলের তথ্য ব্যবস্থাপনা (Crops Management)',
    'রোগবালাই ও দমন গাইড (Pests & Diseases)',
    'কৃষক ও সহায়তা টিকিট মনিটরিং',
  ];

  void _onNavigate(int index) {
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(onNavigate: _onNavigate);
      case 1:
        return const NotificationsManagementScreen();
      case 2:
        return const MarketPricesManagementScreen();
      case 3:
        return const CropsManagementScreen(initialTabIndex: 0);
      case 4:
        return const CropsManagementScreen(initialTabIndex: 1);
      case 5:
        return const UsersFeedbackScreen();
      default:
        return DashboardScreen(onNavigate: _onNavigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminColors.background,
      drawer: isMobile
          ? Drawer(
              child: AdminSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: _onNavigate,
              ),
            )
          : null,
      body: Row(
        children: [
          // Desktop & Tablet Sidebar
          if (!isMobile)
            AdminSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onNavigate,
            ),

          // Main View Body
          Expanded(
            child: Column(
              children: [
                AdminHeader(
                  title: _titles[_selectedIndex],
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: _getCurrentScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
