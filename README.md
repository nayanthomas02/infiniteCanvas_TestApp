infiniteCanvas — Project Documentation
Student Submission | Flutter Application GitHub: https://github.com/nayanthomas02/infiniteCanvas_TestApp Date: 08 April 2026

1. Project Overview
infiniteCanvas is a high-performance, offline-first Flutter application that demonstrates two advanced technical features in a single production-ready app:

Infinite Scrolling Canvas — A performant, paginated list with 120 FPS rendering capability, fast-scroll optimisation, and real-time data loaded from a mock API.
Collaborative Task Manager — An offline-first task management system with full CRUD operations, local SQLite persistence, background sync, and real-time connectivity monitoring.
The application is built using Clean Architecture principles, ensuring a clear separation between Data, Domain, and Presentation layers.

2. Technical Requirements Implemented
✅ Architecture — Clean Architecture
The project is divided into three distinct layers:

Layer	Responsibility
Domain	Business entities (TaskEntity, 
CanvasItem
) and abstract repository contracts
Data	Concrete repository implementations, local database (Drift/SQLite), API services
Presentation	BLoC/Cubit state management, UI pages and widgets
This ensures testability, separation of concerns, and independence of the business logic from framework details.

✅ State Management — BLoC + Cubit
TaskBloc
 — Manages the full task lifecycle: Load, Add, Edit, Toggle, Delete, Sync, and Connectivity changes. Uses event-driven state updates.
CanvasBloc
 — Manages pagination, fast-scroll detection, and data fetching for the infinite list.
ConnectivityCubit — Monitors network status in real time and notifies the 
TaskBloc
 to trigger background sync when connectivity is restored.
✅ Dependency Injection — GetIt
All services, repositories, and BLoCs are registered and resolved using the GetIt service locator, configured in 
injection_container.dart
. This avoids tight coupling throughout the codebase.

✅ Offline-First — Drift (SQLite)
The task manager is fully offline-first:

All create, edit, and delete operations are written to a local SQLite database (via Drift) immediately (Optimistic UI).
Every mutation is also queued as a 
PendingAction
 in a second table (pending_actions).
When the device comes back online, the pending actions queue is flushed to the mock backend.
Failed sync operations are reported via a Snackbar with a Retry button.
Database Tables:

Table	Columns
tasks	id, title, description, isDone, isSynced, createdAt, updatedAt
pending_actions	id, actionType (ADD/EDIT/DELETE), payload (JSON), createdAt
Drift's code generation (build_runner) was used to generate type-safe query builders.

✅ Networking — Dio + Mock API
Dio is configured as a singleton with connection and receive timeouts.
MockApiService
 (Canvas) simulates a paginated REST API with configurable network delay.
TaskApiService
 simulates a task CRUD API with a 30% failure rate to demonstrate rollback and error handling.
CachedNetworkImage is used throughout to load and cache remote images efficiently (picsum.photos).
✅ Infinite Scrolling Canvas (120 FPS Optimisation)
The 
CanvasPage
 implements a production-grade infinite list:

Feature	Implementation
Infinite pagination	Fetches next page when scroll reaches 85% of max extent
Fast-scroll detection	Manual velocity calculation from scroll offset delta; pauses image loads when scrolling fast
RepaintBoundary	Each 
CanvasItemCard
 isolates repaints — only the changed widget repaints
CustomPainter	Performance chart in each card is drawn with CustomPainter (zero widget overhead)
CachedNetworkImage	Images are fetched via CDN with memory cache width capped at 600px
FPS Overlay	A toggleable FPS meter overlay (FpsOverlay) can be enabled in the app bar
Isolate (JSON parsing)	Heavy JSON parsing is offloaded via 
json_parser.dart
 in a separate Isolate
When fast-scrolling is detected, images are replaced by a lightweight placeholder to maintain frame rate.

✅ Connectivity Monitoring — connectivity_plus
ConnectivityCubit listens to the connectivity_plus stream.
An offline banner is shown at the top of the Task Manager page when the device is offline.
When connectivity is restored, 
SyncTasks
 is automatically triggered.
✅ Optimistic UI Pattern
Tasks appear in the UI immediately upon creation, edit, or deletion — before the API call completes. If the API call fails, the error is surfaced via a Snackbar (with Retry), but the local data remains intact and is re-queued for the next sync attempt.

✅ Task Manager — Full Feature Set
Feature	Details
Add Task	Bottom sheet dialog with title (required) + description (optional)
Edit Task	Pre-filled bottom sheet dialog
Delete Task	Swipe-to-dismiss gesture (endToStart) with visual delete background
Toggle Done	Tap avatar/checkbox; strikethrough text + teal overlay animation
Sync Status	Badge shows count of unsynced items; amber clock icon per tile
Force Sync	Cloud sync button in app bar triggers immediate sync
Pending Sync Count	Stats row at top of page shows total, done, and pending sync counts
✅ Network Images in Task Tiles
Each task tile displays a circular avatar image loaded from picsum.photos using a deterministic seed derived from the task's UUID. This means:

Every task gets a unique, consistent avatar.
Images are cached via CachedNetworkImage to avoid repeated network calls.
A fallback person icon is shown while loading or on error.
When a task is marked done, a teal animated overlay with a checkmark appears on the avatar.
✅ UI & Theme
Full dark theme throughout using a custom AppTheme class.
Colour palette: Deep navy (#1A1A2E, #16213E), Purple accent (#6C63FF), Teal (#03DAC6), Amber (#FF9800), Error rose (#CF6679).
Custom NavigationBar with two tabs: Infinite Canvas and Task Manager.
BouncingScrollPhysics for a native feel on all platforms.
SliverAppBar (floating + snap) with contextual action buttons.
Dismissible tiles with animated delete background.
3. Folder Structure
lib/
├── core/
│   ├── constants/        # AppConstants (page size, failure rate, action types)
│   ├── di/               # GetIt injection_container.dart
│   └── theme/            # AppTheme (dark theme, gradients)
│
├── features/
│   ├── canvas/
│   │   ├── data/
│   │   │   ├── isolate/      # json_parser.dart (Isolate-based parsing)
│   │   │   ├── repositories/ # CanvasRepositoryImpl
│   │   │   └── services/     # MockApiService
│   │   ├── domain/
│   │   │   ├── entities/     # CanvasItem
│   │   │   └── repositories/ # CanvasRepository (abstract)
│   │   └── presentation/
│   │       ├── bloc/         # CanvasBloc
│   │       ├── pages/        # CanvasPage
│   │       └── widgets/      # CanvasItemCard, ChartPainter, FpsOverlay
│   │
│   └── tasks/
│       ├── data/
│       │   ├── database/     # AppDatabase (Drift), app_database.g.dart
│       │   ├── repositories/ # TaskRepositoryImpl (offline-first logic)
│       │   └── services/     # TaskApiService (mock with 30% failure)
│       ├── domain/
│       │   ├── entities/     # TaskEntity
│       │   └── repositories/ # TaskRepository (abstract)
│       └── presentation/
│           ├── bloc/         # TaskBloc
│           ├── cubit/        # ConnectivityCubit
│           ├── pages/        # TaskPage
│           └── widgets/      # TaskItemTile, AddEditTaskDialog
│
└── main.dart             # App entry point, MultiBlocProvider, HomeShell
4. Key Packages Used
Package	Version	Purpose
flutter_bloc	^8.1.5	State management (BLoC + Cubit)
equatable	^2.0.5	Value equality for state/events
get_it	^7.7.0	Dependency injection
drift + drift_flutter	^2.18.0	Type-safe SQLite ORM
sqlite3_flutter_libs	^0.5.24	Native SQLite bindings
dio	^5.4.3	HTTP client
cached_network_image	^3.3.1	Image caching
connectivity_plus	^6.0.3	Network connectivity monitoring
uuid	^4.4.0	UUID generation for task IDs
build_runner + drift_dev	—	Code generation (Drift)
5. Summary of What Was Built
This project demonstrates mastery of:

✅ Clean Architecture in Flutter
✅ BLoC pattern for reactive state management
✅ Drift (SQLite) for offline-first data persistence
✅ Optimistic UI with pending action queue and rollback
✅ Real-time connectivity monitoring and auto-sync
✅ High-performance infinite scrolling with 120 FPS techniques
✅ CustomPainter and RepaintBoundary for rendering optimisation
✅ Background computation via Dart Isolates
✅ CachedNetworkImage with CDN images and memory-constrained caching
✅ Dependency injection with GetIt
✅ Full dark-theme UI with animations and micro-interactions
