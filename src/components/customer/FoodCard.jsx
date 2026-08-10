import React from 'react';
import { formatDistance } from '../../utils/haversine';
import { ShieldCheck, MapPin, Clock, ArrowRight } from 'lucide-react';

export default function FoodCard({ item, onViewDetails }) {
  const discountPercent = Math.round(
    ((item.original_price - item.selling_price) / item.original_price) * 100
  );

  return (
    <div className="food-card">
      <div className="food-card-image-wrap">
        <img src={item.image_url} alt={item.food_name} className="food-card-img" />
        <div className="food-card-badges">
          <span className="badge-verified">
            <ShieldCheck size={12} /> Verified
          </span>
          <span className="badge-discount">{discountPercent}% OFF</span>
        </div>
      </div>

      <div className="food-card-content">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
          <div className="property-name">{item.property.name}</div>
          <span className={`badge-diet ${item.dietary_type}`}>
            {item.dietary_type === 'vegetarian' ? '🟢 VEG' : '🔴 NON-VEG'}
          </span>
        </div>

        <h3 className="food-title">{item.food_name}</h3>

        <div className="food-meta-row">
          <span>📍 {formatDistance(item.distance)}</span>
          <span>•</span>
          <span><Clock size={12} inline="true" /> {item.pickup_starts}–{item.pickup_ends}</span>
        </div>

        <div className="food-price-row">
          <div>
            <div className="price-box">
              <span className="price-original">₹{item.original_price}</span>
              <span className="price-selling">₹{item.selling_price}</span>
            </div>
            <div className="portion-counter">
              🔥 {item.available_portions} portions remaining
            </div>
          </div>

          <button className="btn-secondary" style={{ padding: '8px 14px', fontSize: '0.85rem' }} onClick={() => onViewDetails(item)}>
            View Details <ArrowRight size={14} />
          </button>
        </div>
      </div>
    </div>
  );
}
