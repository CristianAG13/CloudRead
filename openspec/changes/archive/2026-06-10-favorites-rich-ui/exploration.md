# Exploration: Enriquecer la sección de Favoritos

## Current State

- **Provider (`FavoritesProvider`)**: `ChangeNotifier` con `List<Book> _favorites`. Operaciones
  (`toggleFavorite`, `removeFavorite`, `removeFavorites`, `updateFavorite`, `addCustomFavorite`)
  mutan la lista in-place, llaman `notifyListeners()` y **luego** ejecutan
  `await _storage.save(_favorites)`. Esto bloquea la respuesta del UI: cada toque en una card
  espera a SharedPreferences.
- **Storage**: `SharedPreferencesFavoritesStorage` con `key = 'cloudread.favorites.v1'`
  (JSON-encoded list). Sin versionado, sin tags, sin reading status, sin notas estructuradas.
- **Pantalla (`FavoritesScreen`)**: header con conteo, search bar con debounce de 250 ms,
  spotlight card estática, `BookGrid` staggered con long-press → CRUD sheet, modo selección
  para batch share/delete. Botón "Add Custom Book" en header.
- **Modelo (`Book`)**: ya tiene `personalNote` y `personalRating`, pero ningún tag, status,
  fecha de agregado, o contador de lectura.
- **Consumidores externos**: `book_detail_screen` usa `favorites.any((b) => b.key == key)` y
  `toggleFavorite(book)`; `search_screen` y `book_carousel` usan `favoriteKeys.contains(book.key)`.
  Esos contratos **no se rompen**.

## Affected Areas

- `lib/models/book.dart` — agregar `tags`, `readingStatus`, `addedAt` y `book` getter helper.
- `lib/providers/favorites_provider.dart` — cache `Map<String, Book>`, write debounced,
  sort/filter/search rico, undo, batch ops, import/export.
- `lib/services/favorites_storage.dart` — versión v2 con migración desde v1 + helpers
  import/export JSON.
- `lib/screens/favorites_screen.dart` — sort menu, filter chips, stats row, undo snackbar,
  import/export actions, spotlight contextual, empty state contextual.
- `lib/widgets/favorite_crud_sheet.dart` — chip input para tags, dropdown de status.
- `lib/widgets/empty_state.dart` — agregar CTA opcional (no invasivo).
- Tests: agregar tests de provider con `InMemoryFavoritesStorage` (no romper el smoke test).

## Approaches

1. **Provider con map interno + write debounced + storage v2 + UI rica**
   - Pros: cambios aislados, contratos públicos estables, performance medible
     (search/filtros O(N) sobre listas chicas ≤ cientos de items, lookup O(1) en map).
   - Cons: más código en el provider (~+200 líneas), migración de storage.
   - Effort: Medium-High.

2. **Solo UI + sort/filter local en pantalla**
   - Pros: poco cambio.
   - Cons: no migra storage (pierde tags/status al reinstalar), write sigue bloqueando.
   - Effort: Low.

3. **Provider con stream de SharedPreferences (reactive)**
   - Pros: reativo de verdad.
   - Cons: shared_preferences no es stream, habría que envolver. Sobre-ingeniería para el caso.
   - Effort: High.

## Recommendation

**Approach 1**. Justificación:

- El usuario pidió más funciones y más velocidad. La única forma de cumplir "más rápido" de verdad
  es evitar que la UI espere a `prefs.setString` en cada toque. Eso se resuelve con un
  **write debouncer** y lookup O(1) por key.
- Las features nuevas (tags, reading status, sort, filter, import/export) requieren persistencia,
  y la migración v1→v2 con `migrate` no es compleja si el storage es tolerante con campos
  faltantes (que ya lo es).
- El contrato público (`favorites`, `isFavorite`, `toggleFavorite`, `addCustomFavorite`,
  `updateFavorite`, `removeFavorite`, `removeFavorites`) se mantiene idéntico. Lo que se
  agrega son métodos nuevos (`setReadingStatus`, `addTag`, `importJson`, `exportJson`,
  `setSort`, `setFilter`).

## Risks

- **Concurrencia del debouncer**: si el usuario cierra la app antes de los 350 ms del debounce,
  el último cambio se pierde. Mitigación: `flush()` en `dispose()` y en `AppLifecycleState.paused`.
- **Migración de storage**: si el JSON v1 tiene un campo nuevo incompatible, falla. Mitigación:
  `try/catch` en `load()` y degradar a lista vacía con un log (como ya hace).
- **Tags duplicados / vacío**: normalizar a lowercase, dedupe, trim. Lo aplicamos en el setter.
- **Búsqueda cara en listas grandes**: en la práctica son <500 items, suficiente con un `where`
  lineal. Si en el futuro crece, se puede agregar un índice invertido.
- **BookCard y BookGrid son widgets const-heavy**: agregar `const` ayuda, pero la mayor ganancia
  es dejar de bloquear en el write de SharedPreferences.

## Ready for Proposal

Yes. El cambio se llama **`favorites-rich-ui`** y vive en
`openspec/changes/favorites-rich-ui/`.
