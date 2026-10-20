import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/bangla_number_converter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../data/models/community_post_model.dart';
import '../../data/models/comment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment(CommunityProvider provider, AuthProvider auth) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = auth.user;
    final authorId = user?.uid ?? 'guest_user';
    final authorName = user?.name ?? 'কৃষক ভাই';

    _commentController.clear();
    await provider.addComment(
      postId: widget.post.postId,
      authorId: authorId,
      authorName: authorName,
      content: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityProvider = Provider.of<CommunityProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid ?? 'guest_user';
    final isLiked = widget.post.likedBy.contains(currentUserId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'আলোচনা ও মন্তব্য'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          widget.post.authorName.isNotEmpty
                              ? widget.post.authorName.substring(0, 1)
                              : 'ক',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.authorName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              BanglaDateFormatter.formatRelative(widget.post.timestamp),
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Post Content
                  Text(
                    widget.post.content,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Photo if exists
                  if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: widget.post.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const ShimmerCardLoader(height: 220),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Interaction bar
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => communityProvider.toggleLike(widget.post.postId, currentUserId),
                        icon: Icon(
                          isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                          color: isLiked ? AppColors.primary : AppColors.textSecondary,
                        ),
                        label: Text(
                          '${BanglaNumberConverter.toBangla(widget.post.likesCount)} ${AppStrings.likes}',
                          style: TextStyle(
                            color: isLiked ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${BanglaNumberConverter.toBangla(widget.post.commentsCount)} ${AppStrings.comments}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),

                  const Divider(color: AppColors.border, height: 28),

                  // Comments Header
                  const Text(
                    'সকল মন্তব্য ও পরামর্শ',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Real-time Comments Stream
                  StreamBuilder<List<CommentModel>>(
                    stream: communityProvider.getCommentsStream(widget.post.postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const ShimmerListLoader(itemCount: 2, itemHeight: 70);
                      }

                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                            child: Text(
                              'এখনো কোনো মন্তব্য নেই। আপনার পরামর্শ লিখুন।',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      c.authorName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    Text(
                                      BanglaDateFormatter.formatRelative(c.timestamp),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  c.content,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Comment Input Box at bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: AppStrings.writeComment,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _sendComment(communityProvider, authProvider),
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary, size: 28),
                    tooltip: 'মন্তব্য পাঠান',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
