const multer = require("multer");

const storage = multer.memoryStorage(); // Store files in memory to upload to ImageKit
const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
});

module.exports = upload;
