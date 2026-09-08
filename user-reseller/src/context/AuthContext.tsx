import React, { createContext, useContext, useState, useEffect } from 'react';
import type { User, Address } from '../core/types';
import { requestApi } from '../core/services/api';

interface AuthContextType {
  user: User | null;
  token: string | null;
  addresses: Address[];
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (name: string, email: string, password: string, mobile: string) => Promise<void>;
  logout: () => void;
  addAddress: (address: Omit<Address, '_id'>) => Promise<void>;
  deleteAddress: (addressId: string) => Promise<void>;
  fetchAddresses: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [addresses, setAddresses] = useState<Address[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  // Load user session on startup
  useEffect(() => {
    const storedToken = localStorage.getItem('ojas_user_token');
    const storedUser = localStorage.getItem('ojas_user_profile');

    if (storedToken && storedUser) {
      setToken(storedToken);
      setUser(JSON.parse(storedUser));
    }
    setLoading(false);
  }, []);

  // Fetch addresses when logged in
  useEffect(() => {
    if (token) {
      fetchAddresses();
    } else {
      setAddresses([]);
    }
  }, [token]);

  const login = async (email: string, password: string) => {
    const data = await requestApi('/user/login', {
      method: 'POST',
      body: JSON.stringify({ email, password })
    });

    if (data && data.token) {
      localStorage.setItem('ojas_user_token', data.token);
      localStorage.setItem('ojas_user_profile', JSON.stringify(data.data));
      setToken(data.token);
      setUser(data.data);
    }
  };

  const register = async (name: string, email: string, password: string, mobile: string) => {
    await requestApi('/user/register', {
      method: 'POST',
      body: JSON.stringify({ name, email, password, mobile })
    });
    // Auto-login after successful registration
    await login(email, password);
  };

  const logout = () => {
    localStorage.removeItem('ojas_user_token');
    localStorage.removeItem('ojas_user_profile');
    setToken(null);
    setUser(null);
    setAddresses([]);
  };

  const fetchAddresses = async () => {
    try {
      const responseData = await requestApi('/user/addresses');
      const list = responseData.data || (Array.isArray(responseData) ? responseData : []);
      setAddresses(list);
    } catch (err) {
      console.error('Failed to fetch addresses:', err);
    }
  };

  const addAddress = async (address: Omit<Address, '_id'>) => {
    const response = await requestApi('/user/address/add', {
      method: 'POST',
      body: JSON.stringify(address)
    });
    if (response && response.data) {
      setAddresses(response.data);
    } else {
      await fetchAddresses();
    }
  };

  const deleteAddress = async (addressId: string) => {
    const response = await requestApi(`/user/address/delete/${addressId}`, {
      method: 'DELETE'
    });
    if (response && response.data) {
      setAddresses(response.data);
    } else {
      await fetchAddresses();
    }
  };

  return (
    <AuthContext.Provider value={{
      user,
      token,
      addresses,
      loading,
      login,
      register,
      logout,
      addAddress,
      deleteAddress,
      fetchAddresses
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within an AuthProvider');
  return context;
};
