import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { formatDistance } from '../../utils/haversine';
import { MapPin, Navigation, ShieldCheck, Clock } from 'lucide-react';

export default function InteractiveMap({ listings, onViewDetails }) {
  const { customerLocation, searchRadius } = useApp();
  const [selectedListing, setSelectedListing] = useState(listings[0] || null);

  return (
    <div>
      <div style={{
        height: '320px',
        width: '100%',
        borderRadius: '16px',
        background: 'linear-gradient(135deg, #1e293b, #0f172a)',
        position: 'relative',
        overflow: 'hidden',
        border: '1px solid var(--border)',
        boxShadow: 'var(--shadow-md)',
        marginBottom: '16px'
      }}>
        {/* Simulated Map Background Grid & Radar Circle */}
        <div style={{
          position: 'absolute',
          inset: 0,
          backgroundImage: 'radial-gradient(rgba(255, 255, 255, 0.1) 1px, transparent 1px)',
          backgroundSize: '24px 24px',
          opacity: 0.8
        }} />

        {/* Radius Radar Ring */}
        <div style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          width: '260px',
          height: '260px',
          borderRadius: '50%',
          border: '2px dashed rgba(16, 185, 129, 0.4)',
          background: 'radial-gradient(circle, rgba(16,185,129,0.08) 0%, rgba(16,185,129,0) 70%)',
          pointerEvents: 'none'
        }} />

        <div style={{
          position: 'absolute',
          top: '12px',
          left: '12px',
          background: 'rgba(15, 23, 42, 0.85)',
          backdropFilter: 'blur(8px)',
          padding: '6px 12px',
          borderRadius: '20px',
          color: '#f8fafc',
          fontSize: '0.75rem',
          fontWeight: '700',
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
          border: '1px solid rgba(255, 255, 255, 0.15)'
        }}>
          <Navigation size={12} color="#10b981" /> Map Radar View ({searchRadius} km)
        </div>

        {/* Customer Position Pin (Center) */}
        <div style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          zIndex: 10
        }}>
          <div style={{
            width: '24px',
            height: '24px',
            borderRadius: '50%',
            background: '#3b82f6',
            border: '3px solid white',
            boxShadow: '0 0 15px rgba(59, 130, 246, 0.8)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            animation: 'pulse 2s infinite'
          }}>
            <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: 'white' }} />
          </div>
          <span style={{ fontSize: '0.65rem', fontWeight: '800', color: '#93c5fd', background: 'rgba(0,0,0,0.6)', padding: '2px 6px', borderRadius: '8px', marginTop: '2px' }}>
            YOU
          </span>
        </div>

        {/* Nearby Verified PG Pins inside radius */}
        {listings.map((item, idx) => {
          // Calculate polar offsets around center
          const angle = (idx * 2 * Math.PI) / (listings.length || 1) + 0.5;
          const radiusRatio = Math.min(110, (item.distance / searchRadius) * 110 + 25);
          const offsetX = Math.cos(angle) * radiusRatio;
          const offsetY = Math.sin(angle) * radiusRatio;

          const isSelected = selectedListing?.id === item.id;

          return (
            <div
              key={item.id}
              onClick={() => setSelectedListing(item)}
              style={{
                position: 'absolute',
                top: `calc(50% + ${offsetY}px)`,
                left: `calc(50% + ${offsetX}px)`,
                transform: 'translate(-50%, -50%)',
                cursor: 'pointer',
                zIndex: isSelected ? 20 : 15,
                transition: 'all 0.2s ease'
              }}
            >
              <div style={{
                background: isSelected ? '#10b981' : '#f97316',
                color: 'white',
                padding: '4px 8px',
                borderRadius: '16px',
                fontSize: '0.7rem',
                fontWeight: '800',
                boxShadow: isSelected ? '0 0 16px rgba(16, 185, 129, 0.8)' : '0 4px 10px rgba(0,0,0,0.3)',
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
                border: '2px solid white',
                transform: isSelected ? 'scale(1.15)' : 'scale(1)'
              }}>
                <MapPin size={12} />
                <span>₹{item.selling_price}</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Selected Map Item Card Preview */}
      {selectedListing && (
        <div className="food-card" style={{ padding: '14px', border: '2px solid var(--primary)' }}>
          <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
            <img
              src={selectedListing.image_url}
              alt={selectedListing.food_name}
              style={{ width: '70px', height: '70px', borderRadius: '12px', objectFit: 'cover' }}
            />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: '0.75rem', fontWeight: '700', color: 'var(--text-muted)' }}>
                {selectedListing.property.name} • {formatDistance(selectedListing.distance)}
              </div>
              <h4 style={{ fontFamily: 'var(--font-heading)', fontSize: '1rem', fontWeight: '700' }}>
                {selectedListing.food_name}
              </h4>
              <div style={{ fontSize: '1.1rem', fontWeight: '800', color: 'var(--primary-dark)', marginTop: '2px' }}>
                ₹{selectedListing.selling_price}{' '}
                <span style={{ fontSize: '0.75rem', textDecoration: 'line-through', color: 'var(--text-muted)' }}>
                  ₹{selectedListing.original_price}
                </span>
              </div>
            </div>
            <button className="btn-primary" style={{ padding: '10px 14px', fontSize: '0.8rem' }} onClick={() => onViewDetails(selectedListing)}>
              View
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
