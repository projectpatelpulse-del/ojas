require("dotenv").config();
const ImageKit = require("@imagekit/nodejs");
const ImageKitClass = ImageKit.default || ImageKit;

const ik = new ImageKitClass({
  publicKey: process.env.IMAGEKIT_PUBLIC_KEY,
  privateKey: process.env.IMAGEKIT_PRIVATE_KEY,
  urlEndpoint: process.env.IMAGEKIT_URL_ENDPOINT,
});

console.log("ImageKit Instance Methods:", Object.keys(Object.getPrototypeOf(ik)));
console.log("Is it an instance of ImageKitClass?", ik instanceof ImageKitClass);
