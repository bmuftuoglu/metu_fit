class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final double? heightCm;
  final double? weightKg;
  final int? age;
  final int? goalCalories;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.heightCm,
    this.weightKg,
    this.age,
    this.goalCalories,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        age: json['age'] as int?,
        goalCalories: json['goal_calories'] as int?,
      );
}
