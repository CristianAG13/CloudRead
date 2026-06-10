# Tasks: Enriquecer y acelerar la sección de Favoritos

## Phase 1: Modelo + Storage

- [x] 1.1 Crear `lib/models/reading_status.dart` con enum + extension `name`/`fromName`
- [x] 1.2 Modificar `lib/models/book.dart`: agregar `tags: List<String>`, `readingStatus`, `addedAt`, `copyWith`, actualizar `toJson`/`fromJson` para incluir los 3 campos nuevos
- [x] 1.3 Modificar `lib/services/favorites_storage.dart`: v2 keys, migración v1→v2 en `load()`, agregar `InMemoryFavoritesStorage`

## Phase 2: Provider (cache + debounce + sort/filter + import/export)

- [x] 2.1 Refactor `lib/providers/favorites_provider.dart`: `Map<String, Book> _byKey` + `List<Book> _view` derivada; mantener API pública existente
- [x] 2.2 Implementar `Timer? _writeDebounce` (350 ms) con `flush()` y hook a `AppLifecycleState`
- [x] 2.3 Agregar `FavoritesSort` y `FavoritesFilter` con `setSort`/`setFilter` y `visibleFavorites`/`spotlight` getters
- [x] 2.4 Agregar `setReadingStatus`, `addTag`, `removeTag` (normalizan lowercase + dedupe)
- [x] 2.5 Implementar `exportJson()` y `importJson(String)` con schema v2
- [x] 2.6 Implementar undo de remoción: pila `_lastRemovals` con TTL 4 s + `undoLastRemoval()`

## Phase 3: Widgets nuevos + adaptación de existentes

- [x] 3.1 Crear `lib/widgets/favorites_sort_menu.dart` con `PopupMenuButton<FavoritesSort>`
- [x] 3.2 Crear `lib/widgets/favorites_filter_chips.dart` (horizontal `ListView`)
- [x] 3.3 Crear `lib/widgets/favorites_stats_row.dart` (total/reading/finished/top tag/avg rating)
- [x] 3.4 Crear `lib/widgets/tags_chip_input.dart` (chip input con add/remove)
- [x] 3.5 Modificar `lib/widgets/empty_state.dart`: agregar `action: Widget?` opcional
- [x] 3.6 Modificar `lib/widgets/favorite_crud_sheet.dart`: integrar `TagsChipInput` + dropdown de status

## Phase 4: Pantalla

- [x] 4.1 Reescribir `lib/screens/favorites_screen.dart` con sort menu, filter chips, stats row, undo snackbar, import/export, spotlight contextual
- [x] 4.2 Envolver sub-árboles con `Selector<FavoritesProvider, ...>` para minimizar rebuilds
- [x] 4.3 Reemplazar `_buildSpotlightCard` por versión que muestra el libro más reciente y solo si hay ≥3 favoritos
- [x] 4.4 Agregar botones Import/Export al header (con confirmación para import destructivo)

## Phase 5: Tests

- [x] 5.1 Crear `test/favorites_storage_test.dart`: roundtrip v2, migración v1→v2, `InMemoryFavoritesStorage` roundtrip
- [x] 5.2 Crear `test/favorites_provider_test.dart`: add/remove/update/toggle con debounce, sort/filter, undo, import/export
- [x] 5.3 Verificar que el smoke test `test/widget_test.dart` sigue pasando

## Phase 6: Verificación

- [x] 6.1 Correr `flutter analyze` y resolver warnings/errores nuevos
- [x] 6.2 Correr `flutter test` y verificar 100% verde
- [x] 6.3 Verificar manualmente: agregar/editar/eliminar/undo/import/export/filter/sort/search
- [x] 6.4 Verificar contrato público del provider (smoke test + `book_detail_screen` + `search_screen`)
