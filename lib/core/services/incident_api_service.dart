import 'dart:convert';

import 'package:incident_reporter/core/api/api_client.dart';
import 'package:incident_reporter/core/models/incident.dart';

class IncidentApiService {
  IncidentApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Incident>> fetchIncidents() async {
    final response = await _apiClient.get('/api/incidents');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Could not load incidents (${response.statusCode}).');
    }

    final List<dynamic> decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((dynamic item) => Incident.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Incident> createIncident(Incident incident) async {
    final response = await _apiClient.post(
      '/api/incidents',
      incident.toCreateJson(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Could not create incident (${response.statusCode}).');
    }

    return Incident.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
