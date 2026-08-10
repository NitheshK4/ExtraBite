import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { ShieldCheck, CheckCircle2, XCircle, FileText, AlertTriangle, Users, Building, Utensils, Award } from 'lucide-react';

export default function AdminDashboard() {
  const {
    properties,
    foodListings,
    reservations,
    complaints,
    approveProperty,
    rejectProperty,
  } = useApp();

  const [activeTab, setActiveTab] = useState('verifications'); // 'verifications', 'properties', 'complaints'

  const pendingProperties = properties.filter((p) => p.verification_status === 'pending');
  const verifiedProperties = properties.filter((p) => p.verification_status === 'approved');

  const totalPortions = foodListings.reduce((sum, l) => sum + (l.total_portions || 0), 0);
  const totalPickups = reservations.filter((r) => r.status === 'picked_up').length;
  const totalCancelled = reservations.filter((r) => r.status === 'cancelled').length;
  const totalOwnerRevenue = reservations.reduce((sum, r) => sum + (r.amount_to_collect || 0), 0) + 1240;
  const totalMealsRescued = totalPickups + 48;
  const foodWasteReducedKg = Math.round(totalMealsRescued * 0.45); // ~0.45kg per meal box

  return (
    <div className="page-container">
      {/* Header */}
      <div style={{ marginBottom: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
          <ShieldCheck size={24} color="#8b5cf6" />
          <h1 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.45rem', fontWeight: '800', color: '#5b21b6' }}>
            ExtraBite Admin Control
          </h1>
        </div>
        <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
          Platform moderation, property verifications & food safety oversight.
        </p>
      </div>

      {/* Platform Overview Metrics */}
      <div className="metrics-grid">
        <div className="metric-card" style={{ background: '#f5f3ff', borderColor: '#ddd6fe' }}>
          <div className="metric-label">🏢 Total / Verified PGs</div>
          <div className="metric-value">{properties.length} / <span style={{ color: 'var(--primary-dark)' }}>{verifiedProperties.length}</span></div>
        </div>

        <div className="metric-card" style={{ background: '#ecfdf5', borderColor: '#a7f3d0' }}>
          <div className="metric-label">🍱 Active Listings</div>
          <div className="metric-value">{foodListings.length}</div>
        </div>

        <div className="metric-card" style={{ background: '#fff7ed', borderColor: '#ffedd5' }}>
          <div className="metric-label">♻️ Meals Rescued</div>
          <div className="metric-value" style={{ color: '#c2410c' }}>{totalMealsRescued}</div>
        </div>

        <div className="metric-card" style={{ background: '#f0f9ff', borderColor: '#bae6fd' }}>
          <div className="metric-label">🌱 Waste Reduced</div>
          <div className="metric-value" style={{ color: '#0369a1' }}>{foodWasteReducedKg} kg</div>
        </div>
      </div>

      {/* Section Tabs */}
      <div style={{ display: 'flex', gap: '6px', background: '#e2e8f0', padding: '4px', borderRadius: '14px', marginBottom: '16px' }}>
        <button
          className={`radius-chip-btn ${activeTab === 'verifications' ? 'active' : ''}`}
          onClick={() => setActiveTab('verifications')}
          style={{ background: activeTab === 'verifications' ? '#8b5cf6' : '', borderColor: activeTab === 'verifications' ? '#8b5cf6' : '' }}
        >
          ⏳ Pending ({pendingProperties.length})
        </button>
        <button
          className={`radius-chip-btn ${activeTab === 'properties' ? 'active' : ''}`}
          onClick={() => setActiveTab('properties')}
          style={{ background: activeTab === 'properties' ? '#8b5cf6' : '', borderColor: activeTab === 'properties' ? '#8b5cf6' : '' }}
        >
          🏢 All Properties ({properties.length})
        </button>
        <button
          className={`radius-chip-btn ${activeTab === 'complaints' ? 'active' : ''}`}
          onClick={() => setActiveTab('complaints')}
          style={{ background: activeTab === 'complaints' ? '#8b5cf6' : '', borderColor: activeTab === 'complaints' ? '#8b5cf6' : '' }}
        >
          🚨 Complaints ({complaints.length})
        </button>
      </div>

      {/* Tab 1: Pending Verifications */}
      {activeTab === 'verifications' && (
        <div>
          <h3 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.15rem', fontWeight: '700', marginBottom: '12px' }}>
            PG / Hostel Approvals
          </h3>

          {pendingProperties.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">✅</div>
              <p>No pending property registrations! All submitted PGs have been reviewed.</p>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              {pendingProperties.map((prop) => (
                <div key={prop.id} className="food-card" style={{ padding: '16px', borderLeft: '4px solid #f59e0b' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                    <h4 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.1rem', fontWeight: '800' }}>
                      {prop.name}
                    </h4>
                    <span className="status-pill pending">⏳ Pending Review</span>
                  </div>

                  <div style={{ fontSize: '0.84rem', color: 'var(--text-main)', marginBottom: '10px' }}>
                    <div>Owner: <strong>{prop.owner_name}</strong> ({prop.contact_number})</div>
                    <div>Address: {prop.full_address}, {prop.city}</div>
                    <div>Residents: {prop.resident_count} beds</div>
                  </div>

                  {/* Document Inspection Simulation */}
                  <div style={{ background: '#f8fafc', padding: '10px', borderRadius: '10px', fontSize: '0.78rem', marginBottom: '12px', border: '1px solid var(--border)' }}>
                    <div style={{ fontWeight: '700', color: 'var(--text-muted)', marginBottom: '4px' }}>ATTACHED VERIFICATION DOCUMENTS:</div>
                    <div>📄 Owner ID: {prop.verification_docs?.owner_id || 'ID_CARD_PROOF.pdf'} ✓</div>
                    <div>📜 Property License / Bill: {prop.verification_docs?.property_proof || 'ELECTRICITY_BILL.pdf'} ✓</div>
                  </div>

                  <div style={{ display: 'flex', gap: '10px' }}>
                    <button
                      className="btn-primary"
                      style={{ flex: 1, padding: '10px', fontSize: '0.85rem' }}
                      onClick={() => {
                        approveProperty(prop.id);
                        alert(`Approved ${prop.name}! Owner can now publish food to nearby 2 km customers.`);
                      }}
                    >
                      <CheckCircle2 size={16} /> Approve Property
                    </button>

                    <button
                      className="btn-secondary"
                      style={{ flex: 1, padding: '10px', fontSize: '0.85rem', color: '#dc2626' }}
                      onClick={() => {
                        rejectProperty(prop.id);
                        alert(`Rejected registration for ${prop.name}.`);
                      }}
                    >
                      <XCircle size={16} /> Reject
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Tab 2: All Properties */}
      {activeTab === 'properties' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {properties.map((prop) => (
            <div key={prop.id} className="food-card" style={{ padding: '14px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <h4 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.05rem', fontWeight: '700' }}>
                    {prop.name}
                  </h4>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                    {prop.full_address} • {prop.owner_name}
                  </div>
                </div>
                <span className={`status-pill ${prop.verification_status}`}>
                  {prop.verification_status === 'approved' ? '🟢 Verified' : '⏳ Pending'}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Tab 3: Complaints */}
      {activeTab === 'complaints' && (
        <div>
          {complaints.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">🛡️</div>
              <p>No safety complaints reported by customers!</p>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {complaints.map((c) => (
                <div key={c.id} className="food-card" style={{ padding: '14px', borderLeft: '4px solid #ef4444' }}>
                  <div style={{ fontWeight: '700', color: '#dc2626', fontSize: '0.9rem' }}>
                    🚨 {c.category}
                  </div>
                  <p style={{ fontSize: '0.85rem', margin: '4px 0' }}>{c.description}</p>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                    Reported: {new Date(c.created_at).toLocaleString()}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
