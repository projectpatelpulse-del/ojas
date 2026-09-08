import React, { createContext, useContext, useState, useEffect } from 'react';
import type { Product, Variation, CartItem, Address } from '../core/types';
import { requestApi } from '../core/services/api';
import { useAuth } from './AuthContext';

interface CartContextType {
  cartItems: CartItem[];
  addToCart: (product: Product, variation?: Variation, referralCode?: string) => void;
  removeFromCart: (productId: string, variationId?: string) => void;
  updateCartItemQty: (productId: string, quantity: number, variationId?: string) => void;
  clearCart: () => void;
  cartSubtotal: number;
  placeOrder: (shippingAddress: Address, paymentMethod: 'COD' | 'ONLINE') => Promise<any>;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export const CartProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [cartItems, setCartItems] = useState<CartItem[]>(() => {
    const storedCart = localStorage.getItem('ojas_customer_cart');
    if (storedCart) {
      try {
        return JSON.parse(storedCart);
      } catch (e) {
        console.error('Failed to parse cart:', e);
      }
    }
    return [];
  });
  const { token } = useAuth();

  // Fetch cart items from server when token becomes available (logged in)
  useEffect(() => {
    if (!token) return;
    const fetchServerCart = async () => {
      try {
        const res = await requestApi('/user/cart');
        const cartObj = res.cart || res.data || res;
        if (cartObj && Array.isArray(cartObj.items)) {
          const itemsMapped = cartObj.items
            .filter((item: any) => item.product !== null)
            .map((item: any) => ({
              product: item.product,
              quantity: item.quantity,
              variation: item.variationId ? { _id: item.variationId, price: item.price } : undefined,
              referralCode: item.referralCode
            }));
          if (itemsMapped.length > 0) {
            setCartItems(itemsMapped);
          }
        }
      } catch (e) {
        console.warn('Failed to load server cart:', e);
      }
    };
    fetchServerCart();
  }, [token]);

  // Sync state to localStorage on changes
  useEffect(() => {
    localStorage.setItem('ojas_customer_cart', JSON.stringify(cartItems));
  }, [cartItems]);

  const addToCart = (product: Product, variation?: Variation, referralCode?: string) => {
    setCartItems(prev => {
      const existingIndex = prev.findIndex(item =>
        item.product._id === product._id &&
        item.variation?._id === variation?._id
      );

      const minQty = product.moq && product.moq > 1 ? product.moq : 1;

      if (existingIndex > -1) {
        const updated = [...prev];
        updated[existingIndex].quantity += 1;
        return updated;
      }

      return [...prev, { product, variation, quantity: minQty, referralCode }];
    });
  };

  const removeFromCart = (productId: string, variationId?: string) => {
    setCartItems(prev => prev.filter(item =>
      !(item.product._id === productId && item.variation?._id === variationId)
    ));
  };

  const updateCartItemQty = (productId: string, quantity: number, variationId?: string) => {
    if (quantity <= 0) {
      removeFromCart(productId, variationId);
      return;
    }
    setCartItems(prev => prev.map(item => {
      if (item.product._id === productId && item.variation?._id === variationId) {
        const minQty = item.product.moq && item.product.moq > 1 ? item.product.moq : 1;
        const validQty = quantity < minQty ? minQty : quantity;
        return { ...item, quantity: validQty };
      }
      return item;
    }));
  };

  const clearCart = () => {
    setCartItems([]);
    localStorage.removeItem('ojas_customer_cart');
  };

  const cartSubtotal = cartItems.reduce((sum, item) => {
    const price = item.variation ? item.variation.price : item.product.sellingPrice;
    return sum + (price * item.quantity);
  }, 0);

  // Sync local cart to server before checkout
  const syncCartWithServer = async () => {
    if (!token || cartItems.length === 0) return;

    // 1. Fetch current server cart to clear or adjust
    try {
      const serverCartData = await requestApi('/user/cart');
      const serverItems = serverCartData.data || serverCartData || [];

      // 2. Remove all existing items in server cart to avoid double accumulation
      for (const item of serverItems) {
        await requestApi('/user/cart/remove', {
          method: 'POST',
          body: JSON.stringify({
            productId: item.product._id || item.product.id,
            variationId: item.variationId
          })
        }).catch(() => { });
      }
    } catch (e) {
      console.warn('Failed to clean server cart, proceeding to push items:', e);
    }

    // 3. Push all current local cart items to the server
    for (const item of cartItems) {
      await requestApi('/user/cart/add', {
        method: 'POST',
        body: JSON.stringify({
          productId: item.product._id,
          variationId: item.variation?._id,
          quantity: item.quantity,
          referralCode: item.referralCode
        })
      });
    }
  };

  const placeOrder = async (shippingAddress: Address, paymentMethod: 'COD' | 'ONLINE') => {
    // Ensure server cart is synced with our local state first
    await syncCartWithServer();

    // Call order creation endpoint
    const response = await requestApi('/order/create', {
      method: 'POST',
      body: JSON.stringify({
        shippingAddress,
        paymentMethod
      })
    });

    if (paymentMethod === 'COD') {
      clearCart();
    }
    return response;
  };

  return (
    <CartContext.Provider value={{
      cartItems,
      addToCart,
      removeFromCart,
      updateCartItemQty,
      clearCart,
      cartSubtotal,
      placeOrder
    }}>
      {children}
    </CartContext.Provider>
  );
};

export const useCart = () => {
  const context = useContext(CartContext);
  if (!context) throw new Error('useCart must be used within a CartProvider');
  return context;
};
