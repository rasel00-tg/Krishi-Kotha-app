import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../providers/auth_provider.dart';
import '../auth/phone_login_screen.dart';
import '../navigation/main_navigation_screen.dart';

/// কৃষি কথা – Krishi Kotha অ্যাপের প্রিমিয়াম কাস্টম স্প্ল্যাশ স্ক্রিন
class SplashScreen extends StatefulWidget {
  final Widget? nextScreen;

  const SplashScreen({
    super.key,
    this.nextScreen,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAppAndNavigate();
  }

  /// ব্যাকগ্রাউন্ড ইনিশিয়ালাইজেশন এবং মিনিমাম ২ সেকেন্ড টাইমার পরিচালনা
  Future<void> _initializeAppAndNavigate() async {
    // ১. ব্যাকগ্রাউন্ড ডিপেন্ডেন্সি চেক ও মিনিমাম ২ সেকেন্ড টাইমার একসাথে চালানো
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      _checkBackgroundDependencies(),
    ]);

    if (!mounted) return;

    // ২. AuthProvider এর ক্যাশড ইউজার লোডিং শেষ হওয়া নিশ্চিত করা
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      while (auth.isLoading && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint('SplashScreen AuthProvider sync notice: $e');
    }

    if (!mounted) return;

    // ৩. ফেড-আউট অ্যানিমেশনের মাধ্যমে নেভিগেশন
    _navigateToNextScreen();
  }

  /// ব্যাকগ্রাউন্ড ডিপেন্ডেন্সি ভেরিফিকেশন (Firebase, SharedPreferences, dotenv)
  Future<void> _checkBackgroundDependencies() async {
    // SharedPreferences ওয়ার্ম-আপ
    try {
      await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('SplashScreen SharedPreferences check: $e');
    }

    // Dotenv ভেরিফিকেশন
    try {
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: ".env");
      }
    } catch (e) {
      debugPrint('SplashScreen Dotenv check: $e');
    }

    // Firebase ভেরিফিকেশন
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint('SplashScreen Firebase check: $e');
    }
  }

  /// মসৃণ ফেড-আউট অ্যানিমেশন (FadeTransition) সহ নেভিগেশন
  void _navigateToNextScreen() {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final Widget destination = widget.nextScreen ??
        (auth.isAuthenticated
            ? const MainNavigationScreen()
            : const PhoneLoginScreen());

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // স্প্ল্যাশ স্ক্রিনে স্ট্যাটাস বার ট্রান্সপারেন্ট রাখা যাতে ফুল স্ক্রিন কাভার করে
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/opening image.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            // সাবফোল্ডার পাথ ফলব্যাক
            return Image.asset(
              'assets/images/opening image/opening image.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, err2, st2) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2E7D32),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
