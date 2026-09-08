import React, { useState, useEffect } from 'react';
import { AuthProvider } from './context/AuthContext';
import { CartProvider } from './context/CartContext';
import { Navbar } from './components/common/Navbar';
import { Footer } from './components/common/Footer';
import { Storefront } from './pages/Storefront';
import { ProductPage } from './pages/ProductPage';
import { OrdersPage } from './pages/OrdersPage';
import { ProfilePage } from './pages/ProfilePage';
import { AuthModal } from './components/auth/AuthModal';
import { CartSidebar } from './components/cart/CartSidebar';
import { CheckoutModal } from './components/checkout/CheckoutModal';
import { Toaster } from 'sonner';
import { requestApi } from './core/services/api';
import type { Collection, Product } from './core/types';
import './App.css';

const AppContent: React.FC = () => {
  const [collection, setCollection] = useState<Collection | null>(null);
  const [singleProduct, setSingleProduct] = useState<Product | null>(null);
  const [resellerCode, setResellerCode] = useState<string | null>(null);
  
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Modals Visibility
  const [showCart, setShowCart] = useState<boolean>(false);
  const [showAuth, setShowAuth] = useState<boolean>(false);
  const [showCheckout, setShowCheckout] = useState<boolean>(false);

  // Simple routing helper based on URL pathname
  const path = window.location.pathname;
  const isOrdersMode = path.startsWith('/orders') || window.location.hash.startsWith('#/orders');
  const isProfileMode = path.startsWith('/profile') || window.location.hash.startsWith('#/profile');
  const isProductMode = !isOrdersMode && !isProfileMode && path.startsWith('/product/');
  
  // Extract product ID from path (e.g., /product/6a6b430f42d37d9d157b4d5c)
  const productId = isProductMode ? path.split('/product/')[1] : null;

  // Extract query parameters
  const queryParams = new URLSearchParams(window.location.search);
  const queryRef = queryParams.get('ref');
  const queryCollection = queryParams.get('collection');

  // Determine shareCode from path or query parameter
  // e.g. path /collection/COLL_123 or path /COLL_123
  let shareCode = queryCollection || '';
  if (!shareCode && !isProductMode && !isOrdersMode && !isProfileMode && path.length > 1) {
    shareCode = path.startsWith('/collection/') ? path.split('/collection/')[1] : path.substring(1);
  }

  // Fallback reseller code logic
  useEffect(() => {
    if (queryRef) {
      setResellerCode(queryRef);
    }
  }, [queryRef]);

  // Fetch Collection Data
  useEffect(() => {
    if (isProductMode || isOrdersMode || isProfileMode || !shareCode) {
      setLoading(false);
      return;
    }

    const fetchCollection = async () => {
      setLoading(true);
      setError(null);
      try {
        const data = await requestApi(`/reseller/shared-collections/${shareCode}`);
        if (data && data.collection) {
          setCollection(data.collection);
          if (data.resellerCode) {
            setResellerCode(data.resellerCode);
          }
        } else {
          setError('Collection could not be resolved from response.');
        }
      } catch (err: any) {
        setError(err.message || 'Failed to fetch shared collection');
      } finally {
        setLoading(false);
      }
    };

    fetchCollection();
  }, [shareCode, isProductMode, isProfileMode, isOrdersMode]);

  // Fetch Single Product Data
  useEffect(() => {
    if (!isProductMode || !productId) return;

    const fetchProduct = async () => {
      setLoading(true);
      setError(null);
      const refCodeParam = resellerCode ? `?ref=${resellerCode}` : (queryRef ? `?ref=${queryRef}` : '');
      try {
        const resData = await requestApi(`/home/products/${productId}${refCodeParam}`);
        const productData = resData.data || resData;
        if (productData && productData._id) {
          setSingleProduct(productData);
          if (productData.resellerCode) {
            setResellerCode(productData.resellerCode);
          }
        } else {
          setError('Product could not be resolved from response.');
        }
      } catch (err: any) {
        setError(err.message || 'Failed to load product');
      } finally {
        setLoading(false);
      }
    };

    fetchProduct();
  }, [productId, isProductMode, resellerCode, queryRef]);

  const handleProductClick = (product: Product) => {
    // Navigate to single product detail page maintaining reseller reference
    const refCode = product.resellerCode || resellerCode;
    const refParam = refCode ? `?ref=${refCode}` : '';
    window.location.href = `/product/${product._id}${refParam}`;
  };

  const handleResetCatalog = () => {
    if (shareCode) {
      window.location.href = `/collection/${shareCode}`;
    } else {
      window.location.href = '/';
    }
  };

  // Render Loader
  if (loading) {
    return (
      <div className="catalog-loading-state">
        <div className="spinner"></div>
        <p>Fetching curated designs...</p>
      </div>
    );
  }

  // Render Error Page
  if (error) {
    return (
      <div className="catalog-error-state">
        <div className="error-card animate-scale-up">
          <svg width="48" height="48" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          <h3>Unable to Load Content</h3>
          <p>{error}</p>
          <div className="error-actions">
            <button className="retry-btn" onClick={() => window.location.reload()}>
              Retry Connection
            </button>
            <button className="back-btn" onClick={handleResetCatalog}>
              Back to Storefront
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="storefront-wrapper">
      <Navbar 
        resellerCode={resellerCode}
        onOpenCart={() => setShowCart(true)}
        onOpenAuth={() => setShowAuth(true)}
        onResetCatalog={handleResetCatalog}
      />

      <main className="main-content-area">
        {isProfileMode ? (
          <ProfilePage />
        ) : isOrdersMode ? (
          <OrdersPage />
        ) : isProductMode && singleProduct ? (
          <ProductPage 
            product={singleProduct} 
            resellerCode={resellerCode} 
            onBuyNow={() => setShowCheckout(true)}
          />
        ) : collection ? (
          <Storefront 
            collection={collection} 
            resellerCode={resellerCode} 
            onProductClick={handleProductClick}
          />
        ) : (
          <div className="empty-catalog-state">
            <div className="empty-card animate-scale-up">
              <h2>Welcome to our Curated Storefront</h2>
              <p>Please load this page using a shared collection link or a product link shared by your Reseller Partner.</p>
              <a href="https://wa.me/918340248443" target="_blank" rel="noreferrer" className="contact-support-btn">
                Contact Support for Links
              </a>
            </div>
          </div>
        )}
      </main>

      <Footer />

      {/* Cart Sidebar drawer */}
      <CartSidebar 
        isOpen={showCart} 
        onClose={() => setShowCart(false)} 
        onCheckout={() => setShowCheckout(true)}
        onOpenAuth={() => setShowAuth(true)}
      />

      {/* Login & Register Modal overlay */}
      <AuthModal 
        isOpen={showAuth} 
        onClose={() => setShowAuth(false)} 
      />

      {/* Address & Checkout Modal overlay */}
      <CheckoutModal 
        isOpen={showCheckout} 
        onClose={() => setShowCheckout(false)} 
      />

      <Toaster position="bottom-right" richColors />
    </div>
  );
};

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <CartProvider>
        <AppContent />
      </CartProvider>
    </AuthProvider>
  );
};

export default App;
