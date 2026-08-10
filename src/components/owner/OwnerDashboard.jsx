import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import AddFoodForm from './AddFoodForm';
import VerifyPickupModal from './VerifyPickupModal';
import { PlusCircle, QrCode, Utensils, CheckCircle2, TrendingUp, AlertTriangle, ShieldCheck } from 'lucide-react';

export default function OwnerDashboard() {
  const {
    ownerView,
    activePropertyId,
    properties,
    foodListings,
    reservations,
  } = useApp();

  const [showAddModal, setShowAddModal] = useState(false);
  const [showVerifyModal, setShowVerifyModal] = useState(false);

  const activeProp = properties.find((p) => p.id === activePropertyId) || properties[0];
  const propListings = foodListings.filter((l) => l.property_id === activeProp.id);
  const propReservations = reservations.filter((r) => r.property_id === activeProp.id);

  // Derived metrics
  const activePortions = propListings.reduce((sum, l) => sum + (l.available_portions || 0), 0);
  const todayReservationsCount = propReservations.length;
  const expectedRevenue = propReservations.reduce((sum, r) => sum + (r.amount_to_collect || 0), 0);
  const mealsRescued = propReservations.filter((r) => r.status === 'picked_up').reduce((sum, r) => sum + r.quantity, 0) + 14;

  const isApproved = activeProp.verification_status === 'approved';

  return (
    <div className="page-container">
      {/* Header Info */}
      <div style={{ marginBottom: '16px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ fontSize: '0.8rem', fontWeight: '700', color: 'var(--text-muted)' }}>OWNER DASHBOARD</div>
            <h1 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.45rem', fontWeight: '800' }}>
              Welcome, {activeProp.name}
            </h1>
          </div>
          <span className={`status-pill ${activeProp.verification_status}`}>
            {isApproved ? '✓ Verified PG' : '⏳ Verification Pending'}
          </span>
        </div>
      </div>

      {!isApproved && (
        <div style={{ background: '#fef3c7', border: '1.5px solid #fde047', color: '#b45309', padding: '14px', borderRadius: '14px', marginBottom: '20px', fontSize: '0.85rem' }}>
          <div style={{ fontWeight: '700', display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '4px' }}>
            <AlertTriangle size={16} /> Property Verification Pending
          </div>
          Admin review is required before food listings become visible to nearby customers. You can use the Admin role switcher to approve this property in demo mode.
        </div>
      )}

      {/* Metrics Grid */}
      <div className="metrics-grid">
        <div className="metric-card">
          <div className="metric-label">🍱 Active Food</div>
          <div className="metric-value">{activePortions} <span style={{ fontSize: '0.8rem', fontWeight: 'normal', color: 'var(--text-muted)' }}>portions</span></div>
        </div>

        <div className="metric-card">
          <div className="metric-label">📦 Reservations</div>
          <div className="metric-value">{todayReservationsCount}</div>
        </div>

        <div className="metric-card">
          <div className="metric-label">💰 Expected Revenue</div>
          <div className="metric-value" style={{ color: 'var(--primary-dark)' }}>₹{expectedRevenue}</div>
        </div>

        <div className="metric-card">
          <div className="metric-label">♻️ Meals Rescued</div>
          <div className="metric-value" style={{ color: '#0284c7' }}>{mealsRescued}</div>
        </div>
      </div>

      {/* Action Buttons */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', marginBottom: '24px' }}>
        <button className="btn-primary" onClick={() => setShowAddModal(true)}>
          <PlusCircle size={18} /> + Add Surplus Food
        </button>

        <button className="btn-secondary" style={{ border: '2px solid var(--primary)', color: 'var(--primary-dark)', background: 'var(--primary-light)' }} onClick={() => setShowVerifyModal(true)}>
          <QrCode size={18} /> Verify Customer Pickup Code / QR
        </button>
      </div>

      {/* Current Active Food Listings Section */}
      <div style={{ marginBottom: '16px' }}>
        <h3 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.2rem', fontWeight: '700', marginBottom: '12px' }}>
          Listed Surplus Food ({propListings.length})
        </h3>

        {propListings.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">🍱</div>
            <p>No food listings active right now. Click "+ Add Surplus Food" to list today's extra meals!</p>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {propListings.map((item) => (
              <div key={item.id} className="food-card" style={{ padding: '14px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <h4 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.05rem', fontWeight: '700' }}>
                      {item.food_name}
                    </h4>
                    <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                      Pickup: {item.pickup_starts} – {item.pickup_ends}
                    </div>
                  </div>

                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '1.1rem', fontWeight: '800', color: 'var(--primary-dark)' }}>
                      ₹{item.selling_price}
                    </div>
                    <div style={{ fontSize: '0.75rem', fontWeight: '700', color: '#b45309' }}>
                      {item.available_portions} / {item.total_portions} portions
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Modals */}
      {showAddModal && <AddFoodForm onClose={() => setShowAddModal(false)} />}
      {showVerifyModal && <VerifyPickupModal onClose={() => setShowVerifyModal(false)} />}
    </div>
  );
}
