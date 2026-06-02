import 'package:flutter/material.dart';
import 'package:ne3ma/core/network/graphql_client.dart';
import 'package:ne3ma/features/food_saver_help/data/graphql/food_saver_queries.dart';
import 'package:ne3ma/features/food_saver_help/data/models/food_saver_help_model.dart';

class FoodSaverHelpRepository {
  Future<List<FoodSaverHelpModel>> fetchMyHelpRequests() async {
    debugPrint('📤 FoodSaverHelpRepo: Fetching help requests...');

    final data = await GraphQLClient.query(
      document: FoodSaverQueries.myFoodSaverHelpRequests,
    );

    final list = data['myFoodSaverHelpRequests'] as List<dynamic>? ?? [];
    final requests = list
        .map((e) => FoodSaverHelpModel.fromJson(e as Map<String, dynamic>))
        .toList();

    debugPrint('✅ FoodSaverHelpRepo: Got ${requests.length} help requests');
    return requests;
  }

  Future<FoodSaverHelpModel?> fetchHelpRequest(String id) async {
    debugPrint('📤 FoodSaverHelpRepo: Fetching help request $id...');

    final data = await GraphQLClient.query(
      document: FoodSaverQueries.myFoodSaverHelpRequest,
      variables: {'id': id},
    );

    final json = data['myFoodSaverHelpRequest'] as Map<String, dynamic>?;
    if (json == null) {
      debugPrint('⚠️ FoodSaverHelpRepo: Help request $id not found');
      return null;
    }

    debugPrint('✅ FoodSaverHelpRepo: Got help request $id');
    return FoodSaverHelpModel.fromJson(json);
  }

  Future<bool> submitResponse({
    required String requestId,
    required String response,
  }) async {
    debugPrint('📤 FoodSaverHelpRepo: Submitting response for $requestId...');

    final data = await GraphQLClient.query(
      document: FoodSaverQueries.submitFoodSaverReport,
      variables: {
        'input': {'requestId': requestId, 'response': response},
      },
    );

    final result = data['submitFoodSaverReport'];
    final success = result != null && result['status'] == 'SUBMITTED';
    debugPrint(
      '${success ? '✅' : '❌'} FoodSaverHelpRepo: Submit ${success ? 'succeeded' : 'failed'}',
    );
    return success;
  }
}
