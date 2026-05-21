import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/activity_model.dart';
import '../providers/activity_provider.dart';

class ActivityListScreen extends ConsumerWidget {
  const ActivityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider);

    return Scaffold(
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (activities) => CustomScrollView(
          slivers: [
            _ActivitySliverAppBar(
              onRefresh: () => ref.invalidate(activitiesProvider),
              activities: activities,
            ),
            if (activities.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList.separated(
                  separatorBuilder: (context, i) => const SizedBox(height: 10),
                  itemCount: activities.length,
                  itemBuilder: (_, i) => _ActivityCard(activity: activities[i]),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(RouteNames.activityTrack);
          ref.invalidate(activitiesProvider);
        },
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Başlat', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ActivitySliverAppBar extends StatelessWidget {
  final VoidCallback onRefresh;
  final List<ActivityModel> activities;

  const _ActivitySliverAppBar({required this.onRefresh, required this.activities});

  @override
  Widget build(BuildContext context) {
    final totalCalories = activities.fold<double>(0, (s, a) => s + (a.caloriesBurned ?? 0));
    final totalSecs = activities.fold<int>(0, (s, a) => s + a.durationSeconds);
    final totalKm = activities.fold<double>(0, (s, a) => s + ((a.distanceMeters ?? 0) / 1000));
    final hasStats = activities.isNotEmpty;

    return SliverAppBar(
      expandedHeight: hasStats ? 180 : null,
      pinned: true,
      stretch: false,
      backgroundColor: AppColors.secondaryDark,
      title: const Text(
        'Aktiviteler',
        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
      ),
      flexibleSpace: hasStats
          ? FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Row(
                      children: [
                        _SummaryTile(
                          icon: Icons.local_fire_department_outlined,
                          value: '${totalCalories.round()}',
                          unit: 'kcal',
                        ),
                        const SizedBox(width: 10),
                        _SummaryTile(
                          icon: Icons.timer_outlined,
                          value: _fmtDur(totalSecs),
                          unit: 'süre',
                        ),
                        if (totalKm > 0) ...[
                          const SizedBox(width: 10),
                          _SummaryTile(
                            icon: Icons.straighten_outlined,
                            value: totalKm.toStringAsFixed(1),
                            unit: 'km',
                          ),
                        ],
                        const SizedBox(width: 10),
                        _SummaryTile(
                          icon: Icons.sports_score_outlined,
                          value: '${activities.length}',
                          unit: 'aktivite',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
              ),
            ),
      leading: const SizedBox.shrink(),
      automaticallyImplyLeading: false,
    );
  }

  String _fmtDur(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    return h > 0 ? '${h}sa ${m}dk' : '${m}dk';
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  const _SummaryTile({required this.icon, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(22),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              unit,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                size: 48,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz aktivite yok',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aşağıdaki butona basarak\nilk aktiviteni başlat!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: activity.durationSeconds);
    final durationStr = duration.inHours > 0
        ? '${duration.inHours}sa ${duration.inMinutes.remainder(60)}dk'
        : '${duration.inMinutes}dk';

    final color = _activityColor(activity.activityType);
    final dateStr = _formatDate(activity.startedAt);

    return Card(
      child: InkWell(
        onTap: () => context.push('/main/activity/${activity.id}'),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_activityIcon(activity.activityType), color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activityLabel(activity.activityType),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: [
                        _Badge(Icons.timer_outlined, durationStr, color),
                        if (activity.distanceMeters != null)
                          _Badge(
                            Icons.straighten_outlined,
                            '${(activity.distanceMeters! / 1000).toStringAsFixed(2)} km',
                            color,
                          ),
                        if (activity.caloriesBurned != null)
                          _Badge(
                            Icons.local_fire_department_outlined,
                            '${activity.caloriesBurned!.round()} kcal',
                            color,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.border, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr);
      return DateFormat('d MMMM, EEEE', 'tr').format(dt);
    } catch (_) {
      return isoStr;
    }
  }

  Color _activityColor(String type) {
    const map = {
      'running': Color(0xFFEF4444),
      'walking': Color(0xFF10B981),
      'cycling': Color(0xFF3B82F6),
      'swimming': Color(0xFF06B6D4),
      'rowing': Color(0xFF8B5CF6),
      'hiking': Color(0xFF84CC16),
      'jump_rope': Color(0xFFF59E0B),
      'yoga': Color(0xFFEC4899),
      'weight_training': Color(0xFF6366F1),
    };
    return map[type] ?? AppColors.secondary;
  }

  IconData _activityIcon(String type) {
    const icons = {
      'running': Icons.directions_run_rounded,
      'walking': Icons.directions_walk_rounded,
      'cycling': Icons.directions_bike_rounded,
      'swimming': Icons.pool_rounded,
      'rowing': Icons.rowing_rounded,
      'hiking': Icons.terrain_rounded,
      'jump_rope': Icons.sports_gymnastics,
      'yoga': Icons.self_improvement_rounded,
      'weight_training': Icons.fitness_center_rounded,
    };
    return icons[type] ?? Icons.sports_rounded;
  }

  String _activityLabel(String type) {
    const labels = {
      'running': 'Koşu',
      'walking': 'Yürüyüş',
      'cycling': 'Bisiklet',
      'swimming': 'Yüzme',
      'rowing': 'Kürek',
      'hiking': 'Trekking',
      'jump_rope': 'İp Atlama',
      'yoga': 'Yoga',
      'weight_training': 'Ağırlık',
    };
    return labels[type] ?? type;
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color.withAlpha(180)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withAlpha(200), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
