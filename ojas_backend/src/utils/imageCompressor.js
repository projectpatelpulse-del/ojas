const sharp = require("sharp");

/**
 * Compresses and optimizes an image buffer for web performance.
 * - Resizes if max dimension exceeds 1600px (preserves aspect ratio without enlarging).
 * - Compresses with quality 80% (visually lossless, 60-80% smaller file size).
 * - Converts to optimized WebP or JPEG based on original mimetype.
 *
 * @param {Buffer} buffer - Image buffer
 * @param {string} mimetype - Original mimetype
 * @returns {Promise<{ buffer: Buffer, mimetype: string, extension: string }>}
 */
async function compressImageBuffer(buffer, mimetype = "image/jpeg") {
    try {
        const originalSize = buffer.length;
        let pipeline = sharp(buffer).rotate(); // auto-rotate based on EXIF

        // Get metadata to inspect dimensions
        const metadata = await pipeline.metadata();
        const maxDimension = 1600;

        if (metadata.width > maxDimension || metadata.height > maxDimension) {
            pipeline = pipeline.resize({
                width: metadata.width >= metadata.height ? maxDimension : undefined,
                height: metadata.height > metadata.width ? maxDimension : undefined,
                fit: "inside",
                withoutEnlargement: true,
            });
        }

        let outMime = mimetype;
        let ext = "jpg";

        if (mimetype === "image/png") {
            // High-quality PNG compression
            pipeline = pipeline.png({ quality: 80, compressionLevel: 8 });
            outMime = "image/png";
            ext = "png";
        } else if (mimetype === "image/webp") {
            pipeline = pipeline.webp({ quality: 80 });
            outMime = "image/webp";
            ext = "webp";
        } else {
            // Default to high-quality JPEG
            pipeline = pipeline.jpeg({ quality: 80, mozjpeg: true });
            outMime = "image/jpeg";
            ext = "jpg";
        }

        const compressedBuffer = await pipeline.toBuffer();
        const compressedSize = compressedBuffer.length;
        const savingsPercent = (((originalSize - compressedSize) / originalSize) * 100).toFixed(1);

        console.log(`[Image Compressor] Original: ${(originalSize / 1024).toFixed(1)} KB, Compressed: ${(compressedSize / 1024).toFixed(1)} KB (Saved ${savingsPercent}%)`);

        return {
            buffer: compressedBuffer,
            mimetype: outMime,
            extension: ext,
        };
    } catch (err) {
        console.error("[Image Compressor] Error during compression, falling back to original:", err.message);
        return {
            buffer,
            mimetype,
            extension: mimetype === "image/png" ? "png" : (mimetype === "image/webp" ? "webp" : "jpg"),
        };
    }
}

module.exports = {
    compressImageBuffer,
};
