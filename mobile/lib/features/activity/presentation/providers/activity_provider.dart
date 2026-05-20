import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/activity_remote_datasource.dart';
import '../../data/models/activity_model.dart';

final activityDatasourceProvider = Provider((_) => ActivityRemoteDatasource());

final activitiesProvider = FutureProvider<List<ActivityModel>>((ref) {
  return ref.read(activityDatasourceProvider).getActivities();
});

final activityDetailProvider = FutureProvider.family<ActivityModel, String>((ref, id) {
  return ref.read(activityDatasourceProvider).getActivity(id);
});

class TrackingState {
  final bool isTracking;
  final DateTime? startedAt;
  final Duration elapsed;
  final double distanceMeters;
  final List<Map<String, double>> points;

  const TrackingState({
    this.isTracking = false,
    this.startedAt,
    this.elapsed = Duration.zero,
    this.distanceMeters = 0,
    this.points = const [],
  });

  TrackingState copyWith({
    bool? isTracking,
    DateTime? startedAt,
    Duration? elapsed,
    double? distanceMeters,
    List<Map<String, double>>? points,
  }) =>
      TrackingState(
        isTracking: isTracking ?? this.isTracking,
        startedAt: startedAt ?? this.startedAt,
        elapsed: elapsed ?? this.elapsed,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        points: points ?? this.points,
      );
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier() : super(const TrackingState());

  void start() => state = TrackingState(isTracking: true, startedAt: DateTime.now());

  void tick(Duration elapsed) => state = state.copyWith(elapsed: elapsed);

  void addPoint(double lat, double lng, double distance) {
    state = state.copyWith(
      points: [...state.points, {'lat': lat, 'lng': lng}],
      distanceMeters: state.distanceMeters + distance,
    );
  }

  void stop() => state = state.copyWith(isTracking: false);

  void reset() => state = const TrackingState();
}

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>(
  (_) => TrackingNotifier(),
);
