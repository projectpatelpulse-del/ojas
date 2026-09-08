import React from 'react';
import type { Collection, Product } from '../core/types';
import { formatImageUrl } from '../core/utils';
import { toast } from 'sonner';
import './Storefront.css';

interface StorefrontProps {
  collection: Collection;
  resellerCode: string | null;
  onProductClick: (product: Product) => void;
}

export const Storefront: React.FC<StorefrontProps> = ({
  collection,
  resellerCode,
  onProductClick,
}) => {
  const handleShareStore = () => {
    navigator.clipboard.writeText(window.location.href);
    toast.success('Store link copied to clipboard!');
  };

  return (
    <div className="store-content-view animate-fade-in">
      {/* Banner Section */}
      <section className="collection-hero-banner">
        <button className="share-store-btn" onClick={handleShareStore}>
          <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth="2">
            <path strokeLinecap="round" strokeLinejoin="round" d="M8.684 10.742l4.286-2.143m0 0a3 3 0 10-4.286-2.143m4.286 2.143L8.684 13.5M14 6.5a3 3 0 11-6 0 3 3 0 016 0zM7 13.5a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          Share Store
        </button>

        <div className="banner-inner">
          <span className="banner-tagline">
            <span style={{ marginRight: '4px' }}>✦</span> CURATED STOREFRONT
          </span>
          <h2>{collection.name}</h2>
          {collection.description && (
            <div className="collection-desc-wrap">
              <p>{collection.description}</p>
              <div className="title-underline"></div>
            </div>
          )}
          
          <div className="banner-meta">
            <div className="meta-card">
              <div className="meta-card-icon" style={{ backgroundColor: 'rgba(226, 35, 42, 0.08)' }}>
                <svg width="20" height="20" fill="none" stroke="#e2232a" viewBox="0 0 24 24" strokeWidth="2">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                </svg>
              </div>
              <div className="meta-card-info">
                <h4>{String(collection.products?.length || 0).padStart(2, '0')}</h4>
                <span>Premium Products</span>
              </div>
            </div>

            {resellerCode && (
              <div className="meta-card">
                <div className="meta-card-icon" style={{ backgroundColor: 'rgba(198, 146, 72, 0.1)' }}>
                  <svg width="20" height="20" fill="none" stroke="#c69248" viewBox="0 0 24 24" strokeWidth="2">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                  </svg>
                </div>
                <div className="meta-card-info">
                  <h4>{resellerCode}</h4>
                  <span>Partner Code</span>
                </div>
              </div>
            )}

            <div className="meta-card">
              <div className="meta-card-icon" style={{ backgroundColor: 'rgba(22, 163, 74, 0.08)' }}>
                <svg width="20" height="20" fill="none" stroke="#16a34a" viewBox="0 0 24 24" strokeWidth="2">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
              <div className="meta-card-info">
                <h4>Active</h4>
                <span>Store Status</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Grid Title */}
      <div className="grid-section-header">
        <h3>Exclusive Shared Catalog</h3>
        <p>Handpicked designs tailored by your partner reseller. Tap on any design to inspect variations, details, or to add to your order.</p>
      </div>

      {/* Products Grid */}
      <section className="products-showcase-grid">
        {collection.products && collection.products.length > 0 ? (
          collection.products.map((item) => {
            const product = item.product;
            if (!product) return null;
            
            const hasDiscount = product.discountPrice && product.discountPrice > 0;
            const displayPrice = product.sellingPrice;
            const oldPrice = hasDiscount ? product.price : undefined;
            const discountPercent = oldPrice ? Math.round(((oldPrice - displayPrice) / oldPrice) * 100) : 0;

            return (
              <div key={product._id} className="store-product-card" onClick={() => onProductClick(product)}>
                <div className="card-image-wrap">
                  <img src={formatImageUrl(product.image)} alt={product.name} loading="lazy" />
                  {discountPercent > 0 && (
                    <span className="card-discount-badge">{discountPercent}% OFF</span>
                  )}
                </div>
                <div className="card-details">
                  <span className="card-category">{product.category}</span>
                  <h4 className="card-title">{product.name}</h4>
                  
                  <div className="card-rating">
                    <div className="stars">
                      {'★'.repeat(Math.round(product.rating || 4))}
                      {'☆'.repeat(5 - Math.round(product.rating || 4))}
                    </div>
                    <span className="review-count">({product.numReviews || 12})</span>
                  </div>

                  <div className="card-price-row">
                    <div className="prices">
                      <span className="current-price">₹{Math.ceil(displayPrice)}</span>
                      {oldPrice && (
                        <span className="old-price">₹{Math.ceil(oldPrice)}</span>
                      )}
                    </div>
                    <button className="view-product-btn">
                      View Details
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        ) : (
          <div className="empty-collection-state">
            <svg width="48" height="48" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
            </svg>
            <p>No products available in this shared collection.</p>
          </div>
        )}
      </section>
    </div>
  );
};
