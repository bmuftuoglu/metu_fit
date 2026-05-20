class AuthorModel {
  final String id;
  final String fullName;
  final String? avatarUrl;

  const AuthorModel({required this.id, required this.fullName, this.avatarUrl});

  factory AuthorModel.fromJson(Map<String, dynamic> json) => AuthorModel(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
      );
}

class PostModel {
  final String id;
  final String groupId;
  final String postType;
  final AuthorModel author;
  final String? description;
  final String? imageUrl;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final double? calories;
  final int? durationSeconds;
  final double? caloriesBurned;
  final List<dynamic>? routeSnapshot;
  final String? activityLogId;
  final String createdAt;

  const PostModel({
    required this.id,
    required this.groupId,
    required this.postType,
    required this.author,
    this.description,
    this.imageUrl,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    this.calories,
    this.durationSeconds,
    this.caloriesBurned,
    this.routeSnapshot,
    this.activityLogId,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        postType: json['post_type'] as String,
        author: AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        likeCount: json['like_count'] as int? ?? 0,
        commentCount: json['comment_count'] as int? ?? 0,
        isLiked: json['is_liked'] as bool? ?? false,
        calories: (json['calories'] as num?)?.toDouble(),
        durationSeconds: json['duration_seconds'] as int?,
        caloriesBurned: (json['calories_burned'] as num?)?.toDouble(),
        routeSnapshot: json['route_snapshot'] as List?,
        activityLogId: json['activity_log_id'] as String?,
        createdAt: json['created_at'] as String,
      );

  PostModel copyWith({bool? isLiked, int? likeCount}) => PostModel(
        id: id,
        groupId: groupId,
        postType: postType,
        author: author,
        description: description,
        imageUrl: imageUrl,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount,
        isLiked: isLiked ?? this.isLiked,
        calories: calories,
        durationSeconds: durationSeconds,
        caloriesBurned: caloriesBurned,
        routeSnapshot: routeSnapshot,
        activityLogId: activityLogId,
        createdAt: createdAt,
      );
}

class CommentModel {
  final String id;
  final AuthorModel author;
  final String content;
  final String createdAt;

  const CommentModel({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] as String,
        author: AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
        content: json['content'] as String,
        createdAt: json['created_at'] as String,
      );
}
