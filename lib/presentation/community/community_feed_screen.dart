import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/widgets/premium_loading_widget.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../data/models/community_post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityFeedScreen extends StatelessWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final communityProvider = Provider.of<CommunityProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid ?? 'guest_user';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: AppStrings.forumTitle,
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add_rounded),
            tooltip: AppStrings.createPostBtn,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          'প্রশ্ন বা পোস্ট লিখুন',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<CommunityPostModel>>(
        stream: communityProvider.postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const PremiumLoadingWidget(topic: 'কমিউনিটি পোস্ট');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Firestore ত্রুটি: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          }

          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return EmptyStateWidget(
              message: 'এখনো কোনো পোস্ট করা হয়নি',
              subtitle: 'প্রথম প্রশ্ন বা ফসলের ছবি দিয়ে আলোচনা শুরু করুন',
              icon: Icons.forum_outlined,
              action: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('নতুন পোস্ট তৈরি করুন'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostCard(context, post, currentUserId, communityProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildPostCard(
    BuildContext context,
    CommunityPostModel post,
    String currentUserId,
    CommunityProvider provider,
  ) {
    final isLiked = post.likedBy.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Info & Time
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      post.authorName.isNotEmpty ? post.authorName.substring(0, 1) : 'ক',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          BanglaDateFormatter.formatRelative(post.timestamp),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Content text
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Attached Photo if exists
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ShimmerCardLoader(height: 200),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 6),

              // Interaction Row: Like, Comment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Like Button
                  TextButton.icon(
                    onPressed: () => provider.toggleLike(post.postId, currentUserId),
                    icon: Icon(
                      isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                      color: isLiked ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                    label: Text(
                      '${BanglaNumberConverter.toBangla(post.likesCount)} ${AppStrings.likes}',
                      style: TextStyle(
                        color: isLiked ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),

                  // Comment Button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                      );
                    },
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    label: Text(
                      '${BanglaNumberConverter.toBangla(post.commentsCount)} ${AppStrings.comments}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
