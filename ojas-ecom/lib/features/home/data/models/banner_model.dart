class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String link;
  final String tag;
  final String type;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.link,
    required this.tag,
    required this.type,
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
    );
  }
}
