# 💻 ExtraBite Admin — Web Operations Console

The official administrative operations and moderation portal for **ExtraBite**, built with Flutter Web, Riverpod, and Supabase.

---

## 🌟 Overview

ExtraBite Admin is a desktop-optimized web application enabling platform administrators to review and verify PG owner registrations, moderate live food listings, monitor active orders, triage safety incident reports, manage user accounts, and view platform sustainability metrics.

---

## 🚀 Key Modules & Capabilities

1. **Dashboard Overview**: Live KPI summary (total users, registered & verified PGs, active meals, meals rescued, estimated CO₂ reduction).
2. **PG Verification**: Inspection queue for pending PG properties with FSSAI document review, location checking, and 1-click Approve / Reject with custom rejection feedback.
3. **PG Detail Review**: In-depth property inspection view with contact info, photo gallery, coordinates, and full audit trail.
4. **Food Listings Moderation**: Real-time listing of active meals across all PGs with instant moderation toggle.
5. **Reservations Feed**: Live feed of active, completed, and cancelled customer orders.
6. **Safety & Reports**: Safety incident reports triage center with severity markers, contact resolution notes, and status updates.
7. **User Management**: User directory with role filtering, detail inspection modals, and account suspension controls.
8. **Analytics & Impact**: Environmental and operational analytics with meal rescue trends and carbon footprint calculations.
9. **Platform Settings**: Campus operational radius defaults, FSSAI verification requirements, and platform policies.

---

## 🛠️ Architecture

* **State Management**: [Riverpod 2.x](https://riverpod.dev)
* **Navigation**: [GoRouter 14.x](https://pub.dev/packages/go_router)
* **Design System**: Pixel-accurate Stitch/HTML design implementation with responsive desktop sidebar layout.
* **Backend**: [Supabase Flutter SDK](https://pub.dev/packages/supabase_flutter) with PostgreSQL RLS security.

---

## 📂 Project Structure

```
lib/
├── app/
│   ├── router/          # Web routing with admin auth protection
│   └── theme/           # Admin color palette, cards, and data table tokens
├── core/
│   ├── config/          # Centralized AppConfig (authoritative Supabase endpoint)
│   └── repositories/    # AdminRepository with PostgreSQL moderation queries
├── features/
│   ├── auth/            # Admin Login Gate
│   └── dashboard/
│       ├── screens/     # Overview, Verification, PG Detail, Food, Orders, Reports, Users, Analytics, Settings
│       └── widgets/     # Rejection modal, detail inspection sheets, metric cards
├── models/              # AdminActivityItem, AdminFoodListing, AdminReport, AdminReservation, PGProfile, UserModel
├── providers/           # admin_provider (StateNotifier with real Supabase actions), auth_provider
└── main.dart            # Web App Entrypoint
```

---

## 🧪 Testing

Run the automated integration test suite (12 tests):

```bash
flutter test
```

### Verified Test Cases:
- Admin login authentication gate and non-admin email rejection.
- Overview metrics loading with real database counts.
- PG verification queue rendering and detailed inspection.
- 1-Click PG approval and rejection with feedback update.
- User management search and suspension toggling.
- Food listing visibility moderation toggling.
- Live reservations feed rendering and detail inspection.
- Safety report resolution with administrator notes.
- Analytics and platform settings tabs rendering.

---

## 📦 Building for Production

### Web Release Build:
```bash
flutter build web --release
```
*Output: `build/web/`*
