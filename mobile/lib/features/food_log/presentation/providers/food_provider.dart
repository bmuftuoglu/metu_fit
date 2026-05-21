import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/food_remote_datasource.dart';
import '../../data/models/food_item_model.dart';

final foodDatasourceProvider = Provider((_) => FoodRemoteDatasource());

// Daily summary
final dailySummaryProvider = FutureProvider.family<DailySummaryModel, String>((ref, date) {
  return ref.read(foodDatasourceProvider).getDailySummary(date);
});

// Monthly calories: key = 'yyyy-MM', value = {dateKey: consumedCalories}
// dailySummaryProvider cache'ini kullanır — önceden yüklenmiş günler için yeni API çağrısı yapmaz
final monthlyCaloriesProvider = FutureProvider.family<Map<String, double>, String>((ref, yearMonth) async {
  final parts = yearMonth.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final daysInMonth = DateTime(year, month + 1, 0).day;

  final entries = await Future.wait(
    List.generate(daysInMonth, (i) async {
      final dateKey = '$yearMonth-${(i + 1).toString().padLeft(2, '0')}';
      try {
        final summary = await ref.read(dailySummaryProvider(dateKey).future);
        return MapEntry(dateKey, summary.consumedCalories);
      } catch (_) {
        return MapEntry(dateKey, 0.0);
      }
    }),
  );

  return Map.fromEntries(entries);
});

// Food search
class FoodSearchNotifier extends StateNotifier<AsyncValue<List<FoodItemModel>>> {
  final FoodRemoteDatasource _ds;
  Timer? _debounce;

  FoodSearchNotifier(this._ds) : super(const AsyncValue.data([]));

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void search(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _ds.searchFoodItems(query));
    });
  }

  void clear() => state = const AsyncValue.data([]);
}

final foodSearchProvider = StateNotifierProvider<FoodSearchNotifier, AsyncValue<List<FoodItemModel>>>(
  (ref) => FoodSearchNotifier(ref.read(foodDatasourceProvider)),
);
