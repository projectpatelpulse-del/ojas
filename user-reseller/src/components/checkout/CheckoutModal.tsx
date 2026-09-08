import React, { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { useCart } from '../../context/CartContext';
import { formatCurrency } from '../../core/utils';
import { toast } from 'sonner';
import './CheckoutModal.css';

interface CheckoutModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const CheckoutModal: React.FC<CheckoutModalProps> = ({ isOpen, onClose }) => {
  const { addresses, addAddress, deleteAddress } = useAuth();
  const { cartItems, cartSubtotal, placeOrder } = useCart();

  const [selectedAddressIndex, setSelectedAddressIndex] = useState<number>(0);
  const [showNewAddressForm, setShowNewAddressForm] = useState<boolean>(false);
  const [paymentMethod, setPaymentMethod] = useState<'COD' | 'ONLINE'>('COD');
  const [loading, setLoading] = useState<boolean>(false);
  const [orderSuccessData, setOrderSuccessData] = useState<any | null>(null);

  // Address form fields
  const [newName, setNewName] = useState<string>('');
  const [newMobile, setNewMobile] = useState<string>('');
  const [newBuilding, setNewBuilding] = useState<string>('');
  const [newStreet, setNewStreet] = useState<string>('');
  const [newArea, setNewArea] = useState<string>('');
  const [newLandmark, setNewLandmark] = useState<string>('');
  const [newCity, setNewCity] = useState<string>('');
  const [newState, setNewState] = useState<string>('');
  const [newZipCode, setNewZipCode] = useState<string>('');

  const cartGst = Math.ceil(cartItems.reduce((sum, item) => {
    const price = item.variation ? item.variation.price : item.product.sellingPrice;
    const markup = item.product.resellerMarkup || 0;
    const basePrice = Math.max(0, price - markup);
    const gstPercent = item.product.gst || 0;
    const gstAmount = (basePrice * gstPercent) / 100;
    return sum + (gstAmount * item.quantity);
  }, 0));

  const cartTotal = cartSubtotal + cartGst;

  if (!isOpen) return null;

  const handleAddNewAddress = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName || !newMobile || !newBuilding || !newStreet || !newArea || !newCity || !newState || !newZipCode) {
      toast.error('Please fill in all required address fields');
      return;
    }
    setLoading(true);
    try {
      await addAddress({
        name: newName,
        mobile: newMobile,
        buildingName: newBuilding,
        street: newStreet,
        area: newArea,
        landmark: newLandmark,
        city: newCity,
        state: newState,
        zipCode: newZipCode
      });
      toast.success('Address added successfully!');
      setShowNewAddressForm(false);
      // Reset form
      setNewName('');
      setNewMobile('');
      setNewBuilding('');
      setNewStreet('');
      setNewArea('');
      setNewLandmark('');
      setNewCity('');
      setNewState('');
      setNewZipCode('');
    } catch (err: any) {
      toast.error(err.message || 'Failed to add address');
    } finally {
      setLoading(false);
    }
  };

  const handleCheckoutSubmit = async () => {
    const address = addresses[selectedAddressIndex];
    if (!address && !showNewAddressForm) {
      toast.error('Please select or add a shipping address');
      return;
    }

    setLoading(true);
    try {
      const response = await placeOrder(address, paymentMethod);
      if (paymentMethod === 'ONLINE') {
        const payload = response.paymentPayload;
        if (payload && payload.payment_session_id) {
          const mode = payload.environment === 'production' ? 'production' : 'sandbox';
          try {
            // @ts-ignore
            const cashfree = window.Cashfree({
              mode: mode
            });
            toast.success('Opening secure payment checkout...');
            // @ts-ignore
            cashfree.checkout({
              paymentSessionId: payload.payment_session_id,
              redirectTarget: "_self"
            });
          } catch (checkoutErr: any) {
            console.error('Cashfree SDK execution failed:', checkoutErr);
            toast.error('Could not initialize Cashfree checkout window.');
          }
        } else {
          toast.error('Failed to initialize payment gateway.');
        }
      } else {
        setOrderSuccessData(response.order || response.data || response);
        toast.success('Order placed successfully!');
      }
    } catch (err: any) {
      toast.error(err.message || 'Failed to place order');
    } finally {
      setLoading(false);
    }
  };

  if (orderSuccessData) {
    return (
      <div className="auth-overlay active">
        <div className="auth-modal checkout-success-view animate-scale-up">
          <div className="success-icon-container">
            <svg width="64" height="64" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h3>Order Confirmed!</h3>
          <p className="success-msg">Thank you for your order. Your partner reseller will review it shortly.</p>

          <div className="order-details-card">
            <div className="detail-row">
              <span className="label">Order ID:</span>
              <span className="val font-semibold">{orderSuccessData.orderId || orderSuccessData._id}</span>
            </div>
            <div className="detail-row">
              <span className="label">Amount Paid:</span>
              <span className="val">{formatCurrency(orderSuccessData.totalAmount || cartSubtotal)}</span>
            </div>
            <div className="detail-row">
              <span className="label">Payment Status:</span>
              <span className="val badge-success">{orderSuccessData.paymentStatus || 'COD_PENDING'}</span>
            </div>
          </div>

          <button className="done-btn" onClick={() => { onClose(); setOrderSuccessData(null); }}>
            Back to Catalog
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="auth-overlay active">
      <div className="auth-modal checkout-modal animate-scale-up">
        <button className="auth-close-btn" onClick={onClose}>&times;</button>

        <div className="auth-header">
          <h3>Secure Checkout</h3>
          <p>Provide delivery address and complete payment to confirm order.</p>
        </div>

        <div className="checkout-content">
          {/* Step 1: Address Selection */}
          <div className="checkout-section">
            <div className="section-title-row">
              <h4>1. Shipping Address</h4>
              {!showNewAddressForm && (
                <button className="text-btn" onClick={() => setShowNewAddressForm(true)}>
                  + Add New
                </button>
              )}
            </div>

            {showNewAddressForm ? (
              <form onSubmit={handleAddNewAddress} className="new-address-form animate-fade-in">
                <div className="form-grid">
                  <div className="form-group">
                    <label>Receiver Name *</label>
                    <input type="text" value={newName} onChange={e => setNewName(e.target.value)} required />
                  </div>
                  <div className="form-group">
                    <label>Mobile Number *</label>
                    <input type="tel" value={newMobile} onChange={e => setNewMobile(e.target.value)} required />
                  </div>
                  <div className="form-group">
                    <label>Building/House No *</label>
                    <input type="text" value={newBuilding} onChange={e => setNewBuilding(e.target.value)} required />
                  </div>
                  <div className="form-group">
                    <label>Street/Road Name *</label>
                    <input type="text" value={newStreet} onChange={e => setNewStreet(e.target.value)} required />
                  </div>
                  <div className="form-group">
                    <label>Area/Locality *</label>
                    <input type="text" value={newArea} onChange={e => setNewArea(e.target.value)} required />
                  </div>
                  <div className="form-group">
                    <label>Landmark (Optional)</label>
                    <input type="text" value={newLandmark} onChange={e => setNewLandmark(e.target.value)} />
                  </div>
                  <div className="form-group">
                    <label>City *</label>
                    <input type="text" value={newCity} onChange={e => setNewCity(e.target.value)} required />
                  </div>
                  <div className="form-group animate-pulse-once">
                    <label>State *</label>
                    <input type="text" value={newState} onChange={e => setNewState(e.target.value)} required />
                  </div>
                  <div className="form-group">
                    <label>Pincode *</label>
                    <input type="text" value={newZipCode} onChange={e => setNewZipCode(e.target.value)} required />
                  </div>
                </div>

                <div className="form-actions">
                  <button type="button" className="cancel-btn" onClick={() => setShowNewAddressForm(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="save-address-btn" disabled={loading}>
                    Save Address
                  </button>
                </div>
              </form>
            ) : (
              <div className="addresses-list">
                {addresses.length === 0 ? (
                  <p className="no-address">No saved addresses found. Please add a shipping address.</p>
                ) : (
                  addresses.map((addr, idx) => (
                    <div
                      key={addr._id || idx}
                      className={`address-card ${selectedAddressIndex === idx ? 'active' : ''}`}
                      onClick={() => setSelectedAddressIndex(idx)}
                      style={{ position: 'relative' }}
                    >
                      <input
                        type="radio"
                        checked={selectedAddressIndex === idx}
                        onChange={() => setSelectedAddressIndex(idx)}
                      />
                      <div className="addr-details" style={{ flex: 1 }}>
                        <span className="name">{addr.name} ({addr.mobile})</span>
                        <p>{addr.buildingName}, {addr.street}, {addr.area}, {addr.landmark ? `${addr.landmark}, ` : ''}{addr.city}, {addr.state} - {addr.zipCode}</p>
                      </div>
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          if (confirm('Are you sure you want to delete this address?')) {
                            deleteAddress(addr._id!);
                          }
                        }}
                        style={{
                          background: 'none',
                          border: 'none',
                          color: '#EF4444',
                          cursor: 'pointer',
                          fontSize: '12px',
                          fontWeight: 600,
                          padding: '4px',
                          alignSelf: 'center'
                        }}
                      >
                        Delete
                      </button>
                    </div>
                  ))
                )}
              </div>
            )}
          </div>

          {/* Step 2: Payment Method */}
          <div className="checkout-section" style={{ marginTop: '20px' }}>
            <h4>2. Payment Method</h4>
            <div className="payment-options">
              <div
                className={`payment-card ${paymentMethod === 'COD' ? 'active' : ''}`}
                onClick={() => setPaymentMethod('COD')}
              >
                <input type="radio" checked={paymentMethod === 'COD'} onChange={() => setPaymentMethod('COD')} />
                <div className="payment-meta">
                  <span className="title">Cash on Delivery (COD)</span>
                  <span className="desc">Pay at the time of courier package arrival.</span>
                </div>
              </div>

              <div
                className={`payment-card ${paymentMethod === 'ONLINE' ? 'active' : ''}`}
                onClick={() => setPaymentMethod('ONLINE')}
              >
                <input type="radio" checked={paymentMethod === 'ONLINE'} onChange={() => setPaymentMethod('ONLINE')} />
                <div className="payment-meta">
                  <span className="title">Online Payment (UPI, Card, Netbanking)</span>
                  <span className="desc">Pay securely online via our payment gateway.</span>
                </div>
              </div>
            </div>
          </div>

          {/* Step 3: Order Summary & Placement */}
          <div className="price-details-card" style={{
            background: '#ffffff',
            borderRadius: '16px',
            border: '1px solid #e2e8f0',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)',
            marginTop: '25px',
            overflow: 'hidden'
          }}>
            <div style={{
              padding: '16px 20px',
              borderBottom: '1px solid #f1f5f9',
              fontSize: '14px',
              fontWeight: 700,
              color: '#1e293b',
              letterSpacing: '0.5px'
            }}>
              PRICE DETAILS
            </div>

            <div style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', color: '#64748b' }}>
                <span>Price ({cartItems.reduce((sum, item) => sum + item.quantity, 0)} items)</span>
                <span style={{ fontWeight: 500, color: '#334155' }}>{formatCurrency(cartSubtotal)}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', color: '#64748b' }}>
                <span>Delivery Charges</span>
                <span style={{ fontWeight: 600, color: '#10b981' }}>FREE</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', color: '#64748b' }}>
                <span>Taxes</span>
                <span style={{ fontWeight: 500, color: '#334155' }}>{formatCurrency(cartGst)}</span>
              </div>

              <div style={{
                margin: '8px 0',
                borderTop: '1px solid #f1f5f9'
              }} />

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: '16px', fontWeight: 700, color: '#1e293b' }}>Total Amount</span>
                <span style={{ fontSize: '20px', fontWeight: 800, color: '#4f46e5' }}>{formatCurrency(cartTotal)}</span>
              </div>
            </div>
          </div>

          <div style={{ marginTop: '20px', display: 'flex', flexDirection: 'column' }}>

            <button
              className="place-order-btn"
              onClick={handleCheckoutSubmit}
              disabled={loading || (!showNewAddressForm && addresses.length === 0)}
              style={{ marginTop: '10px' }}
            >
              {loading ? 'Processing Order...' : `Place ${paymentMethod === 'COD' ? 'COD' : 'Online'} Order`}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
