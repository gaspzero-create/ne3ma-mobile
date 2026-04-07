import 'package:flutter/material.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'chat_screen.dart';

// ── Fake data model (replace with real provider later) ────────────────────────
class _ConversationItem {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String time;
  final int unreadCount;

  const _ConversationItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
  });
}

final _fakeConversations = [
  _ConversationItem(
    id: '1',
    name: 'Darlene Steward',
    avatarUrl: '',
    lastMessage: 'Pls take a look at the images.',
    time: '18:31',
    unreadCount: 5,
  ),
  _ConversationItem(
    id: '2',
    name: 'Fullsnack Associate',
    avatarUrl: '',
    lastMessage: 'Hello, we have discussed about ...',
    time: '16:04',
  ),
  _ConversationItem(
    id: '3',
    name: 'Lee Williamson',
    avatarUrl: '',
    lastMessage: 'Yes, that\'s gonna work.',
    time: '06:12',
  ),
  _ConversationItem(
    id: '4',
    name: 'Ronald Mccoy',
    avatarUrl: '',
    lastMessage: 'Thanks dude 😊',
    time: 'Yesterday',
  ),
  _ConversationItem(
    id: '5',
    name: 'Albert Bell',
    avatarUrl: '',
    lastMessage: 'I\'m happy this meal has such grea...',
    time: 'Yesterday',
  ),
];

// ── Messages Tab ──────────────────────────────────────────────────────────────
class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Conversation List ─────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _fakeConversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final conv = _fakeConversations[index];
                  return _ConversationTile(
                    conversation: conv,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: conv.id,
                            otherUserName: conv.name,
                            // TODO: pass donationTitle from real data
                            donationTitle: 'Homemade Cake',
                            donationStatus: 'Available',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Conversation Tile ─────────────────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final _ConversationItem conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────────────
            _Avatar(name: conversation.name),
            const SizedBox(width: 14),

            // ── Name + Last Message ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Time + Badge ─────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                if (conversation.unreadCount > 0)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
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
