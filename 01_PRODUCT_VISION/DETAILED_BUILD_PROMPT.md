# ExtraBite — Master Build Prompt

Build a polished, production-quality, mobile-first full-stack web application called **ExtraBite**.

## Product mission

ExtraBite connects verified PGs, hostels, and messes that have freshly prepared surplus food with nearby customers who can reserve that food at a discounted price. The product reduces food waste and makes affordable meals easier to find locally.

**Product tagline:** “Good food shouldn’t go to waste.”

Build a real, interactive application—not a static mockup. Use working forms, navigation, validation, persistent data where supported, role-based access, realistic seeded data, empty/loading/success/error states, and responsive layouts.

## Non-negotiable payment rule

This is not an online-payment product. **Do not include any payment processor, payment gateway, checkout, UPI, Razorpay, card payment, wallet, payment link, payment intent, or online payment button.**

Customers reserve food in the application and pay the PG/hostel owner directly when collecting it. In every relevant view, use the text **“Pay at pickup”**. The system can store `amount_to_collect` and a pickup-confirmation status, but it must never process or store a digital payment.

## Users and permissions

Create these three roles:

1. **Customer** — discovers nearby listings, reserves food, cancels eligible reservations, manages favourites, collects food, and reviews completed reservations.
2. **PG / Hostel Owner** — registers a property, waits for verification, publishes surplus food after verification, manages listings, checks reservations, and confirms collection using a QR or pickup code.
3. **Admin** — reviews and approves/rejects owner registrations, manages users and listings, handles complaints, and views platform analytics.

Enforce role-based access. Owners can only manage their own property, listings, and reservations. Only verified owners can publish listings. Only admins can change a property verification state.

## Design direction

Create a warm, friendly, trustworthy food marketplace experience.

- Mobile-first; optimise all customer and owner flows for a phone width before expanding responsively to tablet and desktop.
- Use a warm orange/coral primary colour, a food-safety/fresh green accent, cream or white surfaces, dark readable text, and restrained soft shadows.
- Use rounded cards, large tappable controls, clear status chips, verified badges, location indicators, food imagery, and highly legible INR prices.
- Give the admin panel a more information-dense desktop layout while remaining usable on smaller screens.
- Do not make it look like a generic e-commerce checkout. It is a local food-rescue/reservation service.
- Use accessible contrast, labelled inputs, keyboard navigation, visible focus states, and helpful validation errors.

Use realistic Indian sample content: local PG and hostel names, INR amounts, Indian dishes, realistic pickup times, and a plausible city map. Show food prices such as ₹30, ₹35, and ₹45.

## Required app screens and flows

### 1. Welcome and role selection

The first screen must show:

- `Welcome to ExtraBite 🍱`
- `Good food shouldn’t go to waste.`
- `How do you want to use ExtraBite?`

Provide two prominent role cards:

- `🏠 PG / Hostel Owner` — `List your extra food`
- `👤 Customer` — `Find affordable food near you`

The visitor must choose a role before starting the relevant onboarding flow. Include a clear route to sign in for returning users.

### 2. Customer registration and onboarding

Create an account screen with:

- Full name
- Mobile number
- Email
- Password
- Confirm password

Ask for location with this copy: `Allow ExtraBite to find food near you?`

Provide both:

- `Allow Location` — uses browser/device geolocation after consent.
- `Enter Location Manually` — lets a customer select/address-search a location or enter coordinates in a friendly way.

Collect preferences:

- Food preference: Vegetarian, Non-Vegetarian, Both
- Price preference: Under ₹30, ₹30–₹50, ₹50–₹100, Any price

CTA: `Start Finding Food`.

### 3. Customer home and local discovery

Create the main customer home screen with:

- Heading: `Extra Food Near You`
- Current location indicator
- Search input with placeholder: `Search food or PG`
- Category chips: Breakfast, Lunch, Dinner, Vegetarian, Under ₹30
- Sort controls: Distance, Price, Rating, Pickup Time, Availability
- List/map toggle
- A clear, editable radius filter

#### Mandatory radius behaviour

The default discovery radius is **2 km**. Offer radius buttons or a compact selector for **1 km, 2 km, 5 km, and 10 km**.

When the selected radius is **2 km**, show only food listings from **verified** PGs/hostels/messes whose property coordinates are within 2 km of the customer’s current or manually selected location. Do not merely label far-away results as nearby: filter the actual dataset based on latitude and longitude.

- Use a proper geographic distance calculation such as the Haversine formula or a database geospatial query.
- Sort by shortest distance by default.
- Display a formatted distance on every card, such as `📍 0.5 km away`.
- Refresh both map markers and list results immediately when the radius changes.
- Show a visible summary, for example: `Showing food within 2 km`.
- If zero listings meet the filter, show: `No extra food found within 2 km. Try increasing your search radius.`
- Search, category, preference, price, sort, and radius filters should work together.

Each food card should show:

- Food image
- PG/hostel name
- Verified owner badge
- Food name
- Veg or non-veg badge
- Original price with strike-through when discounted
- ExtraBite price in INR and a percentage-off badge
- Portions available
- Distance
- Pickup window
- `View Details` button

Seed realistic listings including:

| Property | Listing | Original | ExtraBite | Portions | Distance | Pickup |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| Sri Sai PG | Rice + Dal + Curry | ₹60 | ₹30 | 12 | 0.5 km | 7:30 PM–9:30 PM |
| Lakshmi Hostel | Veg Pulao | ₹70 | ₹35 | 8 | 1.2 km | 7:00 PM–9:00 PM |
| Vijaya PG | Chapati + Paneer Curry | ₹90 | ₹45 | 6 | 2.0 km | 8:00 PM–10:00 PM |

Add a few additional records outside 2 km so that the radius selector can be demonstrated and tested. Seed food imagery from safe placeholders or a stock/image service that is appropriate to the project.

### 4. Food detail page

Build a rich detail screen containing:

- Hero food image
- Food name
- PG/hostel name and verified badge
- Average rating and review count
- Description
- Ingredients
- Allergen warnings
- Category and veg/non-veg classification
- Prepared time
- Pickup start and end times
- Consume-before time
- Current portions available
- Original price, ExtraBite price, and discount percentage
- Quantity stepper using `[-] 1 [+]`, limited by availability
- Dynamic total amount

The primary CTA is `Reserve Food`. There must be no payment CTA.

Disable reservation with a clear reason when a listing is expired, sold out, or outside the currently selected discovery radius.

### 5. Reservation and pickup-code flow

On a successful reservation:

- Generate a unique human-readable order ID, for example `#EB10293`.
- Generate a unique QR code and a short fallback pickup code.
- Atomically reduce available portions and prevent overbooking.
- Create a `reserved` reservation record.

Show a confirmation screen with this information:

- `Reservation Confirmed 🎉`
- Order ID
- Food name
- Quantity
- Total amount to collect
- `Payment: Pay at pickup`
- Pickup property name and address
- Pickup time
- QR code and backup pickup code

Include these messages exactly or very closely:

`Show this QR code to the PG owner when collecting your food.`

`Payment must be made directly to the PG/hostel at pickup.`

### 6. Customer navigation and reservations

Use a mobile bottom navigation with:

- Home
- Explore
- Reservations
- Favorites
- Profile

The Reservations screen must have tabs for:

- Active Reservations
- Completed Reservations
- Cancelled Reservations

Each reservation card must show order ID, food, property, quantity, amount to pay, pickup window, status, and a QR/pickup code for active reservations.

Use status chips:

- `🟡 Reserved`
- `🟢 Picked Up`
- `🔴 Cancelled`

Allow customer cancellation only before the listing’s configured cancellation cutoff. A cancelled reservation must restore the inventory quantity safely. Show clear confirmation before cancelling.

### 7. Owner registration and verification

Create an owner registration form with the following owner fields:

- Full name
- Mobile number
- Email
- Password
- Confirm password

Create property fields:

- PG / Hostel name
- Type: PG, Hostel, Mess
- Full address
- City
- State
- Pincode
- Map/GPS location and latitude/longitude
- Number of residents
- Contact number
- WhatsApp number

Require upload fields for:

- Owner ID
- PG/hostel proof
- Property photographs

Use CTA: `Register PG`.

After submission, show: `Registration submitted successfully.` and status: `⏳ Verification Pending`.

Unverified owners can edit registration information but cannot publish listings. Provide a clear pending/rejected/approved status experience.

### 8. Owner dashboard and food management

After approval, show an owner dashboard titled, for example: `Welcome, Sri Sai PG`.

Create metric cards for:

- `🍱 Active Food` — e.g. 12 portions
- `📦 Today’s Reservations` — e.g. 18
- `💰 Today’s Expected Revenue` — e.g. ₹540
- `♻️ Meals Rescued` — e.g. 32

Create prominent actions:

- `+ Add Surplus Food`
- `View Reservations`
- `Verify Pickup`
- `Analytics`

Use owner bottom navigation:

- Dashboard
- Food
- Reservations
- Analytics
- Profile

The Add Surplus Food form must collect:

- Food name
- Description
- Food image
- Category: Breakfast, Lunch, Dinner, Snacks
- Vegetarian / Non-Vegetarian
- Portions available
- Original price
- ExtraBite selling price
- Prepared time
- Pickup start time
- Pickup deadline
- Consume-before time
- Cancellation cutoff time
- Ingredients
- Allergens

Calculate and display the discount automatically, for example:

`Original Price: ₹60`  
`ExtraBite Price: ₹30`  
`50% OFF`

CTA: `Publish Food`.

Prevent publication by unverified owners. Automatically hide/expire a listing after its pickup deadline or consume-before time. Never expose expired food in customer discovery.

### 9. Owner pickup verification

Create a secure `Verify Pickup` flow where the owner can scan a customer QR code or manually enter their pickup code.

After resolving a code, show:

- Customer name
- Order ID
- Food item
- Quantity
- `Amount to collect: ₹60` or the calculated total
- `Payment status: Pay at Pickup`

The owner collects money directly from the customer outside the app. Then the owner presses `Confirm Pickup`.

Confirmation must:

- Mark the reservation as `picked_up` / `completed`.
- Make the QR/code unusable for another pickup.
- Enable the customer review flow.
- Be idempotent: scanning or confirming the same completed code again must not create duplicate actions.

### 10. Ratings, reviews, safety, and reliability

After pickup, customers can:

- Rate food quality from 1 to 5 stars
- Rate the PG experience from 1 to 5 stars
- Add a written review
- Report unsafe food

Every listing visibly includes prepared time, pickup deadline, consume-before time, food category, veg/non-veg state, and allergens. Make allergy information prominent.

Allow the system/admin to flag customers who repeatedly reserve and do not collect. Provide a simple policy indicator in the customer profile, not a punitive unexplained lockout.

### 11. Admin panel

Create a responsive admin dashboard with a desktop-focused sidebar and data tables/cards. Include:

- Pending owner-verification queue with document viewer
- Approve/reject PG/hostel registrations and record a reason
- Customer, owner, and property management
- Food-listing moderation
- Reservation management
- Complaint/unsafe-food report handling
- Account suspension capability
- Platform statistics

Analytics should include:

- Total properties and verified properties
- Active listings
- Today’s reservations
- Completed pickups
- Cancelled/no-show rate
- Meals rescued
- Estimated food-waste reduction
- Expected revenue for owners

## Technical expectations

Use the platform’s preferred full-stack architecture, database, auth, file storage, maps, and QR-generation capabilities. Keep configuration in environment variables. Do not hard-code secrets.

Implement these core entities and relationships:

- Users: identity, authentication, role, profile, location preferences, account status
- Properties: owner, name, type, address, geolocation, contact details, verification status
- Verification documents: property, type, file reference, review state
- Food listings: property, availability, pricing, dietary and safety fields, pickup schedule, lifecycle state
- Reservations: customer, listing, quantity, amount_to_collect, order ID, QR/pickup code, lifecycle timestamps
- Reviews: completed reservation, food rating, property rating, comment
- Complaints: reporter, listing/property, category, details, status
- Favorites: customer and listing/property reference

Use safe server-side authorization and validation for every sensitive action. Do not trust client-side checks alone.

Required lifecycle constraints:

- A listing belongs to one verified property.
- The available portion count cannot go below zero.
- A customer cannot reserve expired or sold-out food.
- Cancellation restores portions only when an active reservation is successfully cancelled before cutoff.
- A pickup code can only complete one valid reserved reservation.
- A customer can review only a completed reservation and only once.
- Expired listings cannot be reserved or returned by customer search.
- Customer discovery only returns verified properties within the chosen radius.

## Required final experience

The complete flow must work end to end:

Owner registers → Admin verifies property → Owner publishes surplus food → Customer finds verified food within selected radius (default 2 km) → Customer reserves food → QR/pickup code is generated → Customer goes to the property → Customer pays the owner directly at pickup → Owner verifies QR/code and confirms pickup → Reservation completes → Customer rates food.

Finish with a coherent, polished interface and make all primary flows testable through seeded accounts and data. Do not omit pages, functionality, data validation, responsive design, the accurate 2 km radius filter, safety information, or the no-online-payment restriction.
