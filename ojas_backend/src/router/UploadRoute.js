const express = require("express");
const router = express.Router();
const multer = require("multer");
const imagekit = require("../config/imagekit");
const flexibleAuth = require("../middlewere/FlexibleAuth");
const adminAuth = require("../middlewere/AdminAuth");
const sharp = require("sharp");

// Image upload middleware (5MB)
const uploadImage = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });
// PDF upload middleware (20MB)
const uploadPdf = multer({ storage: multer.memoryStorage(), limits: { fileSize: 20 * 1024 * 1024 } });

router.post("/image", flexibleAuth, uploadImage.single("image"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No image file provided" });
    }

    let uploadBuffer = req.file.buffer;
    const mimetype = req.file.mimetype;

    if (mimetype && mimetype.startsWith("image/")) {
      try {
        const originalSize = req.file.buffer.length;
        
        // Compress using sharp to 70% quality (60-80% range)
        if (mimetype === "image/jpeg" || mimetype === "image/jpg") {
          uploadBuffer = await sharp(req.file.buffer)
            .jpeg({ quality: 70 })
            .toBuffer();
        } else if (mimetype === "image/png") {
          uploadBuffer = await sharp(req.file.buffer)
            .png({ quality: 70, compressionLevel: 8 })
            .toBuffer();
        } else if (mimetype === "image/webp") {
          uploadBuffer = await sharp(req.file.buffer)
            .webp({ quality: 70 })
            .toBuffer();
        } else {
          // Fallback compression for other image types
          uploadBuffer = await sharp(req.file.buffer)
            .jpeg({ quality: 70 })
            .toBuffer();
        }

        const compressedSize = uploadBuffer.length;
        const savingsPercent = (((originalSize - compressedSize) / originalSize) * 100).toFixed(1);
        console.log(`[Image Compressor] Original: ${(originalSize / 1024).toFixed(1)} KB, Compressed: ${(compressedSize / 1024).toFixed(1)} KB (Saved ${savingsPercent}%)`);
      } catch (sharpError) {
        console.error("[Image Compressor] Compression failed, uploading original:", sharpError.message);
      }
    }

    let targetSubFolder = "general";
    if (req.query.folder) {
      targetSubFolder = req.query.folder.replace(/[^a-zA-Z0-9_\-\s]/g, "");
    } else if (req.body.folder) {
      targetSubFolder = req.body.folder.replace(/[^a-zA-Z0-9_\-\s]/g, "");
    }

    const uploadResponse = await imagekit.files.upload({
      file: uploadBuffer.toString("base64"),
      fileName: `upload_${Date.now()}_${req.file.originalname}`,
      folder: `/ojas/${targetSubFolder}`,
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

// PDF Upload endpoint — flexible authentication (allowing vendors to upload)
// router.post("/pdf", adminAuth, uploadPdf.single("pdf"), async (req, res) => {
router.post("/pdf", flexibleAuth, uploadPdf.single("pdf"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: "No PDF file provided" });
    }
    const allowedMimeTypes = [
      "application/pdf", 
      "application/msword", 
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    ];
    if (!allowedMimeTypes.includes(req.file.mimetype)) {
      return res.status(400).json({ success: false, message: "Only PDF, DOC, and DOCX files are allowed" });
    }

    const originalName = req.file.originalname.replace(/[^a-zA-Z0-9._-]/g, "_");
    const uploadResponse = await imagekit.files.upload({
      file: req.file.buffer.toString("base64"),
      fileName: `pdf_${Date.now()}_${originalName}`,
      folder: `/ojas/pdfs`,
    });

    res.status(200).json({
      success: true,
      url: uploadResponse.url,
      fileId: uploadResponse.fileId,
      name: req.file.originalname,
      message: "PDF uploaded successfully",
    });
  } catch (error) {
    console.error("[PDF Upload] error:", error.message);
    res.status(500).json({ success: false, message: "PDF upload failed: " + error.message });
  }
});

module.exports = router;

