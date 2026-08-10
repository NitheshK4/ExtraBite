import React from 'react';
import { useApp } from '../../context/AppContext';
import { Navigation, Info } from 'lucide-react';

export default function RadiusFilter({ resultsCount }) {
  const { searchRadius, setSearchRadius } = useApp();

  const radiusOptions = [1, 2, 5, 10];

  return (
    <div className="radius-filter-container">
      <div className="radius-filter-header">
        <div className="radius-title">
          <Navigation size={16} color="#10b981" />
          <span>Showing food within <strong>{searchRadius} km</strong></span>
        </div>
        <span className="radius-badge-highlight">
          {resultsCount} {resultsCount === 1 ? 'Meal Available' : 'Meals Available'}
        </span>
      </div>

      <div className="radius-chips">
        {radiusOptions.map((r) => (
          <button
            key={r}
            className={`radius-chip-btn ${searchRadius === r ? 'active' : ''}`}
            onClick={() => setSearchRadius(r)}
          >
            {r} km {r === 2 ? '★ Default' : ''}
          </button>
        ))}
      </div>

      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '8px', display: 'flex', alignItems: 'center', gap: '4px' }}>
        <Info size={12} />
        Real-time GPS Haversine radius filtering. Unverified PGs are automatically excluded.
      </div>
    </div>
  );
}
