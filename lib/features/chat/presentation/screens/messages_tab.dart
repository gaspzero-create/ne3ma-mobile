import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/features/chat/presentation/screens/chat_screen.dart';
import 'package:ne3ma/features/chat/providers/messages_badge_provider.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';

class _ConversationItem {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? badge;
  final String? role;
  final String lastMessage;
  final String time;
  final String donationTitle;
  final String donationStatus;
  final DateTime sortDate;
  final String updatedAt; // raw server timestamp string
  final bool hasNewMessage;

  const _ConversationItem({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.badge,
    this.role,
    required this.lastMessage,
    required this.time,
    required this.donationTitle,
    required this.donationStatus,
    required this.sortDate,
    required this.updatedAt,
    this.hasNewMessage = false,
  });
}

const _seenTimestampsKey = 'seen_conversation_timestamps';

class MessagesTab extends ConsumerStatefulWidget {
  const MessagesTab({super.key});

  @override
  ConsumerState<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends ConsumerState<MessagesTab> {
  final _storage = const FlutterSecureStorage();
  Map<String, String> _seenTimestamps = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Load seen timestamps first
    final raw = await _storage.read(key: _seenTimestampsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _seenTimestamps = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _loaded = true);

    // Fetch fresh data
    ref.read(donationsProvider.notifier).fetchMyReservations();
    ref.read(donationsProvider.notifier).fetchMyDonationReservations();
    ref.read(messagesBadgeProvider.notifier).markAsRead();

    // After data loads, auto-save timestamps for any NEW conversations
    // we haven't seen before (so they don't falsely show as "new message")
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveFirstTimeSeen();
    });
  }

  /// Auto-save timestamps for conversations we see for the first time
  /// so they don't all light up as "new message". We listen for the next
  /// state change to catch the data once it arrives.
  void _saveFirstTimeSeen() {
    ref.listenManual(donationsProvider, (_, next) {
      bool changed = false;
      final all = [
        ...next.myReservations.where((r) => r.status == 'CONFIRMED'),
        ...next.myDonationReservations.where((r) => r.status == 'CONFIRMED'),
      ];
      for (final r in all) {
        final ts = r.updatedAt ?? r.confirmedAt ?? r.reservedAt;
        if (!_seenTimestamps.containsKey(r.id)) {
          _seenTimestamps[r.id] = ts;
          changed = true;
        }
      }
      if (changed) {
        _storage.write(
          key: _seenTimestampsKey,
          value: jsonEncode(_seenTimestamps),
        );
        if (mounted) setState(() {});
      }
    }, fireImmediately: true);
  }

  void _openChat(_ConversationItem c) {
    // Save this conversation's current updatedAt as "seen"
    _seenTimestamps[c.id] = c.updatedAt;
    _storage.write(key: _seenTimestampsKey, value: jsonEncode(_seenTimestamps));
    ref.read(messagesBadgeProvider.notifier).markConversationAsRead(c.id);
    setState(() {});

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: c.id,
          otherUserName: c.name,
          otherUserAvatarUrl: c.avatarUrl,
          otherUserBadge: c.badge,
          otherUserRole: c.role,
          donationTitle: c.donationTitle,
          donationStatus: c.donationStatus,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(donationsProvider);
    final unreadConversationIds = ref.watch(
      messagesBadgeProvider.select((state) => state.unreadConversationIds),
    );
    final conversations = _buildConversations(state, unreadConversationIds);
    final isLoading =
        (state.isReservationsLoading || state.isDonationReservationsLoading) &&
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
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final c = conversations[index];
                          return _ConversationTile(
                            conversation: c,
                            onTap: () => _openChat(c),
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

  List<_ConversationItem> _buildConversations(
    DonationsState state,
    Set<String> unreadConversationIds,
  ) {
    final list = <_ConversationItem>[
      ...state.myReservations.where((r) => r.status == 'CONFIRMED').map((r) {
        final ts = r.updatedAt ?? r.confirmedAt ?? r.reservedAt;
        return _ConversationItem(
          id: r.id,
          name: r.donorName ?? 'Donor',
          avatarUrl: r.donorAvatarUrl,
          badge: r.donorBadge,
          role: r.donorRole,
          lastMessage: r.donationTitle ?? 'Confirmed reservation chat',
          time: _fmtTime(r.confirmedAt ?? r.reservedAt),
          donationTitle: r.donationTitle ?? 'Donation',
          donationStatus: r.status,
          sortDate: _parseDate(r.confirmedAt ?? r.reservedAt),
          updatedAt: ts,
          hasNewMessage:
              unreadConversationIds.contains(r.id) ||
              (_loaded && _seenTimestamps[r.id] != ts),
        );
      }),
      ...state.myDonationReservations.where((r) => r.status == 'CONFIRMED').map(
        (r) {
          final ts = r.updatedAt ?? r.confirmedAt ?? r.reservedAt;
          return _ConversationItem(
            id: r.id,
            name: r.beneficiaryName ?? 'Beneficiary',
            avatarUrl: r.beneficiaryAvatarUrl,
            badge: r.beneficiaryBadge,
            role: r.beneficiaryRole,
            lastMessage: r.donationTitle ?? 'Confirmed donation chat',
            time: _fmtTime(r.confirmedAt ?? r.reservedAt),
            donationTitle: r.donationTitle ?? 'Donation',
            donationStatus: r.status,
            sortDate: _parseDate(r.confirmedAt ?? r.reservedAt),
            updatedAt: ts,
            hasNewMessage:
                unreadConversationIds.contains(r.id) ||
                (_loaded && _seenTimestamps[r.id] != ts),
          );
        },
      ),
    ];

    // Sort: new messages first, then by date
    list.sort((a, b) {
      if (a.hasNewMessage && !b.hasNewMessage) return -1;
      if (!a.hasNewMessage && b.hasNewMessage) return 1;
      return b.sortDate.compareTo(a.sortDate);
    });
    return list;
  }

  DateTime _parseDate(String v) {
    try {
      return DateTime.parse(v).toLocal();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String _fmtTime(String v) {
    try {
      final d = DateTime.parse(v).toLocal();
      final now = DateTime.now();
      if (now.year == d.year && now.month == d.month && now.day == d.day) {
        return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }
      return '${d.day}/${d.month}';
    } catch (_) {
      return '';
    }
  }
}

// ═══════════════════════════════════════════════════════
// Conversation tile — highlights ONLY if hasNewMessage
// ═══════════════════════════════════════════════════════
class _ConversationTile extends StatelessWidget {
  final _ConversationItem conversation;
  final VoidCallback onTap;
  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNew = conversation.hasNewMessage;
    final previewText = isNew
        ? 'Sent you a new message'
        : conversation.lastMessage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isNew
              ? AppColors.primarySurface.withValues(alpha: 0.45)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isNew
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                )
              : null,
        ),
        child: Row(
          children: [
            _Avatar(
              name: conversation.name,
              avatarUrl: conversation.avatarUrl,
              highlight: isNew,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isNew ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isNew ? FontWeight.w700 : FontWeight.normal,
                      color: isNew
                          ? AppColors.primary
                          : AppColors.textSecondary,
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isNew ? FontWeight.w700 : FontWeight.normal,
                    color: isNew ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 10),
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
  final String? avatarUrl;
  final bool highlight;
  const _Avatar({required this.name, this.avatarUrl, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.map((p) => p[0]).join().toUpperCase();

    final avatar = CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.primarySurface,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              initials,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            )
          : null,
    );

    if (!highlight) return avatar;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2.5),
      ),
      child: avatar,
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
