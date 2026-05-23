class ReportMutations {
  ReportMutations._();

  static const String createReport = '''
    mutation CreateReport(\$input: CreateReportInput!) {
      createReport(input: \$input) {
        id
      }
    }
  ''';
}
