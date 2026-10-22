import 'package:flutter/widgets.dart';

/// Widget keys of the chatbot screen (used by tests and finders).
abstract final class ChatbotKeys {
  static const messages = Key('chatbot.messages');
  static const input = Key('chatbot.input');
  static const send = Key('chatbot.send');
  static const sending = Key('chatbot.sending');
  static const error = Key('chatbot.error');

  static Key message(int index) => Key('chatbot.message.$index');
  static Key quickPrompt(int index) => Key('chatbot.quickPrompt.$index');
  static Key suggestion(String productId) =>
      Key('chatbot.suggestion.$productId');
}
