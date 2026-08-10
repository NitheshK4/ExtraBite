# ExtraBite — Owner and Admin Requirements

Build both Owner and Admin areas as secure, functional applications with role-specific permissions.

## PG / Hostel Owner flow

```text
Register property → Upload documents → Wait for admin approval → Publish surplus food
→ View reservations → Verify customer QR/pickup code → Collect money directly → Confirm pickup
```

### 1. Owner registration

Collect owner details: full name, mobile number, email, password, confirm password.

Collect property details: PG/hostel name, type (PG, Hostel, or Mess), full address, city, state, pincode, GPS/map pin, resident count, contact number, and WhatsApp number.

Require uploads for owner ID, property proof, and property photos. Store a real reviewable status: `Pending`, `Approved`, `Rejected`, or `Suspended`.

After registration show:

`Registration submitted successfully.`

`⏳ Verification Pending`

Pending or rejected owners can not publish food. Only `Approved` owners can publish.

### 2. Owner dashboard

Show the property name and these live metrics:

- Active Food
- Today’s Reservations
- Today’s Expected Revenue
- Meals Rescued

Include actions: `+ Add Surplus Food`, `View Reservations`, `Verify Pickup`, and `Analytics`.

Owner bottom navigation: Dashboard, Food, Reservations, Analytics, Profile.

### 3. Create and manage surplus listing

The form must require food name, description, photo, category, diet type, portions, original price, ExtraBite selling price, prepared time, pickup start, pickup deadline, consume-before time, cancellation cutoff, ingredients, and allergens.

Calculate and display the saving, such as `Original Price: ₹60`, `ExtraBite Price: ₹30`, and `50% OFF`.

Rules:

- Refuse to publish if property is not approved.
- Hide listings after pickup deadline or consume-before time.
- Mark listings sold out at zero portions.
- Do not let owners modify an active listing in ways that invalidate existing reservations without explicit safe handling.

### 4. Verify pickup

The owner must be able to scan a customer QR code or enter a pickup code manually. Show customer name, order ID, food, quantity, and `Amount to collect`.

Show `Payment status: Pay at Pickup`.

The owner must personally collect cash/direct payment from the customer outside the application. The application does not take the payment.

On `Confirm Pickup`, mark the reservation `Picked Up`, disable that QR/code permanently, and enable the customer review flow. Repeated confirmation attempts must not duplicate completion.

## Admin flow

Create an admin dashboard with a clear desktop-responsive layout. Admins must be able to:

1. View every pending property registration and its uploaded documents.
2. Approve/reject a property and record a rejection reason.
3. Manage customers, owners, properties, food listings, and reservations.
4. Review and resolve complaints / unsafe-food reports.
5. Suspend accounts where appropriate.
6. See platform metrics: properties, verified properties, active listings, reservations, completed pickups, cancellations/no-shows, meals rescued, waste reduced, and expected owner revenue.

Only admins can change property verification. Owners can only see and change their own property/listing/reservation data.

## No-payment reminder

Neither the Owner dashboard nor Admin panel should contain payment processing, settlement, online payment status, payment provider configurations, or transaction reports. Expected revenue is the total amount owners expect to collect directly at pickup.
