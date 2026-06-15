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
    );
  }
}
