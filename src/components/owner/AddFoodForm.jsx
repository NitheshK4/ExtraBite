import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { Utensils, Clock, Tag, X, PlusCircle } from 'lucide-react';

export default function AddFoodForm({ onClose }) {
  const { addFoodListing, activePropertyId, properties } = useApp();

  const activeProp = properties.find((p) => p.id === activePropertyId);

  const [formData, setFormData] = useState({
    food_name: 'Special Paneer Butter Masala & Roti',
    description: 'Fresh cottage cheese in creamy tomato butter gravy with 3 whole wheat rotis.',
    image_url: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&auto=format&fit=crop&q=80',
    category: 'Dinner',
    dietary_type: 'vegetarian',
    portions: '10',
    original_price: '100',
    selling_price: '50',
    prepared_time: '7:00 PM',
    pickup_starts: '8:00 PM',
    pickup_ends: '10:00 PM',
    consume_before: '11:00 PM',
    cancellation_cutoff: '7:45 PM',
    ingredients: 'Paneer, Wheat flour, Cream, Butter, Tomatoes, Spices',
    allergens: 'Dairy, Gluten',
  });

  const originalNum = parseFloat(formData.original_price) || 0;
  const sellingNum = parseFloat(formData.selling_price) || 0;
  const discountPercent = originalNum > 0 ? Math.round(((originalNum - sellingNum) / originalNum) * 100) : 0;

  const handleSubmit = (e) => {
    e.preventDefault();

    if (activeProp && activeProp.verification_status !== 'approved') {
      alert('⚠️ Unverified Property: Your property registration is pending Admin approval. You cannot publish food until approved.');
      return;
    }

    addFoodListing(formData);
    alert('🎉 Food published successfully! Nearby customers can now discover and reserve it within 2 km.');
    onClose();
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

        <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.4rem', fontWeight: '800', marginBottom: '16px' }}>
          + Add Surplus Food
        </h2>

        {activeProp && activeProp.verification_status !== 'approved' && (
          <div style={{ background: '#fee2e2', border: '1px solid #fca5a5', padding: '12px', borderRadius: '12px', marginBottom: '16px', color: '#991b1b', fontSize: '0.82rem', fontWeight: '600' }}>
            ⚠️ Verification Pending: Admin must approve {activeProp.name} before listings can be published to nearby customers.
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Food Item Name</label>
            <input
              type="text"
              className="form-input"
              required
              value={formData.food_name}
              onChange={(e) => setFormData({ ...formData, food_name: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label className="form-label">Description</label>
            <textarea
              className="form-textarea"
              rows={2}
              required
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
            <div className="form-group">
              <label className="form-label">Category</label>
              <select
                className="form-select"
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              >
                <option value="Breakfast">Breakfast</option>
                <option value="Lunch">Lunch</option>
                <option value="Dinner">Dinner</option>
                <option value="Snacks">Snacks</option>
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Dietary Type</label>
              <select
                className="form-select"
                value={formData.dietary_type}
                onChange={(e) => setFormData({ ...formData, dietary_type: e.target.value })}
              >
                <option value="vegetarian">Vegetarian 🟢</option>
                <option value="non_vegetarian">Non-Vegetarian 🔴</option>
              </select>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Available Portions</label>
            <input
              type="number"
              className="form-input"
              required
              min="1"
              value={formData.portions}
              onChange={(e) => setFormData({ ...formData, portions: e.target.value })}
            />
          </div>

          {/* Pricing & Automatic Discount Calculator */}
          <div style={{ background: '#f8fafc', padding: '14px', borderRadius: '14px', border: '1px solid var(--border)', marginBottom: '16px' }}>
            <div style={{ fontWeight: '700', fontSize: '0.85rem', color: 'var(--text-main)', marginBottom: '10px' }}>
              Pricing & Automatic ExtraBite Discount
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
              <div className="form-group">
                <label className="form-label">Original Price (₹)</label>
                <input
                  type="number"
                  className="form-input"
                  required
                  value={formData.original_price}
                  onChange={(e) => setFormData({ ...formData, original_price: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">ExtraBite Price (₹)</label>
                <input
                  type="number"
                  className="form-input"
                  required
                  value={formData.selling_price}
                  onChange={(e) => setFormData({ ...formData, selling_price: e.target.value })}
                />
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: '8px', paddingTop: '8px', borderTop: '1px dashed var(--border)' }}>
              <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Calculated Discount:</span>
              <span className="badge-discount" style={{ fontSize: '0.85rem' }}>
                {discountPercent}% OFF
              </span>
            </div>
          </div>

          {/* Timings */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
            <div className="form-group">
              <label className="form-label">Prepared Time</label>
              <input
                type="text"
                className="form-input"
                required
                value={formData.prepared_time}
                onChange={(e) => setFormData({ ...formData, prepared_time: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Consume Before</label>
              <input
                type="text"
                className="form-input"
                required
                value={formData.consume_before}
                onChange={(e) => setFormData({ ...formData, consume_before: e.target.value })}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
            <div className="form-group">
              <label className="form-label">Pickup Start</label>
              <input
                type="text"
                className="form-input"
                required
                value={formData.pickup_starts}
                onChange={(e) => setFormData({ ...formData, pickup_starts: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Pickup Deadline</label>
              <input
                type="text"
                className="form-input"
                required
                value={formData.pickup_ends}
                onChange={(e) => setFormData({ ...formData, pickup_ends: e.target.value })}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Ingredients</label>
            <input
              type="text"
              className="form-input"
              value={formData.ingredients}
              onChange={(e) => setFormData({ ...formData, ingredients: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label className="form-label">Allergens</label>
            <input
              type="text"
              className="form-input"
              value={formData.allergens}
              onChange={(e) => setFormData({ ...formData, allergens: e.target.value })}
            />
          </div>

          <button type="submit" className="btn-primary" style={{ marginTop: '12px' }}>
            <PlusCircle size={18} /> Publish Surplus Food
          </button>
        </form>
      </div>
    </div>
  );
}
