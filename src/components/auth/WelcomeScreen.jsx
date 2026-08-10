import React from 'react';
import { useApp } from '../../context/AppContext';
import { Utensils, Home, User, ShieldCheck } from 'lucide-react';

export default function WelcomeScreen({ onSelectCustomer, onSelectOwner }) {
  const { setCurrentRole } = useApp();

  return (
    <div className="welcome-card">
      <div className="welcome-logo">🍱</div>
      <span className="tagline-badge">Good food shouldn’t go to waste.</span>
      
      <h1 className="welcome-title">Welcome to ExtraBite</h1>
      <p className="welcome-subtitle">
        Reserve delicious, fresh surplus meals from top nearby PGs & hostels at affordable prices.
      </p>

      <div style={{ margin: '16px 0 8px 0', fontWeight: '700', fontSize: '0.9rem', color: '#475569' }}>
        How do you want to use ExtraBite?
      </div>

      <div className="role-selection-grid">
        <button
          className="role-select-btn"
          onClick={() => {
            onSelectCustomer();
            setCurrentRole('customer');
          }}
        >
          <div className="role-icon-box">
            <User size={26} />
          </div>
          <div>
            <div className="role-btn-title">👤 Customer</div>
            <div className="role-btn-desc">Find affordable food near you</div>
          </div>
        </button>

        <button
          className="role-select-btn owner"
          onClick={() => {
            onSelectOwner();
            setCurrentRole('owner');
          }}
        >
          <div className="role-icon-box">
            <Home size={26} />
          </div>
          <div>
            <div className="role-btn-title">🏠 PG / Hostel Owner</div>
            <div className="role-btn-desc">List your extra food & earn extra</div>
          </div>
        </button>
      </div>

      <div style={{ marginTop: '28px', fontSize: '0.85rem', color: '#64748b' }}>
        Admin access?{' '}
        <span
          style={{ color: '#8b5cf6', fontWeight: '700', cursor: 'pointer', textDecoration: 'underline' }}
          onClick={() => setCurrentRole('admin')}
        >
          Open Admin Panel
        </span>
      </div>
    </div>
  );
}
