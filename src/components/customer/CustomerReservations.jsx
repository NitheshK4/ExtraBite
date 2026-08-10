import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { generateQRCodeSVG } from '../../utils/qrGenerator';
import { ShoppingBag, Clock, CheckCircle2, XCircle, QrCode, Star, AlertCircle } from 'lucide-react';

export default function CustomerReservations({ onOpenReviewModal }) {
  const { reservations, cancelReservation, setCurrentReservation } = useApp();
  const [activeTab, setActiveTab] = useState('reserved'); // 'reserved', 'picked_up', 'cancelled'

  const filteredReservations = reservations.filter((r) => r.status === activeTab);

  return (
    <div>
      <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.4rem', fontWeight: '800', marginBottom: '14px' }}>
        My Reservations
      </h2>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '6px', background: '#e2e8f0', padding: '4px', borderRadius: '14px', marginBottom: '16px' }}>
        <button
          className={`radius-chip-btn ${activeTab === 'reserved' ? 'active' : ''}`}
          onClick={() => setActiveTab('reserved')}
        >
          🟡 Active ({reservations.filter((r) => r.status === 'reserved').length})
        </button>
        <button
          className={`radius-chip-btn ${activeTab === 'picked_up' ? 'active' : ''}`}
          onClick={() => setActiveTab('picked_up')}
        >
          🟢 Picked Up ({reservations.filter((r) => r.status === 'picked_up').length})
        </button>
        <button
          className={`radius-chip-btn ${activeTab === 'cancelled' ? 'active' : ''}`}
          onClick={() => setActiveTab('cancelled')}
        >
          🔴 Cancelled ({reservations.filter((r) => r.status === 'cancelled').length})
        </button>
      </div>

      {filteredReservations.length === 0 ? (
        <div className="empty-state">
          <div className="empty-icon">🍱</div>
          <h3>No {activeTab} reservations</h3>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            {activeTab === 'reserved'
              ? 'Find surplus food near you and make a reservation!'
              : `You have no ${activeTab.replace('_', ' ')} orders.`}
          </p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          {filteredReservations.map((res) => (
            <div key={res.id} className="food-card" style={{ padding: '16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
                <div>
                  <div style={{ fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-muted)' }}>
                    ORDER {res.order_code}
                  </div>
                  <h4 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.1rem', fontWeight: '700', margin: '2px 0' }}>
                    {res.food_name}
                  </h4>
                  <div style={{ fontSize: '0.85rem', color: 'var(--primary-dark)', fontWeight: '600' }}>
                    🏠 {res.property_name}
                  </div>
                </div>

                <span className={`status-pill ${res.status}`}>
                  {res.status === 'reserved' && '🟡 Reserved'}
                  {res.status === 'picked_up' && '🟢 Picked Up'}
                  {res.status === 'cancelled' && '🔴 Cancelled'}
                </span>
              </div>

              <div style={{ background: '#f8fafc', padding: '10px 12px', borderRadius: '10px', margin: '10px 0', fontSize: '0.82rem', display: 'flex', justifyContent: 'space-between' }}>
                <div>
                  <div>Portions: <strong>{res.quantity}</strong></div>
                  <div>Pickup: <strong>{res.pickup_starts} – {res.pickup_ends}</strong></div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ color: 'var(--text-muted)' }}>Pay at pickup:</div>
                  <div style={{ fontSize: '1.1rem', fontWeight: '800', color: 'var(--primary-dark)' }}>
                    ₹{res.amount_to_collect}
                  </div>
                </div>
              </div>

              {res.status === 'reserved' && (
                <div style={{ display: 'flex', gap: '10px', marginTop: '12px' }}>
                  <button
                    className="btn-primary"
                    style={{ flex: 2, padding: '10px', fontSize: '0.85rem' }}
                    onClick={() => setCurrentReservation(res)}
                  >
                    <QrCode size={16} /> Show QR / Pickup Code
                  </button>

                  <button
                    className="btn-secondary"
                    style={{ flex: 1, padding: '10px', fontSize: '0.85rem', color: '#dc2626' }}
                    onClick={() => {
                      if (confirm('Are you sure you want to cancel this reservation? Inventory will be restored.')) {
                        cancelReservation(res.id);
                      }
                    }}
                  >
                    Cancel
                  </button>
                </div>
              )}

              {res.status === 'picked_up' && (
                <div style={{ marginTop: '10px' }}>
                  <button
                    className="btn-secondary"
                    style={{ width: '100%', padding: '10px', fontSize: '0.85rem', background: '#fef3c7', borderColor: '#fde047', color: '#b45309' }}
                    onClick={() => onOpenReviewModal(res)}
                  >
                    <Star size={14} fill="#b45309" color="#b45309" /> Rate Food & Experience
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
