require("dotenv").config();
const ImageKit = require("imagekit");

const ik = new ImageKit({
  publicKey: process.env.IMAGEKIT_PUBLIC_KEY,
  privateKey: process.env.IMAGEKIT_PRIVATE_KEY,
  urlEndpoint: process.env.IMAGEKIT_URL_ENDPOINT,
});

console.log("Testing ImageKit Auth...");
console.log("Endpoint:", process.env.IMAGEKIT_URL_ENDPOINT);
console.log("Public Key Prefix:", (process.env.IMAGEKIT_PUBLIC_KEY || "").substring(0, 10));

ik.getFileList({}, (err, result) => {
  if (err) {
    console.error("Auth Test Failed!");
    console.error(err);
  } else {
    console.log("Auth Test Succeeded!");
    console.log("Files Found:", result.length);
  }
});
