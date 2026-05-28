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
    mutation ReserveDonation(\$donationId: ID!, \$quantity: Int) {
      reserveDonation(donationId: \$donationId, quantity: \$quantity) {
        id
        status
        quantityReserved
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
        completedAt
        updatedAt
      }
    }
  ''';

  // ── Delete donation ────────────────────────────
  static const String deleteDonation = '''
    mutation DeleteDonation(\$id: ID!) {
      deleteDonation(id: \$id)
    }
  ''';

  static const String updateDonation = '''
    mutation UpdateDonation(\$id: ID!, \$input: UpdateDonationInput!) {
      updateDonation(id: \$id, input: \$input) {
        id
        title
        description
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
        checklistConfirmed
        createdAt
        updatedAt
      }
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
    }
  }
''';
}
