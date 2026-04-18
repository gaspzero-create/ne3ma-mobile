import 'package:flutter/material.dart';
import '../../../../core/network/graphql_client.dart';
import '../graphql/donation_queries.dart';
import '../graphql/donation_mutations.dart';
import '../models/donation_model.dart';

class DonationRepository {
  // ── Get nearby donations ───────────────────────
  Future<List<DonationModel>> getNearbyDonations({
    required double lat,
    required double lng,
    double radiusKm = 1000.00,
    String? categoryId,
    String? pickupType,
    bool? urgentOnly,
  }) async {
    debugPrint('📤 DonationRepo: Fetching nearby donations...');
    debugPrint('📍 DonationRepo: lat=$lat, lng=$lng, radius=$radiusKm');

    final filters = <String, dynamic>{};
    if (categoryId != null) filters['categoryId'] = categoryId;
    if (pickupType != null) filters['pickupType'] = pickupType;
    if (urgentOnly != null) filters['urgentOnly'] = urgentOnly;

    final data = await GraphQLClient.query(
      document: DonationQueries.nearbyDonations,
      variables: {
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        if (filters.isNotEmpty) 'filters': filters,
      },
    );

    final list = data['nearbyDonations'] as List;
    debugPrint('✅ DonationRepo: Got ${list.length} donations');
    return list.map((e) => DonationModel.fromMap(e)).toList();
  }

  // ── Get my donations ───────────────────────────
  Future<List<DonationModel>> getMyDonations() async {
    debugPrint('📤 DonationRepo: Fetching my donations...');
    final data = await GraphQLClient.query(
      document: DonationQueries.myDonations,
    );
    final list = data['myDonations'] as List;
    debugPrint('✅ DonationRepo: Got ${list.length} my donations');
    return list.map((e) => DonationModel.fromMap(e)).toList();
  }

  // ── Get single donation ────────────────────────
  Future<DonationModel?> getDonation(String id) async {
    debugPrint('📤 DonationRepo: Fetching donation $id...');
    final data = await GraphQLClient.query(
      document: DonationQueries.donation,
      variables: {'id': id},
    );
    if (data['donation'] == null) return null;
    return DonationModel.fromMap(data['donation']);
  }

  // ── Get my reservations ────────────────────────
  Future<List<ReservationModel>> getMyReservations() async {
    debugPrint('📤 DonationRepo: Fetching my reservations...');
    final data = await GraphQLClient.query(
      document: DonationQueries.myReservations,
    );
    final list = data['myReservations'] as List;
    debugPrint('✅ DonationRepo: Got ${list.length} reservations');
    return list.map((e) => ReservationModel.fromMap(e)).toList();
  }

  // ── Create donation ────────────────────────────
  Future<DonationModel> createDonation({
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
    debugPrint('📤 DonationRepo: Creating donation...');
    debugPrint('📝 DonationRepo: title=$title, categoryId=$categoryId');

    final data = await GraphQLClient.query(
      document: DonationMutations.createDonation,
      variables: {
        'input': {
          'title': title,
          'categoryId': categoryId,
          'pickupType': pickupType,
          'quantity': quantity,
          'expiresAt': expiresAt,
          if (description != null) 'description': description,
          if (imageBase64 != null) 'imageBase64': imageBase64,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (meetingZone != null) 'meetingZone': meetingZone,
          'checklistConfirmed': checklistConfirmed,
        },
      },
    );

    debugPrint('✅ DonationRepo: Donation created!');
    return DonationModel.fromMap(data['createDonation']);
  }

  // ── Reserve donation ───────────────────────────
  Future<ReservationModel> reserveDonation(String donationId) async {
    debugPrint('📤 DonationRepo: Reserving donation $donationId...');
    final data = await GraphQLClient.query(
      document: DonationMutations.reserveDonation,
      variables: {'donationId': donationId},
    );
    debugPrint('✅ DonationRepo: Reservation created!');
    return ReservationModel.fromMap(data['reserveDonation']);
  }

  // ── Cancel reservation ─────────────────────────
  Future<bool> cancelReservation(String reservationId) async {
    debugPrint('📤 DonationRepo: Cancelling reservation $reservationId...');
    final data = await GraphQLClient.query(
      document: DonationMutations.cancelReservation,
      variables: {'reservationId': reservationId},
    );
    debugPrint('✅ DonationRepo: Reservation cancelled!');
    return data['cancelReservation'] as bool;
  }

  // ── Delete donation ────────────────────────────
  Future<bool> deleteDonation(String id) async {
    debugPrint('📤 DonationRepo: Deleting donation $id...');
    final data = await GraphQLClient.query(
      document: DonationMutations.deleteDonation,
      variables: {'id': id},
    );
    debugPrint('✅ DonationRepo: Donation deleted!');
    return data['deleteDonation'] as bool;
  }

  Future<DonationModel> updateDonation({
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
    debugPrint('📤 DonationRepo: Updating donation $id...');

    final input = <String, dynamic>{
      'title': title,
      'categoryId': categoryId,
      'pickupType': pickupType,
      'quantity': quantity,
      'expiresAt': expiresAt,
      if (description != null) 'description': description,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (meetingZone != null) 'meetingZone': meetingZone,
      if (checklistConfirmed != null) 'checklistConfirmed': checklistConfirmed,
    };

    final data = await GraphQLClient.query(
      document: DonationMutations.updateDonation,
      variables: {'id': id, 'input': input},
    );

    debugPrint('✅ DonationRepo: Donation updated!');
    return DonationModel.fromMap(data['updateDonation']);
  }

  Future<List<ReservationModel>> getMyDonationReservations() async {
    debugPrint('📤 DonationRepo: Fetching my donation reservations...');
    final data = await GraphQLClient.query(
      document: DonationQueries.myDonationReservations,
    );
    final list = data['myDonationReservations'] as List;
    debugPrint('✅ DonationRepo: Got ${list.length} donation reservations');
    return list.map((e) => ReservationModel.fromMap(e)).toList();
  }

  Future<ReservationModel> confirmReservation(String reservationId) async {
    debugPrint('📤 DonationRepo: Confirming reservation $reservationId...');
    final data = await GraphQLClient.query(
      document: DonationMutations.confirmReservation,
      variables: {'reservationId': reservationId},
    );
    debugPrint('✅ DonationRepo: Reservation confirmed!');
    return ReservationModel.fromMap(data['confirmReservation']);
  }

  Future<ReservationModel> completeReservation(String reservationId) async {
    debugPrint('📤 DonationRepo: Completing reservation $reservationId...');
    final data = await GraphQLClient.query(
      document: DonationMutations.completeReservation,
      variables: {'reservationId': reservationId},
    );
    debugPrint('✅ DonationRepo: Reservation completed!');
    return ReservationModel.fromMap(data['completeReservation']);
  }
}
