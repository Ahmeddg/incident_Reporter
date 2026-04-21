import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:incident_reporter/core/models/app_notification.dart';
import 'package:incident_reporter/core/models/chat_message.dart';
import 'package:incident_reporter/core/models/incident.dart';
import 'package:incident_reporter/core/services/chatbot_service.dart';

class MockEmergencyService {
  MockEmergencyService._internal();

  static final MockEmergencyService _instance =
      MockEmergencyService._internal();
  factory MockEmergencyService() => _instance;
  
  final ChatbotService _chatbotService = ChatbotService();

  final ValueNotifier<Incident?> activeIncident =
      ValueNotifier<Incident?>(null);
  final ValueNotifier<List<ChatMessage>> chatMessages =
      ValueNotifier<List<ChatMessage>>([]);
  final ValueNotifier<List<AppNotification>> notifications =
      ValueNotifier<List<AppNotification>>([]);

  Timer? _statusTimer;

  static const List<IncidentStatus> _statusFlow = <IncidentStatus>[
    IncidentStatus.reportReceived,
    IncidentStatus.dispatcherAssigned,
    IncidentStatus.ambulanceEnRoute,
    IncidentStatus.ambulanceNearby,
    IncidentStatus.arrived,
  ];

  void submitIncident({
    required String emergencyType,
    required String severity,
    required String location,
    required String description,
  }) {
    final DateTime now = DateTime.now();
    final Incident incident = Incident(
      id: now.microsecondsSinceEpoch.toString(),
      emergencyType: emergencyType,
      severity: severity,
      location: location,
      description: description,
      createdAt: now,
      status: IncidentStatus.reportReceived,
    );

    activeIncident.value = incident;
    
    // On initialise le chat avec les données du formulaire
    final Map<String, dynamic> initialContext = {
      'emergencyType': emergencyType,
      'location': location,
      'description': description,
      'severity': severity,
    };

    // On récupère le premier message personnalisé du chatbot
    Future<void>.delayed(const Duration(milliseconds: 100), () async {
      try {
        final assistantMsg = await _chatbotService.sendMessage(
          "L'utilisateur vient de signaler une urgence via le formulaire.",
          initialContext: initialContext,
        );
        chatMessages.value = <ChatMessage>[assistantMsg];
      } catch (e) {
        chatMessages.value = <ChatMessage>[
          ChatMessage(
            id: 'assistant-init',
            text: 'Je suis avec vous. Une ambulance a été demandée pour $location. Pouvez-vous me donner plus de détails sur l\'état de la personne ?',
            sender: MessageSender.assistant,
            timestamp: DateTime.now(),
          ),
        ];
      }
    });

    _addNotification(
      title: 'Emergency Report Sent',
      message: 'Dispatch team has received your incident report.',
    );

    _startStatusSimulation();
  }

  void sendUserMessage(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final DateTime now = DateTime.now();
    chatMessages.value = <ChatMessage>[
      ...chatMessages.value,
      ChatMessage(
        id: 'user-${now.microsecondsSinceEpoch}',
        text: trimmed,
        sender: MessageSender.user,
        timestamp: now,
      ),
    ];

    Future<void>.delayed(const Duration(milliseconds: 200), () async {
      try {
        final assistantMsg = await _chatbotService.sendMessage(trimmed);
        chatMessages.value = <ChatMessage>[
          ...chatMessages.value,
          assistantMsg,
        ];
      } catch (e) {
        chatMessages.value = <ChatMessage>[
          ...chatMessages.value,
          ChatMessage(
            id: 'error-${DateTime.now().microsecondsSinceEpoch}',
            text: 'Désolé, je rencontre des difficultés pour me connecter au service.',
            sender: MessageSender.assistant,
            timestamp: DateTime.now(),
          ),
        ];
      }
    });
  }

  void sendQuickGuidance(String scenario) {
    sendUserMessage(scenario);
  }

  void markAllNotificationsRead() {
    notifications.value = notifications.value
        .map((AppNotification item) => item.copyWith(isRead: true))
        .toList(growable: false);
  }

  void clearIncident() {
    _statusTimer?.cancel();
    _statusTimer = null;
    activeIncident.value = null;
    chatMessages.value = <ChatMessage>[];
    _chatbotService.resetSession();
  }

  void _startStatusSimulation() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 16), (Timer timer) {
      final Incident? current = activeIncident.value;
      if (current == null) {
        timer.cancel();
        return;
      }

      final int currentIndex = _statusFlow.indexOf(current.status);
      if (currentIndex == -1 || currentIndex >= _statusFlow.length - 1) {
        timer.cancel();
        return;
      }

      final IncidentStatus next = _statusFlow[currentIndex + 1];
      activeIncident.value = current.copyWith(status: next);
      _onStatusChanged(next);

      if (next == IncidentStatus.arrived) {
        timer.cancel();
      }
    });
  }

  void _onStatusChanged(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.dispatcherAssigned:
        _addNotification(
          title: 'Dispatcher Assigned',
          message: 'A dispatcher is coordinating emergency resources for you.',
        );
        _appendSystemMessage('A dispatcher is now handling your request.');
        break;
      case IncidentStatus.ambulanceEnRoute:
        _addNotification(
          title: 'Ambulance En Route',
          message: 'An ambulance is now on the way to your location.',
        );
        _appendSystemMessage('Ambulance dispatched. Keep your phone nearby.');
        break;
      case IncidentStatus.ambulanceNearby:
        _addNotification(
          title: 'Ambulance Is Close',
          message: 'Ambulance is close to you. Prepare to signal responders.',
        );
        _appendSystemMessage(
          'Responders are nearby. If safe, move to a visible position.',
        );
        break;
      case IncidentStatus.arrived:
        _addNotification(
          title: 'Ambulance Arrived',
          message: 'Emergency team has arrived at your location.',
        );
        _appendSystemMessage(
            'Emergency team arrived. Follow responder instructions.');
        break;
      case IncidentStatus.reportReceived:
        break;
    }
  }

  void _appendSystemMessage(String text) {
    chatMessages.value = <ChatMessage>[
      ...chatMessages.value,
      ChatMessage(
        id: 'system-${DateTime.now().microsecondsSinceEpoch}',
        text: text,
        sender: MessageSender.system,
        timestamp: DateTime.now(),
      ),
    ];
  }

  void _addNotification({
    required String title,
    required String message,
  }) {
    final DateTime now = DateTime.now();
    notifications.value = <AppNotification>[
      AppNotification(
        id: now.microsecondsSinceEpoch.toString(),
        title: title,
        message: message,
        createdAt: now,
      ),
      ...notifications.value,
    ];
  }

}
