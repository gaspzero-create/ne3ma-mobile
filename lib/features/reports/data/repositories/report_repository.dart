import 'package:flutter/material.dart';
import 'package:ne3ma/core/network/graphql_client.dart';
import 'package:ne3ma/features/reports/data/graphql/report_mutations.dart';

class ReportRepository {
  Future<bool> createReport({
    required String reportedUserId,
    required String reason,
    required String description,
  }) async {
    debugPrint('📤 ReportRepo: Creating report for user $reportedUserId...');

    final data = await GraphQLClient.query(
      document: ReportMutations.createReport,
      variables: {
        'input': {
          'reportedUserId': reportedUserId,
          'reason': reason,
          'description': description,
        },
      },
    );

    final reportId = data['createReport']?['id'];
    debugPrint('✅ ReportRepo: Report created - $reportId');
    return reportId != null;
  }
}
