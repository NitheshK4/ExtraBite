# ExtraBite — Customer Experience Requirements

This document defines exactly what a customer must be able to do. Build these as functional screens, not static design samples.

## Customer journey

```text
Choose Customer role → Create account → Share/select location → Browse nearby food
→ Select listing → Reserve portions → Receive QR/pickup code → Pay owner at pickup
→ Owner confirms collection → Leave review
```

## Required screens

### 1. Customer account setup

- Create-account form: full name, mobile number, email, password, confirm password.
- Location choice: `Allow Location` or `Enter Location Manually`.
- Preference choices: Vegetarian / Non-Vegetarian / Both and Under ₹30 / ₹30–₹50 / ₹50–₹100 / Any price.
- CTA: `Start Finding Food`.
- Validate all required information and explain any input error clearly.

### 2. Home and Explore

The customer Home screen includes current location, search, food categories, price/diet filters, sort controls, map/list switcher, and food cards.

#### Location radius — exact behaviour

The active radius defaults to `2 km`. The customer can select `1 km`, `2 km`, `5 km`, or `10 km`.

1. Get the customer coordinate from GPS or selected manual location.
2. Get each verified property coordinate from the database.
3. Calculate real geographic distance in kilometres.
4. Include a listing only when its property distance is less than or equal to the selected radius.
5. At 2 km, include 0.5 km, 1.2 km, and exactly 2.0 km; exclude 2.01 km and all farther results.
6. Apply the same filtered set to list cards, map pins, counts, and search results.
7. Show `Showing food within 2 km` when that radius is active.
8. Sort by distance nearest first unless another sort order is selected.
9. If no records qualify, show `No extra food found within 2 km. Try increasing your search radius.`
10. Never show a listing from an unverified property, even when it is inside the selected radius.

All selected filters must use AND logic. Example: `2 km + Vegetarian + Under ₹30` returns only verified vegetarian listings at or below ₹30 located inside 2 km.

### 3. Listing card

Every customer food card must show:

- Photo of the meal
- Property name
- Green `✓ Verified` badge
- Food name
- Veg/non-veg label
- Original price and ExtraBite price
- Discount percentage
- Portions remaining
- Calculated distance
- Pickup time window
- `View Details` action

### 4. Food details and reservation

The details screen shows meal image, name, property and rating, description, ingredients, allergens, category, diet type, prepared time, pickup window, consume-before time, portions, prices, and calculated total.

Use a quantity stepper. It cannot choose less than one or more than available portions.

Use one primary action: `Reserve Food`.

Never show `Buy`, `Checkout`, `Pay Now`, cards, UPI, wallets, or payment methods.

### 5. Reservation confirmation

On successful reservation, create an order ID, QR code, and backup pickup code. Display food, quantity, total, pickup property, address, pickup window, QR code, and the exact status:

`Payment: Pay at pickup`

Also display:

`Show this QR code to the PG owner when collecting your food.`

`Payment must be made directly to the PG/hostel at pickup.`

### 6. Reservations

Bottom navigation: Home, Explore, Reservations, Favorites, Profile.

Reservation tabs: Active Reservations, Completed Reservations, Cancelled Reservations.

Every record contains order ID, food, property, quantity, amount to pay at pickup, pickup time, and status. Active records include their QR code/pickup code.

Support cancellation only before the listing’s cancellation cutoff. On a valid cancellation, show confirmation and return quantity to the listing exactly once.

### 7. Review and report

After a completed pickup only, allow the customer to give a 1–5 Food Quality rating, a 1–5 PG Experience rating, and a written review. Allow reporting unsafe food from the listing/reservation. Reports must reach the Admin panel.
