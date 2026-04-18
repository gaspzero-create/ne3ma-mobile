import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/donation_model.dart';
import '../data/repositories/donation_repository.dart';
import '../utils/category_utils.dart';

// ── Repository provider ────────────────────────────────
final donationRepositoryProvider = Provider<DonationRepository>((ref) {
  return DonationRepository();
});

// ── Filter State ───────────────────────────────────────
class DonationFilter {
  static const String myDonationsKey = '__my_donations__';
  // Label-based filters that are resolved client-side (not sent to backend)
  static const Set<String> _labelFilters = {
    'FRESH',
    'DRY',
    'URGENT',
    'MY',
    '__my_donations__',
  };

  final String? categoryId;
  final double radiusKm;

  const DonationFilter({this.categoryId, this.radiusKm = 1000.0});

  /// True when the filter is a real backend UUID (not a label)
  bool get isRealId =>
      categoryId != null && !_labelFilters.contains(categoryId);

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
  final List<DonationModel> donations;
  final List<DonationModel> myDonations;
  final List<ReservationModel> myReservations;
  final List<ReservationModel> myDonationReservations;
  final bool isLoading;
  final bool isReservationsLoading;
  final bool isDonationReservationsLoading;
  final String? error;
  final DonationFilter filter;

  const DonationsState({
    this.donations = const [],
    this.myDonations = const [],
    this.myReservations = const [],
    this.myDonationReservations = const [],
    this.isLoading = false,
    this.isReservationsLoading = false,
    this.isDonationReservationsLoading = false,
    this.error,
    this.filter = const DonationFilter(),
  });

  DonationsState copyWith({
    List<DonationModel>? donations,
    List<DonationModel>? myDonations,
    List<ReservationModel>? myReservations,
    List<ReservationModel>? myDonationReservations,
    bool? isLoading,
    bool? isReservationsLoading,
    bool? isDonationReservationsLoading,
    String? error,
    DonationFilter? filter,
  }) {
    return DonationsState(
      donations: donations ?? this.donations,
      myDonations: myDonations ?? this.myDonations,
      myReservations: myReservations ?? this.myReservations,
      myDonationReservations:
          myDonationReservations ?? this.myDonationReservations,
      isLoading: isLoading ?? this.isLoading,
      isReservationsLoading:
          isReservationsLoading ?? this.isReservationsLoading,
      isDonationReservationsLoading:
          isDonationReservationsLoading ?? this.isDonationReservationsLoading,
      error: error,
      filter: filter ?? this.filter,
    );
  }

  // ── Filtered list ──────────────────────────────
  List<DonationModel> get filteredDonations {
    final catId = filter.categoryId;
    if (catId == null || catId == DonationFilter.myDonationsKey) {
      return donations;
    }

    return donations.where((d) {
      // Real UUID match (e.g. from category picker)
      if (d.categoryId != null && d.categoryId == catId) return true;
      // Label-based match: FRESH / DRY / URGENT
      return matchesStoredCategory(
        storedValue: catId,
        categoryId: d.categoryId ?? '',
        categoryName: d.category,
      );
    }).toList();
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
        lat: lat,
        lng: lng,
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
  Future<void> fetchMyReservations({bool background = false}) async {
    if (!background) {
      debugPrint('📤 DonationsProvider: Fetching reservations...');
      state = state.copyWith(isReservationsLoading: true, error: null);
    }
    try {
      final reservations = await _repository.getMyReservations();
      if (!background) {
        debugPrint('✅ DonationsProvider: ${reservations.length} reservations');
      }
      state = state.copyWith(
        isReservationsLoading: false,
        myReservations: reservations,
      );
    } catch (e) {
      if (!background) {
        debugPrint('❌ DonationsProvider: Reservations error - $e');
      }
      state = state.copyWith(
        isReservationsLoading: false,
        error: background ? state.error : e.toString(),
      );
    }
  }

  // ── Fetch reservations on my donations ────────
  Future<void> fetchMyDonationReservations({bool background = false}) async {
    if (!background) {
      debugPrint('📤 DonationsProvider: Fetching my donation reservations...');
      state = state.copyWith(isDonationReservationsLoading: true, error: null);
    }
    try {
      final reservations = await _repository.getMyDonationReservations();
      if (!background) {
        debugPrint(
          '✅ DonationsProvider: ${reservations.length} donation reservations',
        );
      }
      state = state.copyWith(
        isDonationReservationsLoading: false,
        myDonationReservations: reservations,
      );
    } catch (e) {
      if (!background) {
        debugPrint('❌ DonationsProvider: Donation reservations error - $e');
      }
      state = state.copyWith(
        isDonationReservationsLoading: false,
        error: background ? state.error : e.toString(),
      );
    }
  }

  // ── Set filter ─────────────────────────────────
  void setFilter(String? categoryId) {
    debugPrint('🔍 DonationsProvider: Filter = $categoryId');
    state = state.copyWith(
      filter: state.filter.copyWith(
        categoryId: categoryId,
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
              'id': d.id,
              'title': d.title,
              'description': d.description,
              'donor': {
                'id': d.donorId,
                'fullName': d.donorName,
                'avatarUrl': d.donorAvatarUrl,
                'badge': d.donorBadge,
                'role': d.donorRole,
                'wilaya': d.donorWilaya,
                'baladiya': d.donorBaladiya,
              },
              'category': {'id': d.categoryId, 'name': d.category},
              'status': 'RESERVED',
              'pickupType': d.pickupType,
              'quantity': d.quantity,
              'expiresAt': d.expiresAt,
              'imageUrl': d.imageUrl,
              'lat': d.lat,
              'lng': d.lng,
              'meetingZone': d.meetingZone,
              'distanceKm': d.distanceKm,
              'createdAt': d.createdAt,
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
        title: title,
        categoryId: categoryId,
        pickupType: pickupType,
        quantity: quantity,
        expiresAt: expiresAt,
        description: description,
        imageBase64: imageBase64,
        lat: lat,
        lng: lng,
        meetingZone: meetingZone,
        checklistConfirmed: checklistConfirmed,
      );
      debugPrint('✅ DonationsProvider: Created - ${donation.id}');
      state = state.copyWith(myDonations: [donation, ...state.myDonations]);
      return true;
    } catch (e) {
      debugPrint('❌ DonationsProvider: Create error - $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateDonation({
    required String id,
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
    bool? checklistConfirmed,
  }) async {
    debugPrint('📤 DonationsProvider: Updating $id...');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final donation = await _repository.updateDonation(
        id: id,
        title: title,
        categoryId: categoryId,
        pickupType: pickupType,
        quantity: quantity,
        expiresAt: expiresAt,
        description: description,
        imageBase64: imageBase64,
        lat: lat,
        lng: lng,
        meetingZone: meetingZone,
        checklistConfirmed: checklistConfirmed,
      );
      debugPrint('✅ DonationsProvider: Updated - ${donation.id}');
      final updatedMyDonations = state.myDonations
          .map((item) => item.id == id ? donation : item)
          .toList();
      state = state.copyWith(
        isLoading: false,
        myDonations: updatedMyDonations,
        donations: state.donations
            .map((item) => item.id == id ? donation : item)
            .toList(),
      );
      try {
        final refreshedMyDonations = await _repository.getMyDonations();
        state = state.copyWith(myDonations: refreshedMyDonations);
      } catch (refreshError) {
        debugPrint(
          '⚠️ DonationsProvider: Refresh after update failed - $refreshError',
        );
      }
      return true;
    } catch (e) {
      debugPrint('❌ DonationsProvider: Update error - $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteDonation(String id) async {
    debugPrint('📤 DonationsProvider: Deleting $id...');
    try {
      final success = await _repository.deleteDonation(id);
      if (!success) {
        state = state.copyWith(error: 'Failed to delete donation');
        return false;
      }

      state = state.copyWith(
        myDonations: state.myDonations.where((item) => item.id != id).toList(),
        donations: state.donations.where((item) => item.id != id).toList(),
      );
      debugPrint('✅ DonationsProvider: Deleted - $id');
      return true;
    } catch (e) {
      debugPrint('❌ DonationsProvider: Delete error - $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> confirmReservation(String reservationId) async {
    debugPrint('📤 DonationsProvider: Confirming $reservationId...');
    try {
      final slimResult = await _repository.confirmReservation(reservationId);
      debugPrint('✅ DonationsProvider: Confirmed!');
      // Merge only status/confirmedAt from slim response, keep existing data
      state = state.copyWith(
        myDonationReservations: state.myDonationReservations.map((r) {
          if (r.id != reservationId) return r;
          return ReservationModel(
            id: r.id,
            status: slimResult.status,
            createdAt: r.createdAt,
            reservedAt: r.reservedAt,
            confirmedAt: slimResult.confirmedAt ?? r.confirmedAt,
            beneficiaryId: r.beneficiaryId,
            beneficiaryName: r.beneficiaryName,
            beneficiaryPhoneNumber: r.beneficiaryPhoneNumber,
            beneficiaryEmail: r.beneficiaryEmail,
            beneficiaryWilaya: r.beneficiaryWilaya,
            beneficiaryBaladiya: r.beneficiaryBaladiya,
            beneficiaryAvatarUrl: r.beneficiaryAvatarUrl,
            donorName: r.donorName,
            donorAvatarUrl: r.donorAvatarUrl,
            donationId: r.donationId,
            donationTitle: r.donationTitle,
            donationCategory: r.donationCategory,
            donationCategoryId: r.donationCategoryId,
            donationImageUrl: r.donationImageUrl,
            donationMeetingZone: r.donationMeetingZone,
            donationPickupType: r.donationPickupType,
            donationQuantity: r.donationQuantity,
          );
        }).toList(),
      );
      return true;
    } catch (e) {
      debugPrint('❌ DonationsProvider: Confirm error - $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> completeReservation(String reservationId) async {
    debugPrint('📤 DonationsProvider: Completing $reservationId...');
    try {
      final slimResult = await _repository.completeReservation(reservationId);
      debugPrint('✅ DonationsProvider: Completed!');
      // Update in myDonationReservations (donor view)
      state = state.copyWith(
        myDonationReservations: state.myDonationReservations.map((r) {
          if (r.id != reservationId) return r;
          return ReservationModel(
            id: r.id,
            status: slimResult.status,
            createdAt: r.createdAt,
            reservedAt: r.reservedAt,
            confirmedAt: r.confirmedAt,
            updatedAt: slimResult.updatedAt ?? r.updatedAt,
            beneficiaryId: r.beneficiaryId,
            beneficiaryName: r.beneficiaryName,
            beneficiaryPhoneNumber: r.beneficiaryPhoneNumber,
            beneficiaryEmail: r.beneficiaryEmail,
            beneficiaryWilaya: r.beneficiaryWilaya,
            beneficiaryBaladiya: r.beneficiaryBaladiya,
            beneficiaryAvatarUrl: r.beneficiaryAvatarUrl,
            donorName: r.donorName,
            donorAvatarUrl: r.donorAvatarUrl,
            donationId: r.donationId,
            donationTitle: r.donationTitle,
            donationCategory: r.donationCategory,
            donationCategoryId: r.donationCategoryId,
            donationImageUrl: r.donationImageUrl,
            donationMeetingZone: r.donationMeetingZone,
            donationPickupType: r.donationPickupType,
            donationQuantity: r.donationQuantity,
          );
        }).toList(),
        // Also update in myReservations (beneficiary view) if present
        myReservations: state.myReservations.map((r) {
          if (r.id != reservationId) return r;
          return ReservationModel(
            id: r.id,
            status: slimResult.status,
            createdAt: r.createdAt,
            reservedAt: r.reservedAt,
            confirmedAt: r.confirmedAt,
            updatedAt: slimResult.updatedAt ?? r.updatedAt,
            donorName: r.donorName,
            donorAvatarUrl: r.donorAvatarUrl,
            donationId: r.donationId,
            donationTitle: r.donationTitle,
            donationCategory: r.donationCategory,
            donationCategoryId: r.donationCategoryId,
            donationImageUrl: r.donationImageUrl,
            donationMeetingZone: r.donationMeetingZone,
            donationPickupType: r.donationPickupType,
            donationQuantity: r.donationQuantity,
          );
        }).toList(),
      );
      return true;
    } catch (e) {
      debugPrint('❌ DonationsProvider: Complete error - $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearSessionData() {
    state = const DonationsState();
  }

  String? get _categoryIdForQuery {
    final categoryId = state.filter.categoryId;
    // Only pass real UUID category IDs to the backend.
    // Label-based filters (FRESH/DRY/URGENT/MY) are resolved client-side.
    if (categoryId == null || !state.filter.isRealId) {
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
