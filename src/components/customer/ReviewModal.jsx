import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { Star, X, ShieldAlert } from 'lucide-react';

export default function ReviewModal({ reservation, onClose }) {
  const { submitReview } = useApp();
  const [foodRating, setFoodRating] = useState(5);
  const [propertyRating, setPropertyRating] = useState(5);
  const [reviewText, setReviewText] = useState('');
  const [isUnsafe, setIsUnsafe] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  if (!reservation) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    submitReview(reservation.id, foodRating, propertyRating, reviewText, isUnsafe);
    setSubmitted(true);
    setTimeout(() => {
      onClose();
    }, 1500);
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

        {submitted ? (
          <div style={{ padding: '30px 10px', textAlign: 'center' }}>
            <div style={{ fontSize: '3rem', marginBottom: '8px' }}>🌟</div>
            <h3 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.4rem', fontWeight: '800' }}>
              Thank you for your feedback!
            </h3>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
              Your rating helps keep ExtraBite meals high quality & safe for everyone.
            </p>
          </div>
        ) : (
          <form onSubmit={handleSubmit}>
            <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.3rem', fontWeight: '800', marginBottom: '4px' }}>
              Rate Your Meal & Experience
            </h2>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginBottom: '16px' }}>
              Order {reservation.order_code} • {reservation.food_name} at {reservation.property_name}
            </p>

            {/* Food Rating */}
            <div className="form-group">
              <label className="form-label">Food Quality Rating</label>
              <div style={{ display: 'flex', gap: '8px', margin: '4px 0' }}>
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    type="button"
                    key={star}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '4px' }}
                    onClick={() => setFoodRating(star)}
                  >
                    <Star
                      size={28}
                      fill={star <= foodRating ? '#f59e0b' : '#cbd5e1'}
                      color={star <= foodRating ? '#f59e0b' : '#cbd5e1'}
                    />
                  </button>
                ))}
              </div>
            </div>

            {/* PG Rating */}
            <div className="form-group">
              <label className="form-label">PG / Hostel Experience Rating</label>
              <div style={{ display: 'flex', gap: '8px', margin: '4px 0' }}>
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    type="button"
                    key={star}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '4px' }}
                    onClick={() => setPropertyRating(star)}
                  >
                    <Star
                      size={28}
                      fill={star <= propertyRating ? '#3b82f6' : '#cbd5e1'}
                      color={star <= propertyRating ? '#3b82f6' : '#cbd5e1'}
                    />
                  </button>
                ))}
              </div>
            </div>

            {/* Review Comment */}
            <div className="form-group">
              <label className="form-label">Write a Review</label>
              <textarea
                className="form-textarea"
                rows={3}
                placeholder="How was the food packaging, taste, and pickup experience?"
                value={reviewText}
                onChange={(e) => setReviewText(e.target.value)}
              />
            </div>

            {/* Food Safety Complaint Checkbox */}
            <div style={{ background: '#fee2e2', border: '1px solid #fca5a5', padding: '12px', borderRadius: '12px', marginBottom: '20px' }}>
              <label style={{ display: 'flex', alignItems: 'flex-start', gap: '8px', cursor: 'pointer', fontSize: '0.82rem', color: '#991b1b', fontWeight: '600' }}>
                <input
                  type="checkbox"
                  checked={isUnsafe}
                  onChange={(e) => setIsUnsafe(e.target.checked)}
                  style={{ marginTop: '2px' }}
                />
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <ShieldAlert size={14} /> Report Food Safety Concern
                  </div>
                  <div style={{ fontWeight: 'normal', fontSize: '0.78rem', color: '#7f1d1d', marginTop: '2px' }}>
                    Check this if the food was cold, spoiled, or did not match the consume-before quality guarantee.
                  </div>
                </div>
              </label>
            </div>

            <button type="submit" className="btn-primary">
              Submit Review ⭐
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
