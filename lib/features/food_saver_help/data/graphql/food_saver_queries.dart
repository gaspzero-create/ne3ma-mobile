class FoodSaverQueries {
  FoodSaverQueries._();

  static const String myFoodSaverHelpRequests = '''
    query MyFoodSaverHelpRequests {
      myFoodSaverHelpRequests {
        id
        status
        adminMessage
        distanceKm
        response
        respondedAt
        createdAt
        updatedAt
        admin {
          id
          fullName
          avatarUrl
        }
        report {
          id
          reason
          description
          status
          relatedDonationTitle
          relatedMeetingZone
          reportedUser {
            id
            fullName
            avatarUrl
          }
        }
      }
    }
  ''';

  static const String myFoodSaverHelpRequest = '''
    query MyFoodSaverHelpRequest(\$id: ID!) {
      myFoodSaverHelpRequest(id: \$id) {
        id
        status
        adminMessage
        distanceKm
        response
        respondedAt
        createdAt
        updatedAt
        admin {
          id
          fullName
          avatarUrl
        }
        report {
          id
          reason
          description
          status
          relatedDonationTitle
          relatedMeetingZone
          relatedLat
          relatedLng
          reportedUser {
            id
            fullName
            avatarUrl
          }
        }
      }
    }
  ''';

  static const String submitFoodSaverReport = '''
    mutation SubmitFoodSaverReport(\$input: SubmitFoodSaverReportInput!) {
      submitFoodSaverReport(input: \$input) {
        id
        status
        response
        respondedAt
      }
    }
  ''';
}
