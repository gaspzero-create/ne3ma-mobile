import '../../../../core/network/graphql_client.dart';
import '../graphql/category_queries.dart';
import '../models/category_model.dart';

class CategoryRepository {
  Future<List<CategoryModel>> getActiveCategories() async {
    final data = await GraphQLClient.query(
      document: CategoryQueries.activeCategories,
    );

    final list = data['activeCategories'] as List;
    return list
        .map((item) => CategoryModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }
}
