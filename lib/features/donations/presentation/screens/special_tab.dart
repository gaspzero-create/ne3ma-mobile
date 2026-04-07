import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/features/donations/data/models/donation_model.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';

class SpecialTab extends ConsumerStatefulWidget {
  const SpecialTab({super.key});

  @override
  ConsumerState<SpecialTab> createState() => _SpecialTabState();
}

class _SpecialTabState extends ConsumerState<SpecialTab> {

  @override
  void initState() {
    super.initState();
    // Fetch reservations when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(donationsProvider.notifier).fetchMyReservations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(donationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Center(
                child: Text(
                  'Special',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Tab label ────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Reserved',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 80,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Content ─────────────────────────
            Expanded(
              child: state.isReservationsLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryMid,
                      ),
                    )
                  : state.myReservations.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: () async {
                            ref
                                .read(donationsProvider.notifier)
                                .fetchMyReservations();
                          },
                          color: AppColors.primaryMid,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              20, 0, 20, 100,
                            ),
                            itemCount: state.myReservations.length,
                            itemBuilder: (context, index) {
                              return _ReservationCard(
                                reservation: state.myReservations[index],
                                onCancel: () => _onCancel(
                                  state.myReservations[index].id,
                                ),
                                onChat: () {
                                  // TODO Sprint 4: open chat
                                  debugPrint('💬 SpecialTab: Opening chat...');
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

  Future<void> _onCancel(String reservationId) async {
    // ── Confirm dialog ─────────────────────────
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
          'Are you sure you want to cancel this reservation?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'No',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    debugPrint('📤 SpecialTab: Cancelling $reservationId...');
    final success = await ref
        .read(donationsProvider.notifier)
        .cancelReservation(reservationId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Reservation cancelled' : 'Failed to cancel',
        ),
        backgroundColor: success ? AppColors.primaryMid : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('📦', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text(
            'No reservations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Reserve a donation from\nthe home page!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reservation Card ───────────────────────────────────
class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.onCancel,
    required this.onChat,
  });

  final ReservationModel reservation;
  final VoidCallback onCancel;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [

          // ── Top row ───────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [

                // ── Placeholder image ────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🥗', style: TextStyle(fontSize: 32)),
                  ),
                ),

                const SizedBox(width: 12),

                // ── Info ──────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Status badge ─────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Donation',   // TODO: show real title when backend adds it
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          _StatusBadge(status: reservation.status),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // ── Tags ─────────────────────
                      Row(
                        children: [
                          _SmallTag(label: 'Reservation'),
                          const SizedBox(width: 6),
                          _SmallTag(label: _statusLabel(reservation.status)),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ── User placeholder ──────────
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primaryMid,
                            child: const Text(
                              'K',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Donor',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: Color(0xFFFFC107),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Location row ──────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Reserved on ',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _formatDate(reservation.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  reservation.status,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Action buttons ────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [

                // ── Chat ───────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: onChat,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Chat',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ── Cancel ─────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: reservation.status == 'PENDING' ||
                            reservation.status == 'CONFIRMED'
                        ? onCancel
                        : null,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: reservation.status == 'CANCELLED' ||
                                reservation.status == 'COMPLETED'
                            ? AppColors.surfaceVariant
                            : AppColors.errorSurface,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          reservation.status == 'CANCELLED'
                              ? 'Cancelled'
                              : reservation.status == 'COMPLETED'
                                  ? 'Completed'
                                  : 'Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: reservation.status == 'CANCELLED' ||
                                    reservation.status == 'COMPLETED'
                                ? AppColors.textSecondary
                                : AppColors.error,
                          ),
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

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':   return 'Pending';
      case 'CONFIRMED': return 'Confirmed';
      case 'CANCELLED': return 'Cancelled';
      case 'COMPLETED': return 'Completed';
      default:          return status;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
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

    switch (status) {
      case 'CONFIRMED':
        bg        = AppColors.primarySurface;
        textColor = AppColors.primary;
        break;
      case 'CANCELLED':
        bg        = AppColors.errorSurface;
        textColor = AppColors.error;
        break;
      case 'COMPLETED':
        bg        = const Color(0xFFE8F5E9);
        textColor = Colors.green;
        break;
      default: // PENDING
        bg        = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 10, color: Colors.green),
          const SizedBox(width: 3),
          Text(
            status == 'CONFIRMED' ? '✓ Confirmed' : status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
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
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}