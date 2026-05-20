import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/food_remote_datasource.dart';
import '../../data/models/food_item_model.dart';

final foodDatasourceProvider = Provider((_) => FoodRemoteDatasource());

// Daily summary
final dailySummaryProvider = FutureProvider.family<DailySummaryModel, String>((ref, date) {
  return ref.read(foodDatasourceProvider).getDailySummary(date);
});

// Food search
class FoodSearchNotifier extends StateNotifier<AsyncValue<List<FoodItemModel>>> {
  final FoodRemoteDatasource _ds;
  FoodSearchNotifier(this._ds) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ds.searchFoodItems(query));
  }

  void clear() => state = const AsyncValue.data([]);
}

final foodSearchProvider = StateNotifierProvider<FoodSearchNotifier, AsyncValue<List<FoodItemModel>>>(
  (ref) => FoodSearchNotifier(ref.read(foodDatasourceProvider)),
);
