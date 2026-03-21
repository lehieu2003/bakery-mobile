import 'package:bakery_mobile/src/features/chatbot/domain/models/chat.dart';
import 'package:bakery_mobile/src/features/chatbot/data/datasources/chat_api_service.dart';

class ChatRepository {
  ChatRepository(this._chatApiService);

  final ChatApiService _chatApiService;

  Future<ChatReply> sendMessage({
    required String message,
    required List<ChatMessage> history,
  }) {
    return _chatApiService.sendMessage(message: message, history: history);
  }
}


