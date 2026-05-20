import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/activity_provider.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final String activityId;
  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityDetailProvider(activityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Aktivite Detayı')),
      body: activityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (activity) {
          final duration = Duration(seconds: activity.durationSeconds);
          final durationStr =
              '${duration.inHours > 0 ? '${duration.inHours}sa ' : ''}${duration.inMinutes.remainder(60)}dk';

          final routePoints = activity.route?.routePoints
              .map((p) {
                final map = p as Map<String, dynamic>;
                return LatLng((map['lat'] as num).toDouble(), (map['lng'] as num).toDouble());
              })
              .toList();

          return ListView(
            children: [
              if (routePoints != null && routePoints.length >= 2)
                SizedBox(
                  height: 250,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: routePoints[routePoints.length ~/ 2],
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.metufit.app',
                      ),
                      PolylineLayer(polylines: [
                        Polyline(points: routePoints, color: AppColors.primary, strokeWidth: 4),
                      ]),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoCard(items: [
                      _InfoItem('Aktivite', _activityLabel(activity.activityType)),
                      _InfoItem('Süre', durationStr),
                      if (activity.distanceMeters != null)
                        _InfoItem('Mesafe', '${(activity.distanceMeters! / 1000).toStringAsFixed(2)} km'),
                      if (activity.caloriesBurned != null)
                        _InfoItem('Yakılan Kalori', '${activity.caloriesBurned!.round()} kcal'),
                      if (activity.avgSpeedKmh != null)
                        _InfoItem('Ort. Hız', '${activity.avgSpeedKmh!.toStringAsFixed(1)} km/sa'),
                    ]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _activityLabel(String type) {
    const labels = {
      'running': 'Koşu', 'walking': 'Yürüyüş', 'cycling': 'Bisiklet',
      'swimming': 'Yüzme', 'rowing': 'Kürek', 'hiking': 'Trekking',
      'jump_rope': 'İp Atlama', 'yoga': 'Yoga', 'weight_training': 'Ağırlık',
    };
    return labels[type] ?? type;
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.label, style: const TextStyle(color: AppColors.textSecondary)),
                        Text(item.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}
