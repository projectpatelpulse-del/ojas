const ImageKit = require("@imagekit/nodejs");
const ImageKitClass = ImageKit.default || ImageKit;

const ik = new ImageKitClass({
  publicKey: "test",
  privateKey: "test",
  urlEndpoint: "test"
});

console.log("Keys on ik:", Object.keys(ik));
if (ik.files) {
    console.log("Methods on ik.files:", Object.getOwnPropertyNames(Object.getPrototypeOf(ik.files)));
}
