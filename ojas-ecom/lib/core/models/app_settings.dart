class AppSettings {
  final String marketplaceName;
  final String tagline;
  final String supportEmail;
  final String supportPhone;
  final String footerMessage;
  final String logo;
  final String favicon;
  final bool enableAnnouncement;
  final String announcementMessage;
  final String announcementLink;
  final String contactPhone;
  final String contactEmail;
  final String contactAddress;
  final String returnRefundPolicy;
  final String termsConditions;
  final String privacyPolicy;
  final String facebookLink;
  final String instagramLink;
  final String twitterLink;
  final String youtubeLink;
  final String linkedinLink;
  final String whatsappNumber;
  final String aboutUsContent;
  final String navigationMenuItems;
  final String homeSectionsActive;
  final bool showTrendingProducts;
  final bool showTrendingB2BBanner;

  // Trending Section & Service Cards
  final String trendingCategories;
  final String serviceCard1Title;
  final String serviceCard1Subtitle;
  final String serviceCard1Icon;
  final String serviceCard2Title;
  final String serviceCard2Subtitle;
  final String serviceCard2Icon;
  final String serviceCard3Title;
  final String serviceCard3Subtitle;
  final String serviceCard3Icon;
  final String serviceCard4Title;
  final String serviceCard4Subtitle;
  final String serviceCard4Icon;

  AppSettings({
    required this.marketplaceName,
    required this.tagline,
    required this.supportEmail,
    required this.supportPhone,
    required this.footerMessage,
    required this.logo,
    required this.favicon,
    required this.enableAnnouncement,
    required this.announcementMessage,
    required this.announcementLink,
    required this.contactPhone,
    required this.contactEmail,
    required this.contactAddress,
    required this.returnRefundPolicy,
    required this.termsConditions,
    required this.privacyPolicy,
    required this.facebookLink,
    required this.instagramLink,
    required this.twitterLink,
    required this.youtubeLink,
    required this.linkedinLink,
    required this.whatsappNumber,
    required this.aboutUsContent,
    required this.navigationMenuItems,
    required this.homeSectionsActive,
    required this.showTrendingProducts,
    required this.showTrendingB2BBanner,
    required this.trendingCategories,
    required this.serviceCard1Title,
    required this.serviceCard1Subtitle,
    required this.serviceCard1Icon,
    required this.serviceCard2Title,
    required this.serviceCard2Subtitle,
    required this.serviceCard2Icon,
    required this.serviceCard3Title,
    required this.serviceCard3Subtitle,
    required this.serviceCard3Icon,
    required this.serviceCard4Title,
    required this.serviceCard4Subtitle,
    required this.serviceCard4Icon,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      marketplaceName: json['marketplaceName'] ?? 'OJAS',
      tagline: json['tagline'] ?? 'Where Great Products Meet Happy Customers',
      supportEmail: json['supportEmail'] ?? 'support@ojas.com',
      supportPhone: json['supportPhone'] ?? '+1 (555) 123-4567',
      footerMessage: json['footerMessage'] ?? '© 2026 OJAS. All rights reserved.',
      logo: json['logo'] ?? '',
      favicon: json['favicon'] ?? '',
      enableAnnouncement: json['enableAnnouncement'] ?? false,
      announcementMessage: json['announcementMessage'] ?? '',
      announcementLink: json['announcementLink'] ?? '',
      contactPhone: json['contactPhone'] ?? '+91 9087654321',
      contactEmail: json['contactEmail'] ?? 'support@ojas.com',
      contactAddress: json['contactAddress'] ?? 'Ghaziabad, Uttar Pradesh',
      returnRefundPolicy: json['returnRefundPolicy'] ?? '',
      termsConditions: json['termsConditions'] ?? '',
      privacyPolicy: json['privacyPolicy'] ?? '',
      facebookLink: json['facebookLink'] ?? '',
      instagramLink: json['instagramLink'] ?? '',
      twitterLink: json['twitterLink'] ?? '',
      youtubeLink: json['youtubeLink'] ?? '',
      linkedinLink: json['linkedinLink'] ?? '',
      whatsappNumber: json['whatsappNumber'] ?? '',
      aboutUsContent: json['aboutUsContent'] ?? '',
      navigationMenuItems: json['navigationMenuItems'] ?? 'HOME, FEATURES, DEALS, SHOP, BLOG',
      homeSectionsActive: json['homeSectionsActive'] ?? 'HERO, DAILY_DEALS, SUMMER_SALE, TRENDING, PROMO_GRID, BECOME_VENDOR, JUST_FOR_YOU, LATEST_PRODUCTS, ADS_SUBSCRIBE',
      showTrendingProducts: json['showTrendingProducts'] ?? true,
      showTrendingB2BBanner: json['showTrendingB2BBanner'] ?? true,
      trendingCategories: json['trendingCategories'] ?? 'All, Pet Supplies, Jewelry & Accessories, Industrial Parts & Tools, Books & Stationery, Toys & Games',
      serviceCard1Title: json['serviceCard1Title'] ?? 'FREE DELIVERY',
      serviceCard1Subtitle: json['serviceCard1Subtitle'] ?? 'From ₹89.00',
      serviceCard1Icon: json['serviceCard1Icon'] ?? 'https://cdn-icons-png.flaticon.com/512/709/709790.png',
      serviceCard2Title: json['serviceCard2Title'] ?? 'ORDER PROTECTION',
      serviceCard2Subtitle: json['serviceCard2Subtitle'] ?? 'Refund/Resent 120 Day',
      serviceCard2Icon: json['serviceCard2Icon'] ?? 'https://cdn-icons-png.flaticon.com/512/1161/1161388.png',
      serviceCard3Title: json['serviceCard3Title'] ?? 'PAYMENT SECURITY',
      serviceCard3Subtitle: json['serviceCard3Subtitle'] ?? 'SSL Secure Payment',
      serviceCard3Icon: json['serviceCard3Icon'] ?? 'https://cdn-icons-png.flaticon.com/512/1069/1069159.png',
      serviceCard4Title: json['serviceCard4Title'] ?? '24/7 SUPPORT',
      serviceCard4Subtitle: json['serviceCard4Subtitle'] ?? 'Dedicated Support',
      serviceCard4Icon: json['serviceCard4Icon'] ?? 'https://cdn-icons-png.flaticon.com/512/2838/2838634.png',
    );
  }

  static AppSettings defaultSettings() {
    return AppSettings(
      marketplaceName: 'OJAS',
      tagline: 'Where Great Products Meet Happy Customers',
      supportEmail: 'support@ojas.com',
      supportPhone: '+1 (555) 123-4567',
      footerMessage: '© 2026 OJAS. All rights reserved.',
      logo: '',
      favicon: '',
      enableAnnouncement: false,
      announcementMessage: '',
      announcementLink: '',
      contactPhone: '+91 9087654321',
      contactEmail: 'support@ojas.com',
      contactAddress: 'Ghaziabad, Uttar Pradesh',
      returnRefundPolicy: '',
      termsConditions: '',
      privacyPolicy: '',
      facebookLink: '',
      instagramLink: '',
      twitterLink: '',
      youtubeLink: '',
      linkedinLink: '',
      whatsappNumber: '',
      aboutUsContent: '',
      navigationMenuItems: 'HOME, FEATURES, DEALS, SHOP, BLOG',
      homeSectionsActive: 'HERO, DAILY_DEALS, SUMMER_SALE, TRENDING, PROMO_GRID, BECOME_VENDOR, JUST_FOR_YOU, LATEST_PRODUCTS, ADS_SUBSCRIBE',
      showTrendingProducts: true,
      showTrendingB2BBanner: true,
      trendingCategories: 'All, Pet Supplies, Jewelry & Accessories, Industrial Parts & Tools, Books & Stationery, Toys & Games',
      serviceCard1Title: 'FREE DELIVERY',
      serviceCard1Subtitle: 'From ₹89.00',
      serviceCard1Icon: 'https://cdn-icons-png.flaticon.com/512/709/709790.png',
      serviceCard2Title: 'ORDER PROTECTION',
      serviceCard2Subtitle: 'Refund/Resent 120 Day',
      serviceCard2Icon: 'https://cdn-icons-png.flaticon.com/512/1161/1161388.png',
      serviceCard3Title: 'PAYMENT SECURITY',
      serviceCard3Subtitle: 'SSL Secure Payment',
      serviceCard3Icon: 'https://cdn-icons-png.flaticon.com/512/1069/1069159.png',
      serviceCard4Title: '24/7 SUPPORT',
      serviceCard4Subtitle: 'Dedicated Support',
      serviceCard4Icon: 'https://cdn-icons-png.flaticon.com/512/2838/2838634.png',
    );
  }
}
