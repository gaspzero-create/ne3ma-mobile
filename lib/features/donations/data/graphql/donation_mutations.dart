class DonationMutations {
  DonationMutations._();

  // ── Create donation ────────────────────────────
  static const String createDonation = '''
    mutation CreateDonation(\$input: CreateDonationInput!) {
      createDonation(input: \$input) {
        id
        title
        category {
          id
          name
          description
          isActive
        }
        status
        pickupType
        quantity
        expiresAt
        imageUrl
        lat
        lng
        meetingZone
        createdAt
      }
    }
  ''';

  // ── Reserve donation ───────────────────────────
  static const String reserveDonation = '''
    mutation ReserveDonation(\$donationId: ID!) {
      reserveDonation(donationId: \$donationId) {
        id
        status
        createdAt
        confirmedAt
      }
    }
  ''';

  // ── Cancel reservation ─────────────────────────
  static const String cancelReservation = '''
    mutation CancelReservation(\$reservationId: ID!) {
      cancelReservation(reservationId: \$reservationId)
    }
  ''';

  // ── Complete reservation ───────────────────────
  static const String completeReservation = '''
    mutation CompleteReservation(\$reservationId: ID!) {
      completeReservation(reservationId: \$reservationId) {
        id
        status
        confirmedAt
      }
    }
  ''';

  // ── Delete donation ────────────────────────────
  static const String deleteDonation = '''
    mutation DeleteDonation(\$id: ID!) {
      deleteDonation(id: \$id)
    }
  ''';

static const String confirmReservation = '''
  mutation ConfirmReservation(\$reservationId: ID!) {
    confirmReservation(reservationId: \$reservationId) {
      id
      status
      createdAt
      reservedAt
      confirmedAt
      updatedAt
      beneficiary {
        id
        fullName
        phoneNumber
        email
        wilaya
        baladiya
      }
      donation {
        id
        title
        category {
          id
          name
        }
        imageUrl
        meetingZone
        pickupType
        quantity
      }
    }
  }
''';
}
