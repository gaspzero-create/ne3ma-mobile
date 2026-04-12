import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/features/chat/data/models/chat_message_model.dart';
import 'package:ne3ma/features/chat/providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String donationTitle;
  final String donationStatus;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.donationTitle,
    required this.donationStatus,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _hasText = false;
  int _lastMessageCount = 0;

  bool get _canSendMessages =>
      widget.donationStatus.toUpperCase() == 'CONFIRMED';

  @override
  void initState() {
    super.initState();
    _messageCtrl.addListener(() {
      final hasText = _messageCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).initChat(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    if (!_canSendMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat is only available for confirmed reservations'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ref.read(chatProvider.notifier).sendMessage(text);
    _messageCtrl.clear();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(chatProvider.notifier).clearError();
      }
    });

    final chatState = ref.watch(chatProvider);

    if (chatState.messages.length != _lastMessageCount) {
      _lastMessageCount = chatState.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ChatAppBar(
              donationTitle: widget.donationTitle,
              donationStatus: widget.donationStatus,
              otherUserName: widget.otherUserName,
              onBack: () => Navigator.maybePop(context),
              onProfileTap: () {},
            ),
            Expanded(child: _buildBody(chatState)),
            _InputBar(
              controller: _messageCtrl,
              hasText: _hasText && _canSendMessages && chatState.isConnected,
              onSend: _sendMessage,
              onAttach: () {
                debugPrint('📎 ChatScreen: Attach tapped');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ChatState chatState) {
    if (chatState.isLoading && chatState.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMid),
      );
    }

    if (chatState.messages.isEmpty) {
      return _EmptyChatState(canSendMessages: _canSendMessages);
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final message = chatState.messages[index];
        final previousMessage =
            index > 0 ? chatState.messages[index - 1] : null;
        final showTime = previousMessage == null ||
            previousMessage.formattedTime != message.formattedTime;

        return Column(
          children: [
            if (showTime) _TimeStamp(time: message.formattedTime),
            _MessageBubble(
              message: message,
              otherUserName: widget.otherUserName,
            ),
          ],
        );
      },
    );
  }
}

class _ChatAppBar extends StatelessWidget {
  final String donationTitle;
  final String donationStatus;
  final String otherUserName;
  final VoidCallback onBack;
  final VoidCallback onProfileTap;

  const _ChatAppBar({
    required this.donationTitle,
    required this.donationStatus,
    required this.otherUserName,
    required this.onBack,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donationTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    donationStatus,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryMid,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  _Avatar(name: otherUserName, radius: 20),
                  const SizedBox(width: 10),
                  Text(
                    otherUserName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFFFC107),
                  ),
                  const Text(
                    ' 4.6',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeStamp extends StatelessWidget {
  final String time;

  const _TimeStamp({required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          time.isEmpty ? 'Now' : time,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final String otherUserName;

  const _MessageBubble({
    required this.message,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isMine) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bubble(
              content: message.content,
              isMe: true,
            ),
            const SizedBox(width: 8),
            ClipOval(
              child: Container(
                width: 30,
                height: 30,
                color: AppColors.primarySurface,
                child: const Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: AppColors.primaryMid,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Avatar(name: otherUserName, radius: 15),
          const SizedBox(width: 8),
          _Bubble(content: message.content, isMe: false),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String content;
  final bool isMe;

  const _Bubble({required this.content, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.62,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        border: isMe
            ? null
            : Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 14,
          color: isMe ? AppColors.primary : AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const _InputBar({
    required this.controller,
    required this.hasText,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAttach,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: hasText ? onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasText ? AppColors.primary : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 18,
                color: hasText ? Colors.white : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double radius;

  const _Avatar({required this.name, this.radius = 26});

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySurface,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.58,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  String _buildInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.map((part) => part[0]).join().toUpperCase();
  }
}

class _EmptyChatState extends StatelessWidget {
  final bool canSendMessages;

  const _EmptyChatState({required this.canSendMessages});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canSendMessages
                  ? 'Start the conversation with your first message.'
                  : 'Chat becomes available when the reservation is confirmed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
