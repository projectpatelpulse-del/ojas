const Subscriber = require("../model/Subscriber.js");

// Public: Subscribe newsletter
exports.subscribeNewsletter = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email || !email.includes("@")) {
      return res.status(400).json({ success: false, message: "Please provide a valid email address." });
    }

    const cleanEmail = email.toLowerCase().trim();
    const existing = await Subscriber.findOne({ email: cleanEmail });

    if (existing) {
      if (existing.status === "Unsubscribed") {
        existing.status = "Subscribed";
        await existing.save();
        return res.status(200).json({ success: true, message: "Welcome back! Successfully re-subscribed to newsletter." });
      }
      return res.status(200).json({ success: true, message: "You are already subscribed to our newsletter!" });
    }

    const subscriber = new Subscriber({ email: cleanEmail });
    await subscriber.save();

    res.status(201).json({
      success: true,
      message: "Successfully subscribed to newsletter!",
      data: subscriber,
    });
  } catch (error) {
    console.error("Subscribe Newsletter Error:", error);
    res.status(500).json({ success: false, message: "Server error while subscribing." });
  }
};

// Admin: Get all subscribers
exports.getAllSubscribers = async (req, res) => {
  try {
    const subscribers = await Subscriber.find().sort({ createdAt: -1 });
    res.status(200).json({
      success: true,
      data: subscribers,
    });
  } catch (error) {
    console.error("Get All Subscribers Error:", error);
    res.status(500).json({ success: false, message: "Failed to fetch subscribers." });
  }
};

// Admin: Delete subscriber
exports.deleteSubscriber = async (req, res) => {
  try {
    const { id } = req.params;
    await Subscriber.findByIdAndDelete(id);
    res.status(200).json({
      success: true,
      message: "Subscriber removed successfully.",
    });
  } catch (error) {
    console.error("Delete Subscriber Error:", error);
    res.status(500).json({ success: false, message: "Failed to delete subscriber." });
  }
};
