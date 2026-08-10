import React from 'react';
import { useApp } from '../../context/AppContext';
import { MapPin, User, ShieldCheck, Home, Utensils } from 'lucide-react';

export default function Navbar({ onOpenLocationModal }) {
  const { currentRole, setCurrentRole, customerLocation, activePropertyId, properties } = useApp();

  const activeOwnerProperty = properties.find((p) => p.id === activePropertyId);

  return (
    <>
      {/* Demo Switcher Quick Bar */}
      <div className="demo-role-banner">
        <span>⚡ Demo Mode</span>
        <div className="role-pills">
          <button
            className={`role-pill ${currentRole === 'customer' ? 'active' : ''}`}
            onClick={() => setCurrentRole('customer')}
          >
            👤 Customer
          </button>
          <button
            className={`role-pill ${currentRole === 'owner' ? 'active' : ''}`}
            onClick={() => setCurrentRole('owner')}
          >
            🏠 Owner
          </button>
          <button
            className={`role-pill admin ${currentRole === 'admin' ? 'active' : ''}`}
            onClick={() => setCurrentRole('admin')}
          >
            🛡️ Admin
          </button>
        </div>
      </div>

      {/* Main Header */}
      <header className="main-header">
        <div className="brand-title" onClick={() => setCurrentRole('welcome')} style={{ cursor: 'pointer' }}>
          <span>🍱</span> ExtraBite
        </div>

        {currentRole === 'customer' && (
          <div className="location-chip" onClick={onOpenLocationModal} title="Change search location">
            <MapPin size={14} color="#10b981" />
            <span>{customerLocation.name}</span>
          </div>
        )}

        {currentRole === 'owner' && activeOwnerProperty && (
          <div className="location-chip" style={{ background: '#e0f2fe', color: '#0369a1', borderColor: '#bae6fd' }}>
            <Home size={14} />
            <span>{activeOwnerProperty.name}</span>
          </div>
        )}

        {currentRole === 'admin' && (
          <div className="location-chip" style={{ background: '#f3e8ff', color: '#6b21a8', borderColor: '#e9d5ff' }}>
            <ShieldCheck size={14} />
            <span>Admin Portal</span>
          </div>
        )}
      </header>
    </>
  );
}
