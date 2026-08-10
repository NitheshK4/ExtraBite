import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { formatDistance } from '../../utils/haversine';
import { X, ShieldCheck, Star, Clock, AlertCircle, ShoppingBag, MapPin } from 'lucide-react';

export default function FoodDetailsModal({ item, onClose, onReserveSuccess }) {
  const { createReservation } = useApp();
  const [quantity, setQuantity] = useState(1);

  if (!item) return null;

  const totalAmount = item.selling_price * quantity;

  const handleReserve = () => {
    const reservation = createReservation(item.id, quantity);
    if (reservation) {
      onReserveSuccess(reservation);
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
            cursor: 'pointer',
            boxShadow: 'var(--shadow-md)',
            zIndex: 10
          }}
        >
          <X size={18} />
        </button>

        <div style={{ borderRadius: '16px', overflow: 'hidden', height: '180px', marginBottom: '16px' }}>
          <img src={item.image_url} alt={item.food_name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span className="property-name">{item.property.name}</span>
              <span className="badge-verified"><ShieldCheck size={10} /> Verified</span>
            </div>
            <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.4rem', fontWeight: '800', margin: '4px 0' }}>
              {item.food_name}
            </h2>
          </div>

          <div style={{ textAlign: 'right' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '4px', background: '#fef3c7', padding: '3px 8px', borderRadius: '12px', fontSize: '0.8rem', fontWeight: '700', color: '#b45309' }}>
              <Star size={14} fill="#f59e0b" color="#f59e0b" /> {item.property.rating}
            </div>
          </div>
        </div>

        <div className="food-meta-row" style={{ marginBottom: '16px' }}>
          <span>📍 {formatDistance(item.distance)}</span>
          <span>•</span>
          <span className={`badge-diet ${item.dietary_type}`}>
            {item.dietary_type === 'vegetarian' ? 'VEG' : 'NON-VEG'}
          </span>
        </div>

        <p style={{ fontSize: '0.9rem', color: 'var(--text-muted)', marginBottom: '16px' }}>
          {item.description}
        </p>

        <div style={{ background: '#f8fafc', padding: '14px', borderRadius: '14px', border: '1px solid var(--border)', marginBottom: '16px', fontSize: '0.85rem' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '8px' }}>
            <div>
              <span style={{ color: 'var(--text-muted)' }}>Prepared Time:</span>
              <div style={{ fontWeight: '700' }}>{item.prepared_time}</div>
            </div>
            <div>
              <span style={{ color: 'var(--text-muted)' }}>Pickup Window:</span>
              <div style={{ fontWeight: '700', color: 'var(--primary-dark)' }}>{item.pickup_starts} – {item.pickup_ends}</div>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
            <div>
              <span style={{ color: 'var(--text-muted)' }}>Consume Before:</span>
              <div style={{ fontWeight: '700', color: '#dc2626' }}>{item.consume_before}</div>
            </div>
            <div>
              <span style={{ color: 'var(--text-muted)' }}>Cancel Cutoff:</span>
              <div style={{ fontWeight: '700' }}>{item.cancellation_cutoff}</div>
            </div>
          </div>

          <div style={{ marginTop: '10px', paddingTop: '8px', borderTop: '1px dashed var(--border)' }}>
            <div><strong>Ingredients:</strong> {item.ingredients}</div>
            <div style={{ marginTop: '2px' }}><strong>Allergens:</strong> {item.allergens}</div>
          </div>
        </div>

        {/* Mandatory Pay At Pickup Notice */}
        <div className="pay-at-pickup-banner">
          <AlertCircle size={18} />
          <div>
            <strong>Payment: Pay at pickup</strong>
            <div style={{ fontSize: '0.78rem', fontWeight: 'normal' }}>
              No online payment required. Pay ₹{totalAmount} directly to the PG owner when collecting.
            </div>
          </div>
        </div>

        {/* Quantity & Pricing */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '16px 0' }}>
          <div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Portions Quantity</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginTop: '4px' }}>
              <button
                className="btn-secondary"
                style={{ width: '36px', height: '36px', padding: 0, fontSize: '1.2rem', borderRadius: '50%' }}
                onClick={() => setQuantity(Math.max(1, quantity - 1))}
              >
                -
              </button>
              <span style={{ fontWeight: '800', fontSize: '1.2rem', minWidth: '24px', textAlign: 'center' }}>
                {quantity}
              </span>
              <button
                className="btn-secondary"
                style={{ width: '36px', height: '36px', padding: 0, fontSize: '1.2rem', borderRadius: '50%' }}
                onClick={() => setQuantity(Math.min(item.available_portions, quantity + 1))}
              >
                +
              </button>
            </div>
          </div>

          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Total Amount to Pay</div>
            <div style={{ fontSize: '1.6rem', fontWeight: '800', color: 'var(--primary-dark)' }}>
              ₹{totalAmount}
            </div>
          </div>
        </div>

        <button className="btn-primary" onClick={handleReserve}>
          <ShoppingBag size={18} /> Reserve Food (Pay ₹{totalAmount} at Pickup)
        </button>
      </div>
    </div>
  );
}
