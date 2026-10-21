import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/shared/widgets/app_text_input_widget.dart';
import 'package:bakery_mobile/src/features/chatbot/domain/models/chat.dart';
import 'package:bakery_mobile/src/features/chatbot/presentation/widgets/suggested_product_tile.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  static const _quickPrompts = <String>[
    'Goi y banh sinh nhat duoi 500k',
    'Banh nao ban chay nhat?',
    'Toi thich vi it ngot',
  ];
  static const double _hostBottomBarHeight = 20;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;
  bool _lastKeyboardVisible = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(chatbotViewModelProvider);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardVisible = keyboardInset > 0;
    final composerBottomInset =
        (keyboardVisible
            ? keyboardInset
            : MediaQuery.paddingOf(context).bottom + _hostBottomBarHeight) +
        8;

    final shouldAutoScroll =
        _lastMessageCount != vm.messages.length ||
        _lastKeyboardVisible != keyboardVisible;
    if (shouldAutoScroll) {
      _lastMessageCount = vm.messages.length;
      _lastKeyboardVisible = keyboardVisible;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDurations.fast,
          curve: Curves.easeOut,
        );
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Chatbot')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: vm.messages.length,
              itemBuilder: (context, index) {
                final message = vm.messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),
          if (vm.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                vm.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (!keyboardVisible)
            SizedBox(
              height: 40,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                scrollDirection: Axis.horizontal,
                children: _quickPrompts
                    .map(
                      (prompt) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ActionChip(
                          label: Text(prompt),
                          onPressed: vm.isSending
                              ? null
                              : () => _sendPrompt(context, prompt),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          AnimatedPadding(
            duration: AppDurations.fast,
            curve: Curves.easeOut,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              composerBottomInset,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppTextInputWidget(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    hintText: 'Nhap tin nhan...',
                    onSubmitted: (_) => _send(context),
                  ),
                ),
                const Gap(AppSpacing.sm),
                FilledButton(
                  onPressed: vm.isSending ? null : () => _send(context),
                  child: vm.isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _send(BuildContext context) {
    final text = _controller.text;
    _controller.clear();
    ref.read(chatbotViewModelProvider.notifier).send(text);
  }

  void _sendPrompt(BuildContext context, String prompt) {
    ref.read(chatbotViewModelProvider.notifier).send(prompt);
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.content),
                if (!isUser && message.suggestedProducts.isNotEmpty) ...[
                  const Gap(AppSpacing.sm),
                  ...message.suggestedProducts.map(
                    (product) => SuggestedProductTile(product: product),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
