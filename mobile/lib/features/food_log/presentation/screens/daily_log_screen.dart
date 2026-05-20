import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/food_item_model.dart';
import '../providers/food_provider.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  void _changeDate(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dailySummaryProvider(_dateKey));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Takip'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push(RouteNames.foodSearch, extra: _dateKey);
              ref.invalidate(dailySummaryProvider(_dateKey));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _DateBar(date: _selectedDate, onPrev: () => _changeDate(-1), onNext: () => _changeDate(1)),
          Expanded(
            child: summaryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (summary) => _Body(
                summary: summary,
                onDeleteLog: (logId) async {
                  await ref.read(foodDatasourceProvider).deleteFoodLog(logId);
                  ref.invalidate(dailySummaryProvider(_dateKey));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBar extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DateBar({required this.date, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Text(
            isToday ? 'Bugün' : DateFormat('d MMMM yyyy', 'tr').format(date),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isToday ? null : onNext,
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final DailySummaryModel summary;
  final void Function(String) onDeleteLog;

  const _Body({required this.summary, required this.onDeleteLog});

  @override
  Widget build(BuildContext context) {
    final goal = summary.goalCalories?.toDouble() ?? 2000;
    final consumed = summary.consumedCalories;
    final burned = summary.burnedCalories;
    final remaining = (goal - consumed + burned).clamp(0.0, goal);

    final mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
    final mealLabels = {'breakfast': 'Kahvaltı', 'lunch': 'Öğle', 'dinner': 'Akşam', 'snack': 'Ara Öğün'};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CalorieRing(consumed: consumed, burned: burned, goal: goal, remaining: remaining),
        const SizedBox(height: 24),
        _MacroRow(summary: summary),
        const SizedBox(height: 24),
        for (final meal in mealTypes) ...[
          _MealSection(
            label: mealLabels[meal]!,
            logs: summary.logs.where((l) => l.mealType == meal).toList(),
            onDelete: onDeleteLog,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CalorieRing extends StatelessWidget {
  final double consumed;
  final double burned;
  final double goal;
  final double remaining;

  const _CalorieRing({required this.consumed, required this.burned, required this.goal, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final fraction = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: fraction,
                          color: AppColors.primary,
                          radius: 20,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: 1 - fraction,
                          color: AppColors.border,
                          radius: 20,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${consumed.round()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow('Hedef', '${goal.round()} kcal', AppColors.textSecondary),
                  _StatRow('Tüketilen', '${consumed.round()} kcal', AppColors.calorieConsumed),
                  _StatRow('Yakılan', '${burned.round()} kcal', AppColors.calorieBurned),
                  const Divider(height: 16),
                  _StatRow('Kalan', '${remaining.round()} kcal', AppColors.calorieNet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final DailySummaryModel summary;
  const _MacroRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    double protein = 0, carbs = 0, fat = 0;
    for (final log in summary.logs) {
      final factor = log.grams / 100;
      protein += (log.foodItem.proteinG ?? 0) * factor;
      carbs += (log.foodItem.carbsG ?? 0) * factor;
      fat += (log.foodItem.fatG ?? 0) * factor;
    }

    return Row(
      children: [
        _MacroChip('Protein', '${protein.round()}g', Colors.blue),
        const SizedBox(width: 8),
        _MacroChip('Karbonhidrat', '${carbs.round()}g', Colors.orange),
        const SizedBox(width: 8),
        _MacroChip('Yağ', '${fat.round()}g', Colors.red),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String label;
  final List<FoodLogModel> logs;
  final void Function(String) onDelete;

  const _MealSection({required this.label, required this.logs, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final total = logs.fold(0.0, (sum, l) => sum + l.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            if (total > 0)
              Text('${total.round()} kcal', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        if (logs.isEmpty)
          const Text('Henüz eklenmedi', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
        else
          for (final log in logs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(log.foodItem.name),
              subtitle: Text('${log.grams.round()}g'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${log.calories.round()} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    onPressed: () => onDelete(log.id),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
