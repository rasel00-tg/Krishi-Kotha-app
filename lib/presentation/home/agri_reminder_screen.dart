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
          .orderBy('createdAt', descending: true)
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                        hintText: 'যেমন: ধানে সেচ দেওয়া, ইউরিয়া সার প্রয়োগ...',
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminderType == 'regular'
                                    ? (repeatInterval == 'weekly'
                                        ? 'বার নির্বাচন *'
                                        : 'শুরুর তারিখ *')
                                    : 'তারিখ নির্বাচন *',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now().subtract(
                                        const Duration(days: 1)),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
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
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
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
                                            fontWeight: FontWeight.w600),
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
                        hintText: 'প্রয়োজনীয় কোনো নোট বা দিকনির্দেশনা লিখুন...',
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

                          Navigator.pop(bottomSheetCtx);

                          try {
                            final userRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(activeUid);
                            final remindersCol =
                                userRef.collection('agri_reminders');

                            // Strict verify limit before insert (if new)
                            if (!isEdit) {
                              final existingDocs = await remindersCol
                                  .where('isActive', isEqualTo: true)
                                  .get();
                              if (existingDocs.docs.length >=
                                  maxRemindersLimit) {
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
                              'scheduledDateTime':
                                  fullScheduledDateTime.toIso8601String(),
                              'timeText': formattedTimeStr,
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

                            if (mounted) {
                              GlobalPopup.showNotice(
                                context,
                                title: 'সফল',
                                message: isEdit
                                    ? 'রিমাইন্ডার সফলভাবে আপডেট করা হয়েছে।'
                                    : 'নতুন রিমাইন্ডার সফলভাবে যুক্ত করা হয়েছে।',
                              );
                            }
                          } catch (e) {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: PreferredSize(
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
          actions: [
            IconButton(
              icon: const Icon(Icons.add_alert_rounded,
                  color: Colors.white, size: 22),
              tooltip: 'নতুন রিমাইন্ডার',
              onPressed: () => _checkAuthAndShowAddModal(0),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ১. কালারিং টপবার হেডার (Colored Header with Counter & Filter Chips)
            Container(
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
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

                  return Column(
                    children: [
                      // রিমাইন্ডার লিমিট কাউন্টার ব্যাজ (English Digits: e.g. 2/5)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                _checkAuthAndShowAddModal(totalCount),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline_rounded,
                                      size: 14, color: Color(0xFF1B5E20)),
                                  SizedBox(width: 4),
                                  Text(
                                    '+ নতুন রিমাইন্ডার',
                                    style: TextStyle(
                                      color: Color(0xFF1B5E20),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                  );
                },
              ),
            ),

            // ২. স্ক্রলযোগ্য বডি (StreamBuilder List View)
            Expanded(
              child: activeUid == null
                  ? Center(
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
                    )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _remindersStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2E7D32),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'ডেটা লোড করতে সমস্যা হয়েছে: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        // Client-Side in-memory filtering (Zero Extra Firestore Reads)
                        final filteredDocs = docs.where((doc) {
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
                          IconData emptyIcon = Icons.alarm_off_rounded;
                          String emptyTitle =
                              'বর্তমানে কোনো রিমাইন্ডার সেট করা নেই';
                          String emptySub =
                              'নতুন রিমাইন্ডার সেট করতে "+ নতুন রিমাইন্ডার" চাপুন';

                          if (_activeFilter == 'temporary') {
                            emptyIcon = Icons.event_busy_rounded;
                            emptyTitle = 'কোনো অস্থায়ী রিমাইন্ডার নেই';
                            emptySub =
                                'এককালীন কোনো কাজের সতর্কবার্তা পেতে নতুন রিমাইন্ডার যোগ করুন';
                          } else if (_activeFilter == 'regular') {
                            emptyIcon = Icons.repeat_on_rounded;
                            emptyTitle = 'কোনো নিয়মিত রিমাইন্ডার নেই';
                            emptySub =
                                'দৈনিক বা সাপ্তাহিক কাজের জন্য নিয়মিত রিমাইন্ডার সেট করুন';
                          }

                          return Center(
                            child: EmptyStateWidget(
                              icon: emptyIcon,
                              message: emptyTitle,
                              subtitle: emptySub,
                            ),
                          );
                        }

                        return ListView.separated(
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
                            if (data['scheduledDateTime'] != null) {
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
