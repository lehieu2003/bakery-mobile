import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/chatbot/data/dtos/chat_reply_dto.dart';
import 'package:bakery_mobile/src/features/chatbot/domain/models/chat.dart';

class ChatApiService {
  ChatApiService(this._client);

  final ApiClient _client;

  Future<ChatReplyDto> sendMessage({
    required String message,
    required List<ChatMessage> history,
  }) async {
    final response = await _client.post(
      '/api/chat',
      body: {
        'message': message,
        'history': history.map((item) => item.toJson()).toList(),
      },
    );

    return ChatReplyDto.fromJson(response as Map<String, dynamic>);
  }
}
