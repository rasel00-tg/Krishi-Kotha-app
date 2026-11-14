import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';
import '../../core/utils/admin_error_handler.dart';
import '../../core/utils/admin_loading_controller.dart';
import '../../core/utils/platform_file_picker/platform_file_picker.dart';
import '../../core/utils/image_compressor/image_compressor.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_firestore_service.dart';
import '../../data/services/r2_storage_service.dart';
import '../widgets/admin_delete_dialog.dart';
import '../widgets/admin_loading_indicator.dart';

class CropsManagementScreen extends StatefulWidget {
  final int initialTabIndex;
  const CropsManagementScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CropsManagementScreen> createState() => _CropsManagementScreenState();
}

class _CropsManagementScreenState extends State<CropsManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final Stream<List<AdminCropModel>> _cropsStream;
  late final Stream<List<AdminPestModel>> _pestsStream;

  @override
  void initState() {
    super.initState();
    _cropsStream = AdminFirestoreService.instance.getCropsStream();
    _pestsStream = AdminFirestoreService.instance.getPestsStream();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void didUpdateWidget(covariant CropsManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex.clamp(0, 1));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCropDialog({AdminCropModel? existingCrop}) {
    showDialog(
      context: context,
      builder: (context) => _CropEditorDialog(existingCrop: existingCrop),
    );
  }

  void _openPestDialog({AdminPestModel? existingPest}) {
    showDialog(
      context: context,
      builder: (context) => _PestEditorDialog(existingPest: existingPest),
    );
  }

  Future<void> _deleteCrop(String id, String name) async {
    final confirmed = await AdminDeleteDialog.show(
      context,
      title: 'আপনি কি নিশ্চিত মুছে ফেলতে চান?',
      subtitle: 'এই ফসলের তথ্যটি মুছে ফেললে অ্যাপ থেকেও স্থায়ীভাবে মুছে যাবে। আপনি কি এগিয়ে যেতে চান?',
      itemName: 'ফসল: $name',
    );
    if (confirmed) {
      try {
        await AdminFirestoreService.instance.deleteCrop(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ফসল সফলভাবে মুছে ফেলা হয়েছে।'), backgroundColor: AdminColors.primary),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AdminErrorHandler.getFriendlyErrorMessage(e)),
              backgroundColor: AdminColors.alertCritical,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePest(String id, String name) async {
    final confirmed = await AdminDeleteDialog.show(
      context,
      title: 'আপনি কি নিশ্চিত মুছে ফেলতে চান?',
      subtitle: 'এই রোগবালাই তথ্যটি মুছে ফেললে অ্যাপ থেকেও স্থায়ীভাবে মুছে যাবে। আপনি কি এগিয়ে যেতে চান?',
      itemName: 'রোগ/বালাই: $name',
    );
    if (confirmed) {
      try {
        await AdminFirestoreService.instance.deletePest(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('তথ্য সফলভাবে মুছে ফেলা হয়েছে।'), backgroundColor: AdminColors.primary),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AdminErrorHandler.getFriendlyErrorMessage(e)),
              backgroundColor: AdminColors.alertCritical,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Header & Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AdminColors.primary,
                  unselectedLabelColor: AdminColors.textMuted,
                  indicatorColor: AdminColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  tabs: const [
                    Tab(icon: Icon(Icons.grass_rounded), text: 'ফসল ক্যাটালগ (Crops)'),
                    Tab(icon: Icon(Icons.bug_report_rounded), text: 'রোগবালাই ব্যবস্থাপনা (Pests & Diseases)'),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (_tabController.index == 0) {
                    _openCropDialog();
                  } else {
                    _openPestDialog();
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(_tabController.index == 0 ? 'নতুন ফসল যোগ করুন' : 'নতুন রোগবালাই যোগ করুন'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCropsTab(),
              _buildPestsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== TAB 1: CROPS ====================
  Widget _buildCropsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<List<AdminCropModel>>(
        stream: _cropsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const AdminLoadingIndicator(message: 'তথ্য লোডিং হচ্ছে.....');
          }

          final crops = snapshot.data ?? [];
          if (crops.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grass_outlined, size: 44, color: AdminColors.textMuted),
                    SizedBox(height: 10),
                    Text('কোনো তথ্য পাওয়া যায়নি', style: TextStyle(color: AdminColors.textMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              mainAxisExtent: 228,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: crops.length,
            itemBuilder: (context, index) {
              final crop = crops[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                  boxShadow: const [
                    BoxShadow(color: AdminColors.cardShadow, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: crop.imageUrl.isNotEmpty
                                ? Image.network(
                                    crop.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AdminColors.primaryContainer,
                                      child: const Icon(Icons.eco_rounded, color: AdminColors.primary, size: 24),
                                    ),
                                  )
                                : Container(
                                    color: AdminColors.primaryContainer,
                                    child: const Icon(Icons.eco_rounded, color: AdminColors.primary, size: 24),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                crop.nameBn,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      crop.category.isNotEmpty ? crop.category : 'ফসল',
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (crop.season.isNotEmpty)
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF8E1),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          crop.season,
                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFF57F17)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                    const Divider(color: AdminColors.divider, height: 16),
                    _buildCropDetailRow(Icons.landscape_rounded, 'মাটি:', crop.soilType.isEmpty ? 'তথ্য নেই' : crop.soilType),
                    const SizedBox(height: 4),
                    _buildCropDetailRow(Icons.calendar_today_rounded, 'বপন:', crop.sowingTime.isEmpty ? 'তথ্য নেই' : crop.sowingTime),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openCropDetailDialog(crop),
                          icon: const Icon(Icons.visibility_rounded, size: 13, color: Color(0xFF0288D1)),
                          label: const Text('বিস্তারিত', style: TextStyle(fontSize: 11, color: Color(0xFF0288D1), fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            side: const BorderSide(color: Color(0xFFB3E5FC)),
                            backgroundColor: const Color(0xFFE1F5FE),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          onPressed: () => _openCropDialog(existingCrop: crop),
                          icon: const Icon(Icons.edit_rounded, size: 13, color: AdminColors.primary),
                          label: const Text('এডিট', style: TextStyle(fontSize: 11, color: AdminColors.primary, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            side: const BorderSide(color: Color(0xFFC8E6C9)),
                            backgroundColor: const Color(0xFFF1F8E9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          onPressed: () => _deleteCrop(crop.id, crop.nameBn),
                          icon: const Icon(Icons.delete_outline_rounded, size: 13, color: AdminColors.alertCritical),
                          label: const Text('ডিলিট', style: TextStyle(fontSize: 11, color: AdminColors.alertCritical, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            side: const BorderSide(color: Color(0xFFFFCDD2)),
                            backgroundColor: const Color(0xFFFFEBEE),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
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
    );
  }

  void _openCropDetailDialog(AdminCropModel crop) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 580,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Image & Close Button
                Stack(
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        gradient: LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: crop.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Image.network(
                                crop.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.eco_rounded, size: 64, color: Colors.white54),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.eco_rounded, size: 64, color: Colors.white54),
                            ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: CircleAvatar(
                        backgroundColor: Colors.black45,
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 60,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    crop.category.isNotEmpty ? crop.category : 'ফসল',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (crop.season.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE082),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      crop.season,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE65100)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              crop.nameBn,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailCard(
                                Icons.landscape_rounded,
                                'উপযোগী মাটি',
                                crop.soilType.isEmpty ? 'তথ্য নেই' : crop.soilType,
                                const Color(0xFF6D4C41),
                                const Color(0xFFEFEBE9),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailCard(
                                Icons.calendar_today_rounded,
                                'বপন ও রোপণ',
                                crop.sowingTime.isEmpty ? 'তথ্য নেই' : crop.sowingTime,
                                const Color(0xFF00796B),
                                const Color(0xFFE0F2F1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Stages Timeline
                        const Text(
                          'পরিচর্যা ও চাষাবাদ ধাপসমূহ',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AdminColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        if (crop.stages.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AdminColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text('কোনো পরিচর্যা ধাপ যোগ করা হয়নি', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
                            ),
                          )
                        else
                          ...crop.stages.asMap().entries.map((entry) {
                            final idx = entry.key + 1;
                            final name = (s is Map) ? (s['title'] ?? s['name'] ?? s['step'] ?? s['stage_name'] ?? 'ধাপ $idx') : (s.toString());
                            final desc = (s is Map) ? (s['desc'] ?? s['description'] ?? s['details'] ?? '') : '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAF7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE8EDE7)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AdminColors.primary,
                                    child: Text('$idx', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name.toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                        if (desc.toString().isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(desc.toString(), style: const TextStyle(fontSize: 12.5, color: AdminColors.textSecondary)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 16),

                        // Timestamps
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'তৈরি: ${_formatDate(crop.createdAt)}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                              Text(
                                'আপডেট: ${_formatDate(crop.updatedAt)}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('বন্ধ করুন'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                          _openCropDialog(existingCrop: crop);
                        },
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('সম্পাদনা করুন'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AdminColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'তথ্য নেই';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildCropDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AdminColors.textMuted),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textSecondary)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AdminColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==================== TAB 2: PESTS & DISEASES ====================
  Widget _buildPestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<List<AdminPestModel>>(
        stream: _pestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const AdminLoadingIndicator(message: 'তথ্য লোডিং হচ্ছে.....');
          }

          final pests = snapshot.data ?? [];
          if (pests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pest_control_outlined, size: 44, color: AdminColors.textMuted),
                    SizedBox(height: 10),
                    Text('কোনো তথ্য পাওয়া যায়নি', style: TextStyle(color: AdminColors.textMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final pest = pests[index];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                  boxShadow: const [
                    BoxShadow(color: AdminColors.cardShadow, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AdminColors.alertCriticalBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bug_report_rounded, color: AdminColors.alertCritical, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pest.nameBn,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              Text(
                                'আক্রান্ত ফসল: ${pest.cropNameBn}',
                                style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _openPestDialog(existingPest: pest),
                          icon: const Icon(Icons.edit_rounded, size: 14, color: AdminColors.primary),
                          label: const Text('এডিট', style: TextStyle(fontSize: 12, color: AdminColors.primary, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            side: const BorderSide(color: AdminColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _deletePest(pest.id, pest.nameBn),
                          icon: const Icon(Icons.delete_outline_rounded, size: 14, color: AdminColors.alertCritical),
                          label: const Text('ডিলিট', style: TextStyle(fontSize: 12, color: AdminColors.alertCritical, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            side: const BorderSide(color: AdminColors.alertCritical),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AdminColors.divider, height: 20),
                    // Symptoms
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('লক্ষণ: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AdminColors.alertCritical)),
                        Expanded(child: Text(pest.symptoms, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Organic Cure
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('জৈব দমন: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AdminColors.primary)),
                        Expanded(child: Text(pest.organicCure, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Chemical Cure
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('রাসায়নিক প্রতিকার: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AdminColors.alertWarning)),
                        Expanded(child: Text(pest.chemicalCure, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==================== CROP EDITOR DIALOG ====================
class _CropEditorDialog extends StatefulWidget {
  final AdminCropModel? existingCrop;

  const _CropEditorDialog({this.existingCrop});

  @override
  State<_CropEditorDialog> createState() => _CropEditorDialogState();
}

class _CropEditorDialogState extends State<_CropEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _seasonCtrl;
  late TextEditingController _soilCtrl;
  late TextEditingController _sowingCtrl;
  late TextEditingController _imageCtrl;
  bool _saving = false;
  bool _isCompressing = false;

  Uint8List? selectedCropImageBytes;
  String? selectedCropImageName;
  int selectedCropImageSize = 0;
  bool isCropImageRemoved = false;

  @override
  void initState() {
    super.initState();
    final c = widget.existingCrop;
    _nameCtrl = TextEditingController(text: c?.nameBn ?? '');
    _categoryCtrl = TextEditingController(text: c?.category ?? '');
    _seasonCtrl = TextEditingController(text: c?.season ?? '');
    _soilCtrl = TextEditingController(text: c?.soilType ?? '');
    _sowingCtrl = TextEditingController(text: c?.sowingTime ?? '');
    _imageCtrl = TextEditingController(text: c?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _seasonCtrl.dispose();
    _soilCtrl.dispose();
    _sowingCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  /// ১. লোকাল স্টেট ও প্রিভিউ (Fix Premature Upload):
  /// ইমেজ পিকার ফাংশনে সরাসরি Cloudflare R2 কল হবে না।
  /// ২. ওয়েব/মোবাইল সাপোর্টেড অটো কম্প্রেশন:
  /// ইমেজ কোয়ালিটি ৭০-৮০% এবং ম্যাক্স উইডথ ৮০০px করে সাইজ কমিয়ে selectedCropImageBytes-এ স্টোর করা হয়।
  Future<void> _pickImage() async {
    final picked = await pickLocalImageFile();
    if (picked != null) {
      setState(() => _isCompressing = true);
      try {
        final compressed = await compressImageBytes(
          picked.bytes,
          maxWidth: 800,
          quality: 75,
        );
        if (mounted) {
          setState(() {
            selectedCropImageBytes = compressed;
            selectedCropImageName = picked.name;
            selectedCropImageSize = compressed.lengthInBytes;
            isCropImageRemoved = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            selectedCropImageBytes = picked.bytes;
            selectedCropImageName = picked.name;
            selectedCropImageSize = picked.bytes.lengthInBytes;
            isCropImageRemoved = false;
          });
        }
      } finally {
        if (mounted) setState(() => _isCompressing = false);
      }
    }
  }

  /// ৩. ফাইনাল সাবমিট লজিক (Upload strictly on Final Form Submit):
  /// সাবমিট ক্লিক -> গ্লোবাল স্ক্রিন ব্লকিং পপআপ -> R2 আপলোড -> Firestore সেভ -> লোডিং ক্লোজ -> সাকসেস ফিডব্যাক।
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // গ্লোবাল স্ক্রিন-ব্লকিং লোডিং পপআপ চালু
    showGlobalAdminLoading(message: 'তথ্য লোডিং হচ্ছে...', timeout: const Duration(seconds: 30));

    try {
      String finalImageUrl = _imageCtrl.text.trim();
      if (isCropImageRemoved) {
        finalImageUrl = '';
      }

      // ফর্মের ফাইনাল সাবমিটের সময় Cloudflare R2-তে আপলোড হবে
      if (selectedCropImageBytes != null) {
        final cleanExt = (selectedCropImageName?.split('.').last ?? 'jpg').toLowerCase();
        final uniqueFileName = 'crop_${DateTime.now().millisecondsSinceEpoch}_${(selectedCropImageName ?? 'crop').replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}.$cleanExt';

        final uploadedUrl = await R2StorageService.uploadImageBytes(
          bytes: selectedCropImageBytes!,
          fileName: uniqueFileName,
          contentType: cleanExt == 'png' ? 'image/png' : 'image/jpeg',
        );
        finalImageUrl = uploadedUrl;
      }

      // প্রাপ্ত URL ও অন্যান্য তথ্য একসাথে Firestore-এ সেভ
      await AdminFirestoreService.instance.saveCrop(
        id: widget.existingCrop?.id,
        nameBn: _nameCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        season: _seasonCtrl.text.trim(),
        soilType: _soilCtrl.text.trim(),
        sowingTime: _sowingCtrl.text.trim(),
        imageUrl: finalImageUrl,
      );

      safeDismissAdminLoading();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ফসল সফলভাবে সংরক্ষণ করা হয়েছে! মূল অ্যাপে সাথে সাথে সিঙ্ক হয়েছে।'),
            backgroundColor: AdminColors.primary,
          ),
        );
      }
    } catch (e) {
      safeDismissAdminLoading();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AdminErrorHandler.getFriendlyErrorMessage(e)),
            backgroundColor: AdminColors.alertCritical,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      safeDismissAdminLoading();
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveImage = selectedCropImageBytes != null || (_imageCtrl.text.isNotEmpty && !isCropImageRemoved);

    return AlertDialog(
      title: Text(widget.existingCrop != null ? 'ফসল সম্পাদনা করুন' : 'নতুন ফসল যোগ করুন'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ফসলের নাম',
                    hintText: 'ফসলের নাম লিখুন',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'নাম আবশ্যক' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _categoryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'শ্রেণি',
                          hintText: 'শ্রেণি লিখুন',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'শ্রেণি আবশ্যক' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _seasonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'মৌসুম',
                          hintText: 'মৌসুম লিখুন',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'মৌসুম আবশ্যক' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _soilCtrl,
                  decoration: const InputDecoration(
                    labelText: 'উপযোগী মাটি',
                    hintText: 'উপযোগী মাটির বিবরণ দিন',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sowingCtrl,
                  decoration: const InputDecoration(
                    labelText: 'বপন/রোপণের সময়',
                    hintText: 'বপন বা রোপণের সময় লিখুন',
                  ),
                ),
                const SizedBox(height: 14),

                // ফসলের ছবি হেডার
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ফসলের ছবি',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                    ),
                    Text(
                      'Cloudflare R2 স্টোরেজ',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AdminColors.primaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ছবি আপলোড বাটন ও স্ট্যাটাস
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.primaryDark,
                        side: const BorderSide(color: AdminColors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: const Color(0xFFF4FBF4),
                      ),
                      icon: _isCompressing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.primary),
                            )
                          : const Icon(Icons.file_upload_outlined, size: 18),
                      label: Text(
                        hasActiveImage ? 'ছবি পরিবর্তন করুন' : 'ছবি নির্বাচন করুন',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      onPressed: (_saving || _isCompressing) ? null : _pickImage,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isCompressing
                            ? 'ছবি অপ্টিমাইজ ও কম্প্রেস হচ্ছে...'
                            : selectedCropImageBytes != null
                                ? 'ছবি নির্বাচিত (${(selectedCropImageSize / 1024).toStringAsFixed(1)} KB — অপ্টিমাইজড)\nসেভ বাটনে চাপলে R2-তে আপলোড হবে'
                                : (_imageCtrl.text.isNotEmpty && !isCropImageRemoved)
                                    ? 'বর্তমান ছবি সংযুক্ত রয়েছে'
                                    : 'ডিভাইস থেকে লোকাল ছবি নির্বাচন করুন',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: selectedCropImageBytes != null
                              ? const Color(0xFF2E7D32)
                              : AdminColors.textMuted,
                          fontWeight: selectedCropImageBytes != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),

                // লোকাল ইমেজ প্রিভিউ বক্স (Image.memory)
                if (hasActiveImage) ...[
                  const SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.grey.shade50,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: selectedCropImageBytes != null
                              ? Image.memory(
                                  selectedCropImageBytes!,
                                  width: double.infinity,
                                  height: 140,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  _imageCtrl.text,
                                  width: double.infinity,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Text('ছবি প্রিভিউ করা সম্ভব হচ্ছে না', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: _saving ? null : () {
                            setState(() {
                              selectedCropImageBytes = null;
                              selectedCropImageName = null;
                              selectedCropImageSize = 0;
                              isCropImageRemoved = true;
                              _imageCtrl.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('বাতিল')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
          onPressed: (_saving || _isCompressing) ? null : _save,
          child: Text(_saving ? 'সংরক্ষণ হচ্ছে...' : 'সংরক্ষণ করুন', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ==================== PEST EDITOR DIALOG ====================
class _PestEditorDialog extends StatefulWidget {
  final AdminPestModel? existingPest;

  const _PestEditorDialog({this.existingPest});

  @override
  State<_PestEditorDialog> createState() => _PestEditorDialogState();
}

class _PestEditorDialogState extends State<_PestEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _cropNameCtrl;
  late TextEditingController _symptomsCtrl;
  late TextEditingController _organicCtrl;
  late TextEditingController _chemicalCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPest;
    _nameCtrl = TextEditingController(text: p?.nameBn ?? '');
    _cropNameCtrl = TextEditingController(text: p?.cropNameBn ?? '');
    _symptomsCtrl = TextEditingController(text: p?.symptoms ?? '');
    _organicCtrl = TextEditingController(text: p?.organicCure ?? '');
    _chemicalCtrl = TextEditingController(text: p?.chemicalCure ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cropNameCtrl.dispose();
    _symptomsCtrl.dispose();
    _organicCtrl.dispose();
    _chemicalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await AdminFirestoreService.instance.savePest(
        id: widget.existingPest?.id,
        cropId: 'crop_custom',
        cropNameBn: _cropNameCtrl.text.trim(),
        nameBn: _nameCtrl.text.trim(),
        symptoms: _symptomsCtrl.text.trim(),
        organicCure: _organicCtrl.text.trim(),
        chemicalCure: _chemicalCtrl.text.trim(),
        precaution: '',
        imageUrl: '',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('রোগ/বালাই তথ্য সফলভাবে সংরক্ষণ হয়েছে! মূল অ্যাপে সিঙ্ক হয়েছে।'), backgroundColor: AdminColors.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AdminErrorHandler.getFriendlyErrorMessage(e)),
            backgroundColor: AdminColors.alertCritical,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingPest != null ? 'রোগ/বালাই সম্পাদনা' : 'নতুন রোগ/বালাই তথ্য যোগ'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'রোগ বা পোকার নাম',
                    hintText: 'রোগ বা পোকার নাম লিখুন',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'নাম আবশ্যক' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cropNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'আক্রান্ত ফসলের নাম',
                    hintText: 'আক্রান্ত ফসলের নাম লিখুন',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'ফসলের নাম আবশ্যক' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _symptomsCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'লক্ষণসমূহ',
                    hintText: 'লক্ষণসমূহ লিখুন',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'লক্ষণ আবশ্যক' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _organicCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'জৈব বা প্রাকৃতিক প্রতিকার',
                    hintText: 'জৈব বা প্রাকৃতিক প্রতিকার লিখুন',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'জৈব প্রতিকার আবশ্যক' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _chemicalCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'রাসায়নিক সমাধান ও ওষুধের নাম',
                    hintText: 'রাসায়নিক সমাধান ও ওষুধের নাম লিখুন',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'রাসায়নিক প্রতিকার আবশ্যক' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'সংরক্ষণ হচ্ছে...' : 'সংরক্ষণ করুন', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
