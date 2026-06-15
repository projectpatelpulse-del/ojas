const Cart = require('../model/Cart');
const Product = require('../model/Product');
const Vendor = require('../model/Vendor');
const { calculateProductPricing } = require('../utils/pricing.js');

exports.addToCart = async (req, res) => {
  try {
    const { productId, quantity } = req.body;
    const userId = req.user.id; // Assuming user is available via auth middleware

    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    // Base price for commission: use discountPrice if available, else regular price
    const basePrice = (product.discountPrice > 0) ? product.discountPrice : product.price;

    const vendor = await Vendor.findOne({ user: product.user });
    const commissionPercent = vendor ? (vendor.commissionRate || 0) : 0;
    const gstPercent = product.gst || 0;

    const pricing = calculateProductPricing(basePrice, commissionPercent, gstPercent);

    let newQuantity = quantity;
    let itemIndex = -1;

    let cart = await Cart.findOne({ user: userId });
    
    if (cart) {
      itemIndex = cart.items.findIndex(item => item.product.toString() === productId);
      if (itemIndex > -1) {
        newQuantity = cart.items[itemIndex].quantity + quantity;
      }
    }

    const itemData = {
      product: productId,
      quantity: newQuantity,
      price: pricing.sellingPrice, // Display price
      originalPrice: pricing.originalPrice,
      commissionPercent: pricing.commissionPercent,
      commissionAmount: pricing.commissionAmount,
      sellingPrice: pricing.sellingPrice,
      gstPercent: pricing.gstPercent,
      gstAmount: pricing.gstAmount,
      finalPrice: pricing.finalCartPrice
    };

    if (!cart) {
      cart = new Cart({
        user: userId,
        items: [itemData]
      });
    } else {
      if (itemIndex > -1) {
        cart.items[itemIndex].quantity = itemData.quantity;
        cart.items[itemIndex].price = itemData.price;
        cart.items[itemIndex].originalPrice = itemData.originalPrice;
        cart.items[itemIndex].commissionPercent = itemData.commissionPercent;
        cart.items[itemIndex].commissionAmount = itemData.commissionAmount;
        cart.items[itemIndex].sellingPrice = itemData.sellingPrice;
        cart.items[itemIndex].gstPercent = itemData.gstPercent;
        cart.items[itemIndex].gstAmount = itemData.gstAmount;
        cart.items[itemIndex].finalPrice = itemData.finalPrice;
      } else {
        cart.items.push(itemData);
      }
    }

    await cart.save();
    // Populate product details for response
    await cart.populate('items.product');
    
    res.status(200).json({ success: true, cart });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getCart = async (req, res) => {
  try {
    const userId = req.user.id;
    const cart = await Cart.findOne({ user: userId }).populate('items.product');
    
    if (!cart) {
      return res.status(200).json({ success: true, cart: { items: [], subtotal: 0, totalAmount: 0 } });
    }

    res.status(200).json({ success: true, cart });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateCartItem = async (req, res) => {
  try {
    const { productId, quantity } = req.body;
    const userId = req.user.id;

    if (quantity < 1) {
      return res.status(400).json({ message: 'Quantity must be at least 1' });
    }

    const cart = await Cart.findOne({ user: userId });
    if (!cart) return res.status(404).json({ message: 'Cart not found' });

    const itemIndex = cart.items.findIndex(item => item.product.toString() === productId);
    if (itemIndex > -1) {
      const product = await Product.findById(productId);
      if (!product) return res.status(404).json({ message: 'Product not found' });
      
      const basePrice = (product.discountPrice > 0) ? product.discountPrice : product.price;
      const vendor = await Vendor.findOne({ user: product.user });
      const commissionPercent = vendor ? (vendor.commissionRate || 0) : 0;
      const gstPercent = product.gst || 0;

      const pricing = calculateProductPricing(basePrice, commissionPercent, gstPercent);

      cart.items[itemIndex].quantity = quantity;
      cart.items[itemIndex].price = pricing.sellingPrice;
      cart.items[itemIndex].originalPrice = pricing.originalPrice;
      cart.items[itemIndex].commissionPercent = pricing.commissionPercent;
      cart.items[itemIndex].commissionAmount = pricing.commissionAmount;
      cart.items[itemIndex].sellingPrice = pricing.sellingPrice;
      cart.items[itemIndex].gstPercent = pricing.gstPercent;
      cart.items[itemIndex].gstAmount = pricing.gstAmount;
      cart.items[itemIndex].finalPrice = pricing.finalCartPrice;

      await cart.save();
      await cart.populate('items.product');
      return res.status(200).json({ success: true, cart });
    }

    res.status(404).json({ message: 'Item not found in cart' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.removeFromCart = async (req, res) => {
  try {
    const { productId } = req.params;
    const userId = req.user.id;

    const cart = await Cart.findOne({ user: userId });
    if (!cart) return res.status(404).json({ message: 'Cart not found' });

    cart.items = cart.items.filter(item => item.product.toString() !== productId);
    await cart.save();
    await cart.populate('items.product');

    res.status(200).json({ success: true, cart });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.clearCart = async (req, res) => {
  try {
    const userId = req.user.id;
    const cart = await Cart.findOne({ user: userId });
    if (cart) {
      cart.items = [];
      await cart.save();
    }
    res.status(200).json({ success: true, message: 'Cart cleared' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
