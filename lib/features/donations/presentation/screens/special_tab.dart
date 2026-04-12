import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/features/chat/presentation/screens/chat_screen.dart';
import 'package:ne3ma/features/donations/data/models/donation_model.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';

class SpecialTab extends ConsumerStatefulWidget {
  const SpecialTab({super.key});

  @override
  ConsumerState<SpecialTab> createState() => _SpecialTabState();
}

class _SpecialTabState extends ConsumerState<SpecialTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ── Fetch both on open ─────────────────────
      ref.read(donationsProvider.notifier).fetchMyReservations();
      ref.read(donationsProvider.notifier).fetchMyDonationReservations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [

            // ── Header ──────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Center(
                child: Text(
                  'Special',
                  style: TextStyle(
                    fontSize:   18,
                    fontWeight: FontWeight.w700,
                    color:      AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab Bar ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height:      44,
                decoration: BoxDecoration(
                  color:        AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller:         _tabController,
                  labelColor:         Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                  ),
                  indicator: BoxDecoration(
                    color:        AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor:  Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: 'My Donations'),  // donor view
                    Tab(text: 'My Reserved'),   // beneficiary view
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Tab Views ────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MyDonationsTab(),  // Tab 0 — people who reserved from me
                  _MyReservedTab(),   // Tab 1 — I reserved from others
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// TAB 0 — My Donations (donor sees who reserved from him)
// ══════════════════════════════════════════════════════
class _MyDonationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(donationsProvider);

    if (state.isDonationReservationsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMid),
      );
    }

    if (state.myDonationReservations.isEmpty) {
      return _EmptyState(
        emoji:    '📦',
        title:    'No reservations yet',
        subtitle: 'When someone reserves\nyour donation it appears here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(donationsProvider.notifier).fetchMyDonationReservations(),
      color: AppColors.primaryMid,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: state.myDonationReservations.length,
        itemBuilder: (context, index) {
          final reservation = state.myDonationReservations[index];
          return _DonorReservationCard(
            reservation: reservation,
            onConfirm: () => _onConfirm(context, ref, reservation.id),
            onCancel:  () => _onCancel(context, ref, reservation.id),
            onChat:    () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: reservation.id,
                  otherUserName:
                      reservation.beneficiaryName ?? 'Beneficiary',
                  donationTitle: reservation.donationTitle ?? 'Donation',
                  donationStatus: reservation.status,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onConfirm(
    BuildContext context, WidgetRef ref, String reservationId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Confirm Reservation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Accept this reservation? The beneficiary will be notified and chat will open.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Confirm',
              style: TextStyle(
                color:      AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    debugPrint('📤 SpecialTab: Confirming $reservationId...');
    final success = await ref
        .read(donationsProvider.notifier)
        .confirmReservation(reservationId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '✅ Reservation confirmed! Chat is now open.' : '❌ Failed to confirm',
        ),
        backgroundColor: success ? AppColors.primaryMid : AppColors.error,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _onCancel(
    BuildContext context, WidgetRef ref, String reservationId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Cancel Reservation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Reject this reservation? The donation will return to available.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(
                color:      AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ref
        .read(donationsProvider.notifier)
        .cancelReservation(reservationId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Reservation cancelled' : 'Failed to cancel',
        ),
        backgroundColor: success ? AppColors.primaryMid : AppColors.error,
        behavior:        SnackBarBehavior.floating,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// TAB 1 — My Reserved (beneficiary sees what he reserved)
// ══════════════════════════════════════════════════════
class _MyReservedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(donationsProvider);

    if (state.isReservationsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMid),
      );
    }

    if (state.myReservations.isEmpty) {
      return _EmptyState(
        emoji:    '🛒',
        title:    'No reservations yet',
        subtitle: 'Reserve a donation from\nthe home page!',
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(donationsProvider.notifier).fetchMyReservations(),
      color: AppColors.primaryMid,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: state.myReservations.length,
        itemBuilder: (context, index) {
          final reservation = state.myReservations[index];
          return _BeneficiaryReservationCard(
            reservation: reservation,
            onCancel: () => _onCancel(context, ref, reservation.id),
            onChat:   reservation.status == 'CONFIRMED'
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: reservation.id,
                        otherUserName: 'Donor',
                        donationTitle: reservation.donationTitle ?? 'Donation',
                        donationStatus: reservation.status,
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  Future<void> _onCancel(
    BuildContext context, WidgetRef ref, String reservationId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Cancel Reservation',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to cancel this reservation?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(
                color:      AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ref
        .read(donationsProvider.notifier)
        .cancelReservation(reservationId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:         Text(success ? 'Reservation cancelled' : 'Failed to cancel'),
        backgroundColor: success ? AppColors.primaryMid : AppColors.error,
        behavior:        SnackBarBehavior.floating,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// DONOR RESERVATION CARD
// ══════════════════════════════════════════════════════
class _DonorReservationCard extends StatelessWidget {
  const _DonorReservationCard({
    required this.reservation,
    required this.onConfirm,
    required this.onCancel,
    required this.onChat,
  });

  final ReservationModel reservation;
  final VoidCallback     onConfirm;
  final VoidCallback     onCancel;
  final VoidCallback     onChat;

  @override
  Widget build(BuildContext context) {
    final isPending   = reservation.status == 'PENDING';
    final isConfirmed = reservation.status == 'CONFIRMED';
    final reservedByLabel = reservation.beneficiaryName == null ||
            reservation.beneficiaryName!.trim().isEmpty
        ? 'Reserved: ${_formatDate(reservation.reservedAt)}'
        : 'Reserved by ${reservation.beneficiaryName} · ${_formatDate(reservation.reservedAt)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Donation image ───────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: reservation.donationImageUrl != null
                      ? Image.network(
                          reservation.donationImageUrl!,
                          width:  80,
                          height: 80,
                          fit:    BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _ImagePlaceholder(category: reservation.donationCategory),
                        )
                      : _ImagePlaceholder(category: reservation.donationCategory),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Status + title ─────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              reservation.donationTitle ?? 'Donation',
                              style: const TextStyle(
                                fontSize:   15,
                                fontWeight: FontWeight.w700,
                                color:      AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusBadge(status: reservation.status),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // ── Tags ───────────────────
                      Wrap(
                        spacing: 4,
                        children: [
                          if (reservation.donationCategory != null)
                            _SmallTag(
                              label: _categoryLabel(reservation.donationCategory!),
                            ),
                          if (reservation.donationQuantity != null)
                            _SmallTag(label: reservation.donationQuantity!),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ── Reserved date ──────────
                      Text(
                        reservedByLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color:    AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Location row ──────────────────────
          if (reservation.donationMeetingZone != null)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:        AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size:  14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    reservation.donationMeetingZone!,
                    style: const TextStyle(
                      fontSize: 12,
                      color:    AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          // ── Action buttons ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [

                // ── Chat (only if CONFIRMED) ───────
                if (isConfirmed)
                  Expanded(
                    child: _ActionButton(
                      label:   'Chat',
                      icon:    Icons.chat_bubble_outline_rounded,
                      color:   AppColors.surfaceVariant,
                      textColor: AppColors.textPrimary,
                      onTap:   onChat,
                    ),
                  ),

                if (isConfirmed) const SizedBox(width: 10),

                // ── Confirm (only if PENDING) ──────
                if (isPending)
                  Expanded(
                    child: _ActionButton(
                      label:     'Confirm',
                      icon:      Icons.check_circle_outline_rounded,
                      color:     AppColors.primarySurface,
                      textColor: AppColors.primary,
                      onTap:     onConfirm,
                    ),
                  ),

                if (isPending) const SizedBox(width: 10),

                // ── Cancel ─────────────────────────
                if (isPending || isConfirmed)
                  Expanded(
                    child: _ActionButton(
                      label:     isPending ? 'Decline' : 'Cancel',
                      icon:      Icons.cancel_outlined,
                      color:     AppColors.errorSurface,
                      textColor: AppColors.error,
                      onTap:     onCancel,
                    ),
                  ),

                // ── Completed / Cancelled state ────
                if (!isPending && !isConfirmed)
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color:        AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          _statusLabel(reservation.status),
                          style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                            color:      AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// BENEFICIARY RESERVATION CARD
// ══════════════════════════════════════════════════════
class _BeneficiaryReservationCard extends StatelessWidget {
  const _BeneficiaryReservationCard({
    required this.reservation,
    required this.onCancel,
    this.onChat,
  });

  final ReservationModel reservation;
  final VoidCallback     onCancel;
  final VoidCallback?    onChat;

  @override
  Widget build(BuildContext context) {
    final isPending   = reservation.status == 'PENDING';
    final isConfirmed = reservation.status == 'CONFIRMED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Image ────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: reservation.donationImageUrl != null
                      ? Image.network(
                          reservation.donationImageUrl!,
                          width:  80,
                          height: 80,
                          fit:    BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _ImagePlaceholder(category: reservation.donationCategory),
                        )
                      : _ImagePlaceholder(category: reservation.donationCategory),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              reservation.donationTitle ?? 'Donation',
                              style: const TextStyle(
                                fontSize:   15,
                                fontWeight: FontWeight.w700,
                                color:      AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusBadge(status: reservation.status),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Wrap(
                        spacing: 4,
                        children: [
                          if (reservation.donationCategory != null)
                            _SmallTag(
                              label: _categoryLabel(reservation.donationCategory!),
                            ),
                          if (reservation.donationQuantity != null)
                            _SmallTag(label: reservation.donationQuantity!),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ── Waiting message for PENDING ─
                      if (isPending)
                        Row(
                          children: const [
                            Icon(
                              Icons.access_time_rounded,
                              size:  12,
                              color: AppColors.warning,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Waiting for donor confirmation...',
                              style: TextStyle(
                                fontSize: 11,
                                color:    AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                      if (isConfirmed)
                        Row(
                          children: const [
                            Icon(
                              Icons.check_circle_rounded,
                              size:  12,
                              color: AppColors.primaryMid,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Confirmed! Chat is available',
                              style: TextStyle(
                                fontSize:   11,
                                color:      AppColors.primaryMid,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Location ──────────────────────────
          if (reservation.donationMeetingZone != null)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:        AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size:  14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reservation.donationMeetingZone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color:    AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    reservation.status,
                    style: const TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                      color:      AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          // ── Buttons ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [

                // ── Chat (only CONFIRMED) ──────────
                if (isConfirmed && onChat != null)
                  Expanded(
                    child: _ActionButton(
                      label:     'Chat',
                      icon:      Icons.chat_bubble_outline_rounded,
                      color:     AppColors.surfaceVariant,
                      textColor: AppColors.textPrimary,
                      onTap:     onChat!,
                    ),
                  ),

                if (isConfirmed && onChat != null)
                  const SizedBox(width: 10),

                // ── Cancel (only PENDING/CONFIRMED) ─
                if (isPending || isConfirmed)
                  Expanded(
                    child: _ActionButton(
                      label:     'Cancel',
                      icon:      Icons.cancel_outlined,
                      color:     AppColors.errorSurface,
                      textColor: AppColors.error,
                      onTap:     onCancel,
                    ),
                  ),

                // ── Done state ─────────────────────
                if (!isPending && !isConfirmed)
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color:        AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          _statusLabel(reservation.status),
                          style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                            color:      AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────
String _categoryLabel(String c) {
  switch (c) {
    case 'FRESH':  return 'Fresh';
    case 'DRY':    return 'Dry';
    case 'URGENT': return 'Urgent';
    default:       return c;
  }
}

String _statusLabel(String s) {
  switch (s) {
    case 'PENDING':   return 'Pending';
    case 'CONFIRMED': return 'Confirmed';
    case 'CANCELLED': return 'Cancelled';
    case 'COMPLETED': return 'Completed';
    default:          return s;
  }
}

String _formatDate(String dateStr) {
  try {
    final d = DateTime.parse(dateStr).toLocal();
    return '${d.day}/${d.month}/${d.year}';
  } catch (_) {
    return dateStr;
  }
}

// ── Status Badge ───────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    String label;

    switch (status) {
      case 'CONFIRMED':
        bg        = AppColors.primarySurface;
        textColor = AppColors.primary;
        label     = '✓ Confirmed';
        break;
      case 'CANCELLED':
        bg        = AppColors.errorSurface;
        textColor = AppColors.error;
        label     = 'Cancelled';
        break;
      case 'COMPLETED':
        bg        = const Color(0xFFE8F5E9);
        textColor = Colors.green;
        label     = 'Completed';
        break;
      default:
        bg        = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF59E0B);
        label     = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize:   10,
          fontWeight: FontWeight.w600,
          color:      textColor,
        ),
      ),
    );
  }
}

// ── Small Tag ──────────────────────────────────────────
class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color:    AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Action Button ──────────────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String       label;
  final IconData     icon;
  final Color        color;
  final Color        textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height:  44,
        decoration: BoxDecoration(
          color:        color,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image Placeholder ──────────────────────────────────
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.category});
  final String? category;

  @override
  Widget build(BuildContext context) {
    Color bg;
    String emoji;

    switch (category) {
      case 'FRESH':
        bg    = AppColors.primarySurface;
        emoji = '🥗';
        break;
      case 'URGENT':
        bg    = AppColors.errorSurface;
        emoji = '⚡';
        break;
      default:
        bg    = AppColors.accentSurface;
        emoji = '🌾';
    }

    return Container(
      width:  80,
      height: 80,
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 32)),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize:   18,
              fontWeight: FontWeight.w700,
              color:      AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color:    AppColors.textSecondary,
              height:   1.5,
            ),
          ),
        ],
      ),
    );
  }
}
