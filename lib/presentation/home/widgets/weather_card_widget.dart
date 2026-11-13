import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/bangla_number_converter.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../data/services/firebase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../../data/models/weather_info_model.dart';

class WeatherCardWidget extends StatefulWidget {
  const WeatherCardWidget({super.key});

  @override
  State<WeatherCardWidget> createState() => _WeatherCardWidgetState();
}

class _WeatherCardWidgetState extends State<WeatherCardWidget> {
  String? _lastSyncedDistrict;
  String? _activeUid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initRealtimeDistrictListener();
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    super.dispose();
  }

  void _initRealtimeDistrictListener() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final uid = user?.uid;

      // ১. ইনিশিয়াল প্রোফাইল জেলা চেক ও বাইন্ডিং
      final profileDistrict = user?.district?.trim().replaceAll(' জেলা', '');
      if (profileDistrict != null &&
          profileDistrict.isNotEmpty &&
          _lastSyncedDistrict == null) {
        _lastSyncedDistrict = profileDistrict;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Provider.of<WeatherProvider>(context, listen: false)
                .setInitialDistrict(profileDistrict);
          }
        });
      }

      // ২. ফায়ারস্টোরে বর্তমান ইউজারের (currentUser) ডকুমেন্টে রিয়েল-টাইম লিসেনার
      if (uid != null &&
          uid.isNotEmpty &&
          !uid.startsWith('guest_') &&
          FirebaseService.isFirebaseInitialized &&
          _activeUid != uid) {
        _activeUid = uid;
        _userDocSubscription?.cancel();
        _userDocSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots()
            .listen(
          (snapshot) {
            try {
              if (snapshot.exists && snapshot.data() != null) {
                final data = snapshot.data()!;
                final firestoreDistrict =
                    (data['district'] as String?)?.trim().replaceAll(' জেলা', '');
                if (firestoreDistrict != null &&
                    firestoreDistrict.isNotEmpty &&
                    _lastSyncedDistrict != firestoreDistrict) {
                  _lastSyncedDistrict = firestoreDistrict;
                  // জেলা পরিবর্তন হয়েছে! ২ ঘণ্টার ক্যাশ ও ১০ মিনিট থ্রটলিং বাইপাস করে সাথে সাথে ফোর্স API কল
                  if (mounted) {
                    Provider.of<WeatherProvider>(context, listen: false)
                        .onProfileDistrictChanged(firestoreDistrict);
                  }
                }
              }
            } catch (snapErr) {
              debugPrint('User district snapshot processing error: $snapErr');
            }
          },
          onError: (err) {
            debugPrint('User district listener error: $err');
          },
        );
      }
    } catch (e) {
      debugPrint('Real-time district listener init notice: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUid = authProvider.user?.uid;

    // যদি ইউজার লগইন স্টেট বা ইউআইডি পরিবর্তন হয়, রিয়েল-টাইম লিসেনার সক্রিয় করা
    if (currentUid != _activeUid) {
      _initRealtimeDistrictListener();
    }

    // লোকাল ফলব্যাক সিঙ্ক (গেস্ট বা ক্যাশড প্রোফাইলের ক্ষেত্রে)
    final localDistrict = authProvider.user?.district?.trim().replaceAll(' জেলা', '');
    if (localDistrict != null &&
        localDistrict.isNotEmpty &&
        _lastSyncedDistrict != null &&
        _lastSyncedDistrict != localDistrict) {
      _lastSyncedDistrict = localDistrict;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          weatherProvider.onProfileDistrictChanged(localDistrict);
        }
      });
    }

    if (weatherProvider.isLoading && weatherProvider.weatherInfo == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 195,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerCardLoader(height: 24, width: 85, borderRadius: 12),
                        SizedBox(height: 8),
                        ShimmerCardLoader(height: 40, width: 75, borderRadius: 8),
                        SizedBox(height: 8),
                        ShimmerCardLoader(height: 16, width: 95, borderRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 140),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        ShimmerCardLoader(height: 24, width: 75, borderRadius: 12),
                        SizedBox(height: 8),
                        ShimmerCardLoader(height: 24, width: 75, borderRadius: 12),
                        SizedBox(height: 8),
                        ShimmerCardLoader(height: 24, width: 85, borderRadius: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const ShimmerCardLoader(height: 64, borderRadius: 16),
          ],
        ),
      );
    }

    final weather = weatherProvider.weatherInfo;
    if (weather == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ১. অ্যানিমেশন + দুপাশে ওয়েদার ডেটা (Stack Layout)
          SizedBox(
            height: 195,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // সেন্টারে Lottie অ্যানিমেশন
                SizedBox(
                  width: 175,
                  height: 175,
                  child: Lottie.asset(
                    'assets/animation/home animation.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),

                // সময়-ভিত্তিক ডাইনামিক গ্রিটিং (Time-based Dynamic Greeting)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildDynamicGreetingBadge(),
                  ),
                ),

                // বাম পাশে: বর্তমান তাপমাত্রা (Degree), লোকেশন ও অবস্থা
                Positioned(
                  left: 0,
                  top: 25,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // লোকেশন চিপ ও রিফ্রেশ বাটন
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ইউজার প্রোফাইল জেলা লোকেশন চিপ (ড্রপডাউন আইকনহীন, প্রোফাইল অটো-বাইন্ডিং)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  weather.district,
                                  style: const TextStyle(
                                    color: Color(0xFF1B5E20),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (weatherProvider.isLoading) ...[
                                  const SizedBox(width: 4),
                                  const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),

                          // ম্যানুয়াল রিফ্রেশ বাটন (১০ মিনিট থ্রটলিং প্রটেকশন ও লোগো ডায়ালগ সহ)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: weatherProvider.isLoading
                                  ? null
                                  : () => weatherProvider.manualRefresh(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F8E9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
                                ),
                                child: weatherProvider.isLoading
                                    ? const SizedBox(
                                        width: 13,
                                        height: 13,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh_rounded,
                                        color: AppColors.primary,
                                        size: 13,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // বর্তমান তাপমাত্রা (Degree)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            BanglaNumberConverter.toBangla(weather.currentTemp.toStringAsFixed(0)),
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              height: 1.0,
                              letterSpacing: -1,
                            ),
                          ),
                          const Text(
                            '°C',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // আবহাওয়ার অবস্থা
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getWeatherIcon(weather.conditionBn),
                            color: const Color(0xFFF59E0B),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            weather.conditionBn,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ডান পাশে: আর্দ্রতা, বৃষ্টির সম্ভাবনা ও অন্যান্য মেট্রিক্স
                Positioned(
                  right: 0,
                  top: 25,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // আর্দ্রতা
                      _buildOverlayMetricPill(
                        icon: Icons.opacity_rounded,
                        iconColor: const Color(0xFF0288D1),
                        label: 'আর্দ্রতা',
                        value: '${BanglaNumberConverter.toBangla(weather.humidity)}%',
                      ),
                      const SizedBox(height: 6),

                      // বৃষ্টির সম্ভাবনা
                      _buildOverlayMetricPill(
                        icon: Icons.water_drop_outlined,
                        iconColor: const Color(0xFF00897B),
                        label: 'বৃষ্টি',
                        value: '${BanglaNumberConverter.toBangla(weather.rainProbability)}%',
                      ),
                      const SizedBox(height: 6),

                      // বাতাস
                      _buildOverlayMetricPill(
                        icon: Icons.air_rounded,
                        iconColor: const Color(0xFF5C6BC0),
                        label: 'বাতাস',
                        value: '${BanglaNumberConverter.toBangla(weather.windSpeedKmH.toStringAsFixed(0))} কিমি/ঘ',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ২. কম্প্যাক্ট ৫-দিনের পূর্বাভাস (Compact 5-Day Forecast with soft dividers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(weather.fiveDayForecast.length, (index) {
                final f = weather.fiveDayForecast[index];
                final isLast = index == weather.fiveDayForecast.length - 1;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                f.dayNameBn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              if (f.dateBn.isNotEmpty)
                                Text(
                                  f.dateBn,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Icon(
                                _getWeatherIcon(f.conditionBn),
                                color: const Color(0xFFF59E0B),
                                size: 15,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${BanglaNumberConverter.toBangla(f.tempMax.toStringAsFixed(0))}° / ${BanglaNumberConverter.toBangla(f.tempMin.toStringAsFixed(0))}°',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'বৃষ্টি ${BanglaNumberConverter.toBangla(f.rainProbability)}%',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 1,
                          height: 48,
                          color: const Color(0xFFE2E8F0),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// ভাসমান ওভারলে মেট্রিক পিল
  Widget _buildOverlayMetricPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 12),
          const SizedBox(width: 4),
          Text(
            '$label ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('rain') || lower.contains('বৃষ্টি')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('cloud') || lower.contains('মেঘলা')) {
      return Icons.cloud_rounded;
    }
    if (lower.contains('thunder') || lower.contains('ঝড়') || lower.contains('তুফান')) {
      return Icons.thunderstorm_rounded;
    }
    return Icons.wb_sunny_rounded;
  }

  /// সময়-ভিত্তিক ডাইনামিক গ্রিটিং ব্যাজ উইজেট
  Widget _buildDynamicGreetingBadge() {
    final hour = DateTime.now().hour;
    final greeting = _getDynamicGreeting(hour);
    final icon = _getGreetingIcon(hour);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFC8E6C9),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 4.5),
          Text(
            greeting,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
              letterSpacing: 0.2,
              shadows: [
                Shadow(
                  color: Colors.white,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// সময় অনুযায়ী ডাইনামিক গ্রিটিং টেক্সট নির্বাচন
  String _getDynamicGreeting(int hour) {
    if (hour >= 6 && hour < 12) {
      return 'শুভ সকাল';
    } else if (hour >= 12 && hour < 16) {
      return 'শুভ অপরাহ্ণ';
    } else if (hour >= 16 && hour < 18) {
      return 'শুভ বিকেল';
    } else if (hour >= 18 && hour < 20) {
      return 'শুভ সন্ধ্যা';
    } else {
      return 'শুভ রাত্রি';
    }
  }

  /// গ্রিটিং আইকন নির্বাচন
  IconData _getGreetingIcon(int hour) {
    if (hour >= 6 && hour < 12) {
      return Icons.wb_sunny_rounded;
    } else if (hour >= 12 && hour < 16) {
      return Icons.light_mode_rounded;
    } else if (hour >= 16 && hour < 18) {
      return Icons.wb_twilight_rounded;
    } else if (hour >= 18 && hour < 20) {
      return Icons.nights_stay_rounded;
    } else {
      return Icons.bedtime_rounded;
    }
  }
}
