import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/post_model.dart';

class FeedPage {
  final List<PostModel> items;
  final String? nextCursor;
  const FeedPage({required this.items, this.nextCursor});
}

class PostsRemoteDatasource {
  final Dio _dio = DioClient.instance;

  Future<FeedPage> getGroupFeed(String groupId, {String? cursor}) async {
    final response = await _dio.get(
      ApiEndpoints.groupPosts(groupId),
      queryParameters: {'limit': 20, 'cursor': cursor}..removeWhere((_, v) => v == null),
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return FeedPage(items: items, nextCursor: data['next_cursor'] as String?);
  }

  Future<PostModel> createMealPost({
    required String groupId,
    String? description,
    String? imageUrl,
    required double calories,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.groupMealPost(groupId),
      data: {
        'description': description,
        'image_url': imageUrl,
        'calories': calories,
      }..removeWhere((_, v) => v == null),
    );
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PostModel> createActivityPost({
    required String groupId,
    String? description,
    String? imageUrl,
    String? activityLogId,
    required int durationSeconds,
    required double caloriesBurned,
    List<dynamic>? routeSnapshot,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.groupActivityPost(groupId),
      data: {
        'description': description,
        'image_url': imageUrl,
        'activity_log_id': activityLogId,
        'duration_seconds': durationSeconds,
        'calories_burned': caloriesBurned,
        'route_snapshot': routeSnapshot,
      }..removeWhere((_, v) => v == null),
    );
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> likePost(String postId) async {
    await _dio.post(ApiEndpoints.postLikes(postId));
  }

  Future<void> unlikePost(String postId) async {
    await _dio.delete(ApiEndpoints.postLikes(postId));
  }

  Future<List<CommentModel>> getComments(String postId) async {
    final response = await _dio.get(ApiEndpoints.postComments(postId));
    return (response.data as List)
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> addComment(String postId, String content) async {
    final response = await _dio.post(
      ApiEndpoints.postComments(postId),
      data: {'content': content},
    );
    return CommentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _dio.delete(ApiEndpoints.postComment(postId, commentId));
  }

  Future<void> deletePost(String groupId, String postId) async {
    await _dio.delete('${ApiEndpoints.groupPosts(groupId)}/$postId');
  }
}
