import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import RadiusFilter from './RadiusFilter';
import FoodCard from './FoodCard';
import FoodDetailsModal from './FoodDetailsModal';
import ReservationConfirmation from './ReservationConfirmation';
import InteractiveMap from './InteractiveMap';
import CustomerReservations from './CustomerReservations';
import ReviewModal from './ReviewModal';
import { Search, MapPin, List, Map, SlidersHorizontal, AlertCircle } from 'lucide-react';

export default function CustomerHome() {
  const {
    customerView,
    customerLocation,
    searchRadius,
    getFilteredCustomerListings,
    currentReservation,
    setCurrentReservation,
  } = useApp();

  const [searchQuery, setSearchQuery] = useState('');
  const [activeCategory, setActiveCategory] = useState('All');
  const [sortOption, setSortOption] = useState('distance');
  const [viewMode, setViewMode] = useState('list'); // 'list' | 'map'
  const [selectedFood, setSelectedFood] = useState(null);
  const [reviewReservation, setReviewReservation] = useState(null);

  const categories = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Vegetarian', 'Under ₹30'];
  const filteredListings = getFilteredCustomerListings(searchQuery, activeCategory, sortOption);

  if (customerView === 'reservations') {
    return (
      <div className="page-container">
        <CustomerReservations onOpenReviewModal={(res) => setReviewReservation(res)} />
        {reviewReservation && (
          <ReviewModal reservation={reviewReservation} onClose={() => setReviewReservation(null)} />
        )}
        {currentReservation && (
          <ReservationConfirmation reservation={currentReservation} onClose={() => setCurrentReservation(null)} />
        )}
      </div>
    );
  }

  if (customerView === 'favorites' || customerView === 'profile') {
    return (
      <div className="page-container">
        <div style={{ textAlign: 'center', padding: '40px 16px' }}>
          <div style={{ fontSize: '3rem', marginBottom: '8px' }}>👤</div>
          <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.4rem', fontWeight: '800' }}>
            {customerView === 'profile' ? 'Customer Profile' : 'Favorite PGs'}
          </h2>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.88rem', marginTop: '4px' }}>
            Rahul Sharma • rahul.sharma@example.com
          </p>

          <div style={{ background: 'white', borderRadius: '16px', padding: '16px', marginTop: '20px', border: '1px solid var(--border)', textAlign: 'left' }}>
            <div style={{ fontWeight: '700', fontSize: '0.9rem', marginBottom: '8px' }}>Location Preferences</div>
            <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>📍 Active Address: {customerLocation.name}</div>
            <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginTop: '4px' }}>🎯 Default Search Radius: 2 km</div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="page-container">
      {/* Title & Location Header */}
      <div style={{ marginBottom: '14px' }}>
        <h1 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.45rem', fontWeight: '800' }}>
          Extra Food Near You 🍱
        </h1>
        <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '4px' }}>
          <MapPin size={12} color="#10b981" /> {customerLocation.name}
        </p>
      </div>

      {/* Search Bar */}
      <div className="form-group" style={{ marginBottom: '14px' }}>
        <div style={{ position: 'relative' }}>
          <Search size={18} color="#64748b" style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)' }} />
          <input
            type="text"
            className="form-input"
            placeholder="Search food, PG or hostel name..."
            style={{ paddingLeft: '40px' }}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </div>

      {/* Radius Filter Component (2 km default) */}
      <RadiusFilter resultsCount={filteredListings.length} />

      {/* Category Scroll & View Switcher */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
        <div className="categories-scroll" style={{ margin: 0, flex: 1, paddingRight: '8px' }}>
          {categories.map((cat) => (
            <button
              key={cat}
              className={`cat-pill ${activeCategory === cat ? 'active' : ''}`}
              onClick={() => setActiveCategory(cat)}
            >
              {cat}
            </button>
          ))}
        </div>

        {/* View Mode Toggle (List vs Map) */}
        <div style={{ display: 'flex', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: '12px', padding: '2px' }}>
          <button
            style={{
              padding: '6px 10px',
              borderRadius: '10px',
              border: 'none',
              background: viewMode === 'list' ? 'var(--primary)' : 'transparent',
              color: viewMode === 'list' ? 'white' : 'var(--text-muted)',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
              fontSize: '0.75rem',
              fontWeight: '700'
            }}
            onClick={() => setViewMode('list')}
          >
            <List size={14} /> List
          </button>
          <button
            style={{
              padding: '6px 10px',
              borderRadius: '10px',
              border: 'none',
              background: viewMode === 'map' ? 'var(--primary)' : 'transparent',
              color: viewMode === 'map' ? 'white' : 'var(--text-muted)',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
              fontSize: '0.75rem',
              fontWeight: '700'
            }}
            onClick={() => setViewMode('map')}
          >
            <Map size={14} /> Map
          </button>
        </div>
      </div>

      {/* Sort Options */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
        <span>Sort by:</span>
        <div style={{ display: 'flex', gap: '6px' }}>
          {['distance', 'price', 'rating'].map((opt) => (
            <button
              key={opt}
              style={{
                background: sortOption === opt ? '#e2e8f0' : 'transparent',
                border: 'none',
                borderRadius: '8px',
                padding: '3px 8px',
                fontSize: '0.75rem',
                fontWeight: sortOption === opt ? '700' : '500',
                color: sortOption === opt ? 'var(--text-main)' : 'var(--text-muted)',
                cursor: 'pointer'
              }}
              onClick={() => setSortOption(opt)}
            >
              {opt === 'distance' && '📍 Closest'}
              {opt === 'price' && '💰 Price'}
              {opt === 'rating' && '⭐ Rating'}
            </button>
          ))}
        </div>
      </div>

      {/* Content Rendering */}
      {viewMode === 'map' ? (
        <InteractiveMap listings={filteredListings} onViewDetails={(item) => setSelectedFood(item)} />
      ) : (
        <>
          {filteredListings.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">📍</div>
              <h3 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.1rem', fontWeight: '700' }}>
                No extra food found within {searchRadius} km
              </h3>
              <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', margin: '8px 0 16px 0' }}>
                Try increasing your search radius to 5 km or 10 km to find more nearby PGs.
              </p>
            </div>
          ) : (
            <div className="food-grid">
              {filteredListings.map((item) => (
                <FoodCard key={item.id} item={item} onViewDetails={(i) => setSelectedFood(i)} />
              ))}
            </div>
          )}
        </>
      )}

      {/* Food Details Modal */}
      {selectedFood && (
        <FoodDetailsModal
          item={selectedFood}
          onClose={() => setSelectedFood(null)}
          onReserveSuccess={(res) => {
            setSelectedFood(null);
            setCurrentReservation(res);
          }}
        />
      )}

      {/* Reservation Confirmation Modal */}
      {currentReservation && (
        <ReservationConfirmation
          reservation={currentReservation}
          onClose={() => setCurrentReservation(null)}
        />
      )}
    </div>
  );
}
