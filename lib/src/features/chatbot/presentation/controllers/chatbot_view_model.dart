import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/chatbot/domain/models/chat.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class ChatbotState {
  const ChatbotState({
    this.messages = const [],
    this.isSending = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final String? error;

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatbotViewModel extends Notifier<ChatbotState> {
  @override
  ChatbotState build() {
    return const ChatbotState(
      messages: [
        ChatMessage(
          role: 'assistant',
          content:
              'Xin chao. Toi la tro ly tu van banh. Ban co the mo ta dip su kien, ngan sach hoac khau vi de toi goi y.',
        ),
      ],
    );
  }

  Future<void> send(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || state.isSending) return;

    final updated = [
      ...state.messages,
      ChatMessage(role: 'user', content: message),
    ];
    state = state.copyWith(
      messages: updated,
      isSending: true,
      clearError: true,
    );

    try {
      final reply = await ref
          .read(chatRepositoryProvider)
          .sendMessage(message: message, history: updated);
      state = state.copyWith(
        messages: [
          ...updated,
          ChatMessage(
            role: 'assistant',
            content: reply.reply.isEmpty
                ? 'Xin loi, toi chua tra loi duoc luc nay.'
                : reply.reply,
            suggestedProducts: reply.suggestedProducts,
          ),
        ],
        isSending: false,
      );
    } catch (error) {
      state = state.copyWith(
        messages: [
          ...updated,
          const ChatMessage(
            role: 'assistant',
            content: 'Da co loi he thong. Vui long thu lai sau.',
          ),
        ],
        isSending: false,
        error: userErrorMessage(error),
      );
    }
  }
}
