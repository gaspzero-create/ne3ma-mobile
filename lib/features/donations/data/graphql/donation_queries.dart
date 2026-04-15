class DonationQueries {
  DonationQueries._();

  // ── Nearby donations (home feed) ───────────────
  static const String nearbyDonations = '''
    query NearbyDonations(
      \$lat: Float!
      \$lng: Float!
      \$radiusKm: Float!
      \$filters: DonationFilter
    ) {
      nearbyDonations(
        lat: \$lat
        lng: \$lng
        radiusKm: \$radiusKm
        filters: \$filters
      ) {
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
        distanceKm
        checklistConfirmed
        createdAt
      }
    }
  ''';

  // ── My donations ───────────────────────────────
  static const String myDonations = '''
    query MyDonations {
      myDonations {
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
        distanceKm
        createdAt
      }
    }
  ''';

  // ── Single donation ────────────────────────────
  static const String donation = '''
    query Donation(\$id: ID!) {
      donation(id: \$id) {
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
        distanceKm
        checklistConfirmed
        createdAt
      }
    }
  ''';
  static const String myReservations = '''
  query MyReservations {
    myReservations {
      id
      status
      reservedAt
      confirmedAt
      createdAt
      updatedAt
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
  // ── Reservations on MY donations (donor view) ──
  static const String myDonationReservations = '''
  query MyDonationReservations {
    myDonationReservations {
      id
      status
      reservedAt
      confirmedAt
      createdAt
      updatedAt
      beneficiary {
        id
        fullName
        phoneNumber
        email
        wilaya
        baladiya
        avatarUrl
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
