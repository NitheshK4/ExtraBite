import React, { useEffect } from 'react';
import confetti from 'canvas-confetti';
import { generateQRCodeSVG } from '../../utils/qrGenerator';
import { CheckCircle2, AlertCircle, MapPin, Calendar, Clock } from 'lucide-react';

export default function ReservationConfirmation({ reservation, onClose }) {
  useEffect(() => {
    // Launch celebratory confetti burst
    confetti({
      particleCount: 80,
      spread: 70,
      origin: { y: 0.6 }
    });
  }, []);

  if (!reservation) return null;

  const qrSvgHtml = generateQRCodeSVG(reservation.qr_token || reservation.order_code, 180);

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ textAlign: 'center' }}>
        <div style={{ fontSize: '3.5rem', marginBottom: '8px' }}>🎉</div>
        
        <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.6rem', fontWeight: '800', color: 'var(--primary-dark)' }}>
          Reservation Confirmed
        </h2>

        <div style={{ fontSize: '0.9rem', color: 'var(--text-muted)', marginBottom: '16px' }}>
          Order ID: <strong style={{ color: 'var(--text-main)' }}>{reservation.order_code}</strong>
        </div>

        {/* QR Code Container */}
        <div className="confirmation-card">
          <div className="qr-box" dangerouslySetInnerHTML={{ __html: qrSvgHtml }} />
          
          <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '4px' }}>
            Backup Pickup Code
          </div>
          <div className="pickup-code-display">
            {reservation.pickup_code}
          </div>

          <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginTop: '8px' }}>
            Show this QR code or pickup code to the PG owner when collecting your food.
          </p>
        </div>

        {/* Pay At Pickup Rule Notice */}
        <div className="pay-at-pickup-banner" style={{ margin: '16px 0' }}>
          <AlertCircle size={20} />
          <div style={{ textAlign: 'left' }}>
            <strong>Payment: Pay at pickup</strong>
            <div style={{ fontSize: '0.78rem' }}>
              Amount to pay directly to owner: <strong>₹{reservation.amount_to_collect}</strong> (Cash or UPI at collection)
            </div>
          </div>
        </div>

        {/* Order Details Summary */}
        <div style={{ background: '#ffffff', border: '1px solid var(--border)', borderRadius: '14px', padding: '14px', textAlign: 'left', marginBottom: '20px', fontSize: '0.88rem' }}>
          <div style={{ fontWeight: '700', fontSize: '1rem', color: 'var(--text-main)', marginBottom: '4px' }}>
            {reservation.food_name}
          </div>
          <div style={{ color: 'var(--text-muted)', marginBottom: '8px' }}>
            Quantity: {reservation.quantity} portion(s)
          </div>

          <div style={{ borderTop: '1px dashed var(--border)', paddingTop: '8px', display: 'flex', flexDirection: 'column', gap: '4px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <MapPin size={14} color="#10b981" />
              <span><strong>{reservation.property_name}</strong> — {reservation.address}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Clock size={14} color="#10b981" />
              <span>Pickup Window: {reservation.pickup_starts} – {reservation.pickup_ends}</span>
            </div>
          </div>
        </div>

        <button className="btn-primary" onClick={onClose}>
          Done / Go to My Reservations
        </button>
      </div>
    </div>
  );
}
