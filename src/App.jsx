import React, { useState } from 'react';
import { useApp } from './context/AppContext';
import Navbar from './components/common/Navbar';
import BottomNav from './components/common/BottomNav';
import WelcomeScreen from './components/auth/WelcomeScreen';
import CustomerRegistration from './components/auth/CustomerRegistration';
import OwnerRegistration from './components/auth/OwnerRegistration';
import CustomerHome from './components/customer/CustomerHome';
import OwnerDashboard from './components/owner/OwnerDashboard';
import AdminDashboard from './components/admin/AdminDashboard';
import { MapPin, X } from 'lucide-react';

export default function App() {
  const { currentRole, setCurrentRole, customerLocation, setCustomerLocation } = useApp();
  const [authStep, setAuthStep] = useState('welcome'); // 'welcome' | 'register_customer' | 'register_owner'
  const [showLocationModal, setShowLocationModal] = useState(false);
  const [manualAddressInput, setManualAddressInput] = useState('');

  const handleSelectCustomer = () => {
    setAuthStep('register_customer');
  };

  const handleSelectOwner = () => {
    setAuthStep('register_owner');
  };

  const handleUpdateLocation = (name, lat, lng) => {
    setCustomerLocation({ name, lat, lng });
    setShowLocationModal(false);
  };

  return (
    <div className="app-viewport">
      {/* Top Navbar */}
      <Navbar onOpenLocationModal={() => setShowLocationModal(true)} />

      {/* Main View Router based on role and auth step */}
      {currentRole === 'welcome' && (
        <>
          {authStep === 'welcome' && (
            <WelcomeScreen
              onSelectCustomer={handleSelectCustomer}
              onSelectOwner={handleSelectOwner}
            />
          )}

          {authStep === 'register_customer' && (
            <CustomerRegistration
              onComplete={() => {
                setCurrentRole('customer');
              }}
            />
          )}

          {authStep === 'register_owner' && (
            <OwnerRegistration
              onComplete={() => {
                setCurrentRole('owner');
              }}
            />
          )}
        </>
      )}

      {currentRole === 'customer' && <CustomerHome />}

      {currentRole === 'owner' && <OwnerDashboard />}

      {currentRole === 'admin' && <AdminDashboard />}

      {/* Bottom Navigation */}
      {(currentRole === 'customer' || currentRole === 'owner') && <BottomNav />}

      {/* Manual Location Selector Modal */}
      {showLocationModal && (
        <div className="modal-overlay" onClick={() => setShowLocationModal(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <button
              onClick={() => setShowLocationModal(false)}
              style={{
                position: 'absolute',
                top: '16px',
                right: '16px',
                background: 'white',
                border: 'none',
                borderRadius: '50%',
                width: '32px',
                height: '32px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer'
              }}
            >
              <X size={18} />
            </button>

            <h3 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.3rem', fontWeight: '800', marginBottom: '8px' }}>
              Change Search Location
            </h3>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginBottom: '16px' }}>
              Set your current address to calculate nearby 2 km food distance.
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              <button
                className="btn-secondary"
                onClick={() => handleUpdateLocation('Indiranagar, Bengaluru', 12.9784, 77.6408)}
              >
                📍 Indiranagar (0.5 km to Sri Sai PG)
              </button>

              <button
                className="btn-secondary"
                onClick={() => handleUpdateLocation('Domlur, Bengaluru', 12.9690, 77.6460)}
              >
                📍 Domlur (Close to Lakshmi Hostel)
              </button>

              <button
                className="btn-secondary"
                onClick={() => handleUpdateLocation('Koramangala, Bengaluru', 12.9352, 77.6245)}
              >
                📍 Koramangala (Simulated Location)
              </button>
            </div>

            <div style={{ margin: '16px 0 8px 0', fontSize: '0.8rem', fontWeight: '700', color: 'var(--text-muted)' }}>
              Or Enter Custom Address:
            </div>

            <div style={{ display: 'flex', gap: '8px' }}>
              <input
                type="text"
                className="form-input"
                placeholder="e.g. MG Road, Bengaluru"
                value={manualAddressInput}
                onChange={(e) => setManualAddressInput(e.target.value)}
              />
              <button
                className="btn-primary"
                style={{ width: 'auto', padding: '0 16px' }}
                onClick={() => {
                  if (manualAddressInput.trim()) {
                    handleUpdateLocation(manualAddressInput, 12.9750, 77.6400);
                  }
                }}
              >
                Set
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
