class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final int parent;
  final int count;
  final String? imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.parent,
    required this.count,
    this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String? img;
    final imageMap = json['image'];
    if (imageMap != null && imageMap is Map) {
      img = imageMap['src'];
    }
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      parent: json['parent'] ?? 0,
      count: json['count'] ?? 0,
      imageUrl: img,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'parent': parent,
      'count': count,
      'image': imageUrl != null ? {'src': imageUrl} : null,
    };
  }
}
