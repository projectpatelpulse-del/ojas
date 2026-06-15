const ImageKit = require("@imagekit/nodejs");
const ImageKitClass = ImageKit.default || ImageKit;

const ik = new ImageKitClass({
  publicKey: "test",
  privateKey: "test",
  urlEndpoint: "test"
});

function getAllMethods(obj) {
    let methods = new Set();
    while (obj = Object.getPrototypeOf(obj)) {
        let keys = Object.getOwnPropertyNames(obj);
        keys.forEach(k => methods.add(k));
    }
    return Array.from(methods);
}

console.log("All available methods:", getAllMethods(ik).filter(m => !m.includes("__") && m !== 'constructor'));
