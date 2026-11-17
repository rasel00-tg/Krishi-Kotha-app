import 'package:flutter/material.dart';
import '../core/constants/admin_colors.dart';
import '../core/responsive/responsive_layout.dart';
import '../core/utils/admin_loading_controller.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_header.dart';
import 'screens/dashboard_screen.dart';
import 'screens/notifications_management_screen.dart';
import 'screens/market_prices_management_screen.dart';
import 'screens/crops_management_screen.dart';
import 'screens/users_feedback_screen.dart';
import 'screens/krishimate_ai_reporting_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/app_settings_screen.dart';
import 'screens/farming_calendar_management_screen.dart';
import 'screens/expert_helpline_management_screen.dart';
import 'screens/admin_income_expense_history_page.dart';
import 'screens/seed_monitoring_screen.dart';
import 'screens/irrigation_monitoring_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<Widget> _screens;

  final List<String> _titles = [
    'ড্যাশবোর্ড ওভারভিউ',
    'ইউজার কন্ট্রোল (User Management System)',
    'লাইভ নোটিফিকেশন ম্যানেজমেন্ট',
    'বাজার দর ইনপুট ও আপডেট',
    'ফসলের তথ্য ব্যবস্থাপনা (Crops Management)',
    'রোগবালাই ও দমন গাইড (Pests & Diseases)',
    'সাপোর্ট ও যোগাযোগ ব্যবস্থাপনা (Support & Contact)',
    'KrishiMate AI রোগ শনাক্তকরণ ড্যাশবোর্ড',
    'অ্যাপস সেটিংস – গোপনীয় নীতি (Privacy Policy)',
    'হোমপেজ – ফসল ক্যালেন্ডার মনিটরিং',
    'হোমপেজ – কৃষি বিশেষজ্ঞ (Coming Soon)',
    'হোমপেজ – কৃষি আয়-ব্যায় হিস্ট্রি কন্ট্রোল',
    'হোমপেজ – বীজের তথ্য মনিটরিং',
    'হোমপেজ – সেচ ট্র্যাকার মনিটরিং',
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onNavigate: _onNavigate),
      const UserManagementScreen(),
      const NotificationsManagementScreen(),
      const MarketPricesManagementScreen(),
      const CropsManagementScreen(initialTabIndex: 0),
      const CropsManagementScreen(initialTabIndex: 1),
      const UsersFeedbackScreen(),
      const KrishiMateAiReportingScreen(),
      const AppSettingsScreen(),
      const FarmingCalendarManagementScreen(),
      const ExpertHelplineManagementScreen(),
      const AdminIncomeExpenseHistoryPage(),
      const SeedMonitoringScreen(),
      const IrrigationMonitoringScreen(),
    ];
  }

  void _onNavigate(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
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
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
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
