import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/features/chat/presentation/screens/chat_screen.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';

class _ConversationItem {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String donationTitle;
  final String donationStatus;
  final DateTime sortDate;

  const _ConversationItem({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.donationTitle,
    required this.donationStatus,
    required this.sortDate,
  });
}

class MessagesTab extends ConsumerStatefulWidget {
  const MessagesTab({super.key});

  @override
  ConsumerState<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends ConsumerState<MessagesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(donationsProvider.notifier).fetchMyReservations();
      ref.read(donationsProvider.notifier).fetchMyDonationReservations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(donationsProvider);
    final conversations = _buildConversations(state);
    final isLoading = (state.isReservationsLoading ||
            state.isDonationReservationsLoading) &&
        conversations.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryMid,
                      ),
                    )
                  : conversations.isEmpty
                      ? const _EmptyMessagesState()
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref
                                .read(donationsProvider.notifier)
                                .fetchMyReservations();
                            await ref
                                .read(donationsProvider.notifier)
                                .fetchMyDonationReservations();
                          },
                          color: AppColors.primaryMid,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: conversations.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final conversation = conversations[index];
                              return _ConversationTile(
                                conversation: conversation,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        conversationId: conversation.id,
                                        otherUserName: conversation.name,
                                        donationTitle:
                                            conversation.donationTitle,
                                        donationStatus:
                                            conversation.donationStatus,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ConversationItem> _buildConversations(DonationsState state) {
    final conversations = <_ConversationItem>[
      ...state.myReservations
          .where((reservation) => reservation.status == 'CONFIRMED')
          .map(
            (reservation) => _ConversationItem(
              id: reservation.id,
              name: 'Donor',
              lastMessage:
                  reservation.donationTitle ?? 'Confirmed reservation chat',
              time: _formatConversationTime(
                reservation.confirmedAt ?? reservation.reservedAt,
              ),
              donationTitle: reservation.donationTitle ?? 'Donation',
              donationStatus: reservation.status,
              sortDate: _parseDate(
                reservation.confirmedAt ?? reservation.reservedAt,
              ),
            ),
          ),
      ...state.myDonationReservations
          .where((reservation) => reservation.status == 'CONFIRMED')
          .map(
            (reservation) => _ConversationItem(
              id: reservation.id,
              name: reservation.beneficiaryName ?? 'Beneficiary',
              lastMessage:
                  reservation.donationTitle ?? 'Confirmed donation chat',
              time: _formatConversationTime(
                reservation.confirmedAt ?? reservation.reservedAt,
              ),
              donationTitle: reservation.donationTitle ?? 'Donation',
              donationStatus: reservation.status,
              sortDate: _parseDate(
                reservation.confirmedAt ?? reservation.reservedAt,
              ),
            ),
          ),
    ];

    conversations.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return conversations;
  }

  DateTime _parseDate(String value) {
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String _formatConversationTime(String value) {
    try {
      final date = DateTime.parse(value).toLocal();
      final now = DateTime.now();
      final sameDay = now.year == date.year &&
          now.month == date.month &&
          now.day == date.day;

      if (sameDay) {
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }

      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }
}

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
            _Avatar(name: conversation.name),
            const SizedBox(width: 14),
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
                const SizedBox(height: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.map((part) => part[0]).join().toUpperCase();

    return CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.primarySurface,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 26 * 0.58,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _EmptyMessagesState extends StatelessWidget {
  const _EmptyMessagesState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
            SizedBox(height: 16),
            Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Chats appear here after a reservation is confirmed.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
