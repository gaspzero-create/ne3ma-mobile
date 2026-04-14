class CategoryQueries {
  CategoryQueries._();

  static const String activeCategories = '''
    query ActiveCategories {
      activeCategories {
        id
        name
        description
        isActive
      }
    }
  ''';
}
