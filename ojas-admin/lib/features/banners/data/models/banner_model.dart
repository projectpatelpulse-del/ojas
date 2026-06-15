class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String link;
  final String tag;
  final String type;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.link,
    required this.tag,
    required this.type,
    required this.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      link: json['link'] ?? '/',
      tag: json['tag'] ?? '',
      type: json['type'] ?? 'main',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'link': link,
      'tag': tag,
      'type': type,
      'isActive': isActive,
    };
  }
}
