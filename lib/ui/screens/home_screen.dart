import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/core/models/app_notification.dart';
import 'package:incident_reporter/core/models/incident.dart';
import 'package:incident_reporter/ui/controllers/emergency_controller.dart';
import 'package:incident_reporter/ui/screens/incident_tracker_screen.dart';
import 'package:incident_reporter/ui/screens/notifications_screen.dart';
import 'package:incident_reporter/ui/screens/report_incident_screen.dart';

class HomeScreen extends GetView<EmergencyController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Command'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: controller.loadIncidents,
            tooltip: 'Refresh incidents',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Obx(() {
        final Incident? incident = controller.activeIncident.value;
        final List<AppNotification> alerts = controller.notifications;
        final AppNotification? latest = alerts.isEmpty ? null : alerts.first;
        final int unreadCount =
            alerts.where((AppNotification item) => !item.isRead).length;

        if (controller.isLoading.value && incident == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadIncidents,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              _HeroCard(
                activeIncident: incident,
                unreadCount: unreadCount,
                onReport: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReportIncidentScreen(),
                    ),
                  );
                },
                onTrack: incident == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const IncidentTrackerScreen(),
                          ),
                        );
                      },
              ),
              if (controller.errorMessage.value.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                _ErrorCard(message: controller.errorMessage.value),
              ],
              const SizedBox(height: 16),
              if (latest != null) _LatestAlertCard(alert: latest),
              const SizedBox(height: 24),
              if (incident != null) _ActiveIncidentCard(incident: incident),
            ],
          ),
        );
      }),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFC9C9)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFB42318)),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.activeIncident,
    required this.unreadCount,
    required this.onReport,
    required this.onTrack,
  });

  final Incident? activeIncident;
  final int unreadCount;
  final VoidCallback onReport;
  final VoidCallback? onTrack;

  @override
  Widget build(BuildContext context) {
    final bool hasActive = activeIncident != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0B2E36), Color(0xFF16697A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      hasActive ? 'Active response running' : 'Ready to report',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasActive
                          ? activeIncident!.status.label
                          : 'Emergency support, location, and guidance in one flow',
                      style: const TextStyle(color: Color(0xFFD6EFF2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _MetricPill(
                label: 'Open case',
                value: hasActive ? '1' : '0',
                icon: Icons.assignment_turned_in_outlined,
              ),
              const SizedBox(width: 10),
              _MetricPill(
                label: 'Unread alerts',
                value: unreadCount.toString(),
                icon: Icons.campaign_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.sos_rounded),
                    label: const Text('Report Emergency'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A3D),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: onTrack,
                  icon: const Icon(Icons.route_outlined),
                  label: const Text('Track'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white38,
                    side: const BorderSide(color: Color(0xFF8CC8D2)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: const Color(0xFFD6EFF2), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD6EFF2),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD9A8)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notification_important_outlined,
              color: Color(0xFF9C5700),
            ),
          ),
          const SizedBox(width: 12),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Current Incident',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  incident.status.label,
                  style: const TextStyle(
                    color: Color(0xFF0C8F4E),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _IncidentRow(label: 'Type', value: incident.emergencyType),
          _IncidentRow(label: 'Severity', value: incident.severity),
          _IncidentRow(label: 'Location', value: incident.location),
        ],
      ),
    );
  }
}

class _IncidentRow extends StatelessWidget {
  const _IncidentRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF637381),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
