import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_theme.dart';
import 'data/services/firebase_service.dart';
import 'data/services/firestore_service.dart';
import 'providers/auth_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/crop_provider.dart';
import 'providers/market_price_provider.dart';
import 'providers/community_provider.dart';
import 'providers/fertilizer_calculator_provider.dart';
import 'providers/support_provider.dart';
import 'core/widgets/responsive_web_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'presentation/auth/phone_login_screen.dart';
import 'presentation/navigation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Multi-platform Firebase initialization with DefaultFirebaseOptions
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseService.isFirebaseInitialized = true;

    // Web Persistence fix: disable persistence on Web to prevent stream hangs
    try {
      if (kIsWeb) {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: false,
        );
      }
    } catch (_) {}
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Shared singleton firestore service instance
  final firestoreService = FirestoreService();

  runApp(KrishiKothaApp(firestoreService: firestoreService));
}

class KrishiKothaApp extends StatelessWidget {
  final FirestoreService firestoreService;
  const KrishiKothaApp({super.key, required this.firestoreService});

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<WeatherProvider>(
          create: (_) => WeatherProvider(),
        ),
        ChangeNotifierProvider<CropProvider>(
          create: (_) => CropProvider(firestoreService),
        ),
        ChangeNotifierProvider<MarketPriceProvider>(
          create: (_) => MarketPriceProvider(firestoreService),
        ),
        ChangeNotifierProvider<CommunityProvider>(
          create: (_) => CommunityProvider(firestoreService),
        ),
        ChangeNotifierProvider<FertilizerCalculatorProvider>(
          create: (_) => FertilizerCalculatorProvider(),
        ),
        Provider<FirestoreService>.value(
          value: firestoreService,
        ),
        ChangeNotifierProvider<SupportProvider>(
          create: (_) => SupportProvider(firestoreService),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        scrollBehavior: const AppScrollBehavior(),
        builder: (context, child) => ResponsiveWebWrapper(
          child: child ?? const SizedBox.shrink(),
        ),
        home: const AppRootGate(),
      ),
    );
  }
}

class AppRootGate extends StatelessWidget {
  const AppRootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If authenticated or guest, open main screen; otherwise show phone login
        if (auth.isAuthenticated) {
          return const MainNavigationScreen();
        }

        return const PhoneLoginScreen();
      },
    );
  }
}
