import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../providers/activity_provider.dart';

class ActivityListScreen extends ConsumerWidget {
  const ActivityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Aktiviteler')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(RouteNames.activityTrack);
          ref.invalidate(activitiesProvider);
        },
        child: const Icon(Icons.play_arrow),
      ),
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_run_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz aktivite yok', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(activitiesProvider),
            child: ListView.builder(
              itemCount: activities.length,
              itemBuilder: (_, i) {
                final a = activities[i];
                final duration = Duration(seconds: a.durationSeconds);
                final durationStr = '${duration.inHours > 0 ? '${duration.inHours}sa ' : ''}${duration.inMinutes.remainder(60)}dk';
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.directions_run)),
                  title: Text(_activityLabel(a.activityType)),
                  subtitle: Text(durationStr +
                      (a.distanceMeters != null ? ' • ${(a.distanceMeters! / 1000).toStringAsFixed(2)} km' : '') +
                      (a.caloriesBurned != null ? ' • ${a.caloriesBurned!.round()} kcal' : '')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/main/activity/${a.id}'),
                );
              },
            ),
          );
        },
      ),
    );
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
