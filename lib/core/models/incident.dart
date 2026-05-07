enum IncidentStatus {
  reportReceived,
  dispatcherAssigned,
  ambulanceEnRoute,
  ambulanceNearby,
  arrived,
}

class Coordinates {
  const Coordinates({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory Coordinates.fromJson(Map<String, dynamic>? json) {
    return Coordinates(
      lat: (json?['lat'] as num?)?.toDouble() ?? 0,
      lng: (json?['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lat': lat,
        'lng': lng,
      };
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

extension IncidentStatusApi on IncidentStatus {
  String get apiValue {
    switch (this) {
      case IncidentStatus.reportReceived:
        return 'Reported';
      case IncidentStatus.dispatcherAssigned:
        return 'Assigned';
      case IncidentStatus.ambulanceEnRoute:
        return 'En Route';
      case IncidentStatus.ambulanceNearby:
        return 'Nearby';
      case IncidentStatus.arrived:
        return 'Arrived';
    }
  }

  static IncidentStatus fromApi(String? value) {
    final String normalized = (value ?? '').toLowerCase();
    if (normalized.contains('arrived') || normalized.contains('completed')) {
      return IncidentStatus.arrived;
    }
    if (normalized.contains('nearby')) {
      return IncidentStatus.ambulanceNearby;
    }
    if (normalized.contains('route') || normalized.contains('en_route')) {
      return IncidentStatus.ambulanceEnRoute;
    }
    if (normalized.contains('assign')) {
      return IncidentStatus.dispatcherAssigned;
    }
    return IncidentStatus.reportReceived;
  }
}

class Incident {
  Incident({
    required this.id,
    required this.title,
    required this.emergencyType,
    required this.severity,
    required this.location,
    required this.description,
    required this.createdAt,
    required this.status,
    required this.priority,
    required this.tags,
    required this.coordinates,
    this.backendStatus,
  });

  final String id;
  final String title;
  final String emergencyType;
  final String severity;
  final String location;
  final String description;
  final DateTime createdAt;
  final IncidentStatus status;
  final int priority;
  final List<String> tags;
  final Coordinates coordinates;
  final String? backendStatus;

  factory Incident.fromJson(Map<String, dynamic> json) {
    final List<String> tags = (json['tags'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic item) => item.toString())
        .toList(growable: false);
    final String? backendStatus = json['status']?.toString();
    return Incident(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Emergency incident',
      emergencyType: json['type']?.toString() ?? 'urgent',
      severity: _severityFromPriority(json['priority'] as int?),
      location: json['location']?.toString() ?? 'Unknown location',
      description: tags.join(', '),
      createdAt: _parseBackendTime(json['time']?.toString()),
      status: IncidentStatusApi.fromApi(backendStatus),
      priority: json['priority'] as int? ?? 3,
      tags: tags,
      coordinates:
          Coordinates.fromJson(json['coordinates'] as Map<String, dynamic>?),
      backendStatus: backendStatus,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'title': title,
      'location': location,
      'coordinates': coordinates.toJson(),
      'time': createdAt.toIso8601String(),
      'type': emergencyType,
      'tags': tags,
      'status': status.apiValue,
      'priority': priority,
    };
  }

  Incident copyWith({
    IncidentStatus? status,
    String? id,
    String? backendStatus,
  }) {
    return Incident(
      id: id ?? this.id,
      title: title,
      emergencyType: emergencyType,
      severity: severity,
      location: location,
      description: description,
      createdAt: createdAt,
      status: status ?? this.status,
      priority: priority,
      tags: tags,
      coordinates: coordinates,
      backendStatus: backendStatus ?? this.backendStatus,
    );
  }

  static Incident createDraft({
    required String emergencyType,
    required String severity,
    required String location,
    required String description,
    Coordinates coordinates = const Coordinates(lat: 0, lng: 0),
  }) {
    final DateTime now = DateTime.now();
    return Incident(
      id: '',
      title: '$emergencyType emergency',
      emergencyType: 'urgent',
      severity: severity,
      location: location,
      description: description,
      createdAt: now,
      status: IncidentStatus.reportReceived,
      priority: _priorityFromSeverity(severity),
      tags: <String>[
        'type:$emergencyType',
        'severity:$severity',
        if (description.trim().isNotEmpty) 'notes:${description.trim()}',
      ],
      coordinates: coordinates,
      backendStatus: 'Reported',
    );
  }
}

DateTime _parseBackendTime(String? value) {
  if (value == null || value.trim().isEmpty || value.contains('ago')) {
    return DateTime.now();
  }
  return DateTime.tryParse(value.replaceFirst(' ', 'T')) ?? DateTime.now();
}

String _severityFromPriority(int? priority) {
  switch (priority) {
    case 1:
      return 'Critical';
    case 2:
      return 'High';
    case 3:
      return 'Medium';
    default:
      return 'Low';
  }
}

int _priorityFromSeverity(String severity) {
  switch (severity.toLowerCase()) {
    case 'critical':
      return 1;
    case 'high':
      return 2;
    case 'medium':
      return 3;
    default:
      return 4;
  }
}
