# 📱 ExtraBite Mobile Application

The official cross-platform mobile client for **ExtraBite** (iOS & Android), built with Flutter, Riverpod, and Supabase.

---

## 🌟 Overview

ExtraBite Mobile allows students and campus residents to discover nearby surplus meals from university hostels, PGs, and mess facilities at low prices. PG Owners use the same app to publish surplus meals and verify student collections using QR codes.

---

## 🚀 Key Features

* **Role-Based Experience**: Customer and PG Owner workflows with role switching and onboarding guards.
* **Hyperlocal Food Feed**: Live Haversine distance filtering (1km, 2km, 5km, 10km) from current GPS location.
* **Instant Reservations**: Real-time portion locking with zero online payment fees (Pay-at-Pickup).
* **Digital Pickup Pass**: Scannable QR code and 4-character pickup code for swift counter verification.
* **PG Owner Dashboard**: Surplus meal publishing form, active orders management, and built-in camera QR scanner.

---

## 🛠️ Architecture

* **State Management**: [Riverpod 2.x](https://riverpod.dev) with StateNotifier providers.
* **Navigation**: [GoRouter 14.x](https://pub.dev/packages/go_router) with route redirect guards for onboarding, pending verification, and suspended states.
* **Design System**: Stitch-based design tokens, Google Fonts (Plus Jakarta Sans & Inter), accessible contrast ratios, responsive layouts.
* **Backend**: [Supabase Flutter SDK](https://pub.dev/packages/supabase_flutter) with PostgreSQL Row Level Security (RLS).

---

## 📂 Project Structure

```
lib/
├── app/
│   ├── router/          # AppRouter with authentication redirect logic
│   └── theme/           # AppColors, AppTheme, typography tokens
├── core/
│   ├── config/          # Centralized AppConfig (Supabase URL & anon key)
│   ├── location/        # LocationState & Haversine calculation helpers
│   └── repositories/    # SupabaseAuthRepository, FoodRepository, ReservationRepository, PGProfileRepository
├── features/
│   ├── auth/            # Welcome, Role Selection, Customer & Owner Auth, Password Reset, Confirmation
│   ├── customer/        # Food Home Feed, Food Detail, Reservation Flow, Digital Pass, Profile
│   ├── owner/           # PG Dashboard, Add Meal, Registration, Pending Review, QR Verification Modal
│   ├── admin/           # Mobile Admin Quick-View Dashboard
│   └── common/          # Metric cards, status badges, shared widgets
├── models/              # UserModel, FoodListing, Reservation, UserRole, PGProfile
├── providers/           # auth_provider, food_provider, reservation_provider, location_provider
└── main.dart            # Application initialization with Supabase
```

---

## 🧪 Testing

Run the automated test suite (57 tests):

```bash
flutter test
```

### Test Coverage:
- `test/auth_privacy_test.dart`: Role isolation, authentication flow, session persistence.
- `test/food_marketplace_test.dart`: Portion reservation logic, sold-out checks, category filtering.
- `test/location_distance_test.dart`: Haversine formula calculation, radius filtering.
- `test/semantics_diagnostics_test.dart`: Flutter semantics and layout integrity.
- `test/widget_test.dart`: UI navigation and smoke testing.

---

## 📦 Building for Production

### Android Release APK:
```bash
flutter build apk --release
```
*Output: `build/app/outputs/flutter-apk/app-release.apk`*

### Android App Bundle (Play Store):
```bash
flutter build appbundle --release
```
*Output: `build/app/outputs/bundle/release/app-release.aab`*
