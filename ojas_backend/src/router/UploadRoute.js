const express = require("express");
const router = express.Router();
const upload = require("../middlewere/Upload");
const imagekit = require("../config/imagekit");
const flexibleAuth = require("../middlewere/FlexibleAuth");

router.post("/image", flexibleAuth, upload.single("image"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No image file provided" });
    }

    const uploadResponse = await imagekit.files.upload({
      file: req.file.buffer.toString("base64"),
      fileName: `upload_${Date.now()}_${req.file.originalname}`,
      folder: "/uploads",
    });

    res.status(200).json({
      success: true,
      url: uploadResponse.url,
      message: "Image uploaded successfully",
    });
  } catch (error) {
    console.error("Upload error:", error.message);
    res.status(500).json({ message: "Image upload failed: " + error.message });
  }
});

module.exports = router;
