import React, { useState, useEffect } from 'react';
import { requestApi } from '../core/services/api';
import { formatCurrency, formatImageUrl } from '../core/utils';
import { toast } from 'sonner';

interface OrderItem {
  product: {
    _id: string;
    name: string;
  };
  name: string;
  quantity: number;
  price: number;
  image?: string;
  variation?: any;
}

interface Order {
  _id: string;
  orderId: string;
  items: OrderItem[];
  subtotal: number;
  totalAmount: number;
  status: string;
  paymentMethod: string;
  paymentStatus: string;
  transactionId?: string;
  createdAt: string;
  shippingAddress: {
    buildingName: string;
    street: string;
    area: string;
    landmark?: string;
    city: string;
    state: string;
    zipCode: string;
  };
  awb?: string;
  courierPartner?: string;
  trackingUrl?: string;
}

export const OrdersPage: React.FC = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [expandedOrderId, setExpandedOrderId] = useState<string | null>(null);
  
  // Tracking state
  const [trackingLoading, setTrackingLoading] = useState<boolean>(false);
  const [trackingData, setTrackingData] = useState<any | null>(null);
  const [trackingAwb, setTrackingAwb] = useState<string | null>(null);

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const response = await requestApi('/order/user');
      if (response && response.orders) {
        setOrders(response.orders);
      } else if (Array.isArray(response)) {
        setOrders(response);
      }
    } catch (err: any) {
      toast.error(err.message || 'Failed to load your orders');
    } finally {
      setLoading(false);
    }
  };

  const toggleOrderExpand = (orderId: string) => {
    if (expandedOrderId === orderId) {
      setExpandedOrderId(null);
      setTrackingData(null);
      setTrackingAwb(null);
    } else {
      setExpandedOrderId(orderId);
      setTrackingData(null);
      setTrackingAwb(null);
    }
  };

  const handleTrackOrder = async (awb: string) => {
    setTrackingLoading(true);
    setTrackingAwb(awb);
    setTrackingData(null);
    try {
      const response = await requestApi(`/order/track/${awb}`);
      if (response && response.success && response.data) {
        setTrackingData(response.data);
      } else {
        toast.error('No tracking updates found yet.');
      }
    } catch (err: any) {
      toast.error('Could not load tracking information.');
    } finally {
      setTrackingLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'DELIVERED':
        return '#22C55E';
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
        return '#3B82F6';
      case 'CANCELLED':
        return '#EF4444';
      default:
        return '#F59E0B';
    }
  };

  if (loading) {
    return (
      <div className="catalog-loading-state">
        <div className="spinner"></div>
        <p>Loading your order history...</p>
      </div>
    );
  }

  return (
    <div className="orders-history-container animate-fade-in" style={{ padding: '24px', maxWidth: '1000px', margin: '0 auto', minHeight: '60vh' }}>
      <h2 style={{ fontSize: '24px', fontWeight: 800, color: 'var(--text-h)', marginBottom: '8px' }}>Your Orders</h2>
      <p style={{ color: 'var(--text-p)', marginBottom: '24px', fontSize: '14px' }}>Track shipment timelines, view invoice receipts, and review past order transactions.</p>

      {orders.length === 0 ? (
        <div className="empty-cart-state" style={{ padding: '48px 0', border: '1px dashed var(--border)', borderRadius: '16px', background: '#FFFFFF' }}>
          <svg width="48" height="48" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
          <p style={{ margin: '16px 0' }}>You have not placed any orders yet.</p>
          <button className="shop-now-btn" onClick={() => window.location.href = '/'}>Shop Catalog</button>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {orders.map((order) => {
            const isExpanded = expandedOrderId === order._id;
            const orderDate = new Date(order.createdAt).toLocaleDateString('en-IN', {
              day: 'numeric',
              month: 'short',
              year: 'numeric'
            });

            return (
              <div 
                key={order._id} 
                style={{ 
                  backgroundColor: '#FFFFFF', 
                  border: '1px solid var(--border)', 
                  borderRadius: '16px', 
                  overflow: 'hidden',
                  boxShadow: 'var(--shadow)'
                }}
              >
                {/* Header Summary Row */}
                <div 
                  onClick={() => toggleOrderExpand(order._id)}
                  style={{ 
                    padding: '20px', 
                    display: 'flex', 
                    justifyContent: 'space-between', 
                    alignItems: 'center', 
                    cursor: 'pointer',
                    flexWrap: 'wrap',
                    gap: '12px'
                  }}
                >
                  <div>
                    <span style={{ fontSize: '12px', fontWeight: 600, color: 'var(--accent-gold)', display: 'block', marginBottom: '2px' }}>
                      {orderDate}
                    </span>
                    <h3 style={{ fontSize: '15px', fontWeight: 700, margin: 0, color: 'var(--text-h)' }}>
                      Order: {order.orderId}
                    </h3>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
                    <div style={{ textAlign: 'right' }}>
                      <span style={{ fontSize: '12px', color: 'var(--text-p)', display: 'block' }}>Total</span>
                      <span style={{ fontWeight: 800, color: 'var(--accent)', fontSize: '15px' }}>
                        {formatCurrency(order.totalAmount)}
                      </span>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span 
                        style={{ 
                          width: '8px', 
                          height: '8px', 
                          borderRadius: '50%', 
                          backgroundColor: getStatusColor(order.status)
                        }}
                      ></span>
                      <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--text-h)' }}>
                        {order.status}
                      </span>
                    </div>

                    <svg 
                      width="16" 
                      height="16" 
                      fill="none" 
                      stroke="currentColor" 
                      viewBox="0 0 24 24"
                      style={{ 
                        transform: isExpanded ? 'rotate(180deg)' : 'rotate(0deg)',
                        transition: 'transform 0.2s'
                      }}
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </div>
                </div>

                {/* Expanded Details Pane */}
                {isExpanded && (
                  <div style={{ padding: '20px', borderTop: '1px solid var(--border)', backgroundColor: '#FAFAFA' }} className="animate-fade-in">
                    <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', gap: '24px' }}>
                      {/* Left: Items list */}
                      <div>
                        <h4 style={{ fontSize: '13px', textTransform: 'uppercase', letterSpacing: '1px', fontWeight: 700, color: 'var(--text-p)', marginBottom: '12px' }}>
                          Items Ordered
                        </h4>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                          {order.items.map((item, idx) => (
                            <div 
                              key={idx} 
                              style={{ 
                                display: 'flex', 
                                gap: '12px', 
                                alignItems: 'center',
                                backgroundColor: '#FFFFFF',
                                padding: '12px',
                                borderRadius: '8px',
                                border: '1px solid var(--border)'
                              }}
                            >
                              <img 
                                src={formatImageUrl(item.image)} 
                                alt={item.name} 
                                style={{ width: '56px', height: '56px', objectFit: 'cover', borderRadius: '6px', border: '1px solid var(--border)' }} 
                              />
                              <div style={{ flex: 1 }}>
                                <h5 style={{ fontSize: '14px', fontWeight: 600, margin: '0 0 2px 0', color: 'var(--text-h)' }}>
                                  {item.name}
                                </h5>
                                {item.variation && (
                                  <span style={{ fontSize: '12px', color: 'var(--text-p)', display: 'block' }}>
                                    Option: {item.variation.title || item.variation.size}
                                  </span>
                                )}
                                <span style={{ fontSize: '13px', color: 'var(--text-p)' }}>
                                  {item.quantity} x {formatCurrency(item.price)}
                                </span>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>

                      {/* Right: Address & Tracking */}
                      <div>
                        {/* Shipping Address Summary */}
                        <div style={{ marginBottom: '20px' }}>
                          <h4 style={{ fontSize: '13px', textTransform: 'uppercase', letterSpacing: '1px', fontWeight: 700, color: 'var(--text-p)', marginBottom: '8px' }}>
                            Delivery Address
                          </h4>
                          <div style={{ fontSize: '13px', color: 'var(--text-h)', lineHeight: '1.5' }}>
                            <p style={{ margin: 0 }}>{order.shippingAddress.buildingName}</p>
                            <p style={{ margin: 0 }}>{order.shippingAddress.street}, {order.shippingAddress.area}</p>
                            {order.shippingAddress.landmark && <p style={{ margin: 0 }}>Landmark: {order.shippingAddress.landmark}</p>}
                            <p style={{ margin: 0 }}>{order.shippingAddress.city}, {order.shippingAddress.state} - {order.shippingAddress.zipCode}</p>
                          </div>
                        </div>

                        {/* Tracking Section */}
                        {order.awb ? (
                          <div style={{ borderTop: '1px solid var(--border)', paddingTop: '16px' }}>
                            <h4 style={{ fontSize: '13px', textTransform: 'uppercase', letterSpacing: '1px', fontWeight: 700, color: 'var(--text-p)', marginBottom: '8px' }}>
                              Tracking Details
                            </h4>
                            <span style={{ fontSize: '12px', display: 'block', color: 'var(--text-h)', marginBottom: '4px' }}>
                              AWB Code: <strong style={{ fontFamily: 'monospace' }}>{order.awb}</strong>
                            </span>
                            <span style={{ fontSize: '12px', display: 'block', color: 'var(--text-h)', marginBottom: '12px' }}>
                              Courier Partner: {order.courierPartner || 'Delhivery'}
                            </span>

                            {trackingAwb === order.awb && trackingLoading ? (
                              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: 'var(--text-p)' }}>
                                <div className="spinner" style={{ width: '16px', height: '16px', borderWidth: '2px' }}></div>
                                Fetching scan updates...
                              </div>
                            ) : trackingAwb === order.awb && trackingData ? (
                              <div style={{ maxHeight: '200px', overflowY: 'auto', backgroundColor: '#FFFFFF', padding: '12px', borderRadius: '8px', border: '1px solid var(--border)' }}>
                                {trackingData.ScanDetail && trackingData.ScanDetail.length > 0 ? (
                                  <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                                    {trackingData.ScanDetail.map((scan: any, sIdx: number) => (
                                      <div key={sIdx} style={{ fontSize: '12px', borderLeft: '2px solid var(--accent-gold)', paddingLeft: '8px', marginLeft: '4px' }}>
                                        <span style={{ fontWeight: 600, color: 'var(--text-h)', display: 'block' }}>{scan.ScanStatus}</span>
                                        <span style={{ color: 'var(--text-p)' }}>{scan.Instructions || scan.ScannedLocation}</span>
                                        <span style={{ fontSize: '10px', color: '#9CA3AF', display: 'block' }}>{new Date(scan.ScanDateTime).toLocaleString('en-IN')}</span>
                                      </div>
                                    ))}
                                  </div>
                                ) : (
                                  <span style={{ fontSize: '12px', color: 'var(--text-p)' }}>AWB registered. Shipment timeline will update soon.</span>
                                )}
                              </div>
                            ) : (
                              <button 
                                onClick={() => handleTrackOrder(order.awb!)}
                                style={{ 
                                  backgroundColor: 'transparent',
                                  border: '1px solid var(--accent-gold)',
                                  color: 'var(--accent-gold)',
                                  padding: '6px 12px',
                                  borderRadius: '6px',
                                  fontSize: '12px',
                                  fontWeight: 600,
                                  cursor: 'pointer'
                                }}
                              >
                                Track Package Realtime
                              </button>
                            )}
                          </div>
                        ) : (
                          <div style={{ borderTop: '1px solid var(--border)', paddingTop: '16px' }}>
                            <span style={{ fontSize: '12px', color: 'var(--text-p)' }}>
                              Tracking details are generated once your order package is picked up by courier service.
                            </span>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
