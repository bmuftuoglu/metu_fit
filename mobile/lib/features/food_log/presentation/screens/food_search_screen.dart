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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Yiyecek ara...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (v) => ref.read(foodSearchProvider.notifier).search(v),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(RouteNames.addCustomFood, extra: widget.date),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Yeni'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (items) {
          if (items.isEmpty && _searchController.text.isEmpty) {
            return _SearchHint();
          }
          if (items.isEmpty) {
            return _NoResults(query: _searchController.text);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, i) => const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) => _FoodItemTile(item: items[i], date: widget.date),
          );
        },
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_rounded, size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Yiyecek ara',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 6),
          const Text(
            'Yiyecek adını yazarak arama yapın',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 52, color: AppColors.border),
          const SizedBox(height: 16),
          Text(
            '"$query" bulunamadı',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Farklı bir kelime deneyin\nveya yeni yiyecek ekleyin',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.restaurant_outlined, color: AppColors.primary, size: 20),
      ),
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: item.brand != null
          ? Text(item.brand!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${item.caloriesPer100g.round()} kcal',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
      onTap: () => _showAddDialog(context, ref),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final gramsController = TextEditingController(text: '100');
    String mealType = 'lunch';
    const mealLabels = {
      'breakfast': 'Kahvaltı',
      'lunch': 'Öğle Yemeği',
      'dinner': 'Akşam Yemeği',
      'snack': 'Ara Öğün',
    };
    const mealIcons = {
      'breakfast': Icons.wb_sunny_outlined,
      'lunch': Icons.wb_cloudy_outlined,
      'dinner': Icons.nights_stay_outlined,
      'snack': Icons.apple_outlined,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.restaurant_outlined, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${item.caloriesPer100g.round()} kcal / 100g',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: gramsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Miktar',
                  suffixText: 'gram',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Öğün',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: mealLabels.entries.map((e) {
                  final selected = mealType == e.key;
                  return GestureDetector(
                    onTap: () => setInnerState(() => mealType = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mealIcons[e.key]!,
                            size: 14,
                            color: selected ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
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
