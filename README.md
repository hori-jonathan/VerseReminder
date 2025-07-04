# VerseReminder

An iOS app for Bible reading and verse tracking.

## Features

- Browse Bible books and chapters
- Read verses with an API-based loader
- Smart search for books, chapters, and verses with fuzzy matching and colored results
  - Handles typos like "Mathew 4:3" and shows both chapter and verse hits
  - Verse results display full text
  - Selecting a book result opens an expanded view listing all chapters in a grid
  - Book scrolling uses async repeated attempts to reliably center the selected book
  - Each book dropdown offers an "Expand Book" button for quick access to the grid view
