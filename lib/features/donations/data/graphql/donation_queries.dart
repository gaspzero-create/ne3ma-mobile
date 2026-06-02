class DonationQueries {
  DonationQueries._();

  static const String getRouteForReservation = '''
    query GetRouteForReservation(\$input: GetRouteInput!) {
      getRouteForReservation(input: \$input) {
        distance
        duration
        geometry
        steps {
          distance
          duration
          instruction
          name
        }
      }
    }
  ''';

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
        donor {
          id
          fullName
          avatarUrl
          badge
          role
          wilaya
          baladiya
        }
        category {
          id
          name
          description
          isActive
        }
        status
        pickupType
        quantity
        quantityAvailable
        quantityTotal
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
        # Removed donor field

        category {
          id
          name
          description
          isActive
        }
        status
        pickupType
        quantity
        quantityAvailable
        quantityTotal
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

  // ── Single donation ────────────────────────────
  static const String donation = '''
    query Donation(\$id: ID!) {
      donation(id: \$id) {
        id
        title
        description
        donor {
          id
          fullName
          avatarUrl
          badge
          role
          wilaya
          baladiya
        }
        category {
          id
          name
          description
          isActive
        }
        status
        pickupType
        quantity
        quantityAvailable
        quantityTotal
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
      donor {
        id
        fullName
        avatarUrl
        badge
        role
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
        lat
        lng
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
        badge
        role
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
        lat
        lng
      }
    }
  }
''';

  // ── Search donations ───────────────────────────
  static const String searchDonations = '''
    query SearchDonations(\$input: DonationSearchInput!) {
      searchDonations(input: \$input) {
        id
        title
        description
        donor {
          id
          fullName
          avatarUrl
          badge
          role
          wilaya
          baladiya
        }
        category {
          id
          name
          description
          isActive
        }
        status
        pickupType
        quantity
        quantityAvailable
        quantityTotal
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
}
