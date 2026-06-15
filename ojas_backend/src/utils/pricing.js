/**
 * Utility function to calculate product pricing including vendor commission and GST.
 * 
 * Flow:
 * 1. Start with Original Price (or Discounted Price if applicable)
 * 2. Add Vendor Commission to get Selling Price (Displayed to user)
 * 3. Apply GST on Selling Price to get Final Cart Price (Calculated in cart/checkout)
 */
function calculateProductPricing(originalPrice, commissionPercent = 0, gstPercent = 0) {
    // Step 1 → Vendor Commission
    const commissionAmount = (originalPrice * commissionPercent) / 100;
    const sellingPrice = originalPrice + commissionAmount;

    // Step 2 → GST (Applied on the selling price, usually in cart)
    const gstAmount = (sellingPrice * gstPercent) / 100;
    const finalCartPrice = sellingPrice + gstAmount;

    return {
        originalPrice: Number(originalPrice.toFixed(2)),
        
        commissionPercent: Number(commissionPercent),
        commissionAmount: Number(commissionAmount.toFixed(2)),
        
        sellingPrice: Number(sellingPrice.toFixed(2)),
        
        gstPercent: Number(gstPercent),
        gstAmount: Number(gstAmount.toFixed(2)),
        
        finalCartPrice: Number(finalCartPrice.toFixed(2))
    };
}

module.exports = { calculateProductPricing };
