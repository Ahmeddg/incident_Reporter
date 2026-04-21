import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:incident_reporter/core/config/app_config.dart';
import 'package:incident_reporter/core/models/chat_message.dart';

class ChatbotService {
  ChatbotService._internal();
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;

  String? _sessionId;

  Future<ChatMessage> sendMessage(String text, {Map<String, dynamic>? initialContext}) async {
    final response = await http.post(
      Uri.parse('${AppConfig.chatbotBaseUrl}/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        if (_sessionId != null) 'sessionId': _sessionId,
        if (initialContext != null) 'initialContext': initialContext,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _sessionId = data['sessionId'];
      
      return ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: data['text'] ?? 'No response from bot',
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
      );
    } else {
      throw Exception('Failed to communicate with chatbot: ${response.statusCode}');
    }
  }

  void resetSession() {
    _sessionId = null;
  }
}
