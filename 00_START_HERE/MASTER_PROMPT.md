# ExtraBite — Client-Ready Master Prompt

Copy everything below this line into Antigravity. Build the application exactly as specified. Do not simplify the key flows, replace them with placeholders, or add online payment.

---

Build a complete, client-ready mobile-first application named **ExtraBite**.

## A. What this app does

ExtraBite helps people find affordable fresh surplus food from nearby PGs, hostels, and messes. A PG owner publishes leftover freshly prepared meals at a lower price. A nearby customer reserves a meal in the app, goes to the property, pays the owner directly at pickup, and shows a QR code or pickup code to collect the food.

The purpose of the app is:

1. Reduce food waste.
2. Help customers find low-cost meals nearby.
3. Help PGs and hostels recover some cost from surplus food.

Use this exact tagline in the app:

**Good food shouldn’t go to waste.**

## B. Most important business rule — no online payment

This rule is mandatory and must not be changed:

**ExtraBite does not accept online payments.**

The customer only reserves the meal in the app. The customer pays the PG/hostel owner directly when collecting the food.

Do NOT build any of the following:

- UPI payment
- Razorpay
- Card payment
- Wallet payment
- Payment gateway
- Checkout page
- Pay Now button
- Payment API or payment webhooks
- Payment transaction history

On every reservation-related page, show the text:

**Payment: Pay at pickup**

The app may show `Amount to pay: ₹60`, but this amount is only for the owner to collect directly from the customer at pickup.

## C. Required user types

Build three separate roles and dashboards:

1. **Customer** — finds food, reserves it, collects it, and gives a review.
2. **PG / Hostel Owner** — registers a property, publishes surplus food after approval, and verifies collection.
3. **Admin** — verifies PG/hostel registrations, manages the platform, and handles complaints.

## D. Visual style

Make it look like a trustworthy, polished food-rescue marketplace—not a generic ecommerce site.

- Build for mobile first, with responsive desktop screens.
- Use orange/coral as the primary colour, green for verified/success states, and white/cream backgrounds.
- Use food photographs, rounded food cards, clear price displays, prominent discount badges, and large buttons.
- Use Indian Rupees (`₹`) and realistic Indian names, food, and locations.
- Make all buttons work. Do not create static screens only.
- Show loading, empty, error, and success states where needed.

## E. Screen 1: Welcome and role selection

The very first screen must contain:

`Welcome to ExtraBite 🍱`

`Good food shouldn’t go to waste.`

`How do you want to use ExtraBite?`

Show two large selectable cards:

| Card | Title | Subtitle | Action |
| --- | --- | --- | --- |
| Owner card | `🏠 PG / Hostel Owner` | `List your extra food` | Opens owner registration/sign-in |
| Customer card | `👤 Customer` | `Find affordable food near you` | Opens customer registration/sign-in |

Also show a small `Already have an account? Sign in` link.

## F. Customer registration and location setup

Create a customer account form with:

- Full name
- Mobile number
- Email
- Password
- Confirm password

Then show this location question:

`Allow ExtraBite to find food near you?`

Show two choices:

1. `Allow Location` — request device/browser GPS permission and save the selected latitude and longitude.
2. `Enter Location Manually` — provide an address/city search and a selectable map pin; save its latitude and longitude.

Also ask for:

- Food preference: Vegetarian, Non-Vegetarian, Both
- Price preference: Under ₹30, ₹30–₹50, ₹50–₹100, Any price

CTA button: `Start Finding Food`

## G. Customer Home — food available nearby

After onboarding, open the customer home screen.

It must show:

- Heading: `Extra Food Near You`
- Current selected location with an edit button
- Search bar: `Search food or PG`
- Category/filter chips: Breakfast, Lunch, Dinner, Vegetarian, Under ₹30
- Sort control: Distance, Price, Rating, Pickup Time, Availability
- List / Map switcher
- Radius filter described below

### Exact radius requirement — this is mandatory

The default customer search radius is **2 km**.

Show a clear filter control with these options:

`1 km` | `2 km` | `5 km` | `10 km`

When the customer has selected **2 km**, the app must show **only** food from verified PGs, hostels, and messes that are located at a maximum distance of **2.0 km** from the customer’s selected location.

For example:

- A PG at 0.5 km: show it.
- A hostel at 1.2 km: show it.
- A PG at exactly 2.0 km: show it.
- A PG at 2.1 km: do not show it.
- An unverified PG at 0.3 km: do not show it.

Calculate distance from actual latitude/longitude values. Use a real geographic calculation (Haversine formula or database geospatial query). Do not fake this filter by manually tagging cards with distance.

The selected radius must update:

- The food-card list
- Map markers
- Result count
- Text such as: `Showing food within 2 km`

Default sort order is distance from nearest to farthest.

If there are no qualifying listings, show:

`No extra food found within 2 km. Try increasing your search radius.`

All filters must combine correctly. For example, a customer choosing `2 km + Vegetarian + Under ₹30` should see only food matching every selected condition.

### Food cards

Show food in attractive, compact cards. Every card contains:

- Food image
- PG/hostel name
- Green `✓ Verified` badge
- Food name
- Vegetarian or Non-Vegetarian badge
- Original price with strike-through if discounted
- ExtraBite selling price
- Discount badge, for example `50% OFF`
- Portions still available
- Distance, for example `📍 0.5 km away`
- Pickup time range
- `View Details` button

Use these sample results around the demo customer location:

| PG / Hostel | Food | Original price | ExtraBite price | Portions | Distance | Pickup |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| Sri Sai PG | Rice + Dal + Curry | ₹60 | ₹30 | 12 | 0.5 km | 7:30 PM–9:30 PM |
| Lakshmi Hostel | Veg Pulao | ₹70 | ₹35 | 8 | 1.2 km | 7:00 PM–9:00 PM |
| Vijaya PG | Chapati + Paneer Curry | ₹90 | ₹45 | 6 | 2.0 km | 8:00 PM–10:00 PM |

Also add at least two verified demo properties farther than 2 km. They must not appear at the default 2 km radius. They should appear when the user changes the radius to 5 km or 10 km.

## H. Food Details screen

When the customer taps `View Details`, open a full listing page with:

- Large food image
- Food name
- PG/hostel name
- `✓ Verified` badge
- Rating and number of reviews
- Description
- Ingredients
- Allergens
- Food category
- Vegetarian / Non-Vegetarian label
- Prepared at time
- Pickup start and end time
- Consume-before time
- Portions available
- Original price
- ExtraBite price
- Discount percentage

Add a quantity selector:

`[-] 1 [+]`

The quantity cannot be greater than available portions or lower than 1.

Show:

`Total: ₹[calculated amount]`

Use this primary action:

`Reserve Food`

There must be no payment button on this page.

Do not allow reservation if the listing is sold out, expired, past pickup deadline, or unsafe to consume. Explain why with a helpful message.

## I. Reservation confirmation

When the customer presses `Reserve Food`:

1. Validate requested quantity.
2. Decrease available portions safely so two people cannot buy the same final portion.
3. Create a unique order ID, for example `#EB10293`.
4. Generate a unique QR code.
5. Generate a short backup pickup code.
6. Create a reservation with status `Reserved`.

Open a success screen that says:

`Reservation Confirmed 🎉`

Display:

- Order ID: `#EB10293`
- Food
- Quantity
- Total amount to pay
- `Payment: Pay at pickup`
- Pickup location / property name
- Pickup address
- Pickup time
- QR code
- Backup pickup code

Show these instructions:

`Show this QR code to the PG owner when collecting your food.`

`Payment must be made directly to the PG/hostel at pickup.`

## J. Customer navigation and orders

Use this mobile bottom navigation:

`Home` | `Explore` | `Reservations` | `Favorites` | `Profile`

The Reservations screen must have three tabs:

1. Active Reservations
2. Completed Reservations
3. Cancelled Reservations

Every reservation card must show:

- Order ID
- Food name
- PG/hostel name
- Quantity
- Amount to pay at pickup
- Pickup time
- Status
- QR/pickup code for active reservations

Use these statuses:

- `🟡 Reserved`
- `🟢 Picked Up`
- `🔴 Cancelled`

The customer can cancel an active reservation only before the owner’s cancellation cutoff. Ask for confirmation before cancelling. A successful eligible cancellation must add the food quantity back to the listing.

## K. PG / Hostel owner registration

The owner registration flow must collect:

### Owner details

- Full name
- Mobile number
- Email
- Password
- Confirm password

### Property details

- PG / Hostel name
- Type: PG, Hostel, Mess
- Full address
- City
- State
- Pincode
- GPS/map pin with latitude and longitude
- Number of residents
- Contact number
- WhatsApp number

### Verification uploads

- Owner government ID
- PG/hostel ownership or operating proof
- PG/hostel photographs

CTA: `Register PG`

After submission, show:

`Registration submitted successfully.`

`⏳ Verification Pending`

An owner with Pending or Rejected status cannot publish food. An approved owner can publish food.

## L. Owner dashboard

After approval, show an owner dashboard titled:

`Welcome, Sri Sai PG`

Show four key statistics:

- `🍱 Active Food` — example: 12 portions
- `📦 Today’s Reservations` — example: 18
- `💰 Today’s Expected Revenue` — example: ₹540
- `♻️ Meals Rescued` — example: 32

Show action buttons:

- `+ Add Surplus Food`
- `View Reservations`
- `Verify Pickup`
- `Analytics`

Owner bottom navigation:

`Dashboard` | `Food` | `Reservations` | `Analytics` | `Profile`

## M. Add Surplus Food screen

Create a complete listing form with:

- Food name
- Description
- Food image upload
- Category: Breakfast, Lunch, Dinner, Snacks
- Vegetarian / Non-Vegetarian
- Number of portions
- Original price
- ExtraBite selling price
- Prepared time
- Pickup start time
- Pickup deadline
- Consume-before time
- Cancellation cutoff time
- Ingredients
- Allergens

Automatically calculate the discount and show it before publishing:

`Original Price: ₹60`

`ExtraBite Price: ₹30`

`50% OFF`

CTA: `Publish Food`

Rules:

- Only approved properties can publish.
- Food becomes unavailable automatically after pickup deadline or consume-before time.
- Expired food must not appear to customers.
- Food with zero available portions is shown as sold out and cannot be reserved.

## N. Owner pickup verification

The owner needs a screen named `Verify Pickup`.

Give the owner two options:

1. Scan customer QR code.
2. Enter pickup code manually.

When a valid active reservation is found, show:

`Customer: Rahul`

`Order: #EB10293`

`Food: Rice + Dal + Curry`

`Quantity: 2`

`Amount to collect: ₹60`

`Payment status: Pay at Pickup`

The owner collects the cash/direct payment personally outside the app. Then they press:

`Confirm Pickup`

After confirmation:

- Mark the reservation as `Picked Up`.
- Do not allow the code to be used again.
- Move the reservation into completed history.
- Allow the customer to submit a review.

## O. Food safety, reviews, and complaints

Every food listing must visibly include:

- Prepared time
- Pickup deadline
- Consume-before time
- Food category
- Vegetarian / Non-Vegetarian status
- Ingredients
- Allergens

After a completed pickup, allow customers to:

- Give Food Quality rating from 1–5 stars
- Give PG Experience rating from 1–5 stars
- Add a written review

Add a `Report unsafe food` action to listings and completed reservations. The report must be visible to admins.

If a customer repeatedly reserves food but does not collect it, allow the system/admin to flag the account.

## P. Admin panel

Create a secure, desktop-friendly admin panel with:

- Pending verification queue
- Property document viewer
- Approve or reject property registrations, with rejection reason
- Customer management
- Owner/property management
- Food listing management/moderation
- Reservation management
- Complaint and unsafe-food report management
- Account suspension controls
- Analytics dashboard

Admin analytics must show:

- Total PGs/hostels
- Verified properties
- Active listings
- Today’s reservations
- Completed pickups
- Cancellations/no-shows
- Meals rescued
- Estimated food waste reduced
- Expected revenue for property owners

## Q. Required database and security rules

Create persistent records for:

- Users
- Properties / PGs / hostels / messes
- Verification documents
- Food listings
- Reservations
- Reviews
- Complaints
- Favorites

Apply these rules on the server/database side, not only in the UI:

1. Only an admin can approve a property.
2. Only a verified property can publish food.
3. Customer search returns only active, verified, non-expired listings inside the chosen location radius.
4. Available portions can never become negative.
5. Reservation quantity must not exceed availability.
6. A valid cancellation restores portions exactly once.
7. A QR or pickup code can complete only one active reservation.
8. A customer can review only their own completed reservation, and only once.
9. Owners can access only their own property data and reservations.
10. There must be no online payment integration or payment data model.

## R. Final client demonstration flow

Make this complete journey possible with seeded demo accounts and data:

1. Owner registers Sri Sai PG.
2. Admin approves Sri Sai PG.
3. Owner publishes Rice + Dal + Curry for ₹30, with 12 portions.
4. Customer signs in near Sri Sai PG.
5. Customer opens Home and sees the default selected radius: 2 km.
6. Customer sees only verified listings within 2 km.
7. Customer opens the food listing and reserves 2 portions.
8. App creates order `#EB10293`, a QR code, and pickup code.
9. Confirmation shows `Payment: Pay at pickup`.
10. Customer visits Sri Sai PG and pays the owner directly.
11. Owner verifies the QR/code and clicks `Confirm Pickup`.
12. Reservation becomes `Picked Up`.
13. Customer submits a food and PG review.

Deliver a complete, visually polished, responsive application with real page navigation, functional forms, validation, authentication, role permissions, a working radius filter, working QR/pickup flow, and realistic demo data.

Do not deliver a static landing page or mock cards only. Do not omit the customer, owner, or admin flow. Do not add online payment.
