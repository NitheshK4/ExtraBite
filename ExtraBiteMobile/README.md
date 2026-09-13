# 📱 ExtraBite Mobile Application (v1.1.0)

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend%20%26%20Auth-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Architecture](https://img.shields.io/badge/Architecture-Riverpod%20%2B%20GoRouter-FF6F00)](https://riverpod.dev)
[![Tests](https://img.shields.io/badge/Tests-100%25%20Passing-success)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

The official cross-platform mobile client for **ExtraBite** (Android, iOS & Web), built with Flutter, Riverpod, and Supabase.

---

## 🌟 Overview

ExtraBite bridges the gap between campus food providers and hungry students:
* **Students & Campus Residents**: Discover high-quality, freshly prepared surplus meals from nearby university hostels, PGs, and mess facilities at low prices (typically ₹20–₹50) with instant pay-at-counter collection.
* **PG Owners & Hostels**: List excess cooked meals in under 60 seconds, reduce food wastage, recover preparation costs, and verify student collections with instant camera QR scanning.

---

## 🚀 What's New in v1.1.0

1. **Dual-Themed Material 3 Adaptive Design System**:
   - **PG Owner Mode**: Warm Orange palette (`#E65100` primary, `#FFF3E0` container) with storefront branding, business copy, 6-field registration form, and a 3-step onboarding timeline card.
   - **Customer / Personal User Mode**: Emerald Green palette (`#1B5E20` primary, `#E8F5E9` container) with eco leaf branding, meal saving focus, and an interactive 4-bar password strength meter.
2. **Dedicated Android & Web Google OAuth 2.0**:
   - Native Android deep linking (`io.extrabite.extrabitemobile://login-callback`) with Android 11+ browser intent queries.
   - Automatic web browser origin callback resolution.
   - Instant profile metadata fallback for first-time Google sign-ins.
3. **Atomic Inventory Restoration on Cancellation**:
   - Database-level `SECURITY DEFINER` row-locking trigger restores food portion counts and reactivates `sold_out` listings automatically when reservations are cancelled.
4. **Smart Location Search History**:
   - Persistent, isolated location search history per user with automatic deduplication, LRU ordering, and real-time distance sorting.

---

## 🛠️ Architecture & Tech Stack

* **UI Framework**: Flutter 3.24+ (Dart 3.5+)
* **Design System**: Google Stitch semantic tokens, Google Fonts (*Plus Jakarta Sans* & *Inter*), accessible high-contrast palettes, responsive desktop card wrappers.
* **State Management**: [Riverpod 2.x](https://riverpod.dev) (`StateNotifierProvider`, `ProviderScope`, request deduplication).
* **Navigation & Guards**: [GoRouter 14.x](https://pub.dev/packages/go_router) with role onboarding, admin verification, and suspension protection.
* **Backend & Database**: [Supabase Flutter](https://pub.dev/packages/supabase_flutter) + PostgreSQL with Row-Level Security (RLS) policies.
* **Payment Model**: Strict **Pay-at-Pickup** model (no online gateway overhead or lock-ins).

---

## 📂 Project Structure

```
lib/
├── app/
│   ├── router/          # AppRouter with role-based navigation and deep linking
│   └── theme/           # AppColors, AppTheme, typography tokens
├── core/
│   ├── config/          # Centralized AppConfig (Supabase URL, anon key, validation)
│   ├── location/        # LocationService, LocationState & Haversine distance calculations
│   └── repositories/    # SupabaseAuthRepository, FoodRepository, ReservationRepository, PGProfileRepository
├── features/
│   ├── auth/            # Stitch Auth Screen, Role Selection, Forgot Password, Status screens
│   ├── customer/        # Food Discovery Feed, Detail Screen, Reservation Flow, Digital Pass, Profile
│   ├── owner/           # PG Owner Dashboard, Add Meal, Registration, QR Verification Modal
│   ├── admin/           # Admin Operations Quick-Dashboard
│   └── common/          # Metric cards, status badges, shared UI components
├── models/              # UserModel, FoodListing, Reservation, LocationHistoryItem, PGProfile
├── providers/           # auth_provider, food_provider, reservation_provider, location_provider, location_history_provider
└── main.dart            # Flutter application entry point
```

---

## ⚙️ Setup & Configuration

### 1. Prerequisites
- Flutter SDK `>=3.24.0`
- Dart SDK `>=3.5.0`
- Android Studio / VS Code with Flutter extension
- Supabase Project

### 2. Environment Setup
Verify or configure `lib/core/config/app_config.dart` with your Supabase credentials:
```dart
static const String supabaseUrl = 'https://<your-project-ref>.supabase.co';
static const String supabaseAnonKey = '<your-anon-key>';
```

### 3. Google OAuth Setup for Android & Web
1. **Google Cloud Console**:
   - Create an **OAuth 2.0 Web Client ID**.
   - Add Authorized JavaScript Origins: `https://<your-project-ref>.supabase.co`
   - Add Authorized Redirect URIs: `https://<your-project-ref>.supabase.co/auth/v1/callback`
2. **Supabase Dashboard**:
   - Go to **Authentication** → **Providers** → **Google** → Enable and enter Client ID & Secret.
   - Go to **Authentication** → **URL Configuration**:
     - **Site URL**: `io.extrabite.extrabitemobile://login-callback`
     - **Redirect URLs**:
       - `io.extrabite.extrabitemobile://login-callback/**`
       - `io.extrabite.extrabitemobile://login-callback`
       - `http://localhost:*/**` (for local Web testing)

---

## 🧪 Testing & Verification

Run the full automated test suite:

```bash
flutter test
```

### Key Test Suites:
- `test/auth_privacy_test.dart`: Role isolation, authentication flow, data leaks prevention, onboarding guards (7/7 passing).
- `test/location_history_test.dart`: Persistent search history, deduplication, user isolation (9/9 passing).
- `test/reservation_cancellation_test.dart`: Idempotent inventory restoration and concurrency handling (7/7 passing).
- `test/food_marketplace_test.dart`: Portion reservation logic, sold-out checks, category filtering.
- `test/location_distance_test.dart`: Haversine formula calculation, radius filtering (22/22 passing).

---

## 📦 Building for Production

### Android Release APK:
```bash
flutter build apk --release
```
*Output artifact:* `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Google Play Store):
```bash
flutter build appbundle --release
```
*Output artifact:* `build/app/outputs/bundle/release/app-release.aab`

### Flutter Web Release:
```bash
flutter build web --release
```
*Output artifact:* `build/web/`
