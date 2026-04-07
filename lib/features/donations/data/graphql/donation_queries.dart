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
        category
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
        category
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
        category
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
    }
  }
''';
}
