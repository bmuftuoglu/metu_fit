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
  static String get calorieHistory => '$baseUrl/users/me/calorie-history';

  // Food
  static String get foodItems => '$baseUrl/food-items';
  static String get foodLogs => '$baseUrl/food-logs';

  // Activities
  static String get activityLogs => '$baseUrl/activity-logs';

  // Groups
  static String get groups => '$baseUrl/groups';
  static String joinGroup() => '$baseUrl/groups/join';
  static String groupDetail(String id) => '$baseUrl/groups/$id';
  static String groupMembers(String id) => '$baseUrl/groups/$id/members';
  static String groupPosts(String id) => '$baseUrl/groups/$id/posts';

  // Posts
  static String postDetail(String id) => '$baseUrl/posts/$id';
  static String postLikes(String id) => '$baseUrl/posts/$id/likes';
  static String postComments(String id) => '$baseUrl/posts/$id/comments';

  // Uploads
  static String get presignedUrl => '$baseUrl/uploads/presigned-url';
}
