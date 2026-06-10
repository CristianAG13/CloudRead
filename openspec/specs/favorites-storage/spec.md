# Favorites Storage Specification

## Purpose

Define how the favorites library is persisted, versioned, migrated, and exchanged with
external JSON.

## Requirements

### Requirement: Storage schema is versioned as v2

The storage key SHALL be `cloudread.favorites.v2`. Each `Book` JSON SHALL include
`tags: List<String>`, `reading_status: String`, and `added_at: String` (ISO 8601 UTC).

#### Scenario: A v2 payload roundtrips losslessly
- GIVEN a Book with `tags=["fiction"]`, `readingStatus=reading`, `addedAt=2025-01-01T00:00:00Z`
- WHEN it is encoded then decoded
- THEN all three fields are preserved exactly

### Requirement: Storage migrates from v1 transparently

`SharedPreferencesFavoritesStorage` SHALL keep reading the v1 key as a fallback when the
v2 key is absent. Each v1 record SHALL be upgraded in memory: missing `tags` becomes `[]`,
missing `reading_status` becomes `"toRead"`, missing `added_at` becomes the load time in
UTC ISO 8601. After a successful migration the v2 key SHALL be written and the v1 key
MUST be removed.

#### Scenario: v1 user upgrades to v2 seamlessly
- GIVEN SharedPreferences has only the v1 key with three records lacking new fields
- WHEN the app starts and `load()` runs
- THEN the provider receives three upgraded records and the v2 key is written

#### Scenario: Migration does not run twice
- GIVEN the v2 key already exists
- WHEN `load()` runs
- THEN the v1 key is not read

### Requirement: Storage is swappable and has an in-memory implementation

`FavoritesStorage` SHALL remain an abstract interface. A new
`InMemoryFavoritesStorage` SHALL be available for tests and offline debugging.

#### Scenario: In-memory storage roundtrips
- GIVEN an `InMemoryFavoritesStorage` instance
- WHEN three books are saved then loaded
- THEN the same three books are returned in order

### Requirement: Writes are debounced

The provider SHALL schedule a storage write 350 ms after the last mutation. The provider
SHALL expose `flush()` and MUST call it from `dispose()` and on
`AppLifecycleState.paused`.

#### Scenario: Burst mutations produce one write
- GIVEN a freshly loaded library
- WHEN the user toggles three favorites within 200 ms
- THEN `SharedPreferences.setString` for favorites runs exactly once after the debounce

#### Scenario: App background flushes pending writes
- GIVEN two mutations within the last 200 ms
- WHEN `AppLifecycleState.paused` is received
- THEN a single `save` runs synchronously before the app is backgrounded

#### Scenario: Provider disposal flushes pending writes
- GIVEN a pending write
- WHEN the provider is disposed
- THEN the write runs synchronously
