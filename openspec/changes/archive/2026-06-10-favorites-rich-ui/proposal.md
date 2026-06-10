# Proposal: Enriquecer y acelerar la sección de Favoritos

## Intent

La pantalla de Favoritos hoy es funcional pero plana: una grid, una búsqueda básica, un CRUD
sheet, y persistencia sincrónica que bloquea el UI en cada toque. El usuario quiere más
funciones (sort, filtros, tags, status de lectura, import/export) **y** que se sienta más
rápida. Vamos a entregar las dos cosas en un solo cambio coherente.

## Scope

### In Scope
- Modelo `Book` enriquecido: `tags: List<String>`, `readingStatus` (toRead/reading/finished),
  `addedAt: DateTime`.
- `FavoritesProvider` con: cache O(1) por key, write debounced (350 ms), sort y filter
  configurables, búsqueda tokenizada (title/author/tags), undo tras eliminar, import/export JSON,
  setters de status/tag.
- `FavoritesStorage` v2 con migración tolerante desde v1.
- `FavoritesScreen` con: sort menu, filter chips horizontales (All / por status / por tag),
  stats row (total, reading, finished, top tag, avg rating), spotlight contextual, undo snackbar,
  empty state contextual con CTA, botones Import/Export.
- `FavoriteCrudSheet` con chip input para tags y dropdown de status.
- Tests de provider con `InMemoryFavoritesStorage` (para no romper el smoke test existente).
- Micro-perf: `Selector` para sub-árboles, `const` donde aplica, `RepaintBoundary` en cards.

### Out of Scope
- Sync real con backend (sigue siendo stub de 600 ms en `_sendActionToServer`).
- Tags jerárquicos o autocompletado inteligente.
- Lectura dentro de la app (ya existe `reader_screen`, no se toca).
- Sincronización entre dispositivos (no hay backend).

## Capabilities

### New Capabilities
- `favorites-management`: spec para el ciclo de vida completo de un favorito (CRUD, status,
  tags, import/export, undo, sort/filter).
- `favorites-storage`: spec para la capa de persistencia v2 y la migración v1→v2.

### Modified Capabilities
- None (no hay specs previas en `openspec/specs/`).

## Approach

1. Storage v2 primero: extender `Book` con `tags/status/addedAt`, agregar
   `serialize/deserialize` con versión, y un `migrate(rawJson)` que rellena defaults si el JSON
   es v1.
2. Provider: refactor a `Map<String, Book>` interno + `List<Book> _view` derivada del sort.
   El debounce usa un `Timer` de 350 ms con `flush()` en `dispose()` y `AppLifecycleState.paused`.
3. UI: introducir `FavoritesSort` y `FavoritesFilter` como enums en el provider, y un
   `FavoritesController` con `Selector` para que cambios de filter no recompilen el grid
   entero.
4. Tests: `InMemoryFavoritesStorage` + tests unitarios de `toggle/add/remove/sort/filter/undo/import/export`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/models/book.dart` | Modified | Nuevos campos + `copyWith` + `toJson/fromJson` |
| `lib/providers/favorites_provider.dart` | Modified | Cache, debounce, sort/filter, import/export, undo, status/tags |
| `lib/services/favorites_storage.dart` | Modified | v2 con migración |
| `lib/screens/favorites_screen.dart` | Modified | Sort menu, filter chips, stats, undo, import/export, spotlight contextual |
| `lib/widgets/favorite_crud_sheet.dart` | Modified | Chip input de tags, dropdown de status |
| `lib/widgets/empty_state.dart` | Modified | CTA opcional |
| `test/favorites_provider_test.dart` | New | Tests con `InMemoryFavoritesStorage` |
| `test/favorites_storage_test.dart` | New | Tests de migración v1→v2 |
| `openspec/changes/favorites-rich-ui/` | New | SDD artifacts |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Pérdida del último write si la app se cierra dentro del debounce | Low | `flush()` en `dispose()` y `AppLifecycleState.paused` |
| Migración falla con JSON corrupto | Low | `try/catch` + degradar a lista vacía (ya existente) |
| Tags duplicados o vacíos | Med | Normalizar a lowercase, dedupe, trim en el setter |
| UI recompila todo el grid al cambiar filter | Med | `Selector` por sub-árbol + `RepaintBoundary` en cards |
| Tests existentes se rompen | Low | `InMemoryFavoritesStorage` no toca SharedPreferences, y el smoke test no usa favoritos |

## Rollback Plan

1. Revertir los archivos en `lib/models/book.dart`, `lib/providers/favorites_provider.dart`,
   `lib/services/favorites_storage.dart`, `lib/screens/favorites_screen.dart`,
   `lib/widgets/favorite_crud_sheet.dart`, `lib/widgets/empty_state.dart`.
2. Borrar `test/favorites_provider_test.dart` y `test/favorites_storage_test.dart`.
3. El storage v2 sigue leyendo datos v1; no se necesita reset. Si los datos quedan con
   `tags=[]`/`status=toRead`/`addedAt=epoch`, no rompe nada.

## Success Criteria

- [ ] `flutter analyze` pasa sin errores ni warnings nuevos.
- [ ] `flutter test` pasa (incluyendo nuevos tests).
- [ ] El UI responde instantáneamente al toque del corazón: el write a SharedPreferences
      no bloquea la animación.
- [ ] Sort, filter, search, undo, import/export, status y tags funcionan end-to-end.
- [ ] El contrato público de `FavoritesProvider` (`favorites`, `isFavorite`, `toggleFavorite`,
      `addCustomFavorite`, `updateFavorite`, `removeFavorite`, `removeFavorites`) sigue
      funcionando igual para `book_detail_screen` y `search_screen`.
