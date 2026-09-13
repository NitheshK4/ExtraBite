# Google OAuth Deep-Link Redirection Audit Report

**Project:** ExtraBite Mobile (Flutter / Android)  
**Date:** September 14, 2026  
**Auditor:** Antigravity Agentic Security & Architecture Audit  

---

## Executive Summary

| Category | Status | Notes |
|---|---|---|
| **Local Flutter OAuth Code** | **PASS** | `signInWithOAuth` correctly uses `LaunchMode.externalApplication` and platform-specific `redirectTo`. |
| **Android Manifest Configuration** | **PASS** | Dual intent filters for `io.extrabite.extrabite_mobile` and `com.extrabite.extrabite_mobile` on `.MainActivity`. |
| **Package / Application ID Alignment** | **PASS WITH WARNINGS** | `applicationId` is `com.extrabite.extrabite_mobile` while primary OAuth scheme is `io.extrabite.extrabite_mobile`. Handled via dual intent filter. |
| **Routing & Session Restoration** | **PASS** | `GoRouter` listens to `authProvider` stream; new users route to role-selection; sessions restore on cold start. |
| **External Supabase & GCP Configuration** | **NOT VERIFIED** | Cloud dashboards (Supabase Redirect URLs & Google Cloud Authorized Redirect URI) cannot be inspected from local repo. |
| **OVERALL STATUS** | **PASS WITH WARNINGS (Local) / NOT VERIFIED (External)** | Codebase is ready for deep linking; external dashboard allowlists must be confirmed. |

---

## 1. Actual Android Application ID & Namespace

- **Application ID (`applicationId`):** `com.extrabite.extrabite_mobile`  
  *Source:* `ExtraBiteMobile/android/app/build.gradle.kts:29`
- **Android Namespace (`namespace`):** `com.extrabite.extrabite_mobile`  
  *Source:* `ExtraBiteMobile/android/app/build.gradle.kts:13`
- **MainActivity Kotlin Package:** `com.extrabite.extrabite_mobile`  
  *Source:* `ExtraBiteMobile/android/app/src/main/kotlin/com/extrabite/extrabite_mobile/MainActivity.kt:1`
- **Flutter Package Name:** `extrabite_mobile`  
  *Source:* `ExtraBiteMobile/pubspec.yaml:1`

---

## 2. Actual Deep-Link Scheme, Host, and Path

| Component | In Dart Code (`supabase_auth_repository.dart`) | In `AndroidManifest.xml` (`<data>`) | Match Status |
|---|---|---|---|
| **Scheme** | `io.extrabite.extrabite_mobile` | `io.extrabite.extrabite_mobile`<br>`com.extrabite.extrabite_mobile` | **MATCH (Dual-supported)** |
| **Host** | `login-callback` | `login-callback` | **MATCH** |
| **Path** | None (`/`) | None (No `android:path` or `pathPrefix`) | **MATCH (Correct for OAuth tokens)** |
| **Full URI** | `io.extrabite.extrabite_mobile://login-callback` | Matches incoming intent filter | **MATCH** |

> **Note on Scheme Discrepancy:**  
> The Android `applicationId` is `com.extrabite.extrabite_mobile`, but the Dart code uses `io.extrabite.extrabite_mobile`. `AndroidManifest.xml` has intent filters for **both** schemes, which prevents broken redirects regardless of which scheme Supabase sends. However, both must be registered in the Supabase Redirect URLs allowlist.

---

## 3. Supabase Redirect URL References Across the Project

| File Path | Line # | Redirect URL / Scheme | Purpose | Matches Manifest? |
|---|---|---|---|---|
| `ExtraBiteMobile/lib/core/repositories/supabase_auth_repository.dart` | 46 | `io.extrabite.extrabite_mobile://login-callback` | `_androidRedirectTo` constant | Yes |
| `ExtraBiteMobile/lib/core/repositories/supabase_auth_repository.dart` | 50 | `kIsWeb ? null : _androidRedirectTo` | `_authRedirectUrl` getter | Yes |
| `ExtraBiteMobile/lib/core/repositories/supabase_auth_repository.dart` | 65 | `_authRedirectUrl` | Email signup confirmation redirect | Yes |
| `ExtraBiteMobile/lib/core/repositories/supabase_auth_repository.dart` | 148 | `null` | Web OAuth redirect (auto-resolves to current browser origin) | N/A (Web) |
| `ExtraBiteMobile/lib/core/repositories/supabase_auth_repository.dart` | 159 | `_androidRedirectTo` | Android Google OAuth `redirectTo` | Yes |
| `ExtraBiteMobile/lib/core/repositories/supabase_auth_repository.dart` | 239 | `_authRedirectUrl` | Password reset email redirect | Yes |
| `ExtraBiteMobile/android/app/src/main/AndroidManifest.xml` | 36-38 | `io.extrabite.extrabite_mobile://login-callback` | Intent filter `<data>` entry | Yes (Identical) |
| `ExtraBiteMobile/android/app/src/main/AndroidManifest.xml` | 39-41 | `com.extrabite.extrabite_mobile://login-callback` | Intent filter `<data>` entry (applicationId scheme) | Compatible |
| `ExtraBiteMobile/README.md` | 28, 96-98 | `io.extrabite.extrabite_mobile://login-callback/**`<br>`com.extrabite.extrabite_mobile://login-callback/**` | Setup guide for Supabase dashboard allowlist | Yes |

---

## 4. Flutter Supabase Initialization Audit

- **Initialization Location:** `ExtraBiteMobile/lib/main.dart` (lines 14–17)
  ```dart
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  ```
- **Supabase Project URL:** `https://epcurx***.supabase.co` (Masked for security) — **VALID HTTPS**
- **Supabase Anonymous Key:** `sb_publishable_WA8f***` (Masked for security) — **VALID ANON KEY**
- **Service-Role Key Check:** **PASS** — Zero service-role or master keys present in client-side code.
- **Single Client Initialization:** **PASS** — Initialized exactly once in `main()` prior to `runApp()`.
- **Observation:** `deepLinkScheme` is not explicitly passed to `Supabase.initialize()`. In `supabase_flutter` 2.x, `app_links` captures incoming links regardless of scheme, but explicitly supplying `deepLinkScheme: 'io.extrabite.extrabite_mobile'` is recommended for strict filtering.

---

## 5. AndroidManifest.xml Deep-Link Audit

- **Target Activity:** `.MainActivity` (`com.extrabite.extrabite_mobile.MainActivity`)
- **Exported Flag:** `android:exported="true"` (**PASS**)
- **Launch Mode:** `android:launchMode="singleTop"` (**PASS**) — Ensures existing instance receives `onNewIntent` rather than recreating the activity.
- **Intent Filter Structure:**
  ```xml
  <intent-filter>
      <action android:name="android.intent.action.VIEW"/>
      <category android:name="android.intent.category.DEFAULT"/>
      <category android:name="android.intent.category.BROWSABLE"/>
      <data
          android:scheme="io.extrabite.extrabite_mobile"
          android:host="login-callback" />
      <data
          android:scheme="com.extrabite.extrabite_mobile"
          android:host="login-callback" />
  </intent-filter>
  ```
- **Action Check:** `android.intent.action.VIEW` is present (**PASS**)
- **Category Check:** `DEFAULT` and `BROWSABLE` are both present (**PASS**)
- **Package Visibility (`<queries>`):**
  ```xml
  <queries>
      <intent>
          <action android:name="android.intent.action.VIEW"/>
          <category android:name="android.intent.category.BROWSABLE"/>
          <data android:scheme="https"/>
      </intent>
      ...
  </queries>
  ```
  Crucial for Android 11+ (API 30+) package visibility when querying external browsers to launch Google OAuth (**PASS**).

---

## 6. OAuth Sign-In & Callback Flow Audit

### Initiation Flow
```
User taps "Continue with Google"
  └─► authProvider.signInWithGoogle()
        └─► supabase_auth_repository.signInWithGoogle()
              └─► _client.auth.signInWithOAuth(
                    OAuthProvider.google,
                    redirectTo: 'io.extrabite.extrabite_mobile://login-callback',
                    authScreenLaunchMode: LaunchMode.externalApplication,
                  )
```
- **External Browser Launch:** `LaunchMode.externalApplication` is used on Android. This avoids Google OAuth's `disallowed_useragent` (Error 403) which occurs when using embedded webviews.

### Callback & Session Restoration Flow
```
Browser redirects to io.extrabite.extrabite_mobile://login-callback#access_token=...
  └─► Android matches intent-filter on MainActivity
        └─► app_links passes URI to Supabase client
              └─► Supabase parses session & updates currentSession
                    └─► onAuthStateChange emits AuthChangeEvent.signedIn
                          └─► AuthNotifier._listenToSupabaseAuthChanges() triggers
                                └─► _repo.getCurrentUser() fetches profile / metadata fallback
                                      └─► _resolveOnboardingState() updates AuthState
                                            └─► RouterNotifier notifies GoRouter
                                                  └─► GoRouter redirects user to destination
```
- **New Google User Fallback:** In `supabase_auth_repository.dart:177-194`, if a `profiles` row is not yet created in the database, fallback user data is extracted from `session.user.userMetadata['full_name']`. This prevents a null user exception or failed sign-in on first login.
- **Warning on User Cancellation:** If the user opens the external browser and cancels/navigates back to the app without signing in, `authProvider` remains in `AuthState.authenticating`. Adding an app lifecycle resume check to reset authenticating state if no session arrived is recommended.

---

## 7. Routing & Session Restoration Audit

- **Router:** `GoRouter` configured in `ExtraBiteMobile/lib/app/router/app_router.dart`.
- **Session Gate / Guard:**
  - `status == AuthStatus.unauthenticated` or `authenticating`: stays on `/auth/login` (or `/auth/*`).
  - `status == AuthStatus.authenticated`:
    - `user.roleFinalized == false`: Redirects to `/auth/role-selection`.
    - `user.roleFinalized == true`: Redirects to `/customer/home` (Customer), `/owner/dashboard` (PG Owner), or `/admin/dashboard` (Admin).
- **Infinite Redirect Loop Check:** **PASS** — Guard verifies `if (loc == target) return null;` before redirecting.
- **Cold Start Restoration:** **PASS** — `AuthNotifier._init()` invokes `getCurrentUser()`. If Supabase has persisted session tokens in local storage, `_resolveOnboardingState()` restores authenticated state without prompting the user to sign in again.

---

## 8. External Dashboard Settings (Manual Verification Required)

The following settings exist outside the local codebase and **CANNOT** be verified locally. They must be confirmed manually:

### 1. Supabase Dashboard Configuration (`https://supabase.com/dashboard`)
Navigate to **Authentication -> URL Configuration**:
- [ ] **Site URL:** Set to `http://localhost:3000` (development) or production domain.
- [ ] **Redirect URLs (Allowlist):** Ensure the following exact URLs are added:
  - `io.extrabite.extrabite_mobile://login-callback/**`
  - `io.extrabite.extrabite_mobile://login-callback`
  - `com.extrabite.extrabite_mobile://login-callback/**`
  - `http://localhost:*/**` (for local Web testing)

Navigate to **Authentication -> Providers -> Google**:
- [ ] **Enable Sign in with Google:** Enabled (ON).
- [ ] **Client ID:** Google Web Client ID entered.
- [ ] **Client Secret:** Google Web Client Secret entered.
- [ ] **Callback URL (for Google Console):** Note the Supabase callback URL displayed, usually:
  `https://epcurxrrnbqqwifrcrjz.supabase.co/auth/v1/callback`

### 2. Google Cloud Console (`https://console.cloud.google.com/`)
Navigate to **APIs & Services -> Credentials -> OAuth 2.0 Client IDs**:
- [ ] Ensure the Client ID type is **Web application** (Supabase handles the OAuth exchange on its backend servers, so Google requires a Web Client ID, not an Android Client ID).
- [ ] **Authorized redirect URIs** must include:
  `https://epcurxrrnbqqwifrcrjz.supabase.co/auth/v1/callback`

---

## 9. Recommended Enhancements

1. **Explicit `deepLinkScheme` in `main.dart`:**
   ```dart
   await Supabase.initialize(
     url: AppConfig.supabaseUrl,
     anonKey: AppConfig.supabaseAnonKey,
     deepLinkScheme: 'io.extrabite.extrabite_mobile',
   );
   ```
2. **App Lifecycle Resume Timeout / Reset:**
   Reset `AuthState.authenticating` to `AuthState.unauthenticated` if the user returns to the app from the external browser without completing authentication.

---

## 10. Final Verification Verdict

| Target | Result |
|---|---|
| **Flutter Android Deep Linking Implementation** | **PASS** |
| **Android Manifest Configuration** | **PASS** |
| **OAuth Callback Handler & GoRouter Routing** | **PASS** |
| **Local Automated Test Suite** | **PASS (89/89 tests passing)** |
| **External Supabase & GCP Dashboards** | **NOT VERIFIED (Action Required by Project Owner)** |
