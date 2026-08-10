import React, { createContext, useContext, useState, useEffect } from 'react';
import { calculateHaversineDistance } from '../utils/haversine';

const AppContext = createContext();

const DEFAULT_CUSTOMER_LOCATION = {
  name: 'Indiranagar, Bengaluru',
  lat: 12.9784,
  lng: 77.6408,
};

const SEED_PROPERTIES = [
  {
    id: 'p1',
    name: 'Sri Sai PG',
    type: 'pg',
    full_address: '#12, 10th Main, Indiranagar, Bengaluru',
    city: 'Bengaluru',
    state: 'Karnataka',
    pincode: '560038',
    lat: 12.9820,
    lng: 77.6430,
    verification_status: 'approved',
    resident_count: 45,
    contact_number: '+91 98765 43210',
    whatsapp_number: '+91 98765 43210',
    rating: 4.8,
    reviews_count: 24,
    owner_name: 'Ramesh Kumar',
  },
  {
    id: 'p2',
    name: 'Lakshmi Hostel',
    type: 'hostel',
    full_address: '#45, 4th Cross, Domlur, Bengaluru',
    city: 'Bengaluru',
    state: 'Karnataka',
    pincode: '560071',
    lat: 12.9690,
    lng: 77.6460,
    verification_status: 'approved',
    resident_count: 60,
    contact_number: '+91 98765 11223',
    whatsapp_number: '+91 98765 11223',
    rating: 4.6,
    reviews_count: 18,
    owner_name: 'Lakshmi Amma',
  },
  {
    id: 'p3',
    name: 'Vijaya PG',
    type: 'pg',
    full_address: '#88, Old Airport Road, Kodihalli, Bengaluru',
    city: 'Bengaluru',
    state: 'Karnataka',
    pincode: '560008',
    lat: 12.9610,
    lng: 77.6350,
    verification_status: 'approved',
    resident_count: 30,
    contact_number: '+91 98765 99887',
    whatsapp_number: '+91 98765 99887',
    rating: 4.9,
    reviews_count: 32,
    owner_name: 'Vijay V.',
  },
  {
    id: 'p4',
    name: 'Royal Mess',
    type: 'mess',
    full_address: '#102, C.V. Raman Nagar, Bengaluru',
    city: 'Bengaluru',
    state: 'Karnataka',
    pincode: '560093',
    lat: 13.0100,
    lng: 77.6500,
    verification_status: 'approved',
    resident_count: 80,
    contact_number: '+91 98765 33445',
    whatsapp_number: '+91 98765 33445',
    rating: 4.5,
    reviews_count: 15,
    owner_name: 'Suresh Reddy',
  },
  {
    id: 'p5',
    name: 'Green Villa Hostel',
    type: 'hostel',
    full_address: '#5, Kalyan Nagar, Bengaluru',
    city: 'Bengaluru',
    state: 'Karnataka',
    pincode: '560043',
    lat: 13.0400,
    lng: 77.6200,
    verification_status: 'approved',
    resident_count: 50,
    contact_number: '+91 98765 77665',
    whatsapp_number: '+91 98765 77665',
    rating: 4.4,
    reviews_count: 10,
    owner_name: 'Anita Roy',
  },
  {
    id: 'p6',
    name: 'Sunrise PG',
    type: 'pg',
    full_address: '#22, 1st Cross, Indiranagar, Bengaluru',
    city: 'Bengaluru',
    state: 'Karnataka',
    pincode: '560038',
    lat: 12.9800,
    lng: 77.6420,
    verification_status: 'pending', // Unverified! Must never appear in customer results
    resident_count: 25,
    contact_number: '+91 98765 00000',
    whatsapp_number: '+91 98765 00000',
    rating: 0,
    reviews_count: 0,
    owner_name: 'Karan Sharma',
    verification_docs: {
      owner_id: 'ID_CARD_9921.jpg',
      property_proof: 'ELECTRICITY_BILL.pdf',
      property_photo: 'FRONT_VIEW.jpg',
    }
  }
];

const SEED_FOOD_LISTINGS = [
  {
    id: 'l1',
    property_id: 'p1',
    food_name: 'Rice + Dal + Curry Meal Box',
    description: 'Freshly cooked steamed Sona Masoori rice served with flavorful yellow dal tadka and mixed vegetable curry.',
    image_url: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=600&auto=format&fit=crop&q=80',
    category: 'Dinner',
    dietary_type: 'vegetarian',
    ingredients: 'Rice, Toor Dal, Tomatoes, Turmeric, Mixed Vegetables, Spices',
    allergens: 'None',
    original_price: 60,
    selling_price: 30,
    total_portions: 15,
    available_portions: 12,
    prepared_time: '6:30 PM',
    pickup_starts: '7:30 PM',
    pickup_ends: '9:30 PM',
    consume_before: '10:30 PM',
    cancellation_cutoff: '7:00 PM',
    status: 'published',
  },
  {
    id: 'l2',
    property_id: 'p2',
    food_name: 'Special Veg Pulao & Raita',
    description: 'Aromatic Basmati rice cooked with fresh green peas, carrots, beans, and whole Indian spices.',
    image_url: 'https://images.unsplash.com/photo-1633945274405-b6c8069047b0?w=600&auto=format&fit=crop&q=80',
    category: 'Dinner',
    dietary_type: 'vegetarian',
    ingredients: 'Basmati Rice, Peas, Carrots, Ghee, Spices, Curd',
    allergens: 'Dairy (Raita)',
    original_price: 70,
    selling_price: 35,
    total_portions: 10,
    available_portions: 8,
    prepared_time: '6:00 PM',
    pickup_starts: '7:00 PM',
    pickup_ends: '9:00 PM',
    consume_before: '10:00 PM',
    cancellation_cutoff: '6:45 PM',
    status: 'published',
  },
  {
    id: 'l3',
    property_id: 'p3',
    food_name: 'Wheat Chapati (4 pcs) + Paneer Curry',
    description: 'Soft whole wheat chapatis served with rich cottage cheese tomato gravy.',
    image_url: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&auto=format&fit=crop&q=80',
    category: 'Dinner',
    dietary_type: 'vegetarian',
    ingredients: 'Whole Wheat Flour, Paneer, Tomatoes, Cream, Spices',
    allergens: 'Gluten, Dairy',
    original_price: 90,
    selling_price: 45,
    total_portions: 8,
    available_portions: 6,
    prepared_time: '7:00 PM',
    pickup_starts: '8:00 PM',
    pickup_ends: '10:00 PM',
    consume_before: '11:00 PM',
    cancellation_cutoff: '7:45 PM',
    status: 'published',
  },
  {
    id: 'l4',
    property_id: 'p4',
    food_name: 'Butter Chicken & Garlic Naan',
    description: 'Tender chicken pieces in rich creamy tomato butter sauce with fresh garlic naan.',
    image_url: 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=600&auto=format&fit=crop&q=80',
    category: 'Dinner',
    dietary_type: 'non_vegetarian',
    ingredients: 'Chicken, Butter, Cream, Tomatoes, Maida, Garlic',
    allergens: 'Gluten, Dairy',
    original_price: 120,
    selling_price: 60,
    total_portions: 8,
    available_portions: 5,
    prepared_time: '7:30 PM',
    pickup_starts: '8:30 PM',
    pickup_ends: '10:30 PM',
    consume_before: '11:30 PM',
    cancellation_cutoff: '8:15 PM',
    status: 'published',
  },
  {
    id: 'l5',
    property_id: 'p5',
    food_name: 'South Indian Thali Meal Box',
    description: 'Traditional South Indian dinner with Sambar, Rasam, Kootu, Rice, and Papad.',
    image_url: 'https://images.unsplash.com/photo-1610192244261-3f33de3f55e4?w=600&auto=format&fit=crop&q=80',
    category: 'Dinner',
    dietary_type: 'vegetarian',
    ingredients: 'Rice, Toor Dal, Tamarind, Vegetables, Mustard Seeds, Curry Leaves',
    allergens: 'Mustard',
    original_price: 80,
    selling_price: 40,
    total_portions: 12,
    available_portions: 10,
    prepared_time: '6:30 PM',
    pickup_starts: '7:30 PM',
    pickup_ends: '9:30 PM',
    consume_before: '10:30 PM',
    cancellation_cutoff: '7:15 PM',
    status: 'published',
  },
  {
    id: 'l6',
    property_id: 'p6',
    food_name: 'Steamed Idli (4 pcs) & Sambar',
    description: 'Hot fluffy rice cakes with spicy lentil sambar and coconut chutney.',
    image_url: 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=600&auto=format&fit=crop&q=80',
    category: 'Breakfast',
    dietary_type: 'vegetarian',
    ingredients: 'Rice, Urad Dal, Coconut, Spices',
    allergens: 'Coconut',
    original_price: 40,
    selling_price: 20,
    total_portions: 15,
    available_portions: 15,
    prepared_time: '7:00 AM',
    pickup_starts: '7:30 AM',
    pickup_ends: '9:30 AM',
    consume_before: '10:30 AM',
    cancellation_cutoff: '7:15 AM',
    status: 'published',
  }
];

const SEED_RESERVATIONS = [
  {
    id: 'res-101',
    order_code: '#EB10293',
    pickup_code: 'EB-8492',
    qr_token: 'EB10293_TOKEN_SECRET',
    listing_id: 'l1',
    property_id: 'p1',
    customer_id: 'cust-1',
    customer_name: 'Rahul Sharma',
    customer_mobile: '+91 98765 12345',
    food_name: 'Rice + Dal + Curry Meal Box',
    property_name: 'Sri Sai PG',
    address: '#12, 10th Main, Indiranagar, Bengaluru',
    quantity: 2,
    unit_price: 30,
    amount_to_collect: 60,
    pickup_starts: '7:30 PM',
    pickup_ends: '9:30 PM',
    status: 'reserved', // 'reserved', 'picked_up', 'cancelled'
    reserved_at: new Date(Date.now() - 3600000).toISOString(),
  }
];

export function AppProvider({ children }) {
  // Navigation Role & View State
  const [currentRole, setCurrentRole] = useState('welcome'); // 'welcome', 'customer', 'owner', 'admin'
  const [customerView, setCustomerView] = useState('home'); // 'home', 'explore', 'reservations', 'favorites', 'profile'
  const [ownerView, setOwnerView] = useState('dashboard'); // 'dashboard', 'food', 'reservations', 'analytics', 'profile'
  const [activePropertyId, setActivePropertyId] = useState('p1'); // Owner context

  // Customer Location & Radius State
  const [customerLocation, setCustomerLocation] = useState(DEFAULT_CUSTOMER_LOCATION);
  const [searchRadius, setSearchRadius] = useState(2); // 1, 2 (default), 5, 10 km
  const [customerDietaryPref, setCustomerDietaryPref] = useState('both'); // 'vegetarian', 'non_vegetarian', 'both'
  const [customerPricePref, setCustomerPricePref] = useState('any'); // 'under_30', '30_50', '50_100', 'any'

  // Application Data Store
  const [properties, setProperties] = useState(() => {
    const saved = localStorage.getItem('extrabite_properties');
    return saved ? JSON.parse(saved) : SEED_PROPERTIES;
  });

  const [foodListings, setFoodListings] = useState(() => {
    const saved = localStorage.getItem('extrabite_foodListings');
    return saved ? JSON.parse(saved) : SEED_FOOD_LISTINGS;
  });

  const [reservations, setReservations] = useState(() => {
    const saved = localStorage.getItem('extrabite_reservations');
    return saved ? JSON.parse(saved) : SEED_RESERVATIONS;
  });

  const [reviews, setReviews] = useState(() => {
    const saved = localStorage.getItem('extrabite_reviews');
    return saved ? JSON.parse(saved) : [];
  });

  const [complaints, setComplaints] = useState(() => {
    const saved = localStorage.getItem('extrabite_complaints');
    return saved ? JSON.parse(saved) : [];
  });

  // Active reservation modal state
  const [currentReservation, setCurrentReservation] = useState(null);

  // Sync to localStorage
  useEffect(() => {
    localStorage.setItem('extrabite_properties', JSON.stringify(properties));
  }, [properties]);

  useEffect(() => {
    localStorage.setItem('extrabite_foodListings', JSON.stringify(foodListings));
  }, [foodListings]);

  useEffect(() => {
    localStorage.setItem('extrabite_reservations', JSON.stringify(reservations));
  }, [reservations]);

  useEffect(() => {
    localStorage.setItem('extrabite_reviews', JSON.stringify(reviews));
  }, [reviews]);

  useEffect(() => {
    localStorage.setItem('extrabite_complaints', JSON.stringify(complaints));
  }, [complaints]);

  // Derived filtered listings for customer based on radius & verification
  const getFilteredCustomerListings = (query = '', categoryFilter = 'All', sortOption = 'distance') => {
    return foodListings
      .map((listing) => {
        const property = properties.find((p) => p.id === listing.property_id);
        if (!property) return null;

        const distance = calculateHaversineDistance(
          customerLocation.lat,
          customerLocation.lng,
          property.lat,
          property.lng
        );

        return {
          ...listing,
          property,
          distance,
        };
      })
      .filter((item) => {
        if (!item) return false;
        // MUST BE VERIFIED PROPERTY
        if (item.property.verification_status !== 'approved') return false;
        // MUST BE IN RADIUS
        if (item.distance > searchRadius) return false;
        // MUST HAVE AVAILABLE PORTIONS
        if (item.available_portions <= 0) return false;
        // MUST BE PUBLISHED
        if (item.status !== 'published') return false;

        // Dietary Preference filter
        if (customerDietaryPref !== 'both' && item.dietary_type !== customerDietaryPref) {
          return false;
        }

        // Category filter
        if (categoryFilter !== 'All') {
          if (categoryFilter === 'Under ₹30' && item.selling_price > 30) return false;
          if (categoryFilter === 'Vegetarian' && item.dietary_type !== 'vegetarian') return false;
          if (categoryFilter !== 'Under ₹30' && categoryFilter !== 'Vegetarian' && item.category.toLowerCase() !== categoryFilter.toLowerCase()) {
            return false;
          }
        }

        // Text Search
        if (query.trim()) {
          const q = query.toLowerCase();
          const matchFood = item.food_name.toLowerCase().includes(q);
          const matchProperty = item.property.name.toLowerCase().includes(q);
          if (!matchFood && !matchProperty) return false;
        }

        return true;
      })
      .sort((a, b) => {
        if (sortOption === 'distance') return a.distance - b.distance;
        if (sortOption === 'price') return a.selling_price - b.selling_price;
        if (sortOption === 'rating') return b.property.rating - a.property.rating;
        return 0;
      });
  };

  // Actions
  const createReservation = (listingId, quantity) => {
    const listing = foodListings.find((l) => l.id === listingId);
    if (!listing || listing.available_portions < quantity) {
      alert('Sorry! This food is no longer available in the requested quantity.');
      return null;
    }

    const property = properties.find((p) => p.id === listing.property_id);
    const orderNum = Math.floor(100000 + Math.random() * 900000);
    const pickupNum = Math.floor(1000 + Math.random() * 9000);
    const orderCode = `#EB${orderNum}`;
    const pickupCode = `EB-${pickupNum}`;

    const newRes = {
      id: `res-${Date.now()}`,
      order_code: orderCode,
      pickup_code: pickupCode,
      qr_token: `${orderCode}_TOKEN`,
      listing_id: listing.id,
      property_id: property.id,
      customer_id: 'cust-1',
      customer_name: 'Rahul Sharma',
      customer_mobile: '+91 98765 12345',
      food_name: listing.food_name,
      property_name: property.name,
      address: property.full_address,
      quantity,
      unit_price: listing.selling_price,
      amount_to_collect: listing.selling_price * quantity,
      pickup_starts: listing.pickup_starts,
      pickup_ends: listing.pickup_ends,
      status: 'reserved',
      reserved_at: new Date().toISOString(),
    };

    // Atomically decrement available portions
    setFoodListings((prev) =>
      prev.map((l) =>
        l.id === listingId ? { ...l, available_portions: l.available_portions - quantity } : l
      )
    );

    setReservations((prev) => [newRes, ...prev]);
    setCurrentReservation(newRes);
    return newRes;
  };

  const confirmPickupByCode = (codeOrQr) => {
    const code = codeOrQr.trim().toUpperCase();
    const res = reservations.find(
      (r) =>
        (r.pickup_code.toUpperCase() === code || r.order_code.toUpperCase() === code || r.qr_token.toUpperCase() === code) &&
        r.status === 'reserved'
    );

    if (!res) {
      return { success: false, message: 'Invalid or already processed pickup code/QR.' };
    }

    // Confirm pickup
    setReservations((prev) =>
      prev.map((r) => (r.id === res.id ? { ...r, status: 'picked_up', picked_up_at: new Date().toISOString() } : r))
    );

    return { success: true, reservation: res };
  };

  const cancelReservation = (reservationId, reason = 'Changed my mind') => {
    const res = reservations.find((r) => r.id === reservationId);
    if (!res || res.status !== 'reserved') return false;

    // Restore inventory
    setFoodListings((prev) =>
      prev.map((l) =>
        l.id === res.listing_id ? { ...l, available_portions: l.available_portions + res.quantity } : l
      )
    );

    setReservations((prev) =>
      prev.map((r) =>
        r.id === reservationId
          ? { ...r, status: 'cancelled', cancelled_at: new Date().toISOString(), cancellation_reason: reason }
          : r
      )
    );
    return true;
  };

  const submitReview = (reservationId, foodRating, propertyRating, reviewText, isUnsafe = false) => {
    const res = reservations.find((r) => r.id === reservationId);
    if (!res) return;

    const newRev = {
      id: `rev-${Date.now()}`,
      reservation_id: reservationId,
      customer_id: res.customer_id,
      property_id: res.property_id,
      listing_id: res.listing_id,
      food_quality_rating: foodRating,
      property_experience_rating: propertyRating,
      review_text: reviewText,
      created_at: new Date().toISOString(),
    };

    setReviews((prev) => [newRev, ...prev]);

    if (isUnsafe) {
      const newComplaint = {
        id: `cmp-${Date.now()}`,
        reporter_id: res.customer_id,
        property_id: res.property_id,
        listing_id: res.listing_id,
        reservation_id: reservationId,
        category: 'Food Safety Concern',
        description: reviewText || 'Customer reported potential unsafe food quality.',
        status: 'open',
        created_at: new Date().toISOString(),
      };
      setComplaints((prev) => [newComplaint, ...prev]);
    }
  };

  const registerOwner = (ownerData, propertyData) => {
    const propId = `p-${Date.now()}`;
    const newProp = {
      id: propId,
      name: propertyData.name,
      type: propertyData.type || 'pg',
      full_address: propertyData.address,
      city: propertyData.city || 'Bengaluru',
      state: propertyData.state || 'Karnataka',
      pincode: propertyData.pincode || '560038',
      lat: propertyData.lat || 12.9750,
      lng: propertyData.lng || 77.6410,
      verification_status: 'pending', // Pending Admin approval!
      resident_count: parseInt(propertyData.residentCount) || 30,
      contact_number: ownerData.mobile,
      whatsapp_number: ownerData.whatsapp || ownerData.mobile,
      rating: 5.0,
      reviews_count: 0,
      owner_name: ownerData.fullName,
      verification_docs: {
        owner_id: 'ID_PROOF.pdf',
        property_proof: 'RENT_AGREEMENT.pdf',
        property_photo: 'PROPERTY_FRONT.jpg',
      }
    };

    setProperties((prev) => [...prev, newProp]);
    setActivePropertyId(propId);
    return newProp;
  };

  const approveProperty = (propertyId) => {
    setProperties((prev) =>
      prev.map((p) => (p.id === propertyId ? { ...p, verification_status: 'approved' } : p))
    );
  };

  const rejectProperty = (propertyId) => {
    setProperties((prev) =>
      prev.map((p) => (p.id === propertyId ? { ...p, verification_status: 'rejected' } : p))
    );
  };

  const addFoodListing = (foodData) => {
    const newListing = {
      id: `l-${Date.now()}`,
      property_id: activePropertyId,
      food_name: foodData.food_name,
      description: foodData.description,
      image_url: foodData.image_url || 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=600&auto=format&fit=crop&q=80',
      category: foodData.category || 'Dinner',
      dietary_type: foodData.dietary_type || 'vegetarian',
      ingredients: foodData.ingredients || 'Fresh ingredients',
      allergens: foodData.allergens || 'None',
      original_price: parseFloat(foodData.original_price),
      selling_price: parseFloat(foodData.selling_price),
      total_portions: parseInt(foodData.portions),
      available_portions: parseInt(foodData.portions),
      prepared_time: foodData.prepared_time || '6:30 PM',
      pickup_starts: foodData.pickup_starts || '7:30 PM',
      pickup_ends: foodData.pickup_ends || '9:30 PM',
      consume_before: foodData.consume_before || '10:30 PM',
      cancellation_cutoff: foodData.cancellation_cutoff || '7:00 PM',
      status: 'published',
    };

    setFoodListings((prev) => [newListing, ...prev]);
    return newListing;
  };

  return (
    <AppContext.Provider
      value={{
        currentRole,
        setCurrentRole,
        customerView,
        setCustomerView,
        ownerView,
        setOwnerView,
        activePropertyId,
        setActivePropertyId,
        customerLocation,
        setCustomerLocation,
        searchRadius,
        setSearchRadius,
        customerDietaryPref,
        setCustomerDietaryPref,
        customerPricePref,
        setCustomerPricePref,
        properties,
        foodListings,
        reservations,
        reviews,
        complaints,
        currentReservation,
        setCurrentReservation,
        getFilteredCustomerListings,
        createReservation,
        confirmPickupByCode,
        cancelReservation,
        submitReview,
        registerOwner,
        approveProperty,
        rejectProperty,
        addFoodListing,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  return useContext(AppContext);
}
