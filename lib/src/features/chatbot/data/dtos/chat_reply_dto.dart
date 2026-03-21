import 'package:bakery_mobile/src/features/catalog/data/dtos/catalog_dto.dart';
import 'package:bakery_mobile/src/features/chatbot/domain/models/chat.dart';

class ChatReplyDto {
  const ChatReplyDto({required this.reply, required this.suggestedProducts});

  final String reply;
  final List<ProductDto> suggestedProducts;

  factory ChatReplyDto.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['suggestedProducts'] as List<dynamic>? ?? const [];
    return ChatReplyDto(
      reply: (json['reply'] ?? '').toString(),
      suggestedProducts: rawProducts
          .whereType<Map<String, dynamic>>()
          .map(ProductDto.fromJson)
          .toList(),
    );
  }

  ChatReply toDomain() {
    return ChatReply(
      reply: reply,
      suggestedProducts: suggestedProducts.map((e) => e.toDomain()).toList(),
    );
  }
}
