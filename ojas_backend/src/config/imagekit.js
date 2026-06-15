const ImageKit = require("@imagekit/nodejs");

const ImageKitClass = ImageKit.default || ImageKit;

const imagekit = new ImageKitClass({
  publicKey: (process.env.IMAGEKIT_PUBLIC_KEY || "").trim(),
  privateKey: (process.env.IMAGEKIT_PRIVATE_KEY || "").trim(),
  urlEndpoint: (process.env.IMAGEKIT_URL_ENDPOINT || "").trim(),
});

module.exports = imagekit;
