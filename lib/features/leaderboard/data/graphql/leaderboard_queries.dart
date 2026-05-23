class LeaderboardQueries {
  LeaderboardQueries._();

  static const String leaderboard = '''
    query Leaderboard(\$filter: LeaderboardFilterInput) {
      leaderboard(filter: \$filter) {
        rank
        fullName
        points
        badge
        role
        wilaya
      }
    }
  ''';
}
