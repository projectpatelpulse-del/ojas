const Setting = require("../model/Setting.js");

const defaultSettings = {
  marketplaceName: "OJAS",
  tagline: "Where Great Products Meet Happy Customers",
  supportEmail: "support@ojas.com",
  supportPhone: "+1 (555) 123-4567",
  footerMessage: "© 2026 OJAS. All rights reserved.",
  logo: "",
  favicon: "",
  enableAnnouncement: false,
  announcementMessage: "",
  announcementLink: "",
  contactPhone: "+91 908/694321",
  contactEmail: "support@ojas.com",
  contactAddress: "Ghaziabad, Uttar Pradesh",
  returnRefundPolicy: "",
  termsConditions: "",
  privacyPolicy: "",
  facebookLink: "",
  instagramLink: "",
  twitterLink: "",
  youtubeLink: "",
  linkedinLink: "",
  defaultCommission: 10,
};

// Helper to get or create the singleton setting document
const getOrCreateSetting = async () => {
  let setting = await Setting.findOne();
  if (!setting) {
    setting = await Setting.create(defaultSettings);
  }
  return setting;
};

const getSettings = async (req, res) => {
  try {
    const setting = await getOrCreateSetting();
    res.status(200).json({ data: setting });
  } catch (error) {
    console.error("Get settings error:", error.message);
    res.status(500).json({ message: error.message });
  }
};

// Public route — no auth needed so user app can call it freely
const getPublicSettings = async (req, res) => {
  try {
    const setting = await getOrCreateSetting();
    const publicData = setting.toObject();
    
    // Exclude sensitive keys from public settings
    delete publicData.paymentGatewayKey;
    delete publicData.paymentGatewaySalt;
    delete publicData.delhiveryToken;
    delete publicData.emailUser;
    delete publicData.emailPass;
    delete publicData.whatsappToken;
    
    res.status(200).json({ data: publicData });
  } catch (error) {
    console.error("Get public settings error:", error.message);
    res.status(500).json({ message: error.message });
  }
};

const updateSettings = async (req, res) => {
  try {
    console.log("Update settings request received:", req.body);
    const {
      marketplaceName,
      tagline,
      supportEmail,
      supportPhone,
      footerMessage,
      logo,
      favicon,
      enableAnnouncement,
      announcementMessage,
      announcementLink,
      defaultCommission,
      contactPhone,
      contactEmail,
      contactAddress,
      returnRefundPolicy,
      termsConditions,
      privacyPolicy,
      facebookLink,
      instagramLink,
      twitterLink,
      youtubeLink,
      linkedinLink,
      paymentGatewayKey,
      paymentGatewaySalt,
      delhiveryToken,
      emailUser,
      emailPass,
      whatsappToken
    } = req.body;

    let setting = await getOrCreateSetting();

    if (marketplaceName !== undefined) setting.marketplaceName = marketplaceName;
    if (tagline !== undefined) setting.tagline = tagline;
    if (supportEmail !== undefined) setting.supportEmail = supportEmail;
    if (supportPhone !== undefined) setting.supportPhone = supportPhone;
    if (footerMessage !== undefined) setting.footerMessage = footerMessage;
    if (logo !== undefined) setting.logo = logo;
    if (favicon !== undefined) setting.favicon = favicon;
    if (enableAnnouncement !== undefined) setting.enableAnnouncement = enableAnnouncement;
    if (announcementMessage !== undefined) setting.announcementMessage = announcementMessage;
    if (announcementLink !== undefined) setting.announcementLink = announcementLink;
    if (defaultCommission !== undefined) setting.defaultCommission = defaultCommission;
    if (contactPhone !== undefined) setting.contactPhone = contactPhone;
    if (contactEmail !== undefined) setting.contactEmail = contactEmail;
    if (contactAddress !== undefined) setting.contactAddress = contactAddress;
    if (returnRefundPolicy !== undefined) setting.returnRefundPolicy = returnRefundPolicy;
    if (termsConditions !== undefined) setting.termsConditions = termsConditions;
    if (privacyPolicy !== undefined) setting.privacyPolicy = privacyPolicy;
    if (facebookLink !== undefined) setting.facebookLink = facebookLink;
    if (instagramLink !== undefined) setting.instagramLink = instagramLink;
    if (twitterLink !== undefined) setting.twitterLink = twitterLink;
    if (youtubeLink !== undefined) setting.youtubeLink = youtubeLink;
    if (linkedinLink !== undefined) setting.linkedinLink = linkedinLink;
    
    // Sensitive fields
    if (paymentGatewayKey !== undefined) setting.paymentGatewayKey = paymentGatewayKey;
    if (paymentGatewaySalt !== undefined) setting.paymentGatewaySalt = paymentGatewaySalt;
    if (delhiveryToken !== undefined) setting.delhiveryToken = delhiveryToken;
    if (emailUser !== undefined) setting.emailUser = emailUser;
    if (emailPass !== undefined) setting.emailPass = emailPass;
    if (whatsappToken !== undefined) setting.whatsappToken = whatsappToken;

    await setting.save();

    // Emit real-time update to all connected clients
    const io = req.app.get("io");
    if (io) {
      io.emit("admin_data_updated", {
        type: "settings",
        action: "update",
        data: setting,
      });
      console.log("Socket event emitted: settings update");
    }

    res.status(200).json({ data: setting, message: "Settings saved successfully" });
  } catch (error) {
    console.error("Update settings error:", error.message);
    res.status(500).json({ message: error.message });
  }
};

const resetSettings = async (req, res) => {
  try {
    let setting = await getOrCreateSetting();
    Object.assign(setting, defaultSettings);
    await setting.save();

    // Emit real-time update to all connected clients
    const io = req.app.get("io");
    if (io) {
      io.emit("admin_data_updated", {
        type: "settings",
        action: "reset",
        data: setting,
      });
    }

    res.status(200).json({ data: setting, message: "Settings reset to defaults" });
  } catch (error) {
    console.error("Reset settings error:", error.message);
    res.status(500).json({ message: error.message });
  }
};

module.exports = { getSettings, getPublicSettings, updateSettings, resetSettings };
