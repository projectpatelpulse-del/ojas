class CategoryModel {
  final String id;
  final String title;
  final String imageUrl;
  final String? icon;

  CategoryModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.icon,
  });

  static List<CategoryModel> get dummyCategories => [
    CategoryModel(id: '1', title: 'Electronics', imageUrl: 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=500', icon: '💻'),
    CategoryModel(id: '2', title: 'Fashion', imageUrl: 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=500', icon: '👕'),
    CategoryModel(id: '3', title: 'Grocery', imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500', icon: '🍎'),
    CategoryModel(id: '4', title: 'Beauty', imageUrl: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=500', icon: '💄'),
    CategoryModel(id: '5', title: 'Home & Kitchen', imageUrl: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=500', icon: '🏠'),
    CategoryModel(id: '6', title: 'Sports', imageUrl: 'https://images.unsplash.com/photo-1461896756970-49c711601689?w=500', icon: '⚽'),
  ];
}
