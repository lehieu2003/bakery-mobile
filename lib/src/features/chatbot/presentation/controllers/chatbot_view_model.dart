import 'package:flutter/foundation.dart';

import 'package:bakery_mobile/src/features/chatbot/domain/models/chat.dart';
import 'package:bakery_mobile/src/features/chatbot/data/repositories/chat_repository.dart';

class ChatbotViewModel extends ChangeNotifier {
  ChatbotViewModel(this._chatRepository) {
    _messages = const [
      ChatMessage(
        role: 'assistant',
        content:
            'Xin chao. Toi la tro ly tu van banh. Ban co the mo ta dip su kien, ngan sach hoac khau vi de toi goi y.',
      ),
    ];
  }

  final ChatRepository _chatRepository;

  late List<ChatMessage> _messages;
  bool _isSending = false;
  String? _error;

  List<ChatMessage> get messages => _messages;
  bool get isSending => _isSending;
  String? get error => _error;

  Future<void> send(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || _isSending) return;

    final updated = [..._messages, ChatMessage(role: 'user', content: message)];
    _messages = updated;
    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final reply = await _chatRepository.sendMessage(
        message: message,
        history: _messages,
      );
      _messages = [
        ...updated,
        ChatMessage(
          role: 'assistant',
          content: reply.reply.isEmpty
              ? 'Xin loi, toi chua tra loi duoc luc nay.'
              : reply.reply,
          suggestedProducts: reply.suggestedProducts,
        ),
      ];
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      _messages = [
        ...updated,
        const ChatMessage(
          role: 'assistant',
          content: 'Da co loi he thong. Vui long thu lai sau.',
        ),
      ];
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}


