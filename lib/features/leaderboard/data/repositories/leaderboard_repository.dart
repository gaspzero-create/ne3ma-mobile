import 'package:flutter/material.dart';
import '../../../../core/network/graphql_client.dart';
import '../graphql/leaderboard_queries.dart';
import '../models/leaderboard_model.dart';

class LeaderboardRepository {

  Future<List<LeaderboardEntryModel>> getLeaderboard({
    String? wilaya,
    String? baladiya,
  }) async {
    debugPrint('📤 LeaderboardRepo: Fetching leaderboard...');
    debugPrint(
      '🔍 LeaderboardRepo: Using local filters wilaya=$wilaya, baladiya=$baladiya',
    );

    final data = await GraphQLClient.query(
      document: LeaderboardQueries.leaderboard,
    );

    final list = data['leaderboard'] as List;
    debugPrint('✅ LeaderboardRepo: Got ${list.length} entries');
    return list.map((e) => LeaderboardEntryModel.fromMap(e)).toList();
  }
}
