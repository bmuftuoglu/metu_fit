import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/posts_provider.dart';
import '../../data/models/post_model.dart';

class GroupFeedScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? myRole;
  const GroupFeedScreen({super.key, required this.groupId, this.myRole});

  @override
  ConsumerState<GroupFeedScreen> createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends ConsumerState<GroupFeedScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(feedProvider(widget.groupId).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider(widget.groupId));
    final hasMore = ref.read(feedProvider(widget.groupId).notifier).hasMore;

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'activity_post',
            onPressed: () async {
              await context.push('/groups/${widget.groupId}/post/activity');
              ref.read(feedProvider(widget.groupId).notifier).load();
            },
            child: const Icon(Icons.directions_run),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'meal_post',
            onPressed: () async {
              await context.push('/groups/${widget.groupId}/post/meal');
              ref.read(feedProvider(widget.groupId).notifier).load();
            },
            child: const Icon(Icons.restaurant),
          ),
        ],
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('Henüz paylaşım yok'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(feedProvider(widget.groupId).notifier).load(),
            child: ListView.builder(
              controller: _scrollCtrl,
              itemCount: posts.length + (hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == posts.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _PostCard(
                  post: posts[i],
                  groupId: widget.groupId,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final PostModel post;
  final String groupId;
  const _PostCard({required this.post, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMeal = post.postType == 'meal';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(post.author.fullName[0].toUpperCase())),
            title: Text(post.author.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Row(
              children: [
                Icon(isMeal ? Icons.restaurant : Icons.directions_run,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(isMeal ? 'Öğün' : 'Aktivite',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            trailing: Text(
              _formatDate(post.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          if (post.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          if (post.description != null && post.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(post.description!),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: isMeal
                ? Text('${post.calories?.round() ?? 0} kcal',
                    style: const TextStyle(color: AppColors.calorieConsumed, fontWeight: FontWeight.w600))
                : Text(
                    '${_formatDuration(post.durationSeconds ?? 0)} • ${post.caloriesBurned?.round() ?? 0} kcal',
                    style: const TextStyle(color: AppColors.calorieBurned, fontWeight: FontWeight.w600),
                  ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  post.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: post.isLiked ? Colors.red : null,
                ),
                onPressed: () => ref.read(feedProvider(groupId).notifier).toggleLike(post.id),
              ),
              Text('${post.likeCount}'),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () => _showComments(context, ref),
              ),
              Text('${post.commentCount}'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
      if (diff.inHours < 24) return '${diff.inHours}sa önce';
      return '${diff.inDays}g önce';
    } catch (_) {
      return '';
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    if (m < 60) return '${m}dk';
    return '${m ~/ 60}sa ${m % 60}dk';
  }

  void _showComments(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommentsSheet(postId: post.id),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _ctrl = TextEditingController();
  List<dynamic> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final ds = ref.read(postsDatasourceProvider);
    final comments = await ds.getComments(widget.postId);
    if (mounted) setState(() { _comments = comments; _loading = false; });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (_, scrollCtrl) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Yorumlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: _comments.length,
                    itemBuilder: (_, i) {
                      final c = _comments[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(c.author.fullName[0].toUpperCase())),
                        title: Text(c.author.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(c.content),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 12, right: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(hintText: 'Yorum yaz...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = _ctrl.text.trim();
                    if (text.isEmpty) return;
                    _ctrl.clear();
                    await ref.read(postsDatasourceProvider).addComment(widget.postId, text);
                    _loadComments();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
