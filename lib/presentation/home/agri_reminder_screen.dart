import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../global_popup/global_popup.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/auth_service.dart';
import '../../services/agri_reminder_notification_service.dart';
import '../auth/phone_login_screen.dart';

class AgriReminderScreen extends StatefulWidget {
  const AgriReminderScreen({super.key});

  @override
  State<AgriReminderScreen> createState() => _AgriReminderScreenState();
}

class _AgriReminderScreenState extends State<AgriReminderScreen> {
  // Active category filter: 'all', 'temporary', 'regular'
  String _activeFilter = 'all';

  // Cached Stream initialized once per active user for Zero Redundant Reads
  Stream<QuerySnapshot<Map<String, dynamic>>>? _remindersStream;
  String? _currentUserId;

  static const int maxRemindersLimit = 5;

  final List<String> _categories = [
    'সেচ দেওয়া',
    'সার প্রয়োগ',
    'কীটনাশক স্প্রে',
    'বীজ বপন',
    'ফসল সংগ্রহ',
    'পশু-পাখি ও মাছ',
    'অন্যান্য',
  ];

  @override
  void initState() {
    super.initState();
    _resolveInitialUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = _getActiveUserId(context);
    if (uid != null && (_currentUserId != uid || _remindersStream == null)) {
      _ensureStream(uid);
    }
  }

  /// Initial fallback to cached user in SharedPreferences
  Future<void> _resolveInitialUser() async {
    try {
      final cached = await AuthService().loadCachedUser();
      if (cached != null &&
          cached.uid.isNotEmpty &&
          !cached.uid.startsWith('guest_')) {
        if (mounted && _currentUserId != cached.uid) {
          setState(() {
            _ensureStream(cached.uid);
          });
        }
      }
    } catch (_) {}
  }

  /// Ensure Firestore stream is only initialized once per active user ID
  void _ensureStream(String uid) {
    if (_currentUserId != uid || _remindersStream == null) {
      _currentUserId = uid;
      _remindersStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('agri_reminders')
          .limit(10)
          .snapshots();
    }
  }

  /// Unified helper to resolve active logged-in User ID
  String? _getActiveUserId(BuildContext context) {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null &&
          auth.user!.uid.isNotEmpty &&
          !auth.user!.uid.startsWith('guest_')) {
        return auth.user!.uid;
      }
    } catch (_) {}

    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null &&
        fbUser.uid.isNotEmpty &&
        !fbUser.uid.startsWith('guest_')) {
      return fbUser.uid;
    }

    if (_currentUserId != null &&
        _currentUserId!.isNotEmpty &&
        !_currentUserId!.startsWith('guest_')) {
      return _currentUserId;
    }

    return null;
  }

  String _getUserName(BuildContext context) {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null && auth.user!.name.trim().isNotEmpty) {
        return auth.user!.name.trim();
      }
    } catch (_) {}

    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null &&
        fbUser.displayName != null &&
        fbUser.displayName!.trim().isNotEmpty) {
      return fbUser.displayName!.trim();
    }

    return 'কৃষক';
  }

  String _getUserEmailOrPhone(BuildContext context) {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        if (auth.user!.email.trim().isNotEmpty) return auth.user!.email.trim();
        if (auth.user!.phone.trim().isNotEmpty) return auth.user!.phone.trim();
      }
    } catch (_) {}

    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      if (fbUser.email != null && fbUser.email!.trim().isNotEmpty) {
        return fbUser.email!.trim();
      }
      if (fbUser.phoneNumber != null &&
          fbUser.phoneNumber!.trim().isNotEmpty) {
        return fbUser.phoneNumber!.trim();
      }
    }

    return '';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'সেচ দেওয়া':
        return const Color(0xFF0288D1);
      case 'সার প্রয়োগ':
        return const Color(0xFF388E3C);
      case 'কীটনাশক স্প্রে':
        return const Color(0xFFD32F2F);
      case 'বীজ বপন':
        return const Color(0xFF7B1FA2);
      case 'ফসল সংগ্রহ':
        return const Color(0xFFE65100);
      case 'পশু-পাখি ও মাছ':
        return const Color(0xFF00796B);
      default:
        return const Color(0xFF455A64);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'সেচ দেওয়া':
        return Icons.water_drop_rounded;
      case 'সার প্রয়োগ':
        return Icons.grass_rounded;
      case 'কীটনাশক স্প্রে':
        return Icons.sanitizer_rounded;
      case 'বীজ বপন':
        return Icons.spa_rounded;
      case 'ফসল সংগ্রহ':
        return Icons.agriculture_rounded;
      case 'পশু-পাখি ও মাছ':
        return Icons.pets_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  void _checkAuthAndShowAddModal(int currentCount) {
    final activeUid = _getActiveUserId(context);

    if (activeUid == null) {
      GlobalPopup.showConfirm(
        context,
        title: 'লগইন প্রয়োজন',
        message: 'রিমাইন্ডার সেট করতে আপনার একাউন্টে লগইন করুন।',
        confirmText: 'লগইন করুন',
        cancelText: 'বাতিল',
        confirmColor: GlobalPopup.primaryTeal,
        onConfirm: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
          ).then((_) {
            if (mounted) {
              _resolveInitialUser();
            }
          });
        },
      );
      return;
    }

    if (currentCount >= maxRemindersLimit) {
      GlobalPopup.showNotice(
        context,
        title: 'রিমাইন্ডার সীমা পূর্ণ',
        message:
            'আপনি সর্বোচ্চ $maxRemindersLimit টি রিমাইন্ডার সেট করতে পারবেন। নতুন রিমাইন্ডার যুক্ত করতে পুরোনো একটি ডিলিট করুন।',
        buttonText: 'ঠিক আছে',
      );
      return;
    }

    _showReminderFormModal(activeUid: activeUid);
  }

  void _showReminderFormModal(
      {required String activeUid, DocumentSnapshot? doc}) {
    final isEdit = doc != null;
    final Map<String, dynamic> data =
        isEdit ? (doc.data() as Map<String, dynamic>? ?? {}) : {};

    final titleController =
        TextEditingController(text: data['title']?.toString() ?? '');
    final noteController =
        TextEditingController(text: data['note']?.toString() ?? '');

    String selectedCategory = data['category']?.toString() ?? _categories[0];
    if (!_categories.contains(selectedCategory)) {
      selectedCategory = _categories[0];
    }

    String reminderType = data['reminderType']?.toString() ?? 'temporary';
    String repeatInterval = data['repeatInterval']?.toString() ?? 'none';

    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    if (data['scheduledDateTime'] != null) {
      if (data['scheduledDateTime'] is Timestamp) {
        selectedDate = (data['scheduledDateTime'] as Timestamp).toDate();
      } else if (data['scheduledDateTime'] is String) {
        selectedDate =
            DateTime.tryParse(data['scheduledDateTime'] as String) ??
                selectedDate;
      }
    }

    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final formattedDateStr =
                DateFormat('dd/MM/yyyy').format(selectedDate);
            final hourStr = selectedTime.hourOfPeriod == 0
                ? '12'
                : selectedTime.hourOfPeriod.toString().padLeft(2, '0');
            final minuteStr = selectedTime.minute.toString().padLeft(2, '0');
            final periodStr =
                selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
            final formattedTimeStr = '$hourStr:$minuteStr $periodStr';

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Header Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'রিমাইন্ডার সম্পাদনা' : 'নতুন কৃষি রিমাইন্ডার',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(bottomSheetCtx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // ১. শিরোনাম (Title)
                    const Text(
                      'রিমাইন্ডারের শিরোনাম *',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'রিমাইন্ডারের শিরোনাম লিখুন',
                        hintStyle: TextStyle(
                            fontSize: 13, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF2E7D32), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ২. কাজের ক্যাটাগরি (Category)
                    const Text(
                      'কাজের ধরন / ক্যাটাগরি *',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF2E7D32)),
                          items: _categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(_getCategoryIcon(cat),
                                      size: 18, color: _getCategoryColor(cat)),
                                  const SizedBox(width: 8),
                                  Text(cat,
                                      style: const TextStyle(fontSize: 13.5)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCategory = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ৩. রিমাইন্ডারের ধরন (Temporary vs Regular)
                    const Text(
                      'রিমাইন্ডারের ধরন *',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                reminderType = 'temporary';
                                repeatInterval = 'none';
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: reminderType == 'temporary'
                                    ? const Color(0xFFE8F5E9)
                                    : Colors.grey.shade50,
                                border: Border.all(
                                  color: reminderType == 'temporary'
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey.shade300,
                                  width:
                                      reminderType == 'temporary' ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.alarm_rounded,
                                    size: 20,
                                    color: reminderType == 'temporary'
                                        ? const Color(0xFF1B5E20)
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'অস্থায়ী (একবার)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: reminderType == 'temporary'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: reminderType == 'temporary'
                                          ? const Color(0xFF1B5E20)
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                reminderType = 'regular';
                                if (repeatInterval == 'none') {
                                  repeatInterval = 'daily';
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: reminderType == 'regular'
                                    ? const Color(0xFFE8F5E9)
                                    : Colors.grey.shade50,
                                border: Border.all(
                                  color: reminderType == 'regular'
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey.shade300,
                                  width: reminderType == 'regular' ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.repeat_rounded,
                                    size: 20,
                                    color: reminderType == 'regular'
                                        ? const Color(0xFF1B5E20)
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'নিয়মিত (পুনরাবৃত্তি)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: reminderType == 'regular'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: reminderType == 'regular'
                                          ? const Color(0xFF1B5E20)
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ৪. নিয়মিত হলে পুনরাবৃত্তির অপশন (Repeat Interval)
                    if (reminderType == 'regular') ...[
                      const Text(
                        'পুনরাবৃত্তির সময়সীমা *',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('প্রতিদিন',
                                style: TextStyle(fontSize: 12.5)),
                            selected: repeatInterval == 'daily',
                            selectedColor: const Color(0xFF2E7D32),
                            labelStyle: TextStyle(
                              color: repeatInterval == 'daily'
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: repeatInterval == 'daily'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => repeatInterval = 'daily');
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('প্রতি সপ্তাহে',
                                style: TextStyle(fontSize: 12.5)),
                            selected: repeatInterval == 'weekly',
                            selectedColor: const Color(0xFF2E7D32),
                            labelStyle: TextStyle(
                              color: repeatInterval == 'weekly'
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: repeatInterval == 'weekly'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => repeatInterval = 'weekly');
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ৫. তারিখ ও সময় নির্বাচন (Date & Time Picker with English Digits)
                    Row(
                      children: [
                        if (reminderType == 'temporary') ...[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'তারিখ নির্বাচন *',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await _showCustomDatePickerPopup(
                                      context,
                                      selectedDate,
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        selectedDate = DateTime(
                                          picked.year,
                                          picked.month,
                                          picked.day,
                                          selectedDate.hour,
                                          selectedDate.minute,
                                        );
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 11),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded,
                                            size: 16, color: Color(0xFF2E7D32)),
                                        const SizedBox(width: 8),
                                        Text(
                                          formattedDateStr,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              fontFeatures: [FontFeature.tabularFigures()],
                                              height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'সময় নির্বাচন *',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await _showCustomTimePickerPopup(
                                    context,
                                    selectedTime,
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      selectedTime = picked;
                                      selectedDate = DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                        picked.hour,
                                        picked.minute,
                                      );
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded,
                                          size: 16, color: Color(0xFF2E7D32)),
                                      const SizedBox(width: 8),
                                      Text(
                                        formattedTimeStr,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                            height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ৬. সংক্ষিপ্ত নোট (Note, Optional)
                    const Text(
                      'সংক্ষিপ্ত নোট (ঐচ্ছিক)',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'নোট লিখুন (ঐচ্ছিক)',
                        hintStyle: TextStyle(
                            fontSize: 13, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF2E7D32), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // সাবমিট বাটন
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          if (isSubmitting) return;

                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            GlobalPopup.showNotice(
                              context,
                              title: 'শিরোনাম প্রয়োজন',
                              message:
                                  'অনুগ্রহ করে রিমাইন্ডারের একটি শিরোনাম লিখুন।',
                            );
                            return;
                          }

                          isSubmitting = true;

                          // Construct final scheduled datetime
                          final fullScheduledDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          // Generate unique int for notificationId
                          final notifId = isEdit
                              ? (data['notificationId'] is int
                                  ? data['notificationId'] as int
                                  : (int.tryParse(
                                          data['notificationId']?.toString() ??
                                              '') ??
                                      DateTime.now().millisecondsSinceEpoch %
                                          1000000))
                              : (DateTime.now().millisecondsSinceEpoch %
                                  1000000);

                          final uName = _getUserName(context);
                          final uEmail = _getUserEmailOrPhone(context);

                          // Show master Global Loading popup immediately before any await
                          GlobalPopup.showLoading(context, message: 'রিমাইন্ডার সেভ হচ্ছে...');

                          try {
                            final userRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(activeUid);
                            final remindersCol =
                                userRef.collection('agri_reminders');

                            // Strict 2nd-layer limit verification directly from Firestore before insert (if new)
                            if (!isEdit) {
                              final existingDocs =
                                  await remindersCol.limit(5).get();
                              if (existingDocs.docs.length >= maxRemindersLimit) {
                                isSubmitting = false;
                                GlobalPopup.hideLoading(context);
                                if (mounted) {
                                  GlobalPopup.showNotice(
                                    context,
                                    title: 'রিমাইন্ডার সীমা পূর্ণ',
                                    message:
                                        'আপনি সর্বোচ্চ $maxRemindersLimit টি রিমাইন্ডার সেট করতে পারবেন। নতুন রিমাইন্ডার যুক্ত করতে পুরোনো একটি ডিলিট করুন।',
                                  );
                                }
                                return;
                              }
                            }

                            final payload = {
                              'notificationId': notifId,
                              'userId': activeUid,
                              'userName': uName,
                              'userEmail': uEmail,
                              'title': title,
                              'category': selectedCategory,
                              'reminderType': reminderType,
                              'repeatInterval': repeatInterval,
                              'scheduledDateTime': (reminderType == 'temporary')
                                  ? fullScheduledDateTime.toIso8601String()
                                  : null,
                              'timeText': (reminderType == 'temporary')
                                  ? '$formattedDateStr | $formattedTimeStr'
                                  : formattedTimeStr,
                              'note': noteController.text.trim(),
                              'isActive': true,
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            if (isEdit) {
                              await remindersCol.doc(doc.id).update(payload);
                            } else {
                              payload['createdAt'] =
                                  FieldValue.serverTimestamp();
                              final newDoc = await remindersCol.add(payload);
                              await newDoc.update({'id': newDoc.id});
                            }

                            // Schedule in local device notification engine
                            await AgriReminderNotificationService.scheduleReminder(
                              notificationId: notifId,
                              title: title,
                              body: noteController.text.trim().isNotEmpty
                                  ? '$selectedCategory: ${noteController.text.trim()}'
                                  : selectedCategory,
                              scheduledDateTime: fullScheduledDateTime,
                              reminderType: reminderType,
                              repeatInterval: repeatInterval,
                            );

                            isSubmitting = false;
                            GlobalPopup.hideLoading(context);
                            Navigator.pop(bottomSheetCtx);

                            if (mounted) {
                              GlobalPopup.showNotice(
                                context,
                                title: 'সফল',
                                message: isEdit
                                    ? 'রিমাইন্ডার সফলভাবে আপডেট করা হয়েছে।'
                                    : 'রিমাইন্ডার সফলভাবে সেভ করা হয়েছে।',
                              );
                            }
                          } catch (e) {
                            isSubmitting = false;
                            GlobalPopup.hideLoading(context);
                            if (mounted) {
                              GlobalPopup.showNotice(
                                context,
                                title: 'ত্রুটি',
                                message: 'সংরক্ষণে সমস্যা হয়েছে: $e',
                              );
                            }
                          }
                        },
                        child: Text(
                          isEdit ? 'আপডেট করুন' : 'রিমাইন্ডার সংরক্ষণ করুন',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleReminderStatus(
      DocumentSnapshot doc, bool newStatus) async {
    final activeUid = _getActiveUserId(context);
    if (activeUid == null) return;

    final data = doc.data() as Map<String, dynamic>? ?? {};
    final notifId = data['notificationId'] is int
        ? data['notificationId'] as int
        : (int.tryParse(data['notificationId']?.toString() ?? '') ??
            doc.id.hashCode.abs());

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(activeUid)
          .collection('agri_reminders')
          .doc(doc.id)
          .update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (newStatus) {
        // Reschedule
        DateTime? dt;
        if (data['scheduledDateTime'] != null) {
          if (data['scheduledDateTime'] is Timestamp) {
            dt = (data['scheduledDateTime'] as Timestamp).toDate();
          } else if (data['scheduledDateTime'] is String) {
            dt = DateTime.tryParse(data['scheduledDateTime'] as String);
          }
        }
        if (dt != null) {
          await AgriReminderNotificationService.scheduleReminder(
            notificationId: notifId,
            title: data['title']?.toString() ?? 'কৃষি রিমাইন্ডার',
            body: data['note']?.toString() ?? '',
            scheduledDateTime: dt,
            reminderType: data['reminderType']?.toString() ?? 'temporary',
            repeatInterval: data['repeatInterval']?.toString() ?? 'none',
          );
        }
      } else {
        // Cancel schedule
        await AgriReminderNotificationService.cancelReminder(notifId);
      }
    } catch (e) {
      if (mounted) {
        GlobalPopup.showNotice(
          context,
          title: 'ত্রুটি',
          message: 'স্ট্যাটাস পরিবর্তনে সমস্যা হয়েছে: $e',
        );
      }
    }
  }

  // ==========================================
  // CUSTOM MASTER DATE PICKER POPUP
  // ==========================================
  Future<DateTime?> _showCustomDatePickerPopup(
    BuildContext context,
    DateTime initialDate,
  ) async {
    return showDialog<DateTime>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        DateTime selected = initialDate;
        DateTime displayedMonth = DateTime(initialDate.year, initialDate.month, 1);

        return StatefulBuilder(
          builder: (context, setPopupState) {
            final monthNames = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            final weekDays = ['শনি', 'রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র'];

            final dNum = selected.day.toString().padLeft(2, '0');
            final mShort = DateFormat('MMM').format(selected);
            final dayShort = DateFormat('EEE').format(selected);
            final headerText = '$dNum $mShort ${selected.year}, $dayShort';

            final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
            // Saturday is column 0.
            final startCol = (firstDayOfMonth.weekday == DateTime.saturday)
                ? 0
                : (firstDayOfMonth.weekday == DateTime.sunday ? 1 : firstDayOfMonth.weekday + 1);

            final daysInMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
            final today = DateTime.now();
            final todayDateOnly = DateTime(today.year, today.month, today.day);

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF00897B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'তারিখ নির্বাচন করুন',
                              style: TextStyle(
                                fontSize: 11.5,
                                letterSpacing: 0.8,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              headerText,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Quick Select Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _quickDateChip('আজ', () {
                                    setPopupState(() {
                                      selected = DateTime.now();
                                      displayedMonth = DateTime(selected.year, selected.month, 1);
                                    });
                                  }),
                                  const SizedBox(width: 6),
                                  _quickDateChip('আগামীকাল', () {
                                    setPopupState(() {
                                      selected = DateTime.now().add(const Duration(days: 1));
                                      displayedMonth = DateTime(selected.year, selected.month, 1);
                                    });
                                  }),
                                  const SizedBox(width: 6),
                                  _quickDateChip('৩ দিন পর', () {
                                    setPopupState(() {
                                      selected = DateTime.now().add(const Duration(days: 3));
                                      displayedMonth = DateTime(selected.year, selected.month, 1);
                                    });
                                  }),
                                  const SizedBox(width: 6),
                                  _quickDateChip('৭ দিন পর', () {
                                    setPopupState(() {
                                      selected = DateTime.now().add(const Duration(days: 7));
                                      displayedMonth = DateTime(selected.year, selected.month, 1);
                                    });
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Month & Year Navigator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Color(0xFF1B5E20)),
                                  onPressed: () {
                                    setPopupState(() {
                                      displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1, 1);
                                    });
                                  },
                                ),
                                Text(
                                  '${monthNames[displayedMonth.month - 1]} ${displayedMonth.year}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Color(0xFF1B5E20)),
                                  onPressed: () {
                                    setPopupState(() {
                                      displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 1);
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Weekday Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: weekDays.map((d) {
                                return Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF78909C),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),

                            // Calendar Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                              ),
                              itemCount: startCol + daysInMonth,
                              itemBuilder: (context, index) {
                                if (index < startCol) {
                                  return const SizedBox.shrink();
                                }
                                final day = index - startCol + 1;
                                final cellDate = DateTime(displayedMonth.year, displayedMonth.month, day);
                                final isPast = cellDate.isBefore(todayDateOnly);
                                final isSelected = selected.year == cellDate.year &&
                                    selected.month == cellDate.month &&
                                    selected.day == cellDate.day;
                                final isToday = today.year == cellDate.year &&
                                    today.month == cellDate.month &&
                                    today.day == cellDate.day;

                                if (isPast) {
                                  return Center(
                                    child: Text(
                                      '$day',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blueGrey.shade200,
                                      ),
                                    ),
                                  );
                                }

                                if (isSelected) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF1B5E20), Color(0xFF00897B)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x551B5E20),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$day',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                if (isToday) {
                                  return InkWell(
                                    onTap: () {
                                      setPopupState(() => selected = cellDate);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFF1F8E9),
                                        border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$day',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1B5E20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return InkWell(
                                  onTap: () {
                                    setPopupState(() => selected = cellDate);
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF263238),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Actions
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 42,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: const Color(0xFFECEFF1),
                                        side: const BorderSide(color: Color(0xFFCFD8DC), width: 1.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => Navigator.pop(dialogContext, null),
                                      child: const Text(
                                        'বাতিল',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF546E7A),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 42,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2E7D32),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                      ),
                                      onPressed: () => Navigator.pop(dialogContext, selected),
                                      child: const Text(
                                        'নিশ্চিত করুন',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickDateChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC8E6C9)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B5E20),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CUSTOM MASTER TIME PICKER POPUP
  // ==========================================
  Future<TimeOfDay?> _showCustomTimePickerPopup(
    BuildContext context,
    TimeOfDay initialTime,
  ) async {
    return showDialog<TimeOfDay>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        int hour = initialTime.hourOfPeriod == 0 ? 12 : initialTime.hourOfPeriod;
        int minute = initialTime.minute;
        DayPeriod period = initialTime.period;

        return StatefulBuilder(
          builder: (context, setPopupState) {
            final hStr = hour.toString().padLeft(2, '0');
            final mStr = minute.toString().padLeft(2, '0');
            final pStr = period == DayPeriod.am ? 'AM' : 'PM';

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with Digital Display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF00897B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'সময় নির্বাচন করুন',
                              style: TextStyle(
                                fontSize: 11.5,
                                letterSpacing: 0.8,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$hStr : $mStr $pStr',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Quick Presets
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _quickTimeChip('ভোর 06:00', () {
                                    setPopupState(() {
                                      hour = 6;
                                      minute = 0;
                                      period = DayPeriod.am;
                                    });
                                  }),
                                  const SizedBox(width: 6),
                                  _quickTimeChip('সকাল 08:00', () {
                                    setPopupState(() {
                                      hour = 8;
                                      minute = 0;
                                      period = DayPeriod.am;
                                    });
                                  }),
                                  const SizedBox(width: 6),
                                  _quickTimeChip('দুপুর 12:00', () {
                                    setPopupState(() {
                                      hour = 12;
                                      minute = 0;
                                      period = DayPeriod.pm;
                                    });
                                  }),
                                  const SizedBox(width: 6),
                                  _quickTimeChip('বিকাল 04:00', () {
                                    setPopupState(() {
                                      hour = 4;
                                      minute = 0;
                                      period = DayPeriod.pm;
                                    });
                                  }),
                                  const SizedBox(width: 6),
                                  _quickTimeChip('সন্ধ্যা 07:00', () {
                                    setPopupState(() {
                                      hour = 7;
                                      minute = 0;
                                      period = DayPeriod.pm;
                                    });
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Interactive Steppers
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAF7),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE8F5E9)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Hour Stepper
                                  Column(
                                    children: [
                                      _stepperButton(Icons.add, () {
                                        setPopupState(() {
                                          hour = hour >= 12 ? 1 : hour + 1;
                                        });
                                      }),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Text(
                                          hStr,
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1B5E20),
                                            fontFamily: 'monospace',
                                            fontFeatures: [FontFeature.tabularFigures()],
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                      _stepperButton(Icons.remove, () {
                                        setPopupState(() {
                                          hour = hour <= 1 ? 12 : hour - 1;
                                        });
                                      }),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'ঘণ্টা',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF78909C),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 24),
                                    child: Text(
                                      ':',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ),

                                  // Minute Stepper
                                  Column(
                                    children: [
                                      _stepperButton(Icons.add, () {
                                        setPopupState(() {
                                          minute = (minute + 5) % 60;
                                        });
                                      }),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Text(
                                          mStr,
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1B5E20),
                                            fontFamily: 'monospace',
                                            fontFeatures: [FontFeature.tabularFigures()],
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                      _stepperButton(Icons.remove, () {
                                        setPopupState(() {
                                          minute = (minute - 5 < 0) ? 55 : minute - 5;
                                        });
                                      }),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'মিনিট',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF78909C),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 14),

                                  // AM/PM Toggle
                                  Column(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setPopupState(() => period = DayPeriod.am);
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: period == DayPeriod.am
                                                ? const Color(0xFF2E7D32)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: period == DayPeriod.am
                                                  ? const Color(0xFF2E7D32)
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            'AM',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: period == DayPeriod.am
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () {
                                          setPopupState(() => period = DayPeriod.pm);
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: period == DayPeriod.pm
                                                ? const Color(0xFF2E7D32)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: period == DayPeriod.pm
                                                  ? const Color(0xFF2E7D32)
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            'PM',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: period == DayPeriod.pm
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Quick Minute Chips: :00, :15, :30, :45
                            Row(
                              children: [0, 15, 30, 45].map((m) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: InkWell(
                                      onTap: () {
                                        setPopupState(() => minute = m);
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        decoration: BoxDecoration(
                                          color: minute == m ? const Color(0xFFE8F5E9) : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: minute == m ? const Color(0xFF2E7D32) : const Color(0xFFCFD8DC),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            ':${m.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: minute == m ? const Color(0xFF1B5E20) : const Color(0xFF455A64),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // Actions
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 42,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: const Color(0xFFECEFF1),
                                        side: const BorderSide(color: Color(0xFFCFD8DC), width: 1.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => Navigator.pop(dialogContext, null),
                                      child: const Text(
                                        'বাতিল',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF546E7A),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 42,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2E7D32),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                      ),
                                      onPressed: () {
                                        int finalHour = hour % 12;
                                        if (period == DayPeriod.pm) finalHour += 12;
                                        Navigator.pop(dialogContext, TimeOfDay(hour: finalHour, minute: minute));
                                      },
                                      child: const Text(
                                        'সময় সেট করুন',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickTimeChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC8E6C9)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B5E20),
          ),
        ),
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
      ),
    );
  }

  Future<void> _deleteReminder(DocumentSnapshot doc) async {
    final activeUid = _getActiveUserId(context);
    if (activeUid == null) return;

    final confirm = await GlobalPopup.showConfirm(
      context,
      title: 'রিমাইন্ডার ডিলিট',
      message: 'আপনি কি নিশ্চিতভাবে এই রিমাইন্ডারটি মুছে ফেলতে চান?',
      confirmText: 'হ্যাঁ, মুছুন',
      cancelText: 'বাতিল',
      confirmColor: Colors.red.shade700,
    );

    if (confirm != true) return;

    final data = doc.data() as Map<String, dynamic>? ?? {};
    final notifId = data['notificationId'] is int
        ? data['notificationId'] as int
        : (int.tryParse(data['notificationId']?.toString() ?? '') ??
            doc.id.hashCode.abs());

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(activeUid)
          .collection('agri_reminders')
          .doc(doc.id)
          .delete();

      await AgriReminderNotificationService.cancelReminder(notifId);

      if (mounted) {
        GlobalPopup.showNotice(
          context,
          title: 'সফল',
          message: 'রিমাইন্ডারটি সফলভাবে মুছে ফেলা হয়েছে।',
        );
      }
    } catch (e) {
      if (mounted) {
        GlobalPopup.showNotice(
          context,
          title: 'ত্রুটি',
          message: 'ডিলিট করতে সমস্যা হয়েছে: $e',
        );
      }
    }
  }

  Widget _buildFilterChip(
      String label, String filterKey, int count, Color activeColor) {
    final isSelected = _activeFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filterKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.35),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1B5E20).withOpacity(0.12)
                    : Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'ফিরে যান',
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'কৃষি রিমাইন্ডার',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'সময়মতো কৃষি কাজের সতর্কবার্তা',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required int totalCount,
    required int tempCount,
    required int regCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(
          left: 16, right: 16, top: 4, bottom: 14),
      child: Column(
        children: [
          // রিমাইন্ডার লিমিট কাউন্টার ব্যাজ (English Digits: e.g. 2/5)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.alarm_on_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'মোট রিমাইন্ডার: $totalCount/$maxRemindersLimit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ৩টি ফিল্টার চিপস (সব, অস্থায়ী, নিয়মিত)
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  'সব',
                  'all',
                  totalCount,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'অস্থায়ী',
                  'temporary',
                  tempCount,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'নিয়মিত',
                  'regular',
                  regCount,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAddButton(int currentCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _checkAuthAndShowAddModal(currentCount),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1B5E20),
                    Color(0xFF2E7D32),
                    Color(0xFF00897B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'নতুন রিমাইন্ডার যোগ করুন',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Reactive AuthProvider resolution
    final auth = Provider.of<AuthProvider>(context);
    final fbUser = FirebaseAuth.instance.currentUser;

    final String? activeUid = (auth.user != null &&
            auth.user!.uid.isNotEmpty &&
            !auth.user!.uid.startsWith('guest_'))
        ? auth.user!.uid
        : ((fbUser != null &&
                fbUser.uid.isNotEmpty &&
                !fbUser.uid.startsWith('guest_'))
            ? fbUser.uid
            : (_currentUserId != null &&
                    _currentUserId!.isNotEmpty &&
                    !_currentUserId!.startsWith('guest_')
                ? _currentUserId
                : null));

    // 2. Ensure stream is active when activeUid is resolved
    if (activeUid != null) {
      _ensureStream(activeUid);
    }

    if (activeUid == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FAF7),
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(totalCount: 0, tempCount: 0, regCount: 0),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_person_rounded,
                            size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 14),
                        const Text(
                          'লগইন প্রয়োজন',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'রিমাইন্ডার সেট এবং ব্যাকগ্রাউন্ড নোটিফিকেশন পেতে অনুগ্রহ করে আপনার একাউন্টে লগইন করুন।',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PhoneLoginScreen()),
                            ).then((_) {
                              if (mounted) {
                                _resolveInitialUser();
                              }
                            });
                          },
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text('লগইন করুন',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomAddButton(0),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _remindersStream,
      builder: (context, snapshot) {
        final allDocs = snapshot.data?.docs ?? [];
        final totalCount = allDocs.length;
        final tempCount = allDocs
            .where((d) =>
                (d.data()['reminderType']?.toString() ?? '') ==
                'temporary')
            .length;
        final regCount = allDocs
            .where((d) =>
                (d.data()['reminderType']?.toString() ?? '') ==
                'regular')
            .length;

        Widget bodyContent;
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          bodyContent = const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2E7D32),
            ),
          );
        } else if (snapshot.hasError) {
          debugPrint('Reminders stream error: ${snapshot.error}');
          bodyContent = const Center(
            child: EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              message: 'কোনো রিমাইন্ডার নেই',
              subtitle:
                  'এখনো কোনো কৃষি রিমাইন্ডার সেট করা হয়নি। নিচের বাটনে চাপ দিয়ে নতুন রিমাইন্ডার যোগ করুন।',
            ),
          );
        } else {
          // Client-Side in-memory sorting by updatedAt / createdAt descending
          final sortedDocs =
              List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                  allDocs);
          sortedDocs.sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            final aTime = (aData['updatedAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                (aData['createdAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                0;
            final bTime = (bData['updatedAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                (bData['createdAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                0;
            return bTime.compareTo(aTime);
          });

          // Client-Side in-memory filtering (Zero Extra Firestore Reads)
          final filteredDocs = sortedDocs.where((doc) {
            final data = doc.data();
            final type = data['reminderType']?.toString() ??
                'temporary';
            if (_activeFilter == 'temporary') {
              return type == 'temporary';
            } else if (_activeFilter == 'regular') {
              return type == 'regular';
            }
            return true;
          }).toList();

          if (filteredDocs.isEmpty) {
            IconData emptyIcon = Icons.notifications_none_rounded;
            String emptyTitle = 'কোনো রিমাইন্ডার নেই';
            String emptySub =
                'এখনো কোনো কৃষি রিমাইন্ডার সেট করা হয়নি। নিচের বাটনে চাপ দিয়ে নতুন রিমাইন্ডার যোগ করুন।';

            if (_activeFilter == 'temporary') {
              emptyIcon = Icons.calendar_today_rounded;
              emptyTitle = 'কোনো অস্থায়ী রিমাইন্ডার নেই';
              emptySub =
                  'এককালীন কোনো কাজের সতর্কবার্তা পেতে নতুন রিমাইন্ডার যোগ করুন।';
            } else if (_activeFilter == 'regular') {
              emptyIcon = Icons.repeat_rounded;
              emptyTitle = 'কোনো নিয়মিত রিমাইন্ডার নেই';
              emptySub =
                  'দৈনিক বা সাপ্তাহিক কাজের জন্য নিয়মিত রিমাইন্ডার সেট করুন।';
            }

            bodyContent = Center(
              child: EmptyStateWidget(
                icon: emptyIcon,
                message: emptyTitle,
                subtitle: emptySub,
              ),
            );
          } else {
            bodyContent = ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              itemCount: filteredDocs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = filteredDocs[index];
                final data = doc.data();

                final title =
                    data['title']?.toString() ?? 'রিমাইন্ডার';
                final category =
                    data['category']?.toString() ?? 'সাধারণ';
                final reminderType =
                    data['reminderType']?.toString() ??
                        'temporary';
                final repeatInterval =
                    data['repeatInterval']?.toString() ?? 'none';
                final note = data['note']?.toString() ?? '';
                final isActive = data['isActive'] == true;

                final catColor = _getCategoryColor(category);
                final catIcon = _getCategoryIcon(category);

                // Format scheduled date time
                String dateTimeText =
                    data['timeText']?.toString() ?? '';
                if (reminderType == 'temporary' && data['scheduledDateTime'] != null) {
                  DateTime? dt;
                  if (data['scheduledDateTime'] is Timestamp) {
                    dt = (data['scheduledDateTime'] as Timestamp)
                        .toDate();
                  } else if (data['scheduledDateTime']
                      is String) {
                    dt = DateTime.tryParse(
                        data['scheduledDateTime'] as String);
                  }
                  if (dt != null) {
                    final dateStr =
                        DateFormat('dd/MM/yyyy').format(dt);
                    final hour = dt.hour % 12 == 0
                        ? 12
                        : dt.hour % 12;
                    final min =
                        dt.minute.toString().padLeft(2, '0');
                    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
                    dateTimeText =
                        '$dateStr | ${hour.toString().padLeft(2, '0')}:$min $ampm';
                  }
                }

                String typeLabel = 'অস্থায়ী (একবার)';
                if (reminderType == 'regular') {
                  if (repeatInterval == 'daily') {
                    typeLabel = 'নিয়মিত (প্রতিদিন)';
                  } else if (repeatInterval == 'weekly') {
                    typeLabel = 'নিয়মিত (প্রতি সপ্তাহে)';
                  } else {
                    typeLabel = 'নিয়মিত';
                  }
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? catColor.withOpacity(0.3)
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Category badge & Active Toggle
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      catColor.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(catIcon,
                                        size: 13,
                                        color: catColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      category,
                                      style: TextStyle(
                                        color: catColor,
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: reminderType == 'regular'
                                      ? const Color(0xFFE8F5E9)
                                      : Colors.orange.shade50,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    color: reminderType ==
                                            'regular'
                                        ? const Color(0xFF1B5E20)
                                        : Colors.orange.shade900,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Active Switch
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: isActive,
                              activeColor:
                                  const Color(0xFF2E7D32),
                              onChanged: (val) =>
                                  _toggleReminderStatus(
                                      doc, val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? Colors.black87
                              : Colors.grey.shade500,
                          decoration: isActive
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Note (if any)
                      if (note.isNotEmpty) ...[
                        Text(
                          note,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Date & Time + Action Buttons
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 14,
                                  color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                dateTimeText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 19,
                                    color: Color(0xFF0288D1)),
                                tooltip: 'সম্পাদনা করুন',
                                constraints:
                                    const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                onPressed: () =>
                                    _showReminderFormModal(
                                        activeUid: activeUid,
                                        doc: doc),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 19,
                                    color: Colors.red.shade700),
                                tooltip: 'মুছে ফেলুন',
                                constraints:
                                    const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                onPressed: () =>
                                    _deleteReminder(doc),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAF7),
          appBar: _buildAppBar(),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(
                  totalCount: totalCount,
                  tempCount: tempCount,
                  regCount: regCount,
                ),
                Expanded(child: bodyContent),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomAddButton(totalCount),
        );
      },
    );
  }
}
