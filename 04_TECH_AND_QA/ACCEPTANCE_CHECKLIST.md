# ExtraBite — Completion Checklist

The app is complete only when every item below can be demonstrated.

## Main journeys

- [ ] A visitor can choose Customer or PG / Hostel Owner from the welcome screen.
- [ ] A customer can register, allow GPS location or enter one manually, choose preferences, and reach discovery.
- [ ] A customer can see food cards, search, filter, sort, view a map, open a listing, change quantity, and reserve a valid listing.
- [ ] A reservation creates a unique order ID, QR code, and fallback pickup code.
- [ ] Confirmation says `Pay at pickup` and contains no online payment controls.
- [ ] A customer can see active, completed, and cancelled reservations.
- [ ] Cancellation is prevented after the cutoff and restores inventory when valid.
- [ ] An owner can submit a property registration and see `Verification Pending`.
- [ ] An unverified owner cannot publish food.
- [ ] An admin can approve an owner/property.
- [ ] An approved owner can create and publish a fully specified food listing.
- [ ] An owner can scan or enter an active pickup code and confirm pickup once.
- [ ] The customer can submit a review only after pickup.

## Mandatory 2 km search behaviour

- [ ] Customer discovery starts with a 2 km radius selected.
- [ ] Radius choices include 1 km, 2 km, 5 km, and 10 km.
- [ ] With the default demo location and 2 km selected, only Sri Sai PG, Lakshmi Hostel, and Vijaya PG listings are returned.
- [ ] Listings more than 2 km away do not appear in either list or map at 2 km.
- [ ] Changing to 5 km or 10 km reveals the seeded farther listings.
- [ ] Each card displays calculated distance and the active radius is visibly labelled.
- [ ] The empty state suggests increasing radius when no result qualifies.
- [ ] Unverified properties do not appear even when physically inside the selected radius.

## Food safety and inventory

- [ ] Every published listing visibly shows prepared time, pickup deadline, consume-before time, diet type, ingredients, and allergens.
- [ ] Expired and sold-out listings cannot be reserved or discovered.
- [ ] No reservation can cause available portions to become negative.
- [ ] Listing availability updates after a reservation and after a valid cancellation.

## Payment safety

- [ ] There is no checkout page, UPI option, payment provider, card field, wallet, payment API, or payment-related webhook.
- [ ] The reservation flow only records an `amount_to_collect`.
- [ ] Owner pickup verification clearly tells the owner to collect payment directly from the customer.

## Quality and responsiveness

- [ ] Customer and owner views are polished at phone widths.
- [ ] Admin management works on desktop and degrades gracefully on mobile.
- [ ] Forms have client and server validation with clear errors.
- [ ] Loading, empty, error, and success states are included.
- [ ] Auth and role checks are enforced server-side.
- [ ] No secrets are hard-coded.
