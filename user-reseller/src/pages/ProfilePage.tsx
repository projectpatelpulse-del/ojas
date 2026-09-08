import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { toast } from 'sonner';

export const ProfilePage: React.FC = () => {
  const { user, addresses, addAddress, deleteAddress } = useAuth();
  
  const [showAddForm, setShowAddForm] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false);

  // Address form state
  const [newName, setNewName] = useState<string>('');
  const [newMobile, setNewMobile] = useState<string>('');
  const [newBuilding, setNewBuilding] = useState<string>('');
  const [newStreet, setNewStreet] = useState<string>('');
  const [newArea, setNewArea] = useState<string>('');
  const [newLandmark, setNewLandmark] = useState<string>('');
  const [newCity, setNewCity] = useState<string>('');
  const [newState, setNewState] = useState<string>('');
  const [newZipCode, setNewZipCode] = useState<string>('');

  const handleAddAddress = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName || !newMobile || !newBuilding || !newStreet || !newArea || !newCity || !newState || !newZipCode) {
      toast.error('Please fill in all required fields');
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
      toast.success('Address added to your profile!');
      setShowAddForm(false);
      
      // Reset form fields
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

  const handleDeleteAddress = async (addressId: string) => {
    if (window.confirm('Are you sure you want to delete this address?')) {
      try {
        await deleteAddress(addressId);
        toast.success('Address deleted successfully');
      } catch (err: any) {
        toast.error('Failed to delete address');
      }
    }
  };

  if (!user) {
    return (
      <div className="empty-catalog-state" style={{ minHeight: '60vh' }}>
        <div className="empty-card animate-scale-up">
          <h2>Access Denied</h2>
          <p>Please log in to view and manage your profile details and saved shipping addresses.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="profile-dashboard-container animate-fade-in" style={{ padding: '24px', maxWidth: '1000px', margin: '0 auto', minHeight: '60vh' }}>
      <div style={{ display: 'grid', gridTemplateColumns: '320px 1fr', gap: '32px' }} className="profile-grid-layout">
        
        {/* Left Side: Profile Card */}
        <div>
          <div style={{ 
            backgroundColor: '#FFFFFF', 
            border: '1px solid var(--border)', 
            borderRadius: '16px', 
            padding: '24px',
            boxShadow: 'var(--shadow)',
            textAlign: 'center'
          }}>
            <div style={{
              width: '80px',
              height: '80px',
              borderRadius: '50%',
              backgroundColor: 'var(--accent-gold)',
              color: '#FFFFFF',
              fontSize: '32px',
              fontWeight: 800,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 16px auto'
            }}>
              {user.name.charAt(0).toUpperCase()}
            </div>
            
            <h3 style={{ fontSize: '18px', fontWeight: 800, color: 'var(--text-h)', margin: '0 0 4px 0' }}>{user.name}</h3>
            <span style={{ fontSize: '14px', color: 'var(--text-p)' }}>{user.mobile}</span>
            
            <div style={{ borderTop: '1px solid var(--border)', marginTop: '20px', paddingTop: '16px', fontSize: '12px', color: 'var(--text-p)', textAlign: 'left' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span>Account Type</span>
                <span style={{ fontWeight: 600, color: 'var(--text-h)' }}>Customer</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>Joined</span>
                <span style={{ fontWeight: 600, color: 'var(--text-h)' }}>Active Member</span>
              </div>
            </div>
          </div>
          
          <button 
            onClick={() => window.location.href = '/orders'}
            style={{
              width: '100%',
              backgroundColor: 'transparent',
              border: '2px solid var(--accent)',
              color: 'var(--accent)',
              padding: '12px',
              borderRadius: '12px',
              fontWeight: 700,
              cursor: 'pointer',
              marginTop: '16px',
              fontSize: '14px',
              transition: 'opacity 0.2s'
            }}
          >
            View Order History
          </button>
        </div>

        {/* Right Side: Saved Addresses */}
        <div>
          <div style={{ 
            backgroundColor: '#FFFFFF', 
            border: '1px solid var(--border)', 
            borderRadius: '16px', 
            padding: '24px',
            boxShadow: 'var(--shadow)'
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h3 style={{ fontSize: '18px', fontWeight: 800, color: 'var(--text-h)', margin: 0 }}>Saved Delivery Addresses</h3>
              {!showAddForm && (
                <button 
                  onClick={() => setShowAddForm(true)}
                  style={{
                    backgroundColor: 'var(--accent-gold)',
                    color: '#FFFFFF',
                    border: 'none',
                    padding: '8px 16px',
                    borderRadius: '8px',
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: 'pointer'
                  }}
                >
                  + Add New
                </button>
              )}
            </div>

            {showAddForm ? (
              <form onSubmit={handleAddAddress} className="new-address-form animate-fade-in">
                <h4 style={{ fontSize: '14px', fontWeight: 700, color: 'var(--text-h)', marginBottom: '16px' }}>Add Shipping Address</h4>
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
                  <div className="form-group">
                    <label>State *</label>
                    <input type="text" value={newState} onChange={e => setNewState(e.target.value)} required />
                  </div>
                  <div className="form-group">
                    <label>Pincode *</label>
                    <input type="text" value={newZipCode} onChange={e => setNewZipCode(e.target.value)} required />
                  </div>
                </div>

                <div className="form-actions" style={{ marginTop: '20px' }}>
                  <button type="button" className="cancel-btn" onClick={() => setShowAddForm(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="save-address-btn" disabled={loading}>
                    {loading ? 'Saving...' : 'Save Address'}
                  </button>
                </div>
              </form>
            ) : (
              <div className="addresses-list" style={{ marginTop: 0 }}>
                {addresses.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: '32px 0', color: 'var(--text-p)' }}>
                    <p style={{ margin: 0, fontSize: '14px' }}>No saved addresses found. Please add a new delivery address.</p>
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    {addresses.map((addr, idx) => (
                      <div 
                        key={addr._id || idx} 
                        style={{ 
                          border: '1px solid var(--border)', 
                          padding: '16px', 
                          borderRadius: '12px', 
                          display: 'flex',
                          justifyContent: 'space-between',
                          alignItems: 'flex-start',
                          backgroundColor: '#FAFAFA'
                        }}
                      >
                        <div style={{ flex: 1 }}>
                          <span style={{ fontWeight: 700, fontSize: '14px', color: 'var(--text-h)', display: 'block', marginBottom: '4px' }}>
                            {addr.name} ({addr.mobile})
                          </span>
                          <p style={{ margin: 0, fontSize: '13px', color: 'var(--text-p)', lineHeight: '1.5' }}>
                            {addr.buildingName}, {addr.street}, {addr.area}
                            {addr.landmark ? `, Landmark: ${addr.landmark}` : ''}
                            <br />
                            {addr.city}, {addr.state} - {addr.zipCode}
                          </p>
                        </div>
                        <button 
                          onClick={() => handleDeleteAddress(addr._id!)}
                          style={{
                            background: 'none',
                            border: 'none',
                            color: '#EF4444',
                            cursor: 'pointer',
                            fontSize: '13px',
                            fontWeight: 700,
                            padding: '4px 8px'
                          }}
                        >
                          Delete
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
};
