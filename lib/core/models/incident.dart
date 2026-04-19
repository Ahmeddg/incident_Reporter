enum IncidentStatus {
  reportReceived,
  dispatcherAssigned,
  ambulanceEnRoute,
  ambulanceNearby,
  arrived,
}

extension IncidentStatusLabel on IncidentStatus {
  String get label {
    switch (this) {
      case IncidentStatus.reportReceived:
        return 'Report Received';
      case IncidentStatus.dispatcherAssigned:
        return 'Dispatcher Assigned';
      case IncidentStatus.ambulanceEnRoute:
        return 'Ambulance En Route';
      case IncidentStatus.ambulanceNearby:
        return 'Ambulance Nearby';
      case IncidentStatus.arrived:
        return 'Ambulance Arrived';
    }
  }
}

class Incident {
  Incident({
    required this.id,
    required this.emergencyType,
    required this.severity,
    required this.location,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String emergencyType;
  final String severity;
  final String location;
  final String description;
  final DateTime createdAt;
  final IncidentStatus status;

  Incident copyWith({
    IncidentStatus? status,
  }) {
    return Incident(
      id: id,
      emergencyType: emergencyType,
      severity: severity,
      location: location,
      description: description,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
