import React from 'react';
import { useCart } from '../../context/CartContext';
import { useAuth } from '../../context/AuthContext';
import './Navbar.css';

interface NavbarProps {
  resellerCode: string | null;
  onOpenCart: () => void;
  onOpenAuth: () => void;
  onResetCatalog: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  resellerCode,
  onOpenCart,
  onOpenAuth,
  onResetCatalog
}) => {
  const { cartItems } = useCart();
  const { user, logout } = useAuth();
  const [showDropdown, setShowDropdown] = React.useState<boolean>(false);

  const cartCount = cartItems.reduce((sum, item) => sum + item.quantity, 0);
  const dropdownRef = React.useRef<HTMLDivElement>(null);

  // Close dropdown when clicking outside
  React.useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setShowDropdown(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <header className="header-navigation">
      <div className="header-container">
        <div className="header-brand-logo" onClick={onResetCatalog} style={{ cursor: 'pointer' }}>
          <h1 style={{ fontSize: '18px', letterSpacing: '1.2px', fontWeight: 800 }}>MY COLLECTIONS</h1>
        </div>

        {resellerCode && (
          <div className="reseller-badge">
            <span className="dot-pulse"></span>
            <span className="badge-text">
              <span className="badge-prefix">Active: </span>{resellerCode}
            </span>
          </div>
        )}

        <div className="header-action-links">
          {/* Cart Icon */}
          <button className="cart-trigger-btn" onClick={onOpenCart}>
            <svg width="22" height="22" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
            </svg>
            {cartCount > 0 && <span className="cart-badge-count">{cartCount}</span>}
          </button>

          {/* User Account / Auth trigger */}
          {user ? (
            <div className="user-profile-menu-container" ref={dropdownRef}>
              <button 
                className="user-avatar-trigger" 
                onClick={() => setShowDropdown(!showDropdown)}
                aria-label="Toggle user menu"
              >
                <span className="user-initials">{user.name.charAt(0).toUpperCase()}</span>
              </button>

              {showDropdown && (
                <div className="user-profile-dropdown animate-scale-up">
                  <div className="dropdown-user-info">
                    <span className="dropdown-user-name">{user.name}</span>
                    <span className="dropdown-user-email">{user.email || 'Partner Account'}</span>
                  </div>
                  <div className="dropdown-divider"></div>
                  <button 
                    className="dropdown-item-btn" 
                    onClick={() => { setShowDropdown(false); window.location.href = '/profile'; }}
                  >
                    My Profile
                  </button>
                  <button 
                    className="dropdown-item-btn" 
                    onClick={() => { setShowDropdown(false); window.location.href = '/orders'; }}
                  >
                    My Orders
                  </button>
                  <div className="dropdown-divider"></div>
                  <button 
                    className="dropdown-item-btn logout-btn-item" 
                    onClick={() => { setShowDropdown(false); logout(); }}
                  >
                    Log Out
                  </button>
                </div>
              )}
            </div>
          ) : (
            <button className="login-trigger-btn" onClick={onOpenAuth}>
              Log In
            </button>
          )}
        </div>
      </div>
    </header>
  );
};
