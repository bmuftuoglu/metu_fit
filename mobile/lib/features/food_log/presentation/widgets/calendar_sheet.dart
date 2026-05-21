import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/food_provider.dart';

class CalendarSheet extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarSheet({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  ConsumerState<CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends ConsumerState<CalendarSheet> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  String get _monthKey => DateFormat('yyyy-MM').format(_viewMonth);

  void _prevMonth() {
    setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));
  }

  void _nextMonth() {
    final now = DateTime.now();
    final isCurrentOrFuture = _viewMonth.year > now.year ||
        (_viewMonth.year == now.year && _viewMonth.month >= now.month);
    if (!isCurrentOrFuture) {
      setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final caloriesAsync = ref.watch(monthlyCaloriesProvider(_monthKey));
    final now = DateTime.now();
    final isCurrentMonth =
        _viewMonth.year == now.year && _viewMonth.month == now.month;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy', 'tr').format(_viewMonth),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: isCurrentMonth ? null : _nextMonth,
                  color: isCurrentMonth ? AppColors.border : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'].map((d) {
                return Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          caloriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, st) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('Veriler yüklenemedi')),
            ),
            data: (calories) => _CalendarGrid(
              viewMonth: _viewMonth,
              selectedDate: widget.selectedDate,
              calories: calories,
              onDateSelected: (date) {
                widget.onDateSelected(date);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime viewMonth;
  final DateTime selectedDate;
  final Map<String, double> calories;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarGrid({
    required this.viewMonth,
    required this.selectedDate,
    required this.calories,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final selectedKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
    final daysInMonth = DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
    final offset = firstDay.weekday - 1; // Pazartesi = 0
    final totalCells = offset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: List.generate(rows, (rowIndex) {
          return Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - offset + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 64));
              }

              final date = DateTime(viewMonth.year, viewMonth.month, dayNumber);
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
              final isToday = dateKey == todayKey;
              final isSelected = dateKey == selectedKey;
              final cal = calories[dateKey] ?? 0.0;
              final hasCal = cal > 0;

              Color bgColor = Colors.transparent;
              if (isSelected) {
                bgColor = AppColors.primary;
              } else if (isToday) {
                bgColor = AppColors.primary.withAlpha(18);
              }

              Color dayNumColor = AppColors.textPrimary;
              if (isSelected) {
                dayNumColor = Colors.white;
              } else if (isFuture) {
                dayNumColor = AppColors.border;
              }

              return Expanded(
                child: GestureDetector(
                  onTap: isFuture ? null : () => onDateSelected(date),
                  child: Container(
                    height: 64,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isToday || isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: dayNumColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (!isFuture && hasCal)
                          Text(
                            '${cal.round()}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white70
                                  : AppColors.secondary,
                            ),
                          )
                        else if (!isFuture)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white38
                                  : AppColors.border,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}
