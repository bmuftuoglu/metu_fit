import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/posts_remote_datasource.dart';
import '../../data/models/post_model.dart';

final postsDatasourceProvider = Provider((_) => PostsRemoteDatasource());

class FeedNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final PostsRemoteDatasource _ds;
  final String groupId;
  String? _nextCursor;
  bool _hasMore = true;

  FeedNotifier(this._ds, this.groupId) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final result = await _ds.getGroupFeed(groupId);
      _nextCursor = result.nextCursor;
      _hasMore = _nextCursor != null;
      state = AsyncValue.data(result.items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    try {
      final result = await _ds.getGroupFeed(groupId, cursor: _nextCursor);
      _nextCursor = result.nextCursor;
      _hasMore = _nextCursor != null;
      state = AsyncValue.data([...current, ...result.items]);
    } catch (_) {}
  }

  void toggleLike(String postId) {
    final posts = state.valueOrNull;
    if (posts == null) return;
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = posts[idx];
    final updated = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
    final newList = [...posts];
    newList[idx] = updated;
    state = AsyncValue.data(newList);

    if (updated.isLiked) {
      _ds.likePost(postId).catchError((_) => toggleLike(postId));
    } else {
      _ds.unlikePost(postId).catchError((_) => toggleLike(postId));
    }
  }

  void removePost(String postId) {
    final posts = state.valueOrNull;
    if (posts == null) return;
    state = AsyncValue.data(posts.where((p) => p.id != postId).toList());
  }

  bool get hasMore => _hasMore;
}

final feedProvider = StateNotifierProvider.family<FeedNotifier, AsyncValue<List<PostModel>>, String>(
  (ref, groupId) => FeedNotifier(ref.read(postsDatasourceProvider), groupId),
);
