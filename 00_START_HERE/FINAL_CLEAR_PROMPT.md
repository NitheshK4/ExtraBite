# FINAL PROMPT — Build ExtraBite

Copy and paste this full prompt into Antigravity:

---

Create a complete, modern, mobile-first app named **ExtraBite**.

ExtraBite lets PGs, hostels, and messes sell their freshly prepared extra food to nearby people at a low price. Customers use the app to find food near them, reserve it, collect it from the PG/hostel, and pay the owner directly at collection.

Use this tagline everywhere appropriate:

**Good food shouldn’t go to waste.**

# IMPORTANT: PAYMENT RULE

Do not add any online payment feature.

There must be NO:

- UPI
- Razorpay
- Credit/debit card payment
- Wallet
- Checkout page
- Payment gateway
- Pay Now button

Customers only reserve food in the app. They pay the PG/hostel owner directly when they collect the food.

Show this clearly on every order screen:

**Payment: Pay at pickup**

# BUILD 3 USER TYPES

Build separate access and screens for these users:

1. Customer
2. PG / Hostel Owner
3. Admin

# 1. FIRST SCREEN

Create a welcome screen with:

`Welcome to ExtraBite 🍱`

`Good food shouldn’t go to waste.`

`How do you want to use ExtraBite?`

Show two large buttons/cards:

- `🏠 PG / Hostel Owner` — `List your extra food`
- `👤 Customer` — `Find affordable food near you`

Also add a sign-in link for existing users.

# 2. CUSTOMER REGISTRATION

When Customer is selected, show a registration form with:

- Full name
- Mobile number
- Email
- Password
- Confirm password

Then ask:

`Allow ExtraBite to find food near you?`

Show two buttons:

- `Allow Location`
- `Enter Location Manually`

If location is allowed, use the customer’s GPS location. If manual location is selected, let the customer search/select an address on a map.

Ask for food preference:

- Vegetarian
- Non-Vegetarian
- Both

Ask for price preference:

- Under ₹30
- ₹30–₹50
- ₹50–₹100
- Any price

Button: `Start Finding Food`

# 3. CUSTOMER HOME SCREEN

After registration, open the customer home screen.

Show:

- Title: `Extra Food Near You`
- Customer’s current location
- Search bar: `Search food or PG`
- Food category buttons: Breakfast, Lunch, Dinner, Vegetarian, Under ₹30
- Sort options: Distance, Price, Rating, Pickup Time, Availability
- List view and Map view

At the bottom, show customer navigation:

- Home
- Explore
- Reservations
- Favorites
- Profile

# 4. VERY IMPORTANT: 2 KM NEARBY FILTER

Add a distance/radius filter on the Customer Home and Explore pages.

The default selected radius must be **2 km**.

Show these radius options:

- 1 km
- 2 km
- 5 km
- 10 km

When the customer chooses **2 km**, show ONLY verified PGs/hostels/messes that are located inside 2 km from the customer’s current location.

Use real latitude and longitude distance calculation. Do not fake the distance.

Examples:

- PG at 0.5 km: show it
- Hostel at 1.2 km: show it
- PG at 2.0 km: show it
- PG at 2.1 km: do not show it
- Unverified PG at 0.3 km: do not show it

Display this text on the page:

`Showing food within 2 km`

Show the distance on every food card, for example:

`📍 0.5 km away`

When the radius changes, update both the food list and map pins immediately.

Sort food by closest distance first by default.

If there is no food in the selected radius, show:

`No extra food found within 2 km. Try increasing your search radius.`

# 5. FOOD CARDS

Show available food in cards. Every card must show:

- Food image
- PG/hostel name
- `✓ Verified` badge
- Food name
- Veg or Non-Veg label
- Original price with strike-through
- Discounted ExtraBite price
- Discount badge
- Available portions
- Distance
- Pickup time
- Button: `View Details`

Add this sample data:

1. **Sri Sai PG** — Verified
   - Food: Rice + Dal + Curry
   - Original price: ₹60
   - ExtraBite price: ₹30
   - Portions: 12
   - Distance: 0.5 km
   - Pickup: 7:30 PM–9:30 PM

2. **Lakshmi Hostel** — Verified
   - Food: Veg Pulao
   - Original price: ₹70
   - ExtraBite price: ₹35
   - Portions: 8
   - Distance: 1.2 km
   - Pickup: 7:00 PM–9:00 PM

3. **Vijaya PG** — Verified
   - Food: Chapati + Paneer Curry
   - Original price: ₹90
   - ExtraBite price: ₹45
   - Portions: 6
   - Distance: 2.0 km
   - Pickup: 8:00 PM–10:00 PM

Also add two demo PGs outside 2 km. They must be hidden at the default 2 km radius and appear when the user changes the radius to 5 km or 10 km.

# 6. FOOD DETAILS PAGE

When the customer opens a food card, show:

- Food image
- Food name
- PG/hostel name
- `✓ Verified`
- Rating
- Description
- Ingredients
- Allergens
- Prepared time
- Pickup time
- Consume-before time
- Portions available
- Original price
- ExtraBite price
- Quantity selector: `[-] 1 [+]`
- Total amount based on selected quantity

Show only one main button:

`Reserve Food`

Do not show a payment button.

# 7. RESERVATION CONFIRMATION

When the customer clicks `Reserve Food`:

- Create a unique order ID, such as `#EB10293`
- Create a QR code
- Create a backup pickup code
- Reduce available food portions
- Create reservation status: `Reserved`

Show a confirmation page with:

`Reservation Confirmed 🎉`

- Order ID
- Food name
- Quantity
- Total amount
- Payment: Pay at pickup
- PG/hostel name
- Pickup address
- Pickup time
- QR code
- Pickup code

Show this message:

`Show this QR code to the PG owner when collecting your food.`

`Payment must be made directly to the PG/hostel at pickup.`

# 8. CUSTOMER RESERVATIONS

Create a Reservations screen with these tabs:

- Active Reservations
- Completed Reservations
- Cancelled Reservations

Every reservation must show:

- Order ID
- Food
- PG/hostel name
- Quantity
- Amount to pay at pickup
- Pickup time
- Reservation status
- QR code/pickup code when active

Use these statuses:

- `🟡 Reserved`
- `🟢 Picked Up`
- `🔴 Cancelled`

Customers can cancel an order only before the cancellation cutoff time set by the owner.

# 9. PG / HOSTEL OWNER REGISTRATION

When PG / Hostel Owner is selected, show a registration form.

Owner details:

- Full name
- Mobile number
- Email
- Password
- Confirm password

PG/hostel details:

- PG/hostel name
- Type: PG, Hostel, Mess
- Full address
- City
- State
- Pincode
- Map/GPS location
- Number of residents
- Contact number
- WhatsApp number

Verification uploads:

- Owner ID
- PG/hostel proof
- PG/hostel photos

Button: `Register PG`

After submitting, show:

`Registration submitted successfully.`

`⏳ Verification Pending`

Important: only an Admin can approve a PG/hostel. An owner cannot publish food until approved.

# 10. OWNER DASHBOARD

After the owner is approved, show:

`Welcome, Sri Sai PG`

Show dashboard cards:

- `🍱 Active Food` — 12 portions
- `📦 Today’s Reservations` — 18
- `💰 Today’s Expected Revenue` — ₹540
- `♻️ Meals Rescued` — 32

Show buttons:

- `+ Add Surplus Food`
- `View Reservations`
- `Verify Pickup`
- `Analytics`

Owner bottom navigation:

- Dashboard
- Food
- Reservations
- Analytics
- Profile

# 11. ADD SURPLUS FOOD

Create an Add Surplus Food form with:

- Food name
- Description
- Food image
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

Automatically calculate discount. Example:

`Original Price: ₹60`

`ExtraBite Price: ₹30`

`50% OFF`

Button: `Publish Food`

Automatically hide food after its pickup deadline or consume-before time.

# 12. OWNER VERIFY PICKUP

Create a `Verify Pickup` screen for owners.

The owner can:

- Scan customer QR code
- Enter customer pickup code manually

After code is found, show:

- Customer name
- Order ID
- Food
- Quantity
- Amount to collect
- `Payment status: Pay at Pickup`

The owner collects the money directly from the customer. Then the owner clicks:

`Confirm Pickup`

After confirmation:

- Change reservation status to `Picked Up`
- Do not allow the QR/code to be used again
- Move order to completed reservations
- Allow customer to submit a review

# 13. RATINGS AND FOOD SAFETY

After pickup, allow customers to:

- Rate Food Quality from 1 to 5 stars
- Rate PG Experience from 1 to 5 stars
- Write a review
- Report unsafe food

Every food listing must always show:

- Prepared time
- Pickup deadline
- Consume-before time
- Food category
- Veg/Non-Veg
- Ingredients
- Allergens

# 14. ADMIN PANEL

Build a secure Admin panel where Admin can:

- Approve or reject PG/hostel registrations
- View owner ID, property proof, and photos
- Manage customers
- Manage PGs/hostels
- Manage food listings
- Manage reservations
- View and handle complaints
- Suspend accounts
- View platform statistics

Admin statistics must show:

- Total PGs/hostels
- Verified properties
- Active food listings
- Reservations today
- Completed pickups
- Cancelled reservations/no-shows
- Meals rescued
- Estimated food waste reduced
- Expected revenue for PG owners

# 15. FINAL QUALITY REQUIREMENT

Create a real working app, not a static design.

The complete demo flow must work:

1. PG owner registers.
2. Admin approves the PG.
3. Owner publishes surplus food.
4. Customer opens the app and sees the default 2 km radius.
5. Customer sees only verified PGs within 2 km.
6. Customer reserves food.
7. App generates QR code and pickup code.
8. Customer pays owner directly at collection.
9. Owner confirms pickup with QR/code.
10. Customer rates the food.

Use a clean, high-quality mobile design with realistic Indian food, INR prices, maps, working forms, clear error messages, success messages, and responsive layouts.

Do not leave features as TODOs. Do not add online payment.

---
