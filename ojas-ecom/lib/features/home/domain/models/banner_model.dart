class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String buttonText;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.buttonText = 'Shop Now',
  });

  static List<BannerModel> get dummyBanners => [
    BannerModel(
      id: '1',
      title: 'Smart Deals.\nSmarter Shopping.',
      subtitle: 'Up to 50% off on premium electronics and fashion.',
      imageUrl: 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=1000',
    ),
    BannerModel(
      id: '2',
      title: 'Summer Collection\n2026',
      subtitle: 'Discover the latest trends in sustainable fashion.',
      imageUrl: 'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=1000',
    ),
  ];

  static List<BannerModel> get promoBanners => [
    BannerModel(
      id: 'p1',
      title: 'Fashion Sale',
      subtitle: 'Up to 60% off on all clothing.',
      imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800',
      buttonText: 'View Sale',
    ),
    BannerModel(
      id: 'p2',
      title: 'Tech Deals',
      subtitle: 'Latest gadgets at best prices.',
      imageUrl: 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=800',
      buttonText: 'Explore',
    ),
  ];
}
