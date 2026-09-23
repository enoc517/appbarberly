# AGENTS.md

## Project Overview

Flutter app (barberly) for booking barbershop appointments. Firebase backend with Auth, Firestore, and Google Sign-in. Clean Architecture with feature-based modules.

## Key Commands

- `flutter run` — run the app
- `flutter build apk --debug` — build Android debug APK
- `flutter analyze` — run static analysis (the only lint/typecheck step; no separate typecheck command)

## Architecture

- **Clean Architecture**: each feature has `domain/` (entities, repositories interfaces, usecases), `data/` (models, datasources, repository implementations), `presentation/` (screens, widgets, bloc/cubit).
- **Entry point**: `lib/main.dart` → `lib/app.dart` → `lib/core/router/app_router.dart`
- **DI**: Manual static factory class `AppDependencies` in `lib/core/di/app_dependencies.dart`. All bloc/cubit creation goes through factory methods here.
- **State management**: `flutter_bloc` — screens receive pre-built blocs via `BlocProvider`. BLoCs for complex auth flows; Cubits for feature-specific state.

## Navigation

`GoRouter` with a `StatefulShellRoute.indexedStack` for the bottom navigation bar. The shell renders all 8 branches but screens are role-gated at runtime.

Route params are accessed via `state.pathParameters` inside `GoRoute.builder` closures.

## Architectural Patterns

### Event Bus — Cross-branch Cubit Communication

**Problem**: When two cubits live in different `StatefulShellBranch` branches, navigating between their screens does NOT trigger widget lifecycle methods (`initState`, `didChangeDependencies`) in the destination widget because the widget tree is preserved by the shell. This makes it impossible for a cubit to detect "when the user returns to this screen."

**Use case**: Cubit A (e.g., `BarbershopManagementCubit`) performs an action (creates a barbershop) while Cubit B (e.g., `BarbershopManagementHubCubit`) needs to refresh its state (reload barbershop data) after that action completes.

**Solution**: Event Bus pattern — a singleton stream that cubits can subscribe to and emit events through.

```
lib/core/events/barbershop_event_bus.dart
```

**Implementation pattern** (follow this for any future cross-branch cubit sync):

1. **Create the event bus** in `lib/core/events/`:
   ```dart
   enum BarbershopEvent { barbershopCreated }

   class BarbershopEventBus {
     BarbershopEventBus._();
     static final BarbershopEventBus _instance = BarbershopEventBus._();
     static BarbershopEventBus get instance => _instance;

     final _controller = StreamController<BarbershopEvent>.broadcast();
     Stream<BarbershopEvent> get stream => _controller.stream;
     void emit(BarbershopEvent event) => _controller.add(event);
     void dispose() => _controller.close();
   }
   ```

2. **Register as singleton in `AppDependencies`**:
   ```dart
   static final BarbershopEventBus barbershopEventBus = BarbershopEventBus.instance;
   ```

3. **Cubit that needs to react** (subscriber):
   ```dart
   class SomeHubCubit extends Cubit<SomeState> {
     SomeHubCubit({required BarbershopEventBus eventBus}) : _eventBus = eventBus {
       _eventSubscription = _eventBus.stream.listen((event) {
         if (event == BarbershopEvent.barbershopCreated) {
           loadData();  // refresh state
         }
       });
     }
     final BarbershopEventBus _eventBus;
     late final StreamSubscription<BarbershopEvent> _eventSubscription;

     @override
     Future<void> close() {
       _eventSubscription.cancel();
       return super.close();
     }
   }
   ```

4. **Cubit that triggers the update** (publisher):
   ```dart
   // In the method that performs the action:
   emit(SomeCreated(result));
   _eventBus.emit(BarbershopEvent.barbershopCreated);  // AFTER emit
   ```

5. **Factory in `AppDependencies`**:
   ```dart
   static SomeHubCubit buildSomeHubCubit() {
     return SomeHubCubit(eventBus: barbershopEventBus);
   }
   ```

6. **Router** uses factory, not direct instantiation:
   ```dart
   create: (_) => AppDependencies.buildSomeHubCubit(),
   ```

**Key rules**:
- Emit the state FIRST (`emit(SomeCreated)`), then emit to the bus — this ensures UI navigation/listeners run before the reload
- Always cancel the subscription in `close()` to prevent memory leaks
- Do NOT use `didChangeDependencies` or widget lifecycle to detect cross-branch navigation — the shell preserves widgets, so lifecycle methods don't fire
- The bus is a singleton — same instance across all cubits

## Firebase Setup

- `lib/firebase_options.dart` holds `DefaultFirebaseOptions.currentPlatform`.
- Android requires `android/app/google-services.json`; iOS requires `ios/Runner/GoogleService-Info.plist`.
- Missing config files cause `Firebase.initializeApp` to throw at runtime.

## Assets

Three asset directories in `pubspec.yaml`: `assets/images/`, `assets/icons/`, `assets/logos/`.

## Testing

No test files exist (`test/` is empty). Use `flutter_test` (dev dependency present). Prefer widget tests for UI, unit tests for cubits/usecases.

## Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| firebase_core | ^4.6.0 | Firebase init |
| firebase_auth | ^6.3.0 | Auth |
| cloud_firestore | ^6.2.0 | Database |
| flutter_bloc | ^9.1.1 | State management |
| go_router | ^17.2.0 | Navigation |
| equatable | ^2.0.3 | Value equality |
| google_sign_in | ^6.2.2 | Google OAuth |
| geoflutterfire_plus | ^0.0.34 | Geolocation queries |
| geolocator | ^13.0.2 | GPS access |
| flutter_map | ^7.0.2 | OpenStreetMap |
| latlong2 | ^0.9.1 | Lat/lng utilities |

<!-- CODEGRAPH_START -->
## CodeGraph

This project has a CodeGraph MCP server (`codegraph_*` tools) configured. CodeGraph is a tree-sitter-parsed knowledge graph of every symbol, edge, and file. Reads are sub-millisecond and return structural information grep cannot.

### When to prefer codegraph over native search

Use codegraph for **structural** questions — what calls what, what would break, where is X defined, what is X's signature. Use native grep/read only for **literal text** queries (string contents, comments, log messages) or after you already have a specific file open.

| Question | Tool |
|---|---|
| "Where is X defined?" / "Find symbol named X" | `codegraph_search` |
| "What calls function Y?" | `codegraph_callers` |
| "What does Y call?" | `codegraph_callees` |
| "How does X reach/become Y? / trace the flow from X to Y" | `codegraph_trace` (one call = the whole path, incl. callback/React/JSX dynamic hops) |
| "What would break if I changed Z?" | `codegraph_impact` |
| "Show me Y's signature / source / docstring" | `codegraph_node` |
| "Give me focused context for a task/area" | `codegraph_context` |
| "See several related symbols' source at once" | `codegraph_explore` |
| "What files exist under path/" | `codegraph_files` |
| "Is the index healthy?" | `codegraph_status` |

### Rules of thumb

- **Answer directly — don't delegate exploration.** For "how does X work" / architecture questions, answer with 2-3 codegraph calls: `codegraph_context` first, then ONE `codegraph_explore` for the source of the symbols it surfaces. For a specific **flow** ("how does X reach Y") start with `codegraph_trace` from→to — one call returns the whole path with dynamic hops bridged — then ONE `codegraph_explore` for the bodies; don't rebuild the path with `codegraph_search` + `codegraph_callers`. Codegraph IS the pre-built index, so spawning a separate file-reading sub-task/agent — or running a grep + read loop — repeats work codegraph already did and costs more for the same answer.
- **Trust codegraph results.** They come from a full AST parse. Do NOT re-verify them with grep — that's slower, less accurate, and wastes context.
- **Don't grep first** when looking up a symbol by name. `codegraph_search` is faster and returns kind + location + signature in one call.
- **Don't chain `codegraph_search` + `codegraph_node`** when you just want context — `codegraph_context` is one call.
- **Don't loop `codegraph_node` over many symbols** — one `codegraph_explore` call returns several symbols' source grouped in a single capped call, while each separate node/Read call re-reads the whole context and costs far more.
- **Index lag**: the file watcher debounces ~500ms behind writes; don't re-query immediately after editing a file in the same turn.

### If `.codegraph/` doesn't exist

The MCP server returns "not initialized." Ask the user: *"I notice this project doesn't have CodeGraph initialized. Want me to run `codegraph init -i` to build the index?"*
<!-- CODEGRAPH_END -->
