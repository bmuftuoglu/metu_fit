import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/food_item_model.dart';

class FoodRemoteDatasource {
  final Dio _dio = DioClient.instance;

  Future<List<FoodItemModel>> searchFoodItems(String query) async {
    final response = await _dio.get(ApiEndpoints.foodItems, queryParameters: {'q': query});
    return (response.data as List).map((e) => FoodItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FoodItemModel> createCustomFoodItem({
    required String name,
    String? brand,
    required double caloriesPer100g,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) async {
    final response = await _dio.post(ApiEndpoints.foodItems, data: {
      'name': name,
      'brand': brand,
      'calories_per_100g': caloriesPer100g,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
    }..removeWhere((_, v) => v == null));
    return FoodItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DailySummaryModel> getDailySummary(String date) async {
    final response = await _dio.get(ApiEndpoints.foodLogs, queryParameters: {'date': date});
    return DailySummaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FoodLogModel> addFoodLog({
    required String foodItemId,
    required double grams,
    required String mealType,
    String? loggedAt,
  }) async {
    final response = await _dio.post(ApiEndpoints.foodLogs, data: {
      'food_item_id': foodItemId,
      'grams': grams,
      'meal_type': mealType,
      'logged_at': loggedAt,
    }..removeWhere((_, v) => v == null));
    return FoodLogModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteFoodLog(String logId) async {
    await _dio.delete(ApiEndpoints.foodLog(logId));
  }
}
