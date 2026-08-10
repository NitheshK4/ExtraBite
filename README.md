# 🍱 ExtraBite — Native Mobile App

ExtraBite is a native mobile application built with Flutter for rescuing surplus food from PGs, hostels, and messes. It connects food providers with nearby residents and students to sell fresh surplus meals at discounted prices.

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
- **QR & Pickup Code Verification**: Generates a unique order ID, QR code, and backup pickup code upon reservation.
- **Multi-Role Portals**:
  - 👤 **Customer**: Food discovery, list/map view, quantity selection, order tracking, 1-5 star ratings & food safety reporting.
  - 🏠 **PG / Hostel Owner**: Registration, verification status, dashboard metrics, surplus food publishing form, pickup code scanner/verification.
  - 🛡️ **Admin**: Property registration document review, 1-click approvals, platform metrics (rescued meals, food waste reduced in kg, owner revenue).

---

## 🛠️ Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Navigation**: GoRouter (`go_router`)
- **Backend / Database**: Supabase (`supabase_flutter`)
- **Maps & Location**: Google Maps Flutter (`google_maps_flutter`), Geolocator (`geolocator`)
- **Scanner & QR**: `mobile_scanner`, `qr_flutter`

---

## 🚀 Getting Started

```bash
# 1. Get packages
flutter pub get

# 2. Run app
flutter run
```

---

## 📄 License

MIT
