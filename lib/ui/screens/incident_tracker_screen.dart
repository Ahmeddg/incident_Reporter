import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/core/models/chat_message.dart';
import 'package:incident_reporter/core/models/incident.dart';
import 'package:incident_reporter/ui/controllers/emergency_controller.dart';
import 'package:incident_reporter/ui/screens/notifications_screen.dart';

class IncidentTrackerScreen extends StatefulWidget {
  const IncidentTrackerScreen({super.key});

  @override
  State<IncidentTrackerScreen> createState() => _IncidentTrackerScreenState();
}

class _IncidentTrackerScreenState extends State<IncidentTrackerScreen> {
  final EmergencyController _controller = Get.find<EmergencyController>();
  final TextEditingController _messageController = TextEditingController();

  final List<String> _quickPrompts = <String>[
    'I am bleeding',
    'Breathing issue',
    'Unconscious person',
    'Fire nearby',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    _controller.sendUserMessage(_messageController.text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
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
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: Obx(
        () {
          final Incident? incident = _controller.activeIncident.value;
          if (incident == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F3F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        size: 36,
                        color: Color(0xFF16697A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No active incident',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    const Text('No emergency case is being tracked right now.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _IncidentSummaryCard(incident: incident),
              const SizedBox(height: 14),
              _StatusTimeline(currentStatus: incident.status),
              const SizedBox(height: 14),
              _ChatCard(
                controller: _controller,
                quickPrompts: _quickPrompts,
                messageController: _messageController,
                onSend: _sendMessage,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IncidentSummaryCard extends StatelessWidget {
  const _IncidentSummaryCard({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD8D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4D5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: Color(0xFFC2410C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Live Emergency Case',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Current: ${incident.status.label}',
                      style: const TextStyle(
                        color: Color(0xFFC2410C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Type', value: incident.emergencyType),
          _SummaryRow(label: 'Severity', value: incident.severity),
          _SummaryRow(label: 'Location', value: incident.location),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

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
            width: 74,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF637381),
                fontWeight: FontWeight.w800,
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

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.currentStatus});

  final IncidentStatus currentStatus;

  static const List<IncidentStatus> _allStatuses = <IncidentStatus>[
    IncidentStatus.reportReceived,
    IncidentStatus.dispatcherAssigned,
    IncidentStatus.ambulanceEnRoute,
    IncidentStatus.ambulanceNearby,
    IncidentStatus.arrived,
  ];

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _allStatuses.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.route_outlined, color: Color(0xFF16697A)),
              SizedBox(width: 8),
              Text(
                'Ambulance Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._allStatuses
              .asMap()
              .entries
              .map((MapEntry<int, IncidentStatus> entry) {
            final bool done = entry.key <= currentIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFFEAF7EF)
                          : const Color(0xFFF1F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : Icons.circle_outlined,
                      size: 17,
                      color: done ? const Color(0xFF0C8F4E) : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entry.value.label,
                        style: TextStyle(
                          fontWeight: done ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.controller,
    required this.quickPrompts,
    required this.messageController,
    required this.onSend,
  });

  final EmergencyController controller;
  final List<String> quickPrompts;
  final TextEditingController messageController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.support_agent_rounded, color: Color(0xFF16697A)),
              SizedBox(width: 8),
              Text(
                'Safety Chat Assistant',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickPrompts
                .map(
                  (String prompt) => ActionChip(
                    label: Text(prompt),
                    onPressed: () => controller.sendQuickGuidance(prompt),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Obx(
            () {
              final List<ChatMessage> messages = controller.chatMessages;
              return SizedBox(
                height: 250,
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ChatMessage message = messages[index];
                    final bool isUser = message.sender == MessageSender.user;
                    final bool isSystem =
                        message.sender == MessageSender.system;
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isSystem
                              ? const Color(0xFFF3F4F6)
                              : isUser
                                  ? const Color(0xFFDFF5EA)
                                  : const Color(0xFFE2F3F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(message.text),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: 'Describe symptoms or ask for guidance',
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onSend,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF16697A),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
