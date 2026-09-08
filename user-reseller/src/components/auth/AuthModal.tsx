import React, { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { toast } from 'sonner';
import './AuthModal.css';

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const AuthModal: React.FC<AuthModalProps> = ({ isOpen, onClose }) => {
  const { login, register } = useAuth();
  const [isRegisterMode, setIsRegisterMode] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false);

  // Form Fields
  const [name, setName] = useState<string>('');
  const [email, setEmail] = useState<string>('');
  const [password, setPassword] = useState<string>('');
  const [mobile, setMobile] = useState<string>('');

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (isRegisterMode) {
        if (!name || !email || !password || !mobile) {
          toast.error('Please fill in all fields');
          setLoading(false);
          return;
        }
        await register(name, email, password, mobile);
        toast.success('Registration successful! Welcome to our boutique!');
      } else {
        if (!email || !password) {
          toast.error('Please enter email and password');
          setLoading(false);
          return;
        }
        await login(email, password);
        toast.success('Successfully logged in!');
      }
      onClose();
    } catch (err: any) {
      toast.error(err.message || 'Authentication failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-overlay active">
      <div className="auth-modal animate-scale-up">
        <button className="auth-close-btn" onClick={onClose}>&times;</button>
        
        <div className="auth-header">
          <h3>{isRegisterMode ? 'Create an Account' : 'Welcome Back'}</h3>
          <p>{isRegisterMode ? 'Register to place and track your orders' : 'Log in to checkout your shopping cart'}</p>
        </div>

        <form onSubmit={handleSubmit} className="auth-form">
          {isRegisterMode && (
            <div className="form-group">
              <label>Full Name</label>
              <input 
                type="text" 
                placeholder="e.g. Aman Kumar" 
                value={name} 
                onChange={e => setName(e.target.value)} 
                required 
              />
            </div>
          )}

          <div className="form-group">
            <label>Email Address</label>
            <input 
              type="email" 
              placeholder="e.g. customer@example.com" 
              value={email} 
              onChange={e => setEmail(e.target.value)} 
              required 
            />
          </div>

          {isRegisterMode && (
            <div className="form-group">
              <label>Mobile Number</label>
              <input 
                type="tel" 
                placeholder="e.g. 9876543210" 
                value={mobile} 
                onChange={e => setMobile(e.target.value)} 
                required 
              />
            </div>
          )}

          <div className="form-group">
            <label>Password</label>
            <input 
              type="password" 
              placeholder="Enter your password" 
              value={password} 
              onChange={e => setPassword(e.target.value)} 
              required 
            />
          </div>

          <button type="submit" className="auth-submit-btn" disabled={loading}>
            {loading ? 'Processing...' : (isRegisterMode ? 'Sign Up' : 'Log In')}
          </button>
        </form>

        <div className="auth-toggle">
          <span>
            {isRegisterMode ? 'Already have an account? ' : "Don't have an account? "}
          </span>
          <button onClick={() => setIsRegisterMode(!isRegisterMode)}>
            {isRegisterMode ? 'Log In' : 'Sign Up'}
          </button>
        </div>
      </div>
    </div>
  );
};
