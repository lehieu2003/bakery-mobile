import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.suggestedProducts = const [],
  });

  final String role;
  final String content;
  final List<Product> suggestedProducts;

  Map<String, dynamic> toJson() {
    return {'role': role, 'content': content};
  }
}

class ChatReply {
  const ChatReply({required this.reply, required this.suggestedProducts});

  final String reply;
  final List<Product> suggestedProducts;
}


