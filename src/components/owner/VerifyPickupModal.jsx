import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { QrCode, Search, CheckCircle2, AlertCircle, X, DollarSign } from 'lucide-react';

export default function VerifyPickupModal({ onClose }) {
  const { confirmPickupByCode, reservations } = useApp();

  const [inputCode, setInputCode] = useState('');
  const [foundReservation, setFoundReservation] = useState(null);
  const [errorMsg, setErrorMsg] = useState('');
  const [confirmed, setConfirmed] = useState(false);

  const handleSearchCode = (e) => {
    e.preventDefault();
    setErrorMsg('');
    setFoundReservation(null);

    const code = inputCode.trim().toUpperCase();
    if (!code) return;

    const res = reservations.find(
      (r) =>
        (r.pickup_code.toUpperCase() === code || r.order_code.toUpperCase() === code || r.qr_token.toUpperCase() === code) &&
        r.status === 'reserved'
    );

    if (!res) {
      setErrorMsg('No active reservation found with this code. Please check code or QR.');
    } else {
      setFoundReservation(res);
    }
  };

  const handleConfirmPickup = () => {
    if (!foundReservation) return;
    const result = confirmPickupByCode(foundReservation.pickup_code);
    if (result.success) {
      setConfirmed(true);
      setTimeout(() => {
        if (onClose) onClose();
      }, 1800);
    } else {
      setErrorMsg(result.message);
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <button
          onClick={onClose}
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

        <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.4rem', fontWeight: '800', marginBottom: '4px' }}>
          Verify Customer Pickup 📦
        </h2>
        <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginBottom: '16px' }}>
          Scan customer QR code or enter pickup code to collect payment and release food.
        </p>

        {confirmed ? (
          <div style={{ padding: '30px 10px', textAlign: 'center' }}>
            <div style={{ fontSize: '3.5rem', marginBottom: '8px' }}>🎉</div>
            <h3 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.4rem', fontWeight: '800', color: 'var(--primary-dark)' }}>
              Pickup Confirmed!
            </h3>
            <p style={{ fontSize: '0.88rem', color: 'var(--text-muted)' }}>
              Status updated to <strong>🟢 Picked Up</strong>. Thank you for reducing food waste!
            </p>
          </div>
        ) : (
          <>
            <form onSubmit={handleSearchCode} style={{ marginBottom: '16px' }}>
              <div className="form-group">
                <label className="form-label">Enter Pickup Code or Scan QR</label>
                <div style={{ display: 'flex', gap: '8px' }}>
                  <input
                    type="text"
                    className="form-input"
                    placeholder="e.g. EB-8492 or #EB10293"
                    value={inputCode}
                    onChange={(e) => setInputCode(e.target.value)}
                  />
                  <button type="submit" className="btn-primary" style={{ width: 'auto', padding: '0 16px' }}>
                    <Search size={18} />
                  </button>
                </div>
              </div>

              {/* Quick Demo Pre-fill Button */}
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '4px' }}>
                Quick demo code:{' '}
                <span
                  style={{ color: 'var(--primary-dark)', fontWeight: '700', cursor: 'pointer', textDecoration: 'underline' }}
                  onClick={() => {
                    setInputCode('EB-8492');
                  }}
                >
                  EB-8492 (Rahul's Order)
                </span>
              </div>
            </form>

            {errorMsg && (
              <div style={{ background: '#fee2e2', color: '#dc2626', padding: '10px 14px', borderRadius: '10px', fontSize: '0.85rem', marginBottom: '16px', border: '1px solid #fca5a5' }}>
                {errorMsg}
              </div>
            )}

            {foundReservation && (
              <div style={{ background: '#f8fafc', border: '2px solid var(--primary)', borderRadius: '16px', padding: '16px', marginBottom: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                  <div>
                    <div style={{ fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-muted)' }}>ORDER VERIFIED</div>
                    <div style={{ fontWeight: '800', fontSize: '1.1rem' }}>{foundReservation.order_code}</div>
                  </div>
                  <span className="status-pill reserved">🟡 Active</span>
                </div>

                <div style={{ fontSize: '0.88rem', color: 'var(--text-main)', marginBottom: '12px' }}>
                  <div>Customer: <strong>{foundReservation.customer_name}</strong></div>
                  <div>Food: <strong>{foundReservation.food_name}</strong></div>
                  <div>Quantity: <strong>{foundReservation.quantity} portion(s)</strong></div>
                </div>

                {/* Amount to collect banner */}
                <div style={{ background: '#fff7ed', border: '1.5px solid #fdba74', padding: '12px', borderRadius: '12px', color: '#c2410c', marginBottom: '16px' }}>
                  <div style={{ fontSize: '0.8rem', fontWeight: '700' }}>💰 PAYMENT STATUS: PAY AT PICKUP</div>
                  <div style={{ fontSize: '1.3rem', fontWeight: '800', marginTop: '2px' }}>
                    Collect ₹{foundReservation.amount_to_collect} directly from customer
                  </div>
                  <div style={{ fontSize: '0.75rem', marginTop: '2px', color: '#9a3412' }}>
                    Verify cash or UPI payment before clicking confirm.
                  </div>
                </div>

                <button className="btn-primary" onClick={handleConfirmPickup}>
                  <CheckCircle2 size={18} /> Confirm Payment Collected & Complete Pickup
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
