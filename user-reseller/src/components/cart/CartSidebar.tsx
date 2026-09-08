import React from 'react';
import { useCart } from '../../context/CartContext';
import { useAuth } from '../../context/AuthContext';
import { formatImageUrl, formatCurrency } from '../../core/utils';
import './CartSidebar.css';

interface CartSidebarProps {
  isOpen: boolean;
  onClose: () => void;
  onCheckout: () => void;
  onOpenAuth: () => void;
}

export const CartSidebar: React.FC<CartSidebarProps> = ({
  isOpen,
  onClose,
  onCheckout,
  onOpenAuth
}) => {
  const { cartItems, updateCartItemQty, removeFromCart, cartSubtotal } = useCart();
  const { user } = useAuth();

  if (!isOpen) return null;

  const handleCheckoutClick = () => {
    onClose();
    if (!user) {
      onOpenAuth();
    } else {
      onCheckout();
    }
  };

  return (
    <div className="cart-sidebar-overlay active" onClick={onClose}>
      <div className="cart-sidebar" onClick={e => e.stopPropagation()}>
        <div className="cart-header">
          <h3>Shopping Cart ({cartItems.length})</h3>
          <button className="cart-close-btn" onClick={onClose}>&times;</button>
        </div>

        <div className="cart-items-container">
          {cartItems.length === 0 ? (
            <div className="empty-cart-state">
              <svg width="48" height="48" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
              </svg>
              <p>Your shopping cart is empty</p>
              <button className="shop-now-btn" onClick={onClose}>Browse Products</button>
            </div>
          ) : (
            cartItems.map((item, index) => {
              const displayPrice = item.variation ? item.variation.price : item.product.sellingPrice;
              const displayImage = item.variation?.image || item.product.image;
              
              return (
                <div key={index} className="cart-item">
                  <img 
                    src={formatImageUrl(displayImage)} 
                    alt={item.product.name} 
                    className="item-thumb" 
                  />
                  <div className="item-info">
                    <h4>{item.product.name}</h4>
                    {item.variation && (
                      <span className="item-meta">Option: {item.variation.title}</span>
                    )}
                    <span className="item-price">{formatCurrency(displayPrice)}</span>
                    
                    <div className="item-actions">
                      <div className="qty-selector">
                        <button 
                          onClick={() => updateCartItemQty(item.product._id, item.quantity - 1, item.variation?._id)}
                        >
                          -
                        </button>
                        <span>{item.quantity}</span>
                        <button 
                          onClick={() => updateCartItemQty(item.product._id, item.quantity + 1, item.variation?._id)}
                        >
                          +
                        </button>
                      </div>
                      <button 
                        className="item-remove-btn" 
                        onClick={() => removeFromCart(item.product._id, item.variation?._id)}
                      >
                        Remove
                      </button>
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {cartItems.length > 0 && (
          <div className="cart-footer">
            <div className="summary-row">
              <span>Subtotal</span>
              <span className="subtotal-val">{formatCurrency(cartSubtotal)}</span>
            </div>
            <p className="footer-notice">Shipping and taxes will be computed during checkout.</p>
            <button className="checkout-btn" onClick={handleCheckoutClick}>
              Proceed to Checkout
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
