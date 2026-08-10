# 🍱 ExtraBite — Good food shouldn’t go to waste

ExtraBite is a mobile-first surplus-food reservation web application for PGs, hostels, and messes. It connects food providers with nearby residents and students to sell fresh surplus meals at discounted prices.

## 🌟 Tagline
> **Good food shouldn’t go to waste.**

---

## 🚫 Mandatory Payment Rule

ExtraBite is strictly a **reservation and pay-at-pickup** application.
- **NO online payment gateway** (No Razorpay, UPI gateway, card forms, or wallets).
- Every reservation records an `amount_to_collect`.
- Customers pay the PG/hostel owner **directly in cash or UPI at pickup/collection**.

---

## ✨ Key Features

- **2 km Haversine Radius Search**: Real GPS/coordinate distance calculation filtering verified PGs within 1km, 2km (default), 5km, and 10km.
- **QR & Pickup Code Verification**: Generates a unique order ID (e.g. `#EB10293`), QR code, and backup pickup code (`EB-8492`) upon reservation.
- **Multi-Role Portals**:
  - 👤 **Customer**: Food discovery, list/map view, quantity selection, order tracking, 1-5 star ratings & food safety reporting.
  - 🏠 **PG / Hostel Owner**: Registration, verification status, dashboard metrics, surplus food publishing form, pickup code scanner/verification.
  - 🛡️ **Admin**: Property registration document review, 1-click approvals, platform metrics (rescued meals, food waste reduced in kg, owner revenue).

---

## 🛠️ Tech Stack

- **Frontend**: React (Vite), JavaScript (ES Modules)
- **Styling**: Vanilla CSS (Modern design system, glassmorphism, responsive container)
- **Icons**: Lucide React
- **Animations**: Canvas Confetti
- **Geospatial Math**: Haversine formula calculation

---

## 🚀 Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Run development server
npm run dev

# Open http://localhost:3000 in browser
```

---

## 📄 License

MIT
