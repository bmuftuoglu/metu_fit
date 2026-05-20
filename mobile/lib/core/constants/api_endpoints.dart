import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://192.168.0.98/api/v1';

  // Auth
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get refresh => '$baseUrl/auth/refresh';
  static String get logout => '$baseUrl/auth/logout';

  // Users
  static String get me => '$baseUrl/users/me';
  static String get calorieSummary => '$baseUrl/users/me/calorie-summary';

  // Food
  static String get foodItems => '$baseUrl/food/items';
  static String get foodLogs => '$baseUrl/food/logs';
  static String foodLog(String id) => '$baseUrl/food/logs/$id';

  // Activities
  static String get activities => '$baseUrl/activities';
  static String activity(String id) => '$baseUrl/activities/$id';

  // Groups
  static String get groups => '$baseUrl/groups';
  static String get joinGroup => '$baseUrl/groups/join';
  static String group(String id) => '$baseUrl/groups/$id';
  static String groupMembers(String id) => '$baseUrl/groups/$id/members';
  static String groupMember(String gid, String uid) => '$baseUrl/groups/$gid/members/$uid';
  static String groupPosts(String id) => '$baseUrl/groups/$id/posts';
  static String groupMealPost(String id) => '$baseUrl/groups/$id/posts/meal';
  static String groupActivityPost(String id) => '$baseUrl/groups/$id/posts/activity';
  static String regenerateInvite(String id) => '$baseUrl/groups/$id/regenerate-invite';

  // Posts
  static String postLikes(String id) => '$baseUrl/posts/$id/likes';
  static String postComments(String id) => '$baseUrl/posts/$id/comments';
  static String postComment(String postId, String commentId) => '$baseUrl/posts/$postId/comments/$commentId';

  // Uploads
  static String get presignedUrl => '$baseUrl/uploads/presigned-url';
}
