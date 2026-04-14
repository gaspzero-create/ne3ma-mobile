import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/donation_model.dart';
import '../data/repositories/donation_repository.dart';

// ── Repository provider ────────────────────────────────
final donationRepositoryProvider = Provider<DonationRepository>((ref) {
  return DonationRepository();
});

// ── Filter State ───────────────────────────────────────
class DonationFilter {
  static const String myDonationsKey = '__my_donations__';

  final String? categoryId;
  final double radiusKm;

  const DonationFilter({
    this.categoryId,
    this.radiusKm = 1000.0,
  });

  DonationFilter copyWith({
    String? categoryId,
    bool clearCategory = false,
    double? radiusKm,
  }) {
    return DonationFilter(
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }
}

// ── Donations State ────────────────────────────────────
class DonationsState {
  final List<DonationModel>    donations;
  final List<DonationModel>    myDonations;
  final List<ReservationModel> myReservations;
  final List<ReservationModel> myDonationReservations;
  final bool                   isLoading;
  final bool                   isReservationsLoading;
  final bool                   isDonationReservationsLoading;
  final String?                error;
  final DonationFilter         filter;

  const DonationsState({
    this.donations             = const [],
    this.myDonations           = const [],
    this.myReservations        = const [],
    this.myDonationReservations = const [],
    this.isLoading             = false,
    this.isReservationsLoading = false,
    this.isDonationReservationsLoading = false,
    this.error,
    this.filter                = const DonationFilter(),
  });

  DonationsState copyWith({
    List<DonationModel>?    donations,
    List<DonationModel>?    myDonations,
    List<ReservationModel>? myReservations,
    List<ReservationModel>? myDonationReservations,
    bool?                   isLoading,
    bool?                   isReservationsLoading,
    bool?                   isDonationReservationsLoading,
    String?                 error,
    DonationFilter?         filter,
  }) {
    return DonationsState(
      donations:             donations             ?? this.donations,
      myDonations:           myDonations           ?? this.myDonations,
      myReservations:        myReservations        ?? this.myReservations,
      myDonationReservations:
          myDonationReservations ?? this.myDonationReservations,
      isLoading:             isLoading             ?? this.isLoading,
      isReservationsLoading: isReservationsLoading ?? this.isReservationsLoading,
      isDonationReservationsLoading:
          isDonationReservationsLoading ?? this.isDonationReservationsLoading,
      error:                 error,
      filter:                filter                ?? this.filter,
    );
  }

  // ── Filtered list ──────────────────────────────
  List<DonationModel> get filteredDonations {
    if (filter.categoryId == null ||
        filter.categoryId == DonationFilter.myDonationsKey) {
      return donations;
    }

    return donations
        .where((d) => d.categoryId == filter.categoryId)
        .toList();
  }
}

// ── Donations Notifier ─────────────────────────────────
class DonationsNotifier extends StateNotifier<DonationsState> {
  final DonationRepository _repository;

  DonationsNotifier(this._repository) : super(const DonationsState());

  // ── Fetch nearby donations ─────────────────────
  Future<void> fetchNearbyDonations({
    required double lat,
    required double lng,
  }) async {
    debugPrint('📤 DonationsProvider: Fetching nearby...');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final donations = await _repository.getNearbyDonations(
        lat:      lat,
        lng:      lng,
        radiusKm: state.filter.radiusKm,
        categoryId: _categoryIdForQuery,
      );
      final filtered = donations
          .where((d) => !state.myDonations.any((my) => my.id == d.id))
          .toList();
      debugPrint('✅ DonationsProvider: ${filtered.length} nearby donations');
      state = state.copyWith(isLoading: false, donations: filtered);
    } catch (e) {
      debugPrint('❌ DonationsProvider: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Fetch my donations ─────────────────────────
  Future<void> fetchMyDonations() async {
    debugPrint('📤 DonationsProvider: Fetching my donations...');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final myDonations = await _repository.getMyDonations();
      debugPrint('✅ DonationsProvider: Got ${myDonations.length} my donations');
      state = state.copyWith(isLoading: false, myDonations: myDonations);
    } catch (e) {
      debugPrint('❌ DonationsProvider: My donations error - $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Fetch my reservations ──────────────────────
  Future<void> fetchMyReservations() async {
    debugPrint('📤 DonationsProvider: Fetching reservations...');
    state = state.copyWith(isReservationsLoading: true, error: null);
    try {
      final reservations = await _repository.getMyReservations();
      debugPrint('✅ DonationsProvider: ${reservations.length} reservations');
      state = state.copyWith(
        isReservationsLoading: false,
        myReservations: reservations,
      );
    } catch (e) {
      debugPrint('❌ DonationsProvider: Reservations error - $e');
      state = state.copyWith(
        isReservationsLoading: false,
        error: e.toString(),
      );
    }
  }

  // ── Fetch reservations on my donations ────────
  Future<void> fetchMyDonationReservations() async {
    debugPrint('📤 DonationsProvider: Fetching my donation reservations...');
    state = state.copyWith(
      isDonationReservationsLoading: true,
      error: null,
    );
    try {
      final reservations = await _repository.getMyDonationReservations();
      debugPrint(
        '✅ DonationsProvider: ${reservations.length} donation reservations',
      );
      state = state.copyWith(
        isDonationReservationsLoading: false,
        myDonationReservations: reservations,
      );
    } catch (e) {
      debugPrint('❌ DonationsProvider: Donation reservations error - $e');
      state = state.copyWith(
        isDonationReservationsLoading: false,
        error: e.toString(),
      );
    }
  }

  // ── Set filter ─────────────────────────────────
  void setFilter(String? categoryId) {
    debugPrint('🔍 DonationsProvider: Filter = $categoryId');
    state = state.copyWith(
      filter: state.filter.copyWith(
        categoryId:    categoryId,
        clearCategory: categoryId == null,
      ),
    );
  }

  // ── Reserve donation ───────────────────────────
  Future<bool> reserveDonation(String donationId) async {
    debugPrint('📤 DonationsProvider: Reserving $donationId...');
    try {
      await _repository.reserveDonation(donationId);
      debugPrint('✅ DonationsProvider: Reserved!');
      state = state.copyWith(
        donations: state.donations.map((d) {
          if (d.id == donationId) {
            return DonationModel.fromMap({
              'id':          d.id,
              'title':       d.title,
              'description': d.description,
              'category': {
                'id': d.categoryId,
                'name': d.category,
              },
              'status':      'RESERVED',
              'pickupType':  d.pickupType,
              'quantity':    d.quantity,
              'expiresAt':   d.expiresAt,
              'imageUrl':    d.imageUrl,
              'lat':         d.lat,
              'lng':         d.lng,
              'meetingZone': d.meetingZone,
              'distanceKm':  d.distanceKm,
              'createdAt':   d.createdAt,
            });
          }
          return d;
        }).toList(),
      );
      return true;
    } catch (e) {
      debugPrint('❌ DonationsProvider: Reserve error - $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Cancel reservation ─────────────────────────
  Future<bool> cancelReservation(String reservationId) async {
    debugPrint('📤 DonationsProvider: Cancelling $reservationId...');
    try {
      await _repository.cancelReservation(reservationId);
      debugPrint('✅ DonationsProvider: Cancelled!');
      state = state.copyWith(
        myReservations: state.myReservations
            .where((r) => r.id != reservationId)
            .toList(),
        myDonationReservations: state.myDonationReservations
            .where((r) => r.id != reservationId)
            .toList(),
      );
      return true;
    } catch (e) {
      debugPrint('❌ DonationsProvider: Cancel error - $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Create donation ────────────────────────────
  Future<bool> createDonation({
    required String title,
    required String categoryId,
    required String pickupType,
    required String quantity,
    required String expiresAt,
    String? description,
    String? imageBase64,
    double? lat,
    double? lng,
    String? meetingZone,
    bool checklistConfirmed = false,
  }) async {
    debugPrint('📤 DonationsProvider: Creating donation...');
    try {
      final donation = await _repository.createDonation(
        title:              title,
        categoryId:         categoryId,
        pickupType:         pickupType,
        quantity:           quantity,
        expiresAt:          expiresAt,
        description:        description,
        imageBase64:        imageBase64,
        lat:                lat,
        lng:                lng,
        meetingZone:        meetingZone,
        checklistConfirmed: checklistConfirmed,
      );
      debugPrint('✅ DonationsProvider: Created - ${donation.id}');
      state = state.copyWith(
        myDonations: [donation, ...state.myDonations],
      );
      return true;
    } catch (e) {
      debugPrint('❌ DonationsProvider: Create error - $e');
      return false;
    }
  }

  Future<bool> confirmReservation(String reservationId) async {
    debugPrint('📤 DonationsProvider: Confirming $reservationId...');
    try {
      final updatedReservation =
          await _repository.confirmReservation(reservationId);
      debugPrint('✅ DonationsProvider: Confirmed!');
      state = state.copyWith(
        myDonationReservations: state.myDonationReservations.map((r) {
          return r.id == reservationId ? updatedReservation : r;
        }).toList(),
      );
      return true;
    } catch (e) {
      debugPrint('❌ DonationsProvider: Confirm error - $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearSessionData() {
    state = const DonationsState();
  }

  String? get _categoryIdForQuery {
    final categoryId = state.filter.categoryId;
    if (categoryId == DonationFilter.myDonationsKey) {
      return null;
    }
    return categoryId;
  }
}

// ── Provider ───────────────────────────────────────────
final donationsProvider =
    StateNotifierProvider<DonationsNotifier, DonationsState>((ref) {
  return DonationsNotifier(ref.read(donationRepositoryProvider));
});
