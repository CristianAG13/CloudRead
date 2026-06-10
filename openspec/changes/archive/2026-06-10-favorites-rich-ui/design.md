# Design: Enriquecer y acelerar la sección de Favoritos

## Technical Approach

Dos cambios coordinados: **(a) proveedor con cache O(1) + write debounced**, **(b) UI con
sort, filter, status, tags, undo, import/export**. La capa de storage migra a v2 con
fallback a v1.

```
User gesture ─▶ FavoritesProvider ─▶ Map<String, Book> + List<Book> _view
                      │                          │
                      ├── debounced save (350ms)▶ FavoritesStorage v2
                      └── notifyListeners() ───▶ UI (Selector por sub-árbol)
```

## Architecture Decisions

### Decision: Map<String, Book> interno + vista derivada

**Choice**: Mantener `_byKey: Map<String, Book>` como fuente de verdad y derivar
`_view: List<Book>` con sort actual.
**Alternatives**: Lista única + `firstWhereOrNull` en cada lookup.
**Rationale**: Lookup O(1) en `isFavorite`, `removeFavorite`, `updateFavorite` y
batch ops. La vista es recomputable barato (<500 items).

### Decision: Write debounced con `Timer` y `flush()`

**Choice**: `Timer? _writeDebounce` con 350 ms. `flush()` cancela timer y ejecuta
`save` sincrónico. Hooks: `dispose()` y `AppLifecycleState.paused`.
**Alternatives**: `Future` con `Completer` por mutación.
**Rationale**: Timer es el patrón estándar en Flutter para coalescer bursts (mismo
que usa la search debounce actual). `flush()` en lifecycle cubre el caso de cierre
de app.

### Decision: `FavoritesSort` y `FavoritesFilter` como estado del provider

**Choice**: Enums simples en el provider. UI los lee vía `Selector` para que cambiar
sort no recompile el `BookGrid` mientras no cambien los libros.
**Alternatives**: Provider separado (`FavoritesViewController`).
**Rationale**: Dos enums + dos campos no justifican un provider nuevo. La separación
se hace por `Selector` en la UI.

### Decision: Storage v2 con fallback v1

**Choice**: Misma clase `SharedPreferencesFavoritesStorage`, dos keys (`v1` y `v2`).
`load()` lee v2; si está vacío, lee v1, migra in-memory, escribe v2, borra v1.
**Alternatives**: Borrar v1 y empezar limpio (perderíamos datos de usuarios reales).
**Rationale**: La migración in-memory es trivial (defaults) y no rompe nada.

### Decision: `InMemoryFavoritesStorage` para tests

**Choice**: Implementación `implements FavoritesStorage` con `Map` en memoria.
**Alternatives**: Mockear SharedPreferences con `SharedPreferences.setMockInitialValues`.
**Rationale**: Más rápido, determinístico, sin plumbing de plugins en tests puros.

## Data Flow

```
FavoritesScreen.build()
   ├── context.watch<FavoritesProvider>()     ← rebuild cuando count o sort cambian
   │   └── Selector<FavoritesProvider,List<Book>>(selector: (_, p) => p.visibleFavorites)
   │       └── BookGrid (const-friendly)
   ├── Selector<FavoritesProvider,int>(selector: (_, p) => p.favorites.length)
   │   └── stats row
   └── Selector<FavoritesProvider,Book?>(selector: (_, p) => p.spotlight)
       └── spotlight card

User tap on heart
   └── FavoritesProvider.toggleFavorite(book)
         ├── update _byKey + _view
         ├── notifyListeners()      ← UI pinta al toque
         └── schedule debounced save (350ms)
                  └── [350ms] → FavoritesStorage.save()
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/models/book.dart` | Modify | Agregar `tags`, `readingStatus`, `addedAt`, `copyWith`, `toJson`/`fromJson` |
| `lib/models/reading_status.dart` | Create | Enum `ReadingStatus` con `fromName`/`toJson` |
| `lib/providers/favorites_provider.dart` | Modify | Map interno, debounce, sort/filter, undo, import/export, status/tags |
| `lib/services/favorites_storage.dart` | Modify | v2 keys, fallback v1, `InMemoryFavoritesStorage` |
| `lib/screens/favorites_screen.dart` | Modify | Sort menu, filter chips, stats, undo, import/export, spotlight contextual |
| `lib/widgets/favorite_crud_sheet.dart` | Modify | Chip input de tags, dropdown de status |
| `lib/widgets/empty_state.dart` | Modify | Agregar `action` opcional |
| `lib/widgets/favorites_sort_menu.dart` | Create | Botón con `PopupMenuButton<FavoritesSort>` |
| `lib/widgets/favorites_filter_chips.dart` | Create | Lista horizontal de chips |
| `lib/widgets/favorites_stats_row.dart` | Create | Stats row reutilizable |
| `lib/widgets/tags_chip_input.dart` | Create | Chip input reusable |
| `test/favorites_provider_test.dart` | Create | Tests de provider con `InMemoryFavoritesStorage` |
| `test/favorites_storage_test.dart` | Create | Tests de migración v1→v2 |

## Interfaces / Contracts

```dart
enum ReadingStatus { toRead, reading, finished }

extension ReadingStatusX on ReadingStatus {
  String get name;
  static ReadingStatus fromName(String?);
}

enum FavoritesSort { recent, titleAsc, authorAsc, ratingDesc }
enum FavoritesFilter { all, toRead, reading, finished, tag(String) }

class FavoritesProvider extends ChangeNotifier {
  // API existente — sin cambios
  List<Book> get favorites;
  bool isFavorite(String key);
  Future<bool> toggleFavorite(Book book);
  Future<void> removeFavorite(String key);
  Future<void> removeFavorites(List<String> keys);
  Future<void> updateFavorite(Book updatedBook);
  Future<void> addCustomFavorite(Book newBook);
  Future<void> loadFavorites();
  Future<void> flush();

  // API nueva
  List<Book> get visibleFavorites;
  Book? get spotlight;
  FavoritesSort get sort;
  FavoritesFilter get filter;
  void setSort(FavoritesSort);
  void setFilter(FavoritesFilter);
  Future<void> setReadingStatus(String key, ReadingStatus);
  Future<void> addTag(String key, String tag);
  Future<void> removeTag(String key, String tag);
  String exportJson();
  Future<int> importJson(String source);
  bool undoLastRemoval(); // consume un removal reciente (4s window)
}
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | Provider: add/remove/update/toggle/undo, sort/filter, import/export, debounce flush | `InMemoryFavoritesStorage` + `FakeAsync` |
| Unit | Storage: v1→v2 migration, roundtrip v2 | `InMemoryFavoritesStorage` o SharedPreferences mock |
| Unit | Model: `Book.fromJson` con v1 y v2 | Datos fijos |
| Widget | Smoke test existente | Sin cambios |

## Migration / Rollout

No requiere feature flag. El primer `load()` migra v1→v2 en background y deja v2 escrito.
Si v2 no se escribe por algún motivo, el siguiente `load()` reintenta la migración.

## Open Questions

- ¿La UI debe mostrar un `SnackBar` cuando el import termina? Asumimos sí, con un conteo
  de importados.
- ¿El undo debe sobrevivir un cambio de pantalla? Asumimos que no: la lista `pendingUndo`
  vive en el provider y se descarta al cambiar de tab.
