import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/activity_provider.dart';

class ActivityTrackingScreen extends ConsumerStatefulWidget {
  const ActivityTrackingScreen({super.key});

  @override
  ConsumerState<ActivityTrackingScreen> createState() => _ActivityTrackingScreenState();
}

class _ActivityTrackingScreenState extends ConsumerState<ActivityTrackingScreen> {
  final _mapCtrl = MapController();
  StreamSubscription<Position>? _positionSub;
  Timer? _timer;
  String _activityType = 'running';
  Position? _lastPosition;
  final List<LatLng> _polyPoints = [];

  final _activityTypes = {
    'running': 'Koşu',
    'walking': 'Yürüyüş',
    'cycling': 'Bisiklet',
    'swimming': 'Yüzme',
    'hiking': 'Trekking',
    'weight_training': 'Ağırlık',
    'other': 'Diğer',
  };

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum izni gerekli')));
      return;
    }

    ref.read(trackingProvider.notifier).start();
    _polyPoints.clear();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = ref.read(trackingProvider);
      if (state.isTracking) {
        ref.read(trackingProvider.notifier).tick(
          DateTime.now().difference(state.startedAt!),
        );
      }
    });

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((position) {
      double addedDistance = 0;
      if (_lastPosition != null) {
        addedDistance = _haversineDistance(
          _lastPosition!.latitude, _lastPosition!.longitude,
          position.latitude, position.longitude,
        );
      }
      _lastPosition = position;

      final point = LatLng(position.latitude, position.longitude);
      setState(() => _polyPoints.add(point));

      ref.read(trackingProvider.notifier).addPoint(
        position.latitude,
        position.longitude,
        addedDistance,
      );

      _mapCtrl.move(point, 16);
    });
  }

  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<void> _stopAndSave() async {
    _positionSub?.cancel();
    _timer?.cancel();

    final state = ref.read(trackingProvider);
    ref.read(trackingProvider.notifier).stop();

    if (state.startedAt == null) return;

    final endedAt = DateTime.now();
    final points = state.points
        .map((p) => {'lat': p['lat']!, 'lng': p['lng']!})
        .toList();

    try {
      await ref.read(activityDatasourceProvider).createActivity(
            activityType: _activityType,
            startedAt: state.startedAt!,
            endedAt: endedAt,
            durationSeconds: state.elapsed.inSeconds,
            distanceMeters: state.distanceMeters > 0 ? state.distanceMeters : null,
            routePoints: points.isNotEmpty ? points : null,
          );
      ref.read(trackingProvider.notifier).reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aktivite kaydedildi!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingProvider);
    final elapsed = tracking.elapsed;
    final elapsedStr =
        '${elapsed.inHours.toString().padLeft(2, '0')}:${elapsed.inMinutes.remainder(60).toString().padLeft(2, '0')}:${elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Aktivite Takibi')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: const MapOptions(initialCenter: LatLng(39.92, 32.85), initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.metufit.app',
              ),
              if (_polyPoints.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(points: _polyPoints, color: AppColors.primary, strokeWidth: 4),
                ]),
              if (_polyPoints.isNotEmpty)
                MarkerLayer(markers: [
                  Marker(
                    point: _polyPoints.last,
                    child: const Icon(Icons.my_location, color: AppColors.primary, size: 32),
                  ),
                ]),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!tracking.isTracking)
                    DropdownButton<String>(
                      value: _activityType,
                      isExpanded: true,
                      items: _activityTypes.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _activityType = v!),
                    ),
                  if (tracking.isTracking) ...[
                    Text(elapsedStr,
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat('Mesafe', '${(tracking.distanceMeters / 1000).toStringAsFixed(2)} km'),
                        _Stat('Süre', elapsedStr),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: tracking.isTracking
                        ? FilledButton.tonal(
                            onPressed: _stopAndSave,
                            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade100),
                            child: const Text('Durdur ve Kaydet', style: TextStyle(color: Colors.red)),
                          )
                        : FilledButton(
                            onPressed: _startTracking,
                            child: const Text('Başlat'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
