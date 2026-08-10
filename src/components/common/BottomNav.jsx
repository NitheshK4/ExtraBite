import React from 'react';
import { useApp } from '../../context/AppContext';
import { Home, Compass, ShoppingBag, Heart, User, LayoutDashboard, Utensils, CheckCircle2, BarChart2 } from 'lucide-react';

export default function BottomNav() {
  const { currentRole, customerView, setCustomerView, ownerView, setOwnerView, reservations } = useApp();

  const activeReservationsCount = reservations.filter(r => r.status === 'reserved').length;

  if (currentRole === 'customer') {
    return (
      <nav className="bottom-nav">
        <button
          className={`nav-item ${customerView === 'home' ? 'active' : ''}`}
          onClick={() => setCustomerView('home')}
        >
          <Home size={20} />
          <span>Home</span>
        </button>

        <button
          className={`nav-item ${customerView === 'explore' ? 'active' : ''}`}
          onClick={() => setCustomerView('explore')}
        >
          <Compass size={20} />
          <span>Explore</span>
        </button>

        <button
          className={`nav-item ${customerView === 'reservations' ? 'active' : ''}`}
          onClick={() => setCustomerView('reservations')}
          style={{ position: 'relative' }}
        >
          <ShoppingBag size={20} />
          <span>Reservations</span>
          {activeReservationsCount > 0 && (
            <span style={{
              position: 'absolute',
              top: '-2px',
              right: '18px',
              background: '#ef4444',
              color: 'white',
              borderRadius: '50%',
              width: '16px',
              height: '16px',
              fontSize: '10px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 'bold'
            }}>
              {activeReservationsCount}
            </span>
          )}
        </button>

        <button
          className={`nav-item ${customerView === 'favorites' ? 'active' : ''}`}
          onClick={() => setCustomerView('favorites')}
        >
          <Heart size={20} />
          <span>Favorites</span>
        </button>

        <button
          className={`nav-item ${customerView === 'profile' ? 'active' : ''}`}
          onClick={() => setCustomerView('profile')}
        >
          <User size={20} />
          <span>Profile</span>
        </button>
      </nav>
    );
  }

  if (currentRole === 'owner') {
    return (
      <nav className="bottom-nav">
        <button
          className={`nav-item ${ownerView === 'dashboard' ? 'active' : ''}`}
          onClick={() => setOwnerView('dashboard')}
        >
          <LayoutDashboard size={20} />
          <span>Dashboard</span>
        </button>

        <button
          className={`nav-item ${ownerView === 'food' ? 'active' : ''}`}
          onClick={() => setOwnerView('food')}
        >
          <Utensils size={20} />
          <span>Food</span>
        </button>

        <button
          className={`nav-item ${ownerView === 'reservations' ? 'active' : ''}`}
          onClick={() => setOwnerView('reservations')}
        >
          <CheckCircle2 size={20} />
          <span>Verify</span>
        </button>

        <button
          className={`nav-item ${ownerView === 'analytics' ? 'active' : ''}`}
          onClick={() => setOwnerView('analytics')}
        >
          <BarChart2 size={20} />
          <span>Analytics</span>
        </button>

        <button
          className={`nav-item ${ownerView === 'profile' ? 'active' : ''}`}
          onClick={() => setOwnerView('profile')}
        >
          <User size={20} />
          <span>Profile</span>
        </button>
      </nav>
    );
  }

  return null;
}
