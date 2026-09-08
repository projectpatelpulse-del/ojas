import React, { useState, useEffect } from 'react';
import type { Product, Variation } from '../core/types';
import { formatImageUrl, formatCurrency } from '../core/utils';
import { useCart } from '../context/CartContext';
import { toast } from 'sonner';
import './ProductPage.css';

interface ProductPageProps {
  product: Product;
  resellerCode: string | null;
  onBuyNow: () => void;
}

export const ProductPage: React.FC<ProductPageProps> = ({
  product,
  resellerCode,
  onBuyNow
}) => {
  const { addToCart } = useCart();
  const [selectedImage, setSelectedImage] = useState<string>(product.image || '');
  const [selectedVariation, setSelectedVariation] = useState<Variation | null>(null);

  // Get active images based on selected variation, falling back to product main image & gallery
  const getActiveImages = () => {
    const varImages: string[] = [];
    if (selectedVariation) {
      if (selectedVariation.images && selectedVariation.images.length > 0) {
        varImages.push(...selectedVariation.images.filter(img => img));
      }
      if (selectedVariation.image && !varImages.includes(selectedVariation.image)) {
        varImages.unshift(selectedVariation.image);
      }
    }
    
    if (varImages.length > 0) {
      return varImages;
    }
    
    const prodImages: string[] = [];
    if (product.image) {
      prodImages.push(product.image);
    }
    if (product.gallery && product.gallery.length > 0) {
      product.gallery.forEach(img => {
        if (img && !prodImages.includes(img)) {
          prodImages.push(img);
        }
      });
    }
    return prodImages;
  };

  const activeImages = getActiveImages();

  useEffect(() => {
    if (product.variations && product.variations.length > 0) {
      setSelectedVariation(product.variations[0]);
    } else {
      setSelectedVariation(null);
    }
  }, [product]);

  useEffect(() => {
    const currentImages = getActiveImages();
    if (currentImages.length > 0) {
      setSelectedImage(currentImages[0]);
    } else {
      setSelectedImage(product.image || '');
    }
  }, [selectedVariation, product.image]);

  const handleAddToCart = () => {
    addToCart(product, selectedVariation || undefined, resellerCode || undefined);
    toast.success('Added to cart!');
  };

  const handleBuyNow = () => {
    addToCart(product, selectedVariation || undefined, resellerCode || undefined);
    onBuyNow();
  };

  // const handleWhatsAppInquiry = () => {
  //   const priceToDisplay = selectedVariation ? selectedVariation.price : product.sellingPrice;
  //   const variationText = selectedVariation ? ` (Selected: ${selectedVariation.title})` : '';
  //   const message = `Hello, I'm interested in buying this product:\n\n*Product:* ${product.name}${variationText}\n*Price:* ${formatCurrency(priceToDisplay)}\n*Reseller Code:* ${resellerCode || 'N/A'}\n\nPlease share availability and order steps!`;
  //   const encodedMessage = encodeURIComponent(message);
  //   const whatsappUrl = `https://wa.me/918340248443?text=${encodedMessage}`;
  //   window.open(whatsappUrl, '_blank');
  // };

  return (
    <div className="single-product-main-container animate-fade-in">
      <div className="product-page-layout">
        {/* Product Gallery Pane */}
        <div className="modal-gallery-pane">
          <div className="main-preview-image">
            <img src={formatImageUrl(selectedImage || product.image)} alt={product.name} />
          </div>
          {activeImages.length > 1 && (
            <div className="thumbnail-strip">
              {activeImages.map((imgUrl, i) => (
                <div 
                  key={i} 
                  className={`thumb-item ${selectedImage === imgUrl ? 'active' : ''}`}
                  onClick={() => setSelectedImage(imgUrl)}
                >
                  <img src={formatImageUrl(imgUrl)} alt={`gallery-${i}`} />
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Product Configurations & Details Pane */}
        <div className="modal-details-pane">
          <span className="brand-label">{product.brand || 'Premium Design'}</span>
          <h2>{product.name}</h2>
          
          <div className="modal-rating-row">
            <div className="stars">
              {'★'.repeat(Math.round(product.rating || 4))}
              {'☆'.repeat(5 - Math.round(product.rating || 4))}
            </div>
            <span>{product.rating || 4.5} out of 5 stars ({product.numReviews || 12} reviews)</span>
          </div>

          <div className="modal-price-pane">
            <span className="price-now">
              {formatCurrency(selectedVariation ? selectedVariation.price : product.sellingPrice)}
            </span>
            {(selectedVariation ? selectedVariation.oldPrice : (product.discountPrice && product.discountPrice > 0 ? product.price : undefined)) && (
              <span className="price-was">
                {formatCurrency(selectedVariation ? (selectedVariation.oldPrice || 0) : (product.price || 0))}
              </span>
            )}
            <span className="tax-label">Inclusive of all reseller markups & local taxes</span>
          </div>

          {product.shortDescription && (
            <p className="short-desc">{product.shortDescription}</p>
          )}

          {/* MOQ Banner/Container */}
          {((product.moq && product.moq > 1) || (product.moqTiers && product.moqTiers.trim().length > 0)) && (
            <div className="moq-info-container" style={{
              backgroundColor: 'rgba(59, 130, 246, 0.08)',
              border: '1px solid rgba(59, 130, 246, 0.2)',
              borderRadius: '8px',
              padding: '12px',
              marginTop: '16px',
              marginBottom: '16px',
              fontSize: '14px',
              color: '#1e40af'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 600, marginBottom: '4px' }}>
                <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth="2">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                </svg>
                <span>Minimum Order Qty (MOQ): {product.moq || 1} units</span>
              </div>
              
              {product.moqTiers && product.moqTiers.trim().length > 0 ? (
                <div style={{ marginTop: '8px', fontSize: '12px' }}>
                  <div style={{ fontWeight: 700, color: '#1e3a8a', marginBottom: '4px' }}>Volume Discounts:</div>
                  {product.moqTiers.split(',').map((tier, idx) => {
                    const parts = tier.trim().split(':');
                    if (parts.length === 2) {
                      const qty = parts[0].trim();
                      const discount = parts[1].replace('%', '').trim();
                      return (
                        <div key={idx} style={{ margin: '2px 0', color: '#1e3a8a' }}>
                          • Buy {qty}+ units, get {discount}% off
                        </div>
                      );
                    }
                    return null;
                  })}
                </div>
              ) : (product.moqDiscount && product.moqDiscount > 0 ? (
                <div style={{ marginTop: '4px', fontSize: '12px', color: '#1e3a8a' }}>
                  • Buy {product.moq}+ units, get {Math.round(product.moqDiscount)}% off
                </div>
              ) : null)}
            </div>
          )}

          {/* Variations Selector */}
          {product.variations && product.variations.length > 0 && (
            <div className="variations-selector-group">
              <label>Select Option / Size:</label>
              <div className="variations-buttons">
                {product.variations.map((v, i) => (
                  <button 
                    key={v._id || i} 
                    className={`var-btn ${selectedVariation?._id === v._id || (selectedVariation === v) ? 'active' : ''}`}
                    onClick={() => setSelectedVariation(v)}
                  >
                    {v.title || v.size || `Option ${i + 1}`} ({formatCurrency(v.price)})
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Specs List */}
          {product.specs && product.specs.length > 0 && (
            <div className="specs-table-group">
              <h3>Specifications</h3>
              <div className="specs-container">
                {product.specs
                  .filter(spec => {
                    const key = spec.key.trim().toLowerCase();
                    return key !== 'size' && key !== 'weight';
                  })
                  .map((spec, i) => (
                    <div key={i} className="spec-item-row">
                      <span className="spec-item-key">{spec.key}</span>
                      <span className="spec-item-value">{spec.value}</span>
                    </div>
                  ))}
              </div>
            </div>
          )}

          {/* Overview Description */}
          {product.description && (
            <div className="description-text-group">
              <h3>Product Overview</h3>
              <div className="overview-points-wrapper">
                {product.description.includes('•') ? (
                  product.description
                    .split('•')
                    .map(p => p.trim())
                    .filter(p => p.length > 0)
                    .map((point, idx) => {
                      const colonIdx = point.indexOf(':');
                      if (colonIdx !== -1) {
                        const label = point.substring(0, colonIdx + 1);
                        const rest = point.substring(colonIdx + 1);
                        return (
                          <div key={idx} className="overview-point-row">
                            <span className="bullet-indicator">✦</span>
                            <p className="point-text">
                              <strong>{label}</strong>{rest}
                            </p>
                          </div>
                        );
                      }
                      return (
                        <div key={idx} className="overview-point-row">
                          <span className="bullet-indicator">✦</span>
                          <p className="point-text">{point}</p>
                        </div>
                      );
                    })
                ) : (
                  <p className="fallback-description-text">{product.description}</p>
                )}
              </div>
            </div>
          )}

          {/* Buy Buttons */}
          <div className="action-button-pane" style={{ marginTop: '28px', width: '100%' }}>
            <div style={{ display: 'flex', gap: '16px', width: '100%' }}>
              <button 
                className="add-to-cart-checkout-btn" 
                onClick={handleAddToCart}
                style={{ 
                  flex: 1, 
                  backgroundColor: 'transparent', 
                  border: '2px solid var(--accent)', 
                  color: 'var(--accent)',
                  borderRadius: '12px',
                  padding: '14px 20px',
                  fontSize: '16px',
                  fontWeight: '600',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '8px',
                  cursor: 'pointer',
                  transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                  boxShadow: '0 2px 4px rgba(0,0,0,0.02)'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.backgroundColor = 'rgba(127, 29, 29, 0.05)';
                  e.currentTarget.style.transform = 'translateY(-1px)';
                  e.currentTarget.style.boxShadow = '0 4px 8px rgba(0,0,0,0.05)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.backgroundColor = 'transparent';
                  e.currentTarget.style.transform = 'none';
                  e.currentTarget.style.boxShadow = '0 2px 4px rgba(0,0,0,0.02)';
                }}
              >
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth="2">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                </svg>
                Add to Cart
              </button>
              <button 
                className="add-to-cart-checkout-btn" 
                onClick={handleBuyNow}
                style={{ 
                  flex: 1, 
                  backgroundColor: 'var(--accent)', 
                  color: '#ffffff',
                  border: 'none',
                  borderRadius: '12px',
                  padding: '14px 20px',
                  fontSize: '16px',
                  fontWeight: '600',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '8px',
                  cursor: 'pointer',
                  transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                  boxShadow: '0 4px 12px rgba(127, 29, 29, 0.15)'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.filter = 'brightness(1.08)';
                  e.currentTarget.style.transform = 'translateY(-1px)';
                  e.currentTarget.style.boxShadow = '0 6px 16px rgba(127, 29, 29, 0.25)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.filter = 'none';
                  e.currentTarget.style.transform = 'none';
                  e.currentTarget.style.boxShadow = '0 4px 12px rgba(127, 29, 29, 0.15)';
                }}
              >
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth="2">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
                Buy Now
              </button>
            </div>
            
            {/* 
            <button className="whatsapp-checkout-btn" onClick={handleWhatsAppInquiry}>
              <svg width="20" height="20" fill="currentColor" viewBox="0 0 16 16" style={{ marginRight: '8px' }}>
                <path d="M13.601 2.326A7.854 7.854 0 0 0 7.994 0C3.627 0 .068 3.558.064 7.926c0 1.399.366 2.76 1.057 3.965L0 16l4.204-1.102a7.933 7.933 0 0 0 3.79.907h.003c4.368 0 7.926-3.558 7.93-7.93a7.897 7.897 0 0 0-2.326-5.594zm-5.607 11.366A6.98 6.98 0 0 1 4.1 13.11l-.25-.148-2.484.651.662-2.42-.162-.257a6.974 6.974 0 0 1-1.074-3.79c.002-3.859 3.153-7.011 7.014-7.011a6.968 6.968 0 0 1 4.957 2.053 6.978 6.978 0 0 1 2.043 4.96c-.004 3.86-3.15 7.01-7.015 7.01H7.994zm3.847-5.076c-.208-.104-1.234-.61-1.423-.679-.19-.069-.328-.104-.467.104-.139.208-.538.68-.66.816-.122.136-.243.153-.451.05-2.008-.996-2.786-2.057-3.236-2.83-.119-.203-.012-.313.089-.413.09-.09.202-.234.302-.35.101-.118.135-.2.203-.338.068-.138.034-.26-.017-.365-.05-.104-.467-1.127-.64-1.542-.168-.405-.339-.35-.467-.356-.12-.006-.258-.007-.396-.007a.777.777 0 0 0-.563.264c-.19.208-.724.708-.724 1.73 0 1.02.743 2.01.846 2.148.104.137 1.463 2.238 3.548 3.134.496.213.882.437.5.158.955.136 1.314.083.4-.059 1.234-.504 1.41-1.002.175-.498.175-.927.122-1.002-.054-.075-.19-.118-.398-.222z"/>
              </svg>
              Order on WhatsApp
            </button>
            */}
          </div>
        </div>
      </div>
    </div>
  );
};
