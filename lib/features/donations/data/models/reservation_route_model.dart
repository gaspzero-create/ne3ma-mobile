class ReservationRouteModel {
  final double distance;
  final double duration;
  final String geometry;
  final List<RouteStepModel> steps;

  const ReservationRouteModel({
    required this.distance,
    required this.duration,
    required this.geometry,
    this.steps = const [],
  });

  factory ReservationRouteModel.fromMap(Map<String, dynamic> map) {
    final rawSteps = map['steps'] as List? ?? const [];
    return ReservationRouteModel(
      distance: (map['distance'] as num?)?.toDouble() ?? 0,
      duration: (map['duration'] as num?)?.toDouble() ?? 0,
      geometry: map['geometry'] ?? '',
      steps: rawSteps
          .whereType<Map>()
          .map((step) => RouteStepModel.fromMap(Map<String, dynamic>.from(step)))
          .toList(),
    );
  }
}

class RouteStepModel {
  final double distance;
  final double duration;
  final String instruction;
  final String name;

  const RouteStepModel({
    required this.distance,
    required this.duration,
    required this.instruction,
    required this.name,
  });

  factory RouteStepModel.fromMap(Map<String, dynamic> map) {
    return RouteStepModel(
      distance: (map['distance'] as num?)?.toDouble() ?? 0,
      duration: (map['duration'] as num?)?.toDouble() ?? 0,
      instruction: map['instruction'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
