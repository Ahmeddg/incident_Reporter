import 'package:flutter/material.dart';
import 'package:incident_reporter/core/models/app_notification.dart';
import 'package:incident_reporter/core/models/incident.dart';
import 'package:incident_reporter/core/services/mock_emergency_service.dart';
import 'package:incident_reporter/ui/screens/incident_tracker_screen.dart';
import 'package:incident_reporter/ui/screens/notifications_screen.dart';
import 'package:incident_reporter/ui/screens/report_incident_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MockEmergencyService service = MockEmergencyService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Dashboard'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ValueListenableBuilder<Incident?>(
        valueListenable: service.activeIncident,
        builder: (BuildContext context, Incident? incident, _) {
          return ValueListenableBuilder<List<AppNotification>>(
            valueListenable: service.notifications,
            builder: (BuildContext context, List<AppNotification> alerts, __) {
              final AppNotification? latest =
                  alerts.isEmpty ? null : alerts.first;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  _HeroCard(activeIncident: incident),
                  const SizedBox(height: 18),
                  if (latest != null) ...<Widget>[
                    _LatestAlertCard(alert: latest),
                    const SizedBox(height: 18),
                  ],
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ReportIncidentScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.sos_rounded),
                      label: const Text('Report Emergency'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: incident == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const IncidentTrackerScreen(),
                                ),
                              );
                            },
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: Text(
                        incident == null
                            ? 'No Active Incident'
                            : 'Open Active Incident',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (incident != null) _ActiveIncidentCard(incident: incident),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.activeIncident});

  final Incident? activeIncident;

  @override
  Widget build(BuildContext context) {
    final bool hasActive = activeIncident != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0F3460), Color(0xFF355C7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Emergency Assistant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasActive
                ? 'Responders are handling your active report.'
                : 'Send an emergency alert and receive guidance instantly.',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _LatestAlertCard extends StatelessWidget {
  const _LatestAlertCard({required this.alert});

  final AppNotification alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD9A8)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.notification_important_outlined,
              color: Color(0xFF9C5700)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(alert.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(alert.message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveIncidentCard extends StatelessWidget {
  const _ActiveIncidentCard({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Current Incident',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text('Type: ${incident.emergencyType}'),
          Text('Severity: ${incident.severity}'),
          Text('Location: ${incident.location}'),
          Text('Status: ${incident.status.label}'),
        ],
      ),
    );
  }
}
