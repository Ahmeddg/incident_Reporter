import 'package:flutter/material.dart';
import 'package:incident_reporter/core/models/chat_message.dart';
import 'package:incident_reporter/core/models/incident.dart';
import 'package:incident_reporter/core/services/mock_emergency_service.dart';
import 'package:incident_reporter/ui/screens/notifications_screen.dart';

class IncidentTrackerScreen extends StatefulWidget {
  const IncidentTrackerScreen({super.key});

  @override
  State<IncidentTrackerScreen> createState() => _IncidentTrackerScreenState();
}

class _IncidentTrackerScreenState extends State<IncidentTrackerScreen> {
  final MockEmergencyService _service = MockEmergencyService();
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
    _service.sendUserMessage(_messageController.text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Tracking'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: ValueListenableBuilder<Incident?>(
        valueListenable: _service.activeIncident,
        builder: (BuildContext context, Incident? incident, _) {
          if (incident == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.info_outline, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                        'No active incident is being tracked right now.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
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
                service: _service,
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
        color: const Color(0xFFFFF3F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD8D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Live Emergency Case',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('Type: ${incident.emergencyType}'),
          Text('Severity: ${incident.severity}'),
          Text('Location: ${incident.location}'),
          const SizedBox(height: 6),
          Text(
            'Current: ${incident.status.label}',
            style: const TextStyle(fontWeight: FontWeight.w700),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Ambulance Progress',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                children: <Widget>[
                  Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? const Color(0xFF0C8F4E) : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    entry.value.label,
                    style: TextStyle(
                      fontWeight: done ? FontWeight.w700 : FontWeight.w500,
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
    required this.service,
    required this.quickPrompts,
    required this.messageController,
    required this.onSend,
  });

  final MockEmergencyService service;
  final List<String> quickPrompts;
  final TextEditingController messageController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Safety Chat Assistant',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickPrompts
                .map(
                  (String prompt) => ActionChip(
                    label: Text(prompt),
                    onPressed: () => service.sendQuickGuidance(prompt),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<List<ChatMessage>>(
            valueListenable: service.chatMessages,
            builder: (BuildContext context, List<ChatMessage> messages, _) {
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
                                  ? const Color(0xFFD4F5E5)
                                  : const Color(0xFFE8F0FF),
                          borderRadius: BorderRadius.circular(12),
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
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
