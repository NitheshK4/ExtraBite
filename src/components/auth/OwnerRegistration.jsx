import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { Home, Clock, Upload, CheckCircle2, AlertTriangle } from 'lucide-react';

export default function OwnerRegistration({ onComplete }) {
  const { registerOwner, setCurrentRole } = useApp();

  const [submitted, setSubmitted] = useState(false);
  const [formData, setFormData] = useState({
    fullName: 'Ramesh Kumar',
    mobile: '9876543210',
    email: 'ramesh.srisai@example.com',
    whatsapp: '9876543210',
    propertyName: 'Sri Sai PG',
    type: 'pg',
    address: '#12, 10th Main, Indiranagar',
    city: 'Bengaluru',
    state: 'Karnataka',
    pincode: '560038',
    residentCount: '45',
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    registerOwner(
      { fullName: formData.fullName, mobile: formData.mobile, email: formData.email, whatsapp: formData.whatsapp },
      {
        name: formData.propertyName,
        type: formData.type,
        address: formData.address,
        city: formData.city,
        state: formData.state,
        pincode: formData.pincode,
        residentCount: formData.residentCount,
      }
    );
    setSubmitted(true);
  };

  if (submitted) {
    return (
      <div style={{ padding: '24px', textAlign: 'center' }}>
        <div style={{ fontSize: '3.5rem', marginBottom: '16px' }}>⏳</div>
        <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.6rem', fontWeight: '800', marginBottom: '8px' }}>
          Registration Submitted Successfully
        </h2>
        <div className="status-pill pending" style={{ padding: '8px 16px', fontSize: '0.9rem', marginBottom: '20px' }}>
          <Clock size={16} /> Verification Pending
        </div>
        
        <div style={{ background: '#f8fafc', padding: '16px', borderRadius: '14px', border: '1px solid var(--border)', textAlign: 'left', marginBottom: '24px', fontSize: '0.88rem' }}>
          <p style={{ fontWeight: '700', color: 'var(--text-main)', marginBottom: '6px' }}>
            What happens next?
          </p>
          <ul style={{ paddingLeft: '20px', color: 'var(--text-muted)', lineHeight: '1.6' }}>
            <li>Our Admin team is inspecting your ID and property verification documents.</li>
            <li>Once approved, your property will be activated and you can start listing surplus food.</li>
            <li>You can test the Admin approval flow directly in this demo using the role switcher above.</li>
          </ul>
        </div>

        <button
          className="btn-primary"
          onClick={() => {
            setCurrentRole('owner');
            if (onComplete) onComplete();
          }}
        >
          Go to Owner Dashboard
        </button>
      </div>
    );
  }

  return (
    <div style={{ padding: '16px' }}>
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.5rem', fontWeight: '800' }}>
          PG / Hostel Registration
        </h2>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
          List your surplus food and reach nearby customers instantly.
        </p>
      </div>

      <form onSubmit={handleSubmit}>
        <div style={{ fontWeight: '700', fontSize: '0.95rem', color: 'var(--primary-dark)', marginBottom: '12px', borderBottom: '1px solid var(--border)', paddingBottom: '6px' }}>
          1. Owner Personal Information
        </div>

        <div className="form-group">
          <label className="form-label">Owner Full Name</label>
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
          <label className="form-label">WhatsApp Number</label>
          <input
            type="tel"
            className="form-input"
            required
            value={formData.whatsapp}
            onChange={(e) => setFormData({ ...formData, whatsapp: e.target.value })}
          />
        </div>

        <div style={{ fontWeight: '700', fontSize: '0.95rem', color: 'var(--primary-dark)', margin: '20px 0 12px 0', borderBottom: '1px solid var(--border)', paddingBottom: '6px' }}>
          2. PG / Hostel / Mess Details
        </div>

        <div className="form-group">
          <label className="form-label">Property Name</label>
          <input
            type="text"
            className="form-input"
            required
            value={formData.propertyName}
            onChange={(e) => setFormData({ ...formData, propertyName: e.target.value })}
          />
        </div>

        <div className="form-group">
          <label className="form-label">Property Type</label>
          <select
            className="form-select"
            value={formData.type}
            onChange={(e) => setFormData({ ...formData, type: e.target.value })}
          >
            <option value="pg">Paying Guest (PG)</option>
            <option value="hostel">Hostel</option>
            <option value="mess">Mess / Food Hall</option>
          </select>
        </div>

        <div className="form-group">
          <label className="form-label">Full Street Address</label>
          <input
            type="text"
            className="form-input"
            required
            value={formData.address}
            onChange={(e) => setFormData({ ...formData, address: e.target.value })}
          />
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
          <div className="form-group">
            <label className="form-label">City</label>
            <input
              type="text"
              className="form-input"
              required
              value={formData.city}
              onChange={(e) => setFormData({ ...formData, city: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label className="form-label">Pincode</label>
            <input
              type="text"
              className="form-input"
              required
              value={formData.pincode}
              onChange={(e) => setFormData({ ...formData, pincode: e.target.value })}
            />
          </div>
        </div>

        <div className="form-group">
          <label className="form-label">Number of Residents</label>
          <input
            type="number"
            className="form-input"
            required
            value={formData.residentCount}
            onChange={(e) => setFormData({ ...formData, residentCount: e.target.value })}
          />
        </div>

        <div style={{ fontWeight: '700', fontSize: '0.95rem', color: 'var(--primary-dark)', margin: '20px 0 12px 0', borderBottom: '1px solid var(--border)', paddingBottom: '6px' }}>
          3. Verification Uploads (Demo Simulation)
        </div>

        <div style={{ background: '#f8fafc', border: '1px dashed var(--border)', padding: '12px', borderRadius: '12px', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Upload size={20} color="#10b981" />
          <div style={{ fontSize: '0.8rem' }}>
            <strong>Government ID Proof</strong> (Aadhaar / PAN)
            <div style={{ color: 'var(--text-muted)' }}>Attached: ID_CARD_RAMESH.pdf ✓</div>
          </div>
        </div>

        <div style={{ background: '#f8fafc', border: '1px dashed var(--border)', padding: '12px', borderRadius: '12px', marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Upload size={20} color="#10b981" />
          <div style={{ fontSize: '0.8rem' }}>
            <strong>PG Registration / Electricity Bill</strong>
            <div style={{ color: 'var(--text-muted)' }}>Attached: PG_PROOF_DOCUMENT.pdf ✓</div>
          </div>
        </div>

        <button type="submit" className="btn-primary">
          Register PG & Submit Verification 🏠
        </button>
      </form>
    </div>
  );
}
