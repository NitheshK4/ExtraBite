import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { MapPin, CheckCircle2, ChevronRight } from 'lucide-react';

export default function CustomerRegistration({ onComplete }) {
  const { setCustomerLocation, setCustomerDietaryPref, setCustomerPricePref } = useApp();

  const [step, setStep] = useState(1); // 1: Personal Details, 2: Location & Preferences
  const [formData, setFormData] = useState({
    fullName: 'Rahul Sharma',
    mobile: '9876512345',
    email: 'rahul.sharma@example.com',
    password: 'password123',
    confirmPassword: 'password123',
  });

  const [locationMode, setLocationMode] = useState('gps'); // 'gps' | 'manual'
  const [manualAddress, setManualAddress] = useState('Koramangala, Bengaluru');
  const [dietary, setDietary] = useState('both');
  const [price, setPrice] = useState('any');
  const [locGranted, setLocGranted] = useState(false);

  const handleAllowLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          setCustomerLocation({
            name: 'Current Location (GPS)',
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
          });
          setLocGranted(true);
        },
        () => {
          // Fallback location if permission denied
          setCustomerLocation({
            name: 'Indiranagar, Bengaluru (Default)',
            lat: 12.9784,
            lng: 77.6408,
          });
          setLocGranted(true);
        }
      );
    } else {
      setCustomerLocation({
        name: 'Indiranagar, Bengaluru (Default)',
        lat: 12.9784,
        lng: 77.6408,
      });
      setLocGranted(true);
    }
  };

  const handleFormSubmit = (e) => {
    e.preventDefault();
    setCustomerDietaryPref(dietary);
    setCustomerPricePref(price);

    if (locationMode === 'manual' && manualAddress) {
      setCustomerLocation({
        name: manualAddress,
        lat: 12.9720, // Simulated Koramangala / manual coordinates
        lng: 77.6300,
      });
    }

    onComplete();
  };

  return (
    <div style={{ padding: '16px' }}>
      <div style={{ marginBottom: '24px' }}>
        <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.5rem', fontWeight: '800' }}>
          Customer Registration
        </h2>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
          Create an account to reserve affordable surplus meals near you.
        </p>
      </div>

      {step === 1 ? (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            setStep(2);
          }}
        >
          <div className="form-group">
            <label className="form-label">Full Name</label>
            <input
              type="text"
              className="form-input"
              required
              value={formData.fullName}
              onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label className="form-label">Mobile Number</label>
            <input
              type="tel"
              className="form-input"
              required
              value={formData.mobile}
              onChange={(e) => setFormData({ ...formData, mobile: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label className="form-label">Email Address</label>
            <input
              type="email"
              className="form-input"
              required
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label className="form-label">Password</label>
            <input
              type="password"
              className="form-input"
              required
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label className="form-label">Confirm Password</label>
            <input
              type="password"
              className="form-input"
              required
              value={formData.confirmPassword}
              onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
            />
          </div>

          <button type="submit" className="btn-primary" style={{ marginTop: '20px' }}>
            Next: Location & Preferences <ChevronRight size={18} />
          </button>
        </form>
      ) : (
        <form onSubmit={handleFormSubmit}>
          {/* Location Permission Box */}
          <div className="radius-filter-container">
            <div style={{ fontWeight: '700', fontSize: '0.95rem', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <MapPin size={18} color="#10b981" /> Allow ExtraBite to find food near you?
            </div>

            <div style={{ display: 'flex', gap: '10px', marginTop: '12px' }}>
              <button
                type="button"
                className={`btn-secondary ${locationMode === 'gps' ? 'active' : ''}`}
                style={{ flex: 1, border: locationMode === 'gps' ? '2px solid var(--primary)' : '1px solid var(--border)' }}
                onClick={() => {
                  setLocationMode('gps');
                  handleAllowLocation();
                }}
              >
                📍 {locGranted ? 'Location Allowed ✓' : 'Allow Location'}
              </button>

              <button
                type="button"
                className={`btn-secondary ${locationMode === 'manual' ? 'active' : ''}`}
                style={{ flex: 1, border: locationMode === 'manual' ? '2px solid var(--primary)' : '1px solid var(--border)' }}
                onClick={() => setLocationMode('manual')}
              >
                🗺️ Enter Manually
              </button>
            </div>

            {locationMode === 'manual' && (
              <div style={{ marginTop: '12px' }}>
                <input
                  type="text"
                  className="form-input"
                  placeholder="Enter neighborhood or address"
                  value={manualAddress}
                  onChange={(e) => setManualAddress(e.target.value)}
                />
              </div>
            )}
          </div>

          {/* Food Preference */}
          <div className="form-group">
            <label className="form-label">Food Preference</label>
            <select
              className="form-select"
              value={dietary}
              onChange={(e) => setDietary(e.target.value)}
            >
              <option value="vegetarian">Vegetarian Only</option>
              <option value="non_vegetarian">Non-Vegetarian Only</option>
              <option value="both">Both (Vegetarian & Non-Veg)</option>
            </select>
          </div>

          {/* Price Preference */}
          <div className="form-group">
            <label className="form-label">Price Preference</label>
            <select
              className="form-select"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
            >
              <option value="under_30">Under ₹30</option>
              <option value="30_50">₹30 – ₹50</option>
              <option value="50_100">₹50 – ₹100</option>
              <option value="any">Any Price</option>
            </select>
          </div>

          <div style={{ display: 'flex', gap: '10px', marginTop: '24px' }}>
            <button type="button" className="btn-secondary" onClick={() => setStep(1)} style={{ flex: 1 }}>
              Back
            </button>
            <button type="submit" className="btn-primary" style={{ flex: 2 }}>
              Start Finding Food 🍱
            </button>
          </div>
        </form>
      )}
    </div>
  );
}
