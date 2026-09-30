class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final String? parent;
  final String? status;
  final bool isGlobal;
  final int sequence;
  final bool isBestSelling;
  final Map<String, dynamic>? user;
  final DateTime? createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.parent,
    this.status,
    this.isGlobal = true,
    this.sequence = 0,
    this.isBestSelling = false,
    this.user,
    this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      image: json['image'],
      parent: json['parent'],
      status: json['status'],
      isGlobal: json['isGlobal'] ?? true,
      sequence: (json['sequence'] is num) ? (json['sequence'] as num).toInt() : 0,
      isBestSelling: json['isBestSelling'] ?? false,
      user: json['user'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'parent': parent,
      'status': status,
      'isGlobal': isGlobal,
      'sequence': sequence,
      'isBestSelling': isBestSelling,
    };
  }
}
