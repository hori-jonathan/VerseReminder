# VerseReminder

An iOS app for Bible reading and verse tracking.

## Onboarding & Authentication

The app automatically signs users in anonymously with Firebase on first launch.
Progress is stored in Firestore under the user's UID and loaded as part of each
user's profile. Accounts can later be linked to Google or email using Firebase's
`link` API so progress can be synced across devices.
If the initial sign‑in fails due to a transient network error, the app will
automatically retry a few times and provide a "Retry" button so you can manually
attempt again.

## Features

- Home screen summarizes your reading progress
- Quick Settings panel with sliders and live previews for text size, spacing and Bible version
- Browse Bible books and chapters
- Read verses with an API-based loader
- Smart search for books, chapters, and verses with fuzzy matching and colored results
  - Handles typos like "Mathew 4:3" and shows both chapter and verse hits
  - Verse results display full text
  - Selecting a book result opens an expanded view listing all chapters in a grid
  - Book scrolling uses async repeated attempts to reliably center the selected book
  - Each book dropdown offers an "Expand Book" button for quick access to the grid view
- Flexible reading plans with support for finish-by-date or chapters-per-day goals
- Reading plans are non-linear by default and can be built from presets such as the full Bible, Old or New Testament, Gospels, Prophets, and more
- Each plan stores a progress tree so completion can be computed from your reading history
- Edit your reading plan anytime from the Home tab
- Contact Us form to reach the developer
