import 'package:flutter/material.dart';
import 'package:ne3ma/core/constants/app_colors.dart';

// ── Fake message model (replace with real GraphQL ChatMessage later) ──────────
class _ChatMessage {
  final String id;
  final String content;
  final bool isMe;
  final String sentAt;
  final String? avatarName; // for the other user's avatar

  const _ChatMessage({
    required this.id,
    required this.content,
    required this.isMe,
    required this.sentAt,
    this.avatarName,
  });
}

final _fakeMessages = [
  _ChatMessage(
    id: '1',
    content: 'Lorem Ipsum Dolor Sit Amet',
    isMe: true,
    sentAt: '10:00 AM',
  ),
  _ChatMessage(
    id: '2',
    content: 'Lorem Ipsum Dolor Sit Amet',
    isMe: false,
    sentAt: '10:00 AM',
    avatarName: 'Robert Fox',
  ),
  _ChatMessage(
    id: '3',
    content: 'Lorem Ipsum Dolor Sit Amet',
    isMe: true,
    sentAt: '10:01 AM',
  ),
  _ChatMessage(
    id: '4',
    content: '...',
    isMe: false,
    sentAt: '10:02 AM',
    avatarName: 'Robert Fox',
    // typing indicator placeholder
  ),
];

// ── Chat Screen ───────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
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
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageCtrl    = TextEditingController();
  final _scrollCtrl     = ScrollController();
  bool  _hasText        = false;

  @override
  void initState() {
    super.initState();
    _messageCtrl.addListener(() {
      final hasText = _messageCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
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
    // TODO: wire to GraphQL mutation / real-time subscription
    debugPrint('📤 ChatScreen: Sending message "$text"');
    _messageCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ────────────────────────────────────────────────────
            _ChatAppBar(
              donationTitle:  widget.donationTitle,
              donationStatus: widget.donationStatus,
              otherUserName:  widget.otherUserName,
              onBack:         () => Navigator.maybePop(context),
              onProfileTap:   () {
                // TODO: navigate to donation detail screen
              },
            ),

            // ── Message List ───────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _fakeMessages.length,
                itemBuilder: (context, index) {
                  final msg      = _fakeMessages[index];
                  final prevMsg  = index > 0 ? _fakeMessages[index - 1] : null;
                  final showTime = prevMsg == null || prevMsg.sentAt != msg.sentAt;

                  return Column(
                    children: [
                      if (showTime) _TimeStamp(time: msg.sentAt),
                      _MessageBubble(message: msg),
                    ],
                  );
                },
              ),
            ),

            // ── Input Bar ──────────────────────────────────────────────────
            _InputBar(
              controller: _messageCtrl,
              hasText:    _hasText,
              onSend:     _sendMessage,
              onAttach:   () {
                // TODO: image/media picker
                debugPrint('📎 ChatScreen: Attach tapped');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────
class _ChatAppBar extends StatelessWidget {
  final String       donationTitle;
  final String       donationStatus;
  final String       otherUserName;
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
          // ── Title row ──────────────────────────────────────────────────
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

          // ── User row ───────────────────────────────────────────────────
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

// ── Timestamp ─────────────────────────────────────────────────────────────────
class _TimeStamp extends StatelessWidget {
  final String time;
  const _TimeStamp({required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          time,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  bool get _isTyping => message.content == '...';

  @override
  Widget build(BuildContext context) {
    if (message.isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bubble(
              content: message.content,
              isMe:    true,
            ),
            const SizedBox(width: 8),
            // Me: small avatar on right (optional — shown in design)
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
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Avatar(name: message.avatarName ?? '?', radius: 15),
            const SizedBox(width: 8),
            _isTyping
                ? _TypingIndicator()
                : _Bubble(content: message.content, isMe: false),
          ],
        ),
      );
    }
  }
}

// ── Bubble ────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final String content;
  final bool   isMe;

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
          topLeft:     const Radius.circular(18),
          topRight:    const Radius.circular(18),
          bottomLeft:  Radius.circular(isMe ? 18 : 4),
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

// ── Typing Indicator ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft:     Radius.circular(18),
          topRight:    Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft:  Radius.circular(4),
        ),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = (_ctrl.value - i * 0.18).clamp(0.0, 1.0);
              final scale = 0.6 + 0.4 * (1 - (t * 2 - 1).abs());
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool        hasText;
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
        16, 10, 16, 10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // ── Attach button ──────────────────────────────────────────────
          GestureDetector(
            onTap: onAttach,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
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

          // ── Text field ─────────────────────────────────────────────────
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
                  border:           InputBorder.none,
                  contentPadding:   EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // ── Send button ────────────────────────────────────────────────
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

// ── Avatar (reused from messages_tab.dart — copy or extract to widget) ────────
class _Avatar extends StatelessWidget {
  final String name;
  final double radius;

  const _Avatar({required this.name, this.radius = 26});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2).map((w) => w[0]).join();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySurface,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.58,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
