import 'package:get/get.dart';
import 'package:incident_reporter/core/models/app_notification.dart';
import 'package:incident_reporter/core/models/chat_message.dart';
import 'package:incident_reporter/core/models/dispatch_assignment_model.dart';
import 'package:incident_reporter/core/models/incident.dart';
import 'package:incident_reporter/core/services/auth_service.dart';
import 'package:incident_reporter/core/services/chatbot_service.dart';
import 'package:incident_reporter/core/services/dispatch_socket_service.dart';
import 'package:incident_reporter/core/services/incident_api_service.dart';

class EmergencyController extends GetxController {
  EmergencyController({
    IncidentApiService? incidentApiService,
    ChatbotService? chatbotService,
    DispatchSocketService? dispatchSocketService,
  })  : _incidentApiService = incidentApiService ?? IncidentApiService(),
        _chatbotService = chatbotService ?? ChatbotService(),
        _dispatchSocket = dispatchSocketService ?? DispatchSocketService();

  final IncidentApiService _incidentApiService;
  final ChatbotService _chatbotService;
  final DispatchSocketService _dispatchSocket;

  final RxList<Incident> incidents = <Incident>[].obs;
  final Rxn<Incident> activeIncident = Rxn<Incident>();
  final RxList<ChatMessage> chatMessages = <ChatMessage>[].obs;
  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString errorMessage = ''.obs;
  late final Worker _authWorker;

  @override
  void onInit() {
    super.onInit();
    _authWorker = ever<bool>(AuthService().isAuthenticated, (isAuthenticated) {
      if (isAuthenticated) {
        loadIncidents();
      } else {
        _dispatchSocket.disconnect();
      }
    });
    loadIncidents();
  }

  @override
  void onClose() {
    _authWorker.dispose();
    _dispatchSocket.disconnect();
    super.onClose();
  }

  Future<void> loadIncidents() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final List<Incident> loaded = await _incidentApiService.fetchIncidents();
      incidents.assignAll(loaded);
      activeIncident.value = loaded.isEmpty ? null : loaded.first;
      notifications.assignAll(
        loaded.take(5).map(_notificationFromIncident).toList(growable: false),
      );
      await _connectWebSocket();
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitIncident({
    required String emergencyType,
    required String severity,
    required String location,
    required String description,
    Coordinates coordinates = const Coordinates(lat: 0, lng: 0),
  }) async {
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      final Incident draft = Incident.createDraft(
        emergencyType: emergencyType,
        severity: severity,
        location: location,
        description: description,
        coordinates: coordinates,
      );
      final Incident created = await _incidentApiService.createIncident(draft);
      incidents.insert(0, created);
      activeIncident.value = created;
      notifications.insert(0, _notificationFromIncident(created));
      await _startAssistantFor(created, emergencyType, description);
      await _connectWebSocket();
      return true;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> sendUserMessage(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final DateTime now = DateTime.now();
    chatMessages.add(
      ChatMessage(
        id: 'user-${now.microsecondsSinceEpoch}',
        text: trimmed,
        sender: MessageSender.user,
        timestamp: now,
      ),
    );

    try {
      final ChatMessage assistantMessage =
          await _chatbotService.sendMessage(trimmed);
      chatMessages.add(assistantMessage);
    } catch (_) {
      chatMessages.add(
        ChatMessage(
          id: 'error-${DateTime.now().microsecondsSinceEpoch}',
          text:
              'Sorry, I cannot reach the guidance service right now. Stay near your phone and follow dispatcher instructions.',
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void sendQuickGuidance(String scenario) {
    sendUserMessage(scenario);
  }

  void markAllNotificationsRead() {
    notifications.assignAll(
      notifications
          .map((AppNotification item) => item.copyWith(isRead: true))
          .toList(growable: false),
    );
  }

  void clearIncident() {
    _dispatchSocket.disconnect();
    activeIncident.value = null;
    chatMessages.clear();
    _chatbotService.resetSession();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _connectWebSocket() async {
    if (activeIncident.value == null) {
      _dispatchSocket.disconnect();
      return;
    }
    final String? token = await AuthService().getValidToken();
    if (token == null || AuthService().userId.value.isEmpty) {
      return; // demo mode or not yet logged in
    }
    _dispatchSocket.connect(
      token: token,
      onAssignment: _onDispatchAssignment,
      onError: (msg) => errorMessage.value = msg,
    );
  }

  void _onDispatchAssignment(DispatchAssignmentModel assignment) {
    final Incident? current = activeIncident.value;
    if (current == null) return;

    final IncidentStatus newStatus = _stateToStatus(assignment.state);
    activeIncident.value = current.copyWith(
      status: newStatus,
      backendStatus: assignment.state,
    );
    notifications.insert(
        0,
        AppNotification(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: _statusTitle(newStatus),
          message: _statusMessage(newStatus, assignment),
          createdAt: DateTime.now(),
        ));
    _appendSystemMessage(_statusMessage(newStatus, assignment));
  }

  IncidentStatus _stateToStatus(String? state) {
    switch ((state ?? '').toUpperCase()) {
      case 'ASSIGNED':
        return IncidentStatus.dispatcherAssigned;
      case 'EN_ROUTE':
        return IncidentStatus.ambulanceEnRoute;
      case 'ARRIVED':
        return IncidentStatus.ambulanceNearby;
      case 'COMPLETED':
        return IncidentStatus.arrived;
      default:
        return IncidentStatus.dispatcherAssigned;
    }
  }

  String _statusTitle(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.dispatcherAssigned:
        return 'Dispatcher Assigned';
      case IncidentStatus.ambulanceEnRoute:
        return 'Ambulance En Route';
      case IncidentStatus.ambulanceNearby:
        return 'Ambulance Nearby';
      case IncidentStatus.arrived:
        return 'Ambulance Arrived';
      default:
        return 'Update';
    }
  }

  String _statusMessage(IncidentStatus status, DispatchAssignmentModel a) {
    switch (status) {
      case IncidentStatus.dispatcherAssigned:
        return 'Dispatcher is coordinating. Ambulance: ${a.vehicleName}.';
      case IncidentStatus.ambulanceEnRoute:
        return 'Ambulance ${a.vehicleName} is on its way to you.';
      case IncidentStatus.ambulanceNearby:
        return 'Ambulance is almost at your location. Be ready to signal.';
      case IncidentStatus.arrived:
        return 'Emergency team has arrived. Follow responder instructions.';
      default:
        return 'Status updated.';
    }
  }

  void _appendSystemMessage(String text) {
    chatMessages.add(ChatMessage(
      id: 'system-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      sender: MessageSender.system,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _startAssistantFor(
    Incident incident,
    String reportedType,
    String description,
  ) async {
    _chatbotService.resetSession();
    try {
      final ChatMessage assistantMessage = await _chatbotService.sendMessage(
        'The user has reported an emergency through the incident form.',
        initialContext: <String, dynamic>{
          'emergencyType': reportedType,
          'location': incident.location,
          'description': description,
          'severity': incident.severity,
          'citoyenId': AuthService().userId.value,
        },
      );
      chatMessages.assignAll(<ChatMessage>[assistantMessage]);
    } catch (_) {
      chatMessages.assignAll(<ChatMessage>[
        ChatMessage(
          id: 'assistant-init',
          text:
              'I am with you. Your incident report was sent. Keep the phone nearby and share any change in the situation.',
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
        ),
      ]);
    }
  }

  AppNotification _notificationFromIncident(Incident incident) {
    return AppNotification(
      id: incident.id.isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : incident.id,
      title: incident.title,
      message:
          '${incident.backendStatus ?? incident.status.label} - ${incident.location}',
      createdAt: incident.createdAt,
    );
  }
}
