class FoodItemModel {
  final String id;
  final String name;
  final String? brand;
  final double caloriesPer100g;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final bool isCustom;

  const FoodItemModel({
    required this.id,
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    this.proteinG,
    this.carbsG,
    this.fatG,
    required this.isCustom,
  });

  factory FoodItemModel.fromJson(Map<String, dynamic> json) => FoodItemModel(
        id: json['id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        caloriesPer100g: (json['calories_per_100g'] as num).toDouble(),
        proteinG: (json['protein_g'] as num?)?.toDouble(),
        carbsG: (json['carbs_g'] as num?)?.toDouble(),
        fatG: (json['fat_g'] as num?)?.toDouble(),
        isCustom: json['is_custom'] as bool? ?? false,
      );
}

class FoodLogModel {
  final String id;
  final FoodItemModel foodItem;
  final double grams;
  final double calories;
  final String mealType;
  final String loggedAt;

  const FoodLogModel({
    required this.id,
    required this.foodItem,
    required this.grams,
    required this.calories,
    required this.mealType,
    required this.loggedAt,
  });

  factory FoodLogModel.fromJson(Map<String, dynamic> json) => FoodLogModel(
        id: json['id'] as String,
        foodItem: FoodItemModel.fromJson(json['food_item'] as Map<String, dynamic>),
        grams: (json['grams'] as num).toDouble(),
        calories: (json['calories'] as num).toDouble(),
        mealType: json['meal_type'] as String,
        loggedAt: json['logged_at'] as String,
      );
}

class DailySummaryModel {
  final String date;
  final int? goalCalories;
  final double consumedCalories;
  final double burnedCalories;
  final double netCalories;
  final List<FoodLogModel> logs;

  const DailySummaryModel({
    required this.date,
    this.goalCalories,
    required this.consumedCalories,
    required this.burnedCalories,
    required this.netCalories,
    required this.logs,
  });

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) => DailySummaryModel(
        date: json['date'] as String,
        goalCalories: json['goal_calories'] as int?,
        consumedCalories: (json['consumed_calories'] as num).toDouble(),
        burnedCalories: (json['burned_calories'] as num).toDouble(),
        netCalories: (json['net_calories'] as num).toDouble(),
        logs: (json['logs'] as List)
            .map((e) => FoodLogModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
