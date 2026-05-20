import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/food_item_model.dart';
import '../providers/food_provider.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  final String date;
  const FoodSearchScreen({super.key, required this.date});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(foodSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Yiyecek ara...',
            border: InputBorder.none,
          ),
          onChanged: (v) => ref.read(foodSearchProvider.notifier).search(v),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push(RouteNames.addCustomFood, extra: widget.date),
            child: const Text('Yeni Ekle'),
          ),
        ],
      ),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (items) {
          if (items.isEmpty && _searchController.text.isNotEmpty) {
            return const Center(child: Text('Sonuç bulunamadı'));
          }
          if (items.isEmpty) return const Center(child: Text('Arama yapın'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => _FoodItemTile(item: items[i], date: widget.date),
          );
        },
      ),
    );
  }
}

class _FoodItemTile extends ConsumerWidget {
  final FoodItemModel item;
  final String date;
  const _FoodItemTile({required this.item, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text(item.brand ?? '${item.caloriesPer100g.round()} kcal / 100g'),
      trailing: Text('${item.caloriesPer100g.round()} kcal',
          style: const TextStyle(color: AppColors.textSecondary)),
      onTap: () => _showAddDialog(context, ref),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final gramsController = TextEditingController(text: '100');
    String mealType = 'lunch';
    final mealLabels = {
      'breakfast': 'Kahvaltı',
      'lunch': 'Öğle',
      'dinner': 'Akşam',
      'snack': 'Ara Öğün',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(item.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: gramsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Miktar (gram)',
                  suffixText: 'g',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: mealType,
                isExpanded: true,
                items: mealLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setInnerState(() => mealType = v!),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final grams = double.tryParse(gramsController.text) ?? 100;
                  await ref.read(foodDatasourceProvider).addFoodLog(
                        foodItemId: item.id,
                        grams: grams,
                        mealType: mealType,
                        loggedAt: date,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) context.pop();
                },
                child: const Text('Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
