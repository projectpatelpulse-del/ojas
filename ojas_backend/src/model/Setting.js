const mongoose = require('mongoose');

const settingSchema = new mongoose.Schema({
  marketplaceName: {
    type: String,
    default: 'OJAS'
  },
  tagline: {
    type: String,
    default: 'Where Great Products Meet Happy Customers'
  },
  supportEmail: {
    type: String,
    default: 'support@ojas.com'
  },
  supportPhone: {
    type: String,
    default: '+1 (555) 123-4567'
  },
  footerMessage: {
    type: String,
    default: '© 2026 OJAS. All rights reserved.'
  },
  logo: {
    type: String,
    default: ''
  },
  favicon: {
    type: String,
    default: ''
  },
  enableAnnouncement: {
    type: Boolean,
    default: false
  },
  announcementMessage: {
    type: String,
    default: ''
  },
  announcementLink: {
    type: String,
    default: ''
  },
  // Contact Info (shown in footer "Get In Touch")
  contactPhone: {
    type: String,
    default: '+91 908/694321'
  },
  contactEmail: {
    type: String,
    default: 'support@ojas.com'
  },
  contactAddress: {
    type: String,
    default: 'Ghaziabad, Uttar Pradesh'
  },
  // Legal Pages Content
  returnRefundPolicy: {
    type: String,
    default: ''
  },
  termsConditions: {
    type: String,
    default: ''
  },
  privacyPolicy: {
    type: String,
    default: ''
  },
  // Social Media Links
  facebookLink: {
    type: String,
    default: ''
  },
  instagramLink: {
    type: String,
    default: ''
  },
  twitterLink: {
    type: String,
    default: ''
  },
  youtubeLink: {
    type: String,
    default: ''
  },
  linkedinLink: {
    type: String,
    default: ''
  },
  defaultCommission: {
    type: Number,
    default: 10
  },
  paymentGatewayKey: {
    type: String,
    default: ''
  },
  paymentGatewaySalt: {
    type: String,
    default: ''
  },
  delhiveryToken: {
    type: String,
    default: ''
  },
  emailUser: {
    type: String,
    default: ''
  },
  emailPass: {
    type: String,
    default: ''
  },
  whatsappToken: {
    type: String,
    default: ''
  },
  geminiApiKey: {
    type: String,
    default: ''
  }
}, {
  timestamps: true
});

const Setting = mongoose.model('Setting', settingSchema);
module.exports = Setting;
