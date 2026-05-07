import 'package:incident_reporter/core/models/coordinates.dart';

class DispatchRoute {
  const DispatchRoute({
    required this.vehicleId,
    required this.vehicleName,
    required this.incidentId,
    required this.incidentTitle,
    required this.origin,
    required this.destination,
    required this.path,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.trafficLevel,
    required this.turnByTurn,
  });

  final String vehicleId;
  final String vehicleName;
  final String incidentId;
  final String incidentTitle;
  final CoordinatesModel origin;
  final CoordinatesModel destination;
  final List<CoordinatesModel> path;
  final double distanceKm;
  final int estimatedMinutes;
  final String? trafficLevel;
  final List<String> turnByTurn;

  factory DispatchRoute.fromJson(Map<String, dynamic> json) {
    return DispatchRoute(
      vehicleId: json['vehicleId']?.toString() ?? '',
      vehicleName: json['vehicleName']?.toString() ?? '',
      incidentId: json['incidentId']?.toString() ?? '',
      incidentTitle: json['incidentTitle']?.toString() ?? 'Emergency incident',
      origin: CoordinatesModel.fromJson(
        (json['origin'] as Map<String, dynamic>?) ?? const {},
      ),
      destination: CoordinatesModel.fromJson(
        (json['destination'] as Map<String, dynamic>?) ?? const {},
      ),
      path: ((json['path'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CoordinatesModel.fromJson)
          .toList(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
      trafficLevel: json['trafficLevel']?.toString(),
      turnByTurn: ((json['turnByTurn'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(),
    );
  }
}
