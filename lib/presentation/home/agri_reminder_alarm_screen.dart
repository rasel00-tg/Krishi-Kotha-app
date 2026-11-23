import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class AgriReminderAlarmScreen extends StatefulWidget {
  final Map<String, dynamic> reminderData;

  const AgriReminderAlarmScreen({
    super.key,
    required this.reminderData,
  });

  @override
  State<AgriReminderAlarmScreen> createState() =>
      _AgriReminderAlarmScreenState();
}

class _AgriReminderAlarmScreenState extends State<AgriReminderAlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  AudioPlayer? _audioPlayer;
  Timer? _clockTimer;
  Timer? _vibrateTimer;
  String _currentTimeStr = '';

  @override
  void initState() {
    super.initState();

    // 1. Animated pulse rings for app logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. Realtime clock updater
    _updateCurrentTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCurrentTime();
    });

    // 3. Start audio playback and vibration
    _initAudioAndVibration();
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _currentTimeStr = DateFormat('hh:mm a').format(now);
    });
  }

  Future<void> _initAudioAndVibration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localAudioPath = prefs.getString('agri_ringtone_local_path') ?? '';
      final ringtoneUrl = prefs.getString('agri_ringtone_url') ?? '';
      final volume = prefs.getDouble('agri_ringtone_volume') ?? 0.85;

      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setVolume(volume.clamp(0.0, 1.0));
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);

      bool playbackStarted = false;

      // 1. Priority: Local cached offline file
      if (localAudioPath.isNotEmpty) {
        final localFile = File(localAudioPath);
        if (await localFile.exists()) {
          try {
            await _audioPlayer!.play(DeviceFileSource(localAudioPath));
            playbackStarted = true;
            debugPrint('Playing local cached reminder ringtone: $localAudioPath');
          } catch (e) {
            debugPrint('Local audio playback error: $e');
          }
        }
      }

      // 2. Fallback: Cloudflare R2 Remote URL
      if (!playbackStarted && ringtoneUrl.isNotEmpty) {
        try {
          await _audioPlayer!.play(UrlSource(ringtoneUrl));
          playbackStarted = true;
          debugPrint('Playing remote R2 reminder ringtone: $ringtoneUrl');
        } catch (e) {
          debugPrint('Remote audio playback error: $e');
        }
      }

      // 3. Fallback: Haptic vibration pattern loop
      _vibrateTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
        HapticFeedback.vibrate();
      });
    } catch (e) {
      debugPrint('AgriReminderAlarmScreen audio init error: $e');
    }
  }

  Future<void> _stopAlarmAndDismiss() async {
    // STRICT BEHAVIOR:
    // Only stop the audio & vibration and close this alarm screen.
    // DOES NOT disable or delete the reminder in Firestore.
    // Regular reminders remain active for next scheduled time.
    try {
      _vibrateTimer?.cancel();
      _vibrateTimer = null;
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _vibrateTimer?.cancel();
    _pulseController.dispose();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.reminderData['title']?.toString() ?? 'কৃষি রিমাইন্ডার';
    final category = widget.reminderData['category']?.toString() ?? 'সাধারণ';
    final reminderType =
        widget.reminderData['reminderType']?.toString() ?? 'temporary';
    final timeText = widget.reminderData['timeText']?.toString() ?? '';
    final note = widget.reminderData['note']?.toString() ?? '';

    final typeLabel = reminderType == 'regular' ? 'নিয়মিত' : 'অস্থায়ী';

    return WillPopScope(
      onWillPop: () async {
        await _stopAlarmAndDismiss();
        return false;
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF0F3813),
                Color(0xFF081F0B),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TOP SECTION: Logo, Time, Badges, Title & Details
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      // Animated Pulsing App Logo
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 120 * _pulseAnimation.value,
                                height: 120 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF81C784)
                                        .withOpacity(
                                            (1.3 - _pulseAnimation.value)
                                                .clamp(0.0, 0.6)),
                                    width: 3,
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              'assets/icons/appicon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.agriculture_rounded,
                                size: 48,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Header Subtitle
                      Text(
                        'কৃষি কথা • কৃষি রিমাইন্ডার',
                        style: TextStyle(
                          color: const Color(0xFFA5D6A7),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Current Digital Clock (Tabular Figures)
                      Text(
                        _currentTimeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category & Type Badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.spa_rounded,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 5),
                                Text(
                                  category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: reminderType == 'regular'
                                  ? const Color(0xFF2E7D32).withOpacity(0.85)
                                  : Colors.orange.shade800.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              typeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Headline
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Frosted Details Card
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 380),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (timeText.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 15,
                                    color: const Color(0xFFC8E6C9),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    timeText,
                                    style: const TextStyle(
                                      color: Color(0xFFC8E6C9),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              note.isNotEmpty
                                  ? note
                                  : '$category কাজের নির্ধারিত সময় হয়েছে। সময়মতো প্রয়োজনীয় পদক্ষেপ গ্রহণ করুন।',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // BOTTOM SECTION: High-Contrast "বন্ধ করুন" Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 380),
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade700.withOpacity(0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _stopAlarmAndDismiss,
                          icon: const Icon(Icons.notifications_off_rounded,
                              size: 22),
                          label: const Text(
                            'বন্ধ করুন',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '* বন্ধ করুন বাটনে চাপ দিলে শুধু অ্যালার্মের শব্দ বন্ধ হবে, রিমাইন্ডার সক্রিয় থাকবে।',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
