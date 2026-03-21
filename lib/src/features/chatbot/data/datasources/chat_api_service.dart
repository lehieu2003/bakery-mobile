import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/chatbot/domain/models/chat.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';

class ChatApiService {
  ChatApiService(this._client);

  final ApiClient _client;

  Future<ChatReply> sendMessage({
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

    final data = response as Map<String, dynamic>;
    final rawProducts = data['suggestedProducts'] as List<dynamic>? ?? const [];

    final products = rawProducts
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();

    return ChatReply(
      reply: (data['reply'] ?? '').toString(),
      suggestedProducts: products,
    );
  }
}


