# Raunaq — in-app FAQ (static knowledge for the assistant)

## What is Raunaq
Raunaq is an event planning app: browse vendors (venues, catering, photography, decoration, music), save event plans, message vendors, and register interest for services.

## Accounts and login
- Sign up / sign in uses email and password (Firebase Auth).
- Forgot password: use **Forgot Password?** on the login screen; check email for a reset link (web opens in-app set-new-password when configured).
- Sign out: **Profile** (from home) → **Logout**.

## Home and navigation
- Bottom bar: **Home** (categories), **Explore** (search across all categories), **Messages** (in-app assistant — see below).
- **Profile** is opened from the person icon on the home app bar.

## Admin view (your own listings)
- In **Profile**, **Switch to Admin View** unlocks create / edit / delete for **your own** category listings (venues, catering, etc.) where `ownerEmail` matches your account.
- **Switch to User View** returns to normal browsing without management controls.
- You cannot manage another user’s listings from the app (Firestore rules enforce ownership).

## Categories (browse vs manage)
- **Venues, Catering, Photography, Decoration, Music**: tap a category from home to open that screen.
- Listings are stored in Firestore under `categories/{categoryId}/items`.
- **Register / inquire**: tapping someone else’s listing may open a registration or inquiry flow where implemented.

## Vendors (featured list)
- The app may show a **vendors** collection (featured vendor cards). Vendors can maintain listings via vendor flows where enabled.

## Event plans
- Event plans live under your user document: `users/{yourUid}/eventPlans`. Only you can read/write your plans (when signed in).

## Messages
- The **Messages** tab opens this assistant: ask questions about using Raunaq; answers use this FAQ and general app navigation.
- **Chats with vendors** open when you send an inquiry from a vendor or listing flow (not from the Messages tab list).

## Privacy and limits
- This assistant answers from this FAQ and general navigation help. It does not know live venue availability or prices unless that data is in the app screens you see.
- For account or payment issues, contact support through your course or project owner.
