import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../chat/providers/messages_badge_provider.dart';
import '../../../donations/providers/donation_provider.dart';
import '../../../notifications/providers/notifications_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _pollingTimer;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_bootstrapped) return;
      _bootstrapped = true;
      ref.read(donationsProvider.notifier).fetchMyReservations();
      ref.read(donationsProvider.notifier).fetchMyDonationReservations();
      ref.read(notificationsProvider.notifier).fetchNotifications();
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref
          .read(donationsProvider.notifier)
          .fetchMyReservations(background: true);
      ref
          .read(donationsProvider.notifier)
          .fetchMyDonationReservations(background: true);
      ref
          .read(notificationsProvider.notifier)
          .fetchNotifications(background: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _onTabSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(donationsProvider);
    final pendingCount = state.myDonationReservations
        .where((r) => r.status == 'PENDING')
        .length;
    final hasActiveChats = ref.watch(
      messagesBadgeProvider.select((s) => s.hasUnread),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: BottomNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTabSelected: _onTabSelected,
        hasUnreadMessages: hasActiveChats,
        pendingReservationsCount: pendingCount,
        onMessagesTap: () {
          ref.read(messagesBadgeProvider.notifier).markAsRead();
        },
      ),
    );
  }
}
