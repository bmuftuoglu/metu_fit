import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/food_item_model.dart';
import '../providers/food_provider.dart';
import '../widgets/calendar_sheet.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  DateTime _selectedDate = DateTime.now();
  DailySummaryModel? _lastSummary;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefetchRecentDays());
  }

  void _prefetchRecentDays() {
    final now = DateTime.now();
    for (int i = 1; i <= 30; i++) {
      final key = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
      ref.read(dailySummaryProvider(key).future).ignore();
    }
  }

  void _changeDate(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
  }

  void _openCalendar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CalendarSheet(
        selectedDate: _selectedDate,
        onDateSelected: (date) => setState(() => _selectedDate = date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dailySummaryProvider(_dateKey));

    final freshSummary = summaryAsync.valueOrNull;
    if (freshSummary != null) _lastSummary = freshSummary;
    final displaySummary = freshSummary ?? _lastSummary;
    final isLoading = summaryAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Takip'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              onPressed: () async {
                await context.push(RouteNames.foodSearch, extra: _dateKey);
                ref.invalidate(dailySummaryProvider(_dateKey));
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ekle'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withAlpha(15),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _DateBar(
            date: _selectedDate,
            onPrev: () => _changeDate(-1),
            onNext: () => _changeDate(1),
            isLoading: isLoading,
            onCalendarTap: _openCalendar,
          ),
          Expanded(
            child: displaySummary == null
                ? const Center(child: CircularProgressIndicator())
                : _Body(
                    summary: displaySummary,
                    isLoading: isLoading,
                    onDeleteLog: (logId) async {
                      await ref.read(foodDatasourceProvider).deleteFoodLog(logId);
                      ref.invalidate(dailySummaryProvider(_dateKey));
                    },
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
  final VoidCallback onCalendarTap;
  final bool isLoading;

  const _DateBar({
    required this.date,
    required this.onPrev,
    required this.onNext,
    required this.onCalendarTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrev,
            style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
          ),
          GestureDetector(
            onTap: onCalendarTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isToday ? 'Bugün' : DateFormat('d MMMM yyyy', 'tr').format(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: isToday ? null : onNext,
            style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final DailySummaryModel summary;
  final void Function(String) onDeleteLog;
  final bool isLoading;

  const _Body({required this.summary, required this.onDeleteLog, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final goal = summary.goalCalories?.toDouble() ?? 2000;
    final consumed = summary.consumedCalories;
    final burned = summary.burnedCalories;
    const mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        _CalorieCard(consumed: consumed, burned: burned, goal: goal),
        const SizedBox(height: 14),
        _MacroRow(summary: summary),
        const SizedBox(height: 20),
        const _SectionHeader('Öğünler'),
        const SizedBox(height: 10),
        for (final meal in mealTypes) ...[
          _MealSection(
            label: mealLabels[meal]!,
            icon: mealIcons[meal]!,
            logs: summary.logs.where((l) => l.mealType == meal).toList(),
            onDelete: onDeleteLog,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _CalorieCard extends StatefulWidget {
  final double consumed;
  final double burned;
  final double goal;

  const _CalorieCard({
    required this.consumed,
    required this.burned,
    required this.goal,
  });

  @override
  State<_CalorieCard> createState() => _CalorieCardState();
}

class _CalorieCardState extends State<_CalorieCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_CalorieCard old) {
    super.didUpdateWidget(old);
    if (old.consumed != widget.consumed ||
        old.burned != widget.burned ||
        old.goal != widget.goal) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value;
        final consumed = widget.consumed * t;
        final burned = widget.burned * t;
        final goal = widget.goal;
        final remaining = (goal - consumed + burned).clamp(0.0, double.infinity);
        final fraction = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;

        return Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            children: [
              SizedBox(
                width: 156,
                height: 156,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        sectionsSpace: 0,
                        centerSpaceRadius: 60,
                        sections: [
                          PieChartSectionData(
                            value: fraction.clamp(0.001, 1.0),
                            color: Colors.white,
                            radius: 16,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (1 - fraction).clamp(0.001, 1.0),
                            color: Colors.white.withAlpha(35),
                            radius: 16,
                            showTitle: false,
                          ),
                        ],
                      ),
                      duration: Duration.zero,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${remaining.round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'kcal kalan',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _CalStat(Icons.restaurant_outlined, 'Tüketilen', consumed.round()),
                  _VertDivider(),
                  _CalStat(Icons.local_fire_department_outlined, 'Yakılan', burned.round()),
                  _VertDivider(),
                  _CalStat(Icons.flag_outlined, 'Hedef', goal.round()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CalStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  const _CalStat(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white60, size: 17),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 44, color: Colors.white.withAlpha(35));
  }
}

class _MacroRow extends StatefulWidget {
  final DailySummaryModel summary;
  const _MacroRow({required this.summary});

  @override
  State<_MacroRow> createState() => _MacroRowState();
}

class _MacroRowState extends State<_MacroRow> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_MacroRow old) {
    super.didUpdateWidget(old);
    if (old.summary != widget.summary) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double protein = 0, carbs = 0, fat = 0;
    for (final log in widget.summary.logs) {
      final factor = log.grams / 100;
      protein += (log.foodItem.proteinG ?? 0) * factor;
      carbs += (log.foodItem.carbsG ?? 0) * factor;
      fat += (log.foodItem.fatG ?? 0) * factor;
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value;
        return Row(
          children: [
            _MacroChip('Protein', '${(protein * t).round()}g', const Color(0xFF3B82F6), Icons.egg_outlined),
            const SizedBox(width: 8),
            _MacroChip('Karbonhidrat', '${(carbs * t).round()}g', const Color(0xFFF59E0B), Icons.grain),
            const SizedBox(width: 8),
            _MacroChip('Yağ', '${(fat * t).round()}g', const Color(0xFFEF4444), Icons.water_drop_outlined),
          ],
        );
      },
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _MacroChip(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<FoodLogModel> logs;
  final void Function(String) onDelete;

  const _MealSection({
    required this.label,
    required this.icon,
    required this.logs,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final total = logs.fold(0.0, (sum, l) => sum + l.calories);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const Spacer(),
                if (total > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${total.round()} kcal',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (logs.isNotEmpty) const Divider(height: 1),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: const Text(
                'Henüz eklenmedi',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          for (final log in logs) _FoodLogTile(log: log, onDelete: onDelete),
        ],
      ),
    );
  }
}

class _FoodLogTile extends StatelessWidget {
  final FoodLogModel log;
  final void Function(String) onDelete;
  const _FoodLogTile({required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.restaurant_outlined, size: 16, color: AppColors.textSecondary),
      ),
      title: Text(
        log.foodItem.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${log.grams.round()} g',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${log.calories.round()} kcal',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
            onPressed: () => onDelete(log.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
