import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../chat/providers/messages_badge_provider.dart';
import '../../../donations/providers/donation_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _pollingTimer;
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/messages')) return 1;
    if (location.startsWith('/add')) return 2;
    if (location.startsWith('/special')) return 3;
    if (location.startsWith('/profile-tab')) return 4;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch reservations globally so the nav bar badges are populated immediately
      ref.read(donationsProvider.notifier).fetchMyReservations();
      ref.read(donationsProvider.notifier).fetchMyDonationReservations();
    });

    // Background poll every 30s to keep badges updated (lightweight, no spinners)
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref
          .read(donationsProvider.notifier)
          .fetchMyReservations(background: true);
      ref
          .read(donationsProvider.notifier)
          .fetchMyDonationReservations(background: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read the donations state to calculate badges
    final state = ref.watch(donationsProvider);

    // Calculate pending reservations count (for donors: reservations on their donations that are waiting to be confirmed/declined)
    // Assuming status is 'PENDING' for unconfirmed reservations
    final pendingCount = state.myDonationReservations
        .where((r) => r.status == 'PENDING')
        .length;

    // Use the messages badge provider which tracks if there are new unread messages
    // since the tab was last opened.
    final hasActiveChats = ref.watch(
      messagesBadgeProvider.select((state) => state.hasUnread),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _getCurrentIndex(context),
        hasUnreadMessages: hasActiveChats,
        pendingReservationsCount: pendingCount,
        onMessagesTap: () {
          ref.read(messagesBadgeProvider.notifier).markAsRead();
        },
      ),
    );
  }
}
