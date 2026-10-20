import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/widgets/premium_loading_widget.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../data/models/pest_disease_model.dart';
import 'pest_detail_screen.dart';

class PestCatalogScreen extends StatefulWidget {
  final String? initialCropId;

  const PestCatalogScreen({super.key, this.initialCropId});

  @override
  State<PestCatalogScreen> createState() => _PestCatalogScreenState();
}

class _PestCatalogScreenState extends State<PestCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pests_diseases').snapshots().timeout(
        const Duration(seconds: 4),
        onTimeout: (sink) async {
          try {
            final snap = await FirebaseFirestore.instance.collection('pests_diseases').get();
            sink.add(snap);
          } catch (e) {
            sink.addError(e);
          }
        },
      ),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

        Widget bodyContent;
        if (isLoading) {
          bodyContent = const SizedBox.shrink();
        } else if (snapshot.hasError) {
          final errStr = snapshot.error.toString();
          final isPermissionDenied = errStr.toLowerCase().contains('permission-denied') ||
              errStr.toLowerCase().contains('permission_denied') ||
              errStr.toLowerCase().contains('permission denied');

          bodyContent = Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPermissionDenied ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPermissionDenied
                        ? 'ফায়ারবেস পারমিশন এরর (Permission Denied)'
                        : 'Firestore ত্রুটি',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPermissionDenied
                        ? 'ফায়ারবেস কনসোলের Firestore Database -> Rules ট্যাবে গিয়ে\n"allow read, write: if true;" সক্রিয় করুন।'
                        : errStr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isPermissionDenied ? Colors.black87 : Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      (context as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('পুনরায় চেষ্টা করুন'),
                  ),
                ],
              ),
            ),
          );
        } else {
          // ৩. ডেটা আসার পর মূল কনটেন্ট (সার্চ বার ও রোগবালাই তালিকা)
          Widget listContent;
          final docs = snapshot.data?.docs ?? [];
          final List<PestDiseaseModel> allPests = [];
          for (final doc in docs) {
            try {
              allPests.add(PestDiseaseModel.fromFirestore(doc));
            } catch (e) {
              debugPrint('PestDiseaseModel parse error for doc ${doc.id}: $e');
            }
          }

          // Sort newest first
          allPests.sort((a, b) {
            final aTime = a.updatedAt;
            final bTime = b.updatedAt;
            if (aTime != null && bTime != null) return bTime.compareTo(aTime);
            if (aTime != null) return -1;
            if (bTime != null) return 1;
            return 0;
          });

          // In-memory filters
          var filtered = allPests;
          if (widget.initialCropId != null && widget.initialCropId!.isNotEmpty) {
            filtered = filtered.where((p) => p.cropId == widget.initialCropId).toList();
          }
          if (_searchQuery.isNotEmpty) {
            filtered = filtered.where((p) =>
              p.nameBn.toLowerCase().contains(_searchQuery) ||
              p.cropNameBn.toLowerCase().contains(_searchQuery) ||
              p.symptoms.toLowerCase().contains(_searchQuery)
            ).toList();
          }

          // 3. Empty State
          if (filtered.isEmpty) {
            listContent = Center(
              child: EmptyStateWidget(
                message: 'রোগবালাইয়ের কোনো তথ্য পাওয়া যায়নি',
                icon: Icons.bug_report_outlined,
                action: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('পুনরায় চেষ্টা করুন'),
                ),
              ),
            );
          } else {
            listContent = ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final pest = filtered[index];
                return _buildPestCard(context, pest);
              },
            );
          }

          bodyContent = Column(
            children: [
              // Search Input Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: AppStrings.searchPest,
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              Expanded(child: listContent),
            ],
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Scaffold(
              backgroundColor: AppColors.background,
              appBar: const CustomAppBar(title: AppStrings.pestCatalogTitle),
              body: bodyContent,
            ),
            if (isLoading)
              const Positioned.fill(
                child: PremiumLoadingWidget(topic: 'রোগবালাইয়ের তথ্য'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPestCard(BuildContext context, PestDiseaseModel pest) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PestDetailScreen(pest: pest)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pest Sample Image or Agriculture Icon Fallback
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 90,
                  height: 90,
                  color: const Color(0xFFF1F8E9),
                  child: pest.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: pest.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ShimmerCardLoader(height: 90, width: 90),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.agriculture_rounded,
                              color: AppColors.primary,
                              size: 44,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.agriculture_rounded,
                            color: AppColors.primary,
                            size: 44,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pest.cropNameBn.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pest.cropNameBn,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    Text(
                      pest.nameBn,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (pest.symptoms.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'লক্ষণ: ${pest.symptoms}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (pest.organicCure.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'প্রতিকার: ${pest.organicCure}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Text(
                          'বিস্তারিত ও প্রতিকার দেখুন →',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC2185B),
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
  }
}
