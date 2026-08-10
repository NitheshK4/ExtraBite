# ExtraBite — Product, Data, and Business Rules

Use this as supporting implementation context for the ExtraBite build.

## Source of truth for payments

ExtraBite never accepts money online. The `amount_to_collect` field represents money the customer will pay directly to the property on collection. Do not create payment transactions, payment provider integrations, card forms, UPI components, wallets, payment webhooks, or a checkout route.

| Screen or feature | Correct language | Forbidden language/features |
| --- | --- | --- |
| Food detail | Reserve Food | Buy now, Pay now, Checkout |
| Reservation confirmation | Pay at pickup | Payment successful, Paid online |
| Owner verification | Amount to collect | Charge customer, Process payment |
| History | Amount paid at pickup / amount to pay | Payment transaction |

## Roles and permissions

| Action | Customer | Owner | Admin |
| --- | :---: | :---: | :---: |
| Discover verified listings | Yes | No | Yes |
| Reserve food | Yes | No | No |
| Publish food | No | Verified only | Moderate/manage |
| Confirm pickup | No | Own property only | Manage if needed |
| Approve property | No | No | Yes |
| Create review | Completed own reservation | No | Moderate/manage |
| Handle complaints | Report | View own property reports | Yes |

## Suggested data model

### users

- id
- role: `customer`, `owner`, `admin`
- full_name, mobile_number, email, password/auth identifier
- profile_photo_url
- food_preference: `vegetarian`, `non_vegetarian`, `both`
- price_preference
- latitude, longitude, formatted_location
- account_status: `active`, `flagged`, `suspended`
- created_at, updated_at

### properties

- id, owner_id
- name, type: `pg`, `hostel`, `mess`
- full_address, city, state, pincode
- latitude, longitude
- resident_count, contact_number, whatsapp_number
- verification_status: `pending`, `approved`, `rejected`, `suspended`
- verification_reason
- average_rating, rating_count
- created_at, updated_at

### verification_documents

- id, property_id
- document_type: `owner_id`, `property_proof`, `property_photo`
- file_url
- review_status
- reviewed_by, reviewed_at

### food_listings

- id, property_id
- food_name, description, image_url
- category: `breakfast`, `lunch`, `dinner`, `snacks`
- dietary_type: `vegetarian`, `non_vegetarian`
- ingredients, allergens
- original_price, selling_price
- total_portions, available_portions
- prepared_at, pickup_starts_at, pickup_ends_at, consume_before_at, cancellation_cutoff_at
- status: `draft`, `published`, `sold_out`, `expired`, `cancelled`
- created_at, updated_at

### reservations

- id, order_code, pickup_code, qr_token
- listing_id, property_id, customer_id
- quantity, amount_to_collect
- status: `reserved`, `picked_up`, `cancelled`, `expired`, `no_show`
- reserved_at, cancelled_at, picked_up_at
- cancellation_reason, verified_by_owner_id

### reviews

- id, reservation_id, customer_id, property_id, listing_id
- food_quality_rating, property_experience_rating, review_text
- created_at

### complaints

- id, reporter_id, property_id, listing_id, reservation_id
- category, description, photo_url
- status: `open`, `reviewing`, `resolved`, `dismissed`
- resolved_by, resolution_note

### favorites

- id, customer_id
- listing_id or property_id
- created_at

## Listing lifecycle

```text
draft → published → sold_out
                  ↘ expired
published → cancelled
```

- An owner can create drafts, but publishing requires property status `approved`.
- Automatically mark a listing `expired` once the earlier of `pickup_ends_at` and `consume_before_at` has passed.
- Customer discovery only returns `published` listings from approved properties with `available_portions > 0` and unexpired safe pickup times.

## Reservation lifecycle

```text
reserved → picked_up
    ↘ cancelled
    ↘ expired / no_show
```

- On reservation: validate listing state, pickup time, customer eligibility, and requested quantity; decrement `available_portions` atomically.
- On cancellation before cutoff: mark `cancelled` and restore the quantity atomically.
- On owner confirmation: require valid QR token or pickup code and current reservation status `reserved`; mark `picked_up` exactly once.
- `amount_to_collect` is informational only. It does not trigger a transaction or payment record.

## Radius search contract

Customer location may originate from device GPS or a manually selected address. Store latitude and longitude for the active search location.

1. Use 2 km as default selection.
2. Support exactly 1 km, 2 km, 5 km, and 10 km options at minimum.
3. Calculate distance from customer coordinate to `properties.latitude/longitude` using a Haversine calculation or native database geospatial function.
4. Include results only if calculated distance is less than or equal to the selected radius.
5. Return/map/display calculated distance and order ascending by it unless the customer selects another sort option.
6. Apply radius filtering before rendering cards and pins, not only visually in the UI.
7. Make manual location and location-permission failure graceful, with an address selector and explanatory empty state.

Example Haversine pseudocode:

```text
distanceKm(lat1, lon1, lat2, lon2):
  earthRadiusKm = 6371
  dLat = radians(lat2 - lat1)
  dLon = radians(lon2 - lon1)
  a = sin(dLat / 2)^2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dLon / 2)^2
  return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a))
```

## Initial demo data criteria

Seed a signed-in customer near the following approved properties so that the 2 km radius shows exactly the nearby listings:

- Sri Sai PG: 0.5 km; Rice + Dal + Curry; 12 portions; ₹60 → ₹30
- Lakshmi Hostel: 1.2 km; Veg Pulao; 8 portions; ₹70 → ₹35
- Vijaya PG: 2.0 km; Chapati + Paneer Curry; 6 portions; ₹90 → ₹45

Also seed at least two approved properties beyond 2 km. They must appear when the radius is increased to 5 or 10 km, but not at the 2 km default.

Seed one unverified property that is geographically nearby. It must never appear in customer results or be allowed to publish a listing.
