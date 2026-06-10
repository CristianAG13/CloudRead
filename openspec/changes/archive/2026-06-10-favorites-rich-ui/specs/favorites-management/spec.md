# Delta for favorites-management

## Purpose

Define the user-facing behavior of the Favoritos section: lifecycle, organization, and
persistence-aware operations.

## ADDED Requirements

### Requirement: Book model exposes reading status, tags and added date

The `Book` model SHALL expose `readingStatus: ReadingStatus` (toRead | reading | finished),
`tags: List<String>` (lowercase, deduped, non-empty), and `addedAt: DateTime`.

`ReadingStatus` SHALL be an enum persisted as its `name` string.

#### Scenario: New favorite defaults to To Read
- GIVEN a book is added to favorites
- WHEN it is persisted
- THEN `readingStatus` is `toRead`, `tags` is `[]`, and `addedAt` is the UTC time of insertion

#### Scenario: Tags are normalized
- GIVEN a user enters `[" Fiction ", "fiction", "Mystery"]`
- WHEN the tags are set on a favorite
- THEN the stored value is `["fiction", "mystery"]`

### Requirement: Favorites support rich organization

The provider SHALL expose:
- `setSort(FavoritesSort)` (recent | titleAsc | authorAsc | ratingDesc),
- `setFilter(FavoritesFilter)` (all | toRead | reading | finished | tag:<slug>),
- `searchFavorites(query)` matching `title`, `authorName`, `tags`, and `readingStatus` token.

The UI SHALL present a sort menu and horizontal filter chips that reflect the current
provider state.

#### Scenario: Sorting by title is case-insensitive and stable
- GIVEN a library with `["zebra","Apple","apple"]`
- WHEN the user selects sort `titleAsc`
- THEN the visible order is `["Apple","apple","zebra"]`

#### Scenario: Filtering by tag returns only matching books
- GIVEN favorites with tags `["fiction"]` and `["science"]`
- WHEN the user selects the `fiction` chip
- THEN only books whose `tags` contain `fiction` are visible

#### Scenario: Search matches tag tokens
- GIVEN a favorite tagged `fiction`
- WHEN the user types `fic` in the search box
- THEN that favorite is included in the result

### Requirement: Reading status and tags are editable from the CRUD sheet

The CRUD sheet SHALL allow setting `readingStatus` (segmented control) and `tags` (chip
input with add/remove). On save the provider SHALL update the favorite in place.

#### Scenario: Editing status persists
- GIVEN an existing favorite in `toRead`
- WHEN the user changes the status to `reading` and saves
- THEN the favorite is stored with `readingStatus: reading`

#### Scenario: Removing a tag persists
- GIVEN a favorite with `tags: ["fiction","mystery"]`
- WHEN the user removes `mystery` and saves
- THEN the favorite is stored with `tags: ["fiction"]`

### Requirement: Undo after removal

When a favorite or batch of favorites is removed from the library, the UI SHALL show a
snackbar with an "Undo" action. Activating undo within 4 seconds SHALL restore the
removed books at their previous positions.

#### Scenario: Single removal is undoable
- GIVEN a library of three books
- WHEN the user removes book B
- THEN a snackbar appears; pressing Undo re-inserts B at its original index

#### Scenario: Batch removal is undoable
- GIVEN books A, B, C selected
- WHEN the user deletes the selection
- THEN pressing Undo restores A, B and C at their original indices

### Requirement: Library is importable and exportable as JSON

The provider SHALL expose `exportJson()` and `importJson(String)`. Export SHALL produce
a JSON string with schema `{ "version": 2, "books": [...] }`. Import SHALL merge by key,
overwriting existing entries with the same key, and SHALL notify listeners once.

#### Scenario: Export roundtrip preserves data
- GIVEN a library with three favorites including tags and status
- WHEN the user exports then re-imports on top of an empty library
- THEN the library contains the same three favorites with the same fields

#### Scenario: Import merges by key
- GIVEN an existing favorite with key `K` (rating 4.0) and an imported entry with the same
  key (rating 5.0)
- WHEN import runs
- THEN the favorite with key `K` is updated to rating 5.0 and other favorites are untouched

## MODIFIED Requirements

### Requirement: Search debounce is preserved
(Previously: Search used a 250 ms debounce inside the screen and called
`searchFavorites(query)` on each tick.)

The system SHALL debounce search input at 200 ms, run it on the in-memory list, and SHALL
NOT trigger any storage write.

#### Scenario: Rapid typing only runs search once
- GIVEN the user types `f`, `fi`, `fic` within 200 ms
- WHEN the debounce timer fires
- THEN the search runs once with `fic` and no write to storage happens

### Requirement: Spotlight adapts to library state
(Previously: A single hard-coded spotlight was shown on top of the grid.)

The system SHALL show a contextual spotlight that highlights the most recently added book
when there are at least three favorites, otherwise it SHALL be hidden.

#### Scenario: Spotlight is hidden for tiny libraries
- GIVEN fewer than three favorites
- WHEN the screen builds
- THEN the spotlight widget is not rendered

#### Scenario: Spotlight tracks the newest favorite
- GIVEN four favorites with `addedAt` timestamps
- WHEN a new favorite is added
- THEN the spotlight card displays that new favorite

## REMOVED Requirements

### Requirement: Library level progress bar
(Reason: The static "Collection level X%" bar was arbitrary and replaced by a stats row
that surfaces real numbers: total, reading, finished, top tag, average rating.)

#### Scenario: Progress bar is gone
- GIVEN the favorites screen
- WHEN it renders
- THEN the `Collection level` bar is no longer visible
