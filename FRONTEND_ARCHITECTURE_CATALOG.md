# Ninja Tutor Frontend Architecture Catalog

## Module Hierarchy

```
lib/
├── core/                          # Core application infrastructure
│   ├── constants/                 # Shared constants and configuration
│   │   ├── app_constants.dart     # API URLs, timeouts, spacing, breakpoints
│   │   ├── app_strings.dart       # Localized/shared strings
│   │   └── book_categories.dart   # Book classification constants
│   ├── navigation/
│   │   └── app_router.dart        # GoRouter configuration
│   ├── providers/                 # Riverpod state management
│   │   ├── app_providers.dart
│   │   ├── auth_provider.dart
│   │   ├── bookmark_provider.dart
│   │   ├── gamification_provider.dart
│   │   ├── notes_provider.dart
│   │   ├── quiz_provider.dart
│   │   ├── reading_ai_provider.dart
│   │   ├── reading_page_provider.dart
│   │   └── unified_library_provider.dart
│   ├── theme/
│   │   └── app_theme.dart         # Material 3 theme with gradients, colors
│   └── utils/                     # Helper utilities
│       ├── animation_helper.dart
│       ├── debouncer.dart
│       ├── haptics_helper.dart
│       └── responsive_layout.dart
│
├── models/                        # Data models with JSON serialization
│   ├── bookmark/
│   │   └── bookmark_model.dart
│   ├── content/
│   │   ├── book_model.dart
│   │   └── book_model.g.dart     # Generated code
│   ├── gamification/
│   │   └── achievement_model.dart
│   ├── note/
│   │   ├── highlight_model.dart
│   │   ├── note_model.dart
│   │   └── note_model.g.dart
│   ├── quiz/
│   │   ├── quiz_model.dart
│   │   └── quiz_model.g.dart
│   └── user/
│       ├── user_model.dart
│       └── user_model.g.dart
│
├── services/                      # Business logic and external integrations
│   ├── api/
│   │   └── api_service.dart      # HTTP client (Dio) for backend API
│   ├── bookmarks/
│   │   └── bookmark_service.dart  # Bookmark logic
│   ├── notes/
│   │   └── notes_service.dart     # Note persistence
│   └── storage/
│       ├── hive_service.dart      # Local database (Hive)
│       └── secure_storage_service.dart  # Encrypted storage
│
└── ui/                            # User interface layer
    ├── screens/                   # Full-page routes
    │   ├── auth/                  # Authentication flows
    │   │   ├── login_screen.dart
    │   │   └── register_screen.dart
    │   ├── dashboard/
    │   │   └── dashboard_screen.dart  # User overview, stats
    │   ├── library/
    │   │   ├── category_books_screen.dart
    │   │   └── library_screen.dart    # Browse & manage books
    │   ├── notes/
    │   │   └── notes_screen.dart      # All notes view
    │   ├── practice/
    │   │   └── practice_screen.dart   # Quiz/practice interface
    │   ├── reading/
    │   │   ├── reader_full_screen.dart
    │   │   └── reading_screen.dart    # Main reading interface
    │   ├── settings/
    │   │   └── settings_screen.dart
    │   └── splash/
    │       └── splash_screen.dart
    └── widgets/                   # Reusable components
        ├── auth/
        │   ├── auth_background.dart
        │   ├── login_dialog.dart
        │   └── social_login_buttons.dart
        ├── common/                # Shared UI components
        │   ├── ai_tip_card.dart
        │   ├── book_card.dart
        │   ├── empty_state.dart
        │   ├── loading_state.dart
        │   ├── modern_buttons.dart
        │   ├── modern_card.dart
        │   ├── profile_menu_button.dart
        │   ├── progress_card.dart
        │   ├── quick_actions_fab.dart
        │   ├── responsive_grid_helpers.dart
        │   ├── search_filter_bar.dart
        │   └── skeleton_loader.dart
        ├── gamification/
        │   ├── achievement_popup.dart
        │   ├── streak_flame.dart
        │   └── xp_progress_bar.dart
        ├── library/
        │   ├── add_book_bottom_sheet.dart
        │   ├── book_filter.dart
        │   ├── book_options_sheet.dart
        │   └── book_upload_dialog.dart
        ├── navigation/
        │   └── main_navigation.dart
        ├── notes/
        │   ├── note_card.dart
        │   └── note_filter.dart
        ├── practice/
        │   ├── question_display.dart
        │   ├── quiz_card.dart
        │   ├── quiz_results.dart
        │   ├── quiz_review.dart
        │   └── quiz_session.dart
        └── reading/
            ├── ai_chat_panel.dart
            ├── bookmark_panel.dart
            ├── bookmark_tooltip.dart
            ├── highlights_panel.dart
            ├── note_creation_dialog.dart
            ├── note_edit_dialog.dart
            ├── notes_panel.dart
            ├── notes_tooltip.dart
            ├── reading_controls_overlay.dart
            ├── reading_controls_panel.dart
            ├── reading_interface_mixin.dart  # State/behavior mixin
            └── reading_viewer.dart           # PDF/EPUB viewer (1636 lines)
```

## API Endpoints Used by Frontend

### Base URL Configuration
- **Development**: `http://localhost:8000`
- **Production**: `https://ninja-tutor-backend-764764156207.us-central1.run.app`
- **API Version**: `/api/v1`

### Authentication & User Management (`/auth`)

| Method | Endpoint | Purpose | Used By |
|--------|----------|---------|---------|
| POST | `/auth/login` | User login | auth_provider.dart, login_screen.dart |
| POST | `/auth/register` | User registration | auth_provider.dart, register_screen.dart |
| POST | `/auth/logout` | User logout | auth_provider.dart |
| POST | `/auth/sync-user` | Sync Firebase user with backend | auth_provider.dart |
| GET | `/auth/profile` | Get user profile | auth_provider.dart, settings_screen.dart |
| PUT | `/auth/profile` | Update user profile | settings_screen.dart |
| PUT | `/auth/preferences` | Update app preferences | settings_screen.dart |
| PUT | `/auth/reading-preferences` | Update reading settings | settings_screen.dart |
| POST | `/auth/upload-avatar` | Upload profile picture | settings_screen.dart |

### Books & Content (`/books`)

| Method | Endpoint | Purpose | Used By |
|--------|----------|---------|---------|
| GET | `/books` | Get books list (with filters) | unified_library_provider.dart, library_screen.dart |
| GET | `/books/{bookId}` | Get book details | unified_library_provider.dart |
| GET | `/books/{bookId}/file` | Stream book file (PDF/EPUB) | reading_viewer.dart |
| GET | `/books/search` | Search books by query | library_screen.dart |
| POST | `/books/upload` | Upload new book | book_upload_dialog.dart |

### User Library Management (`/library`)

| Method | Endpoint | Purpose | Used By |
|--------|----------|---------|---------|
| POST | `/library/add-book` | Add book to user library | unified_library_provider.dart |
| DELETE | `/library/remove-book/{bookId}` | Remove from library | unified_library_provider.dart |
| GET | `/library/my-books` | Get user's library | unified_library_provider.dart |
| PUT | `/library/update-progress` | Update reading progress | unified_library_provider.dart, reading_viewer.dart |
| GET | `/library/check-book/{bookId}` | Check if book in library | unified_library_provider.dart |

### AI Features (`/ai`)

| Method | Endpoint | Purpose | Used By |
|--------|----------|---------|---------|
| POST | `/ai/definition` | Get word/phrase definition | reading_ai_provider.dart |
| POST | `/ai/explanation` | Get concept explanation | reading_ai_provider.dart |
| POST | `/ai/generate-questions` | Generate practice questions | quiz_provider.dart |
| POST | `/ai/insights` | Get AI insights for note | notes_provider.dart |
| POST | `/ai/comprehension` | Analyze comprehension | reading_ai_provider.dart |
| POST | `/ai/study-tips` | Get contextual study tips | reading_ai_provider.dart |
| POST | `/ai/reading/ask` | Ask question about content | reading_ai_provider.dart, ai_chat_panel.dart |
| GET | `/ai/reading/page-content/{bookId}/{page}` | Get single page content | reading_ai_provider.dart |
| POST | `/ai/reading/page-content-batch` | Get multiple pages content | reading_ai_provider.dart |

### Quizzes (`/quizzes`)

| Method | Endpoint | Purpose | Used By |
|--------|----------|---------|---------|
| POST | `/quizzes/generate` | Generate quiz from book | quiz_provider.dart |
| GET | `/quizzes/{quizId}` | Get quiz details | quiz_provider.dart, practice_screen.dart |
| POST | `/quizzes/{quizId}/submit` | Submit quiz answers | quiz_provider.dart |
| GET | `/quizzes/stats/{userId}` | Get quiz statistics | dashboard_screen.dart |

### User Quiz Management (`/user-quiz`)

| Method | Endpoint | Purpose | Used By |
|--------|----------|---------|---------|
| GET | `/user-quiz/my-quizzes` | Get user's quizzes | quiz_provider.dart |
| POST | `/user-quiz/submit-attempt` | Submit quiz attempt | quiz_provider.dart |
| GET | `/user-quiz/results` | Get quiz results | quiz_provider.dart, practice_screen.dart |
| DELETE | `/user-quiz/{quizId}` | Delete quiz | quiz_provider.dart |
| GET | `/user-quiz/attempt/{quizId}/{attemptNumber}` | Get attempt detail for review | practice_screen.dart |

### Notes (`/notes`)

| Method | Endpoint | Purpose | Used By |
|--------|----------|---------|---------|
| POST | `/notes/sync` | Sync notes to cloud | notes_service.dart |
| GET | `/notes/shared/{bookId}` | Get shared notes | notes_provider.dart |
| GET | `/notes/all` | Get all user notes | notes_provider.dart, notes_screen.dart |
| GET | `/notes/favorites` | Get favorite notes | notes_screen.dart |
| GET | `/notes/book/{bookId}` | Get notes for book | notes_provider.dart, reading_interface_mixin.dart |
| GET | `/notes/book/{bookId}/page/{page}/notes` | Get notes for page | notes_panel.dart |
| POST | `/notes` | Create new note | notes_service.dart, reading_interface_mixin.dart |
| PUT | `/notes/{noteId}` | Update note | notes_service.dart |
| DELETE | `/notes/{noteId}` | Delete note | notes_service.dart |
| PUT | `/notes/{noteId}/favorite` | Toggle favorite | notes_provider.dart |

### Bookmarks (`/bookmarks`)

| Method | Endpoint | Purpose | Used By |
|--------|----------|---------|---------|
| GET | `/bookmarks/book/{bookId}` | Get bookmarks for book | bookmark_provider.dart |
| GET | `/bookmarks/all` | Get all user bookmarks | bookmark_provider.dart |
| POST | `/bookmarks` | Create bookmark | bookmark_service.dart |
| DELETE | `/bookmarks/{bookmarkId}` | Delete bookmark | bookmark_service.dart |
| DELETE | `/bookmarks/book/{bookId}/page/{page}` | Delete bookmark by page | bookmark_service.dart |
| GET | `/bookmarks/book/{bookId}/page/{page}` | Get bookmark for page | bookmark_service.dart |

### Reading Analytics (`/reading`)

| Method | Endpoint | Purpose | Used By |
|--------|----------|---------|---------|
| GET | `/reading/highlights/{bookId}` | Get highlights for book | reading_viewer.dart, highlights_panel.dart |
| POST | `/reading/highlights` | Create highlight | reading_viewer.dart |
| DELETE | `/reading/highlights/{highlightId}` | Delete highlight | reading_viewer.dart |

### Dashboard (`/dashboard`)

| Method | Endpoint | Purpose | Used By |
|--------|----------|---------|---------|
| GET | `/dashboard/overview` | Get dashboard data | dashboard_screen.dart |
| GET | `/dashboard/practice-suggestions` | Get practice suggestions | dashboard_screen.dart |
| GET | `/dashboard/reading-analytics/{bookId}` | Get reading analytics | dashboard_screen.dart |

### Progress Tracking (`/progress`)

| Method | Endpoint | Purpose | Used By |
|--------|----------|---------|---------|
| POST | `/progress/sync` | Sync reading progress batch | api_service.dart (unused?) |
| GET | `/progress/analytics/{userId}` | Get progress analytics | api_service.dart (unused?) |

## Data Flow Architecture

### State Management (Riverpod)

#### Provider Hierarchy

1. **AuthProvider** (`auth_provider.dart`)
   - Manages: User authentication state, Firebase Auth integration
   - Dependencies: Firebase Auth, ApiService
   - Consumers: All screens (via authentication guard)

2. **UnifiedLibraryProvider** (`unified_library_provider.dart`)
   - Manages: Book catalog, user library, reading progress
   - API Calls: `/books`, `/library/*`, `/library/update-progress`
   - Consumers: library_screen, dashboard_screen, reading_screen

3. **NotesProvider** (`notes_provider.dart`)
   - Manages: Notes CRUD, favorite notes
   - API Calls: `/notes/*`
   - Consumers: notes_screen, notes_panel, reading_interface_mixin

4. **BookmarkProvider** (`bookmark_provider.dart`)
   - Manages: Bookmarks for current book
   - API Calls: `/bookmarks/*`
   - Consumers: bookmark_panel, reading_viewer

5. **QuizProvider** (`quiz_provider.dart`)
   - Manages: Quiz generation, attempts, results
   - API Calls: `/quizzes/*`, `/user-quiz/*`
   - Consumers: practice_screen, dashboard_screen

6. **ReadingAiProvider** (`reading_ai_provider.dart`)
   - Manages: AI chat, definitions, explanations
   - API Calls: `/ai/*`
   - Consumers: ai_chat_panel, reading_interface_mixin

7. **GamificationProvider** (`gamification_provider.dart`)
   - Manages: XP, achievements, streaks
   - Dependencies: Local state (Hive?)
   - Consumers: dashboard_screen, achievement_popup

8. **ReadingPageProvider** (`reading_page_provider.dart`)
   - Manages: Current page state in reader
   - Consumers: reading_screen, reading_viewer

### Service Layer

1. **ApiService** (`services/api/api_service.dart`)
   - **Pattern**: Singleton
   - **HTTP Client**: Dio with interceptors
   - **Interceptors**: 
     - AuthInterceptor (Firebase ID token injection)
     - LogInterceptor (debug mode only)
     - ErrorInterceptor (401/403 handling)
   - **Methods**: 71 API endpoint methods
   - **Used By**: All providers and some screens directly

2. **NotesService** (`services/notes/notes_service.dart`)
   - **Pattern**: Facade over ApiService
   - **Purpose**: Notes-specific business logic
   - **Used By**: NotesProvider

3. **BookmarkService** (`services/bookmarks/bookmark_service.dart`)
   - **Pattern**: Facade over ApiService
   - **Purpose**: Bookmark-specific logic
   - **Used By**: BookmarkProvider

4. **HiveService** (`services/storage/hive_service.dart`)
   - **Purpose**: Local database abstraction
   - **Storage**: Hive boxes for offline caching
   - **Boxes**: user, books, notes, highlights, progress, cache

5. **SecureStorageService** (`services/storage/secure_storage_service.dart`)
   - **Purpose**: Encrypted key-value storage
   - **Used For**: Auth tokens, sensitive data

### Navigation Flow

**Router**: GoRouter-based declarative routing

Routes:
- `/` → SplashScreen
- `/login` → LoginScreen
- `/register` → RegisterScreen
- `/dashboard` → DashboardScreen (auth required)
- `/library` → LibraryScreen (auth required)
- `/library/category/:category` → CategoryBooksScreen
- `/reading` → ReadingScreen (auth required)
- `/viewer` → ReaderFullScreen (full-screen reading mode)
- `/practice` → PracticeScreen (auth required)
- `/notes` → NotesScreen (auth required)
- `/settings` → SettingsScreen (auth required)

## Critical Data Flows

### 1. Authentication Flow
```
User Login → LoginScreen
  → AuthProvider.login()
    → ApiService.login(email, password)
      → POST /auth/login
        → Backend validates credentials
          → Returns user data + session
            → AuthProvider updates state
              → Firebase Auth signs in
                → Router redirects to /dashboard
```

### 2. Library Browse Flow
```
User → LibraryScreen (Explore tab)
  → UnifiedLibraryProvider.loadBooks()
    → ApiService.getBooks(filters)
      → GET /books?offset=X&limit=Y&subject=Z
        → Returns BookModel list
          → Provider caches in state
            → UI renders BookCard grid
```

### 3. Reading Flow
```
User selects book → NavigationRouter
  → ReadingScreen (bookId parameter)
    → reading_viewer.dart loads
      → Detects format (PDF/EPUB)
        → _loadPdfData() OR _loadEpubData()
          → Fetches: GET /books/{bookId}/file
            → Creates blob URL / data URI
              → Sends to iframe (custom_viewer.html or custom_epub_viewer.html)
                → flutter_bridge.js handles postMessage communication
                  → Events: pageChange, textSelection, highlight, bookmark
                    → Flutter handles via _handlePdfMessage()
                      → Updates: ReadingAiProvider, BookmarkProvider, NotesProvider
```

### 4. Note Creation Flow
```
User selects text in reader → flutter_bridge.js
  → postMessage('textSelection')
    → reading_viewer.dart._onTextSelection()
      → Stores selection in state
        → User clicks "Note" button
          → ReadingInterfaceMixin.onTextSelected()
            → Shows NoteCreationDialog
              → User fills form, clicks Save
                → NotesService.createNote()
                  → ApiService.createNote()
                    → POST /notes
                      → Backend saves to Firestore
                        → Returns NoteModel
                          → NotesProvider updates state
                            → reading_viewer.dart._sendNotesToPdfViewer()
                              → flutter_bridge.js highlights text
```

### 5. Quiz Generation Flow
```
User clicks "Generate Quiz" → PracticeScreen
  → QuizProvider.generateQuiz()
    → ApiService.generateQuiz(bookId, pageRange, difficulty)
      → POST /quizzes/generate
        → Backend extracts PDF text, calls OpenAI
          → Returns QuizModel with questions
            → QuizProvider caches quiz
              → UI renders QuizSession
                → User answers questions
                  → QuizProvider.submitAttempt()
                    → POST /user-quiz/submit-attempt
                      → Backend scores, saves result
                        → Returns results
                          → UI shows QuizResults
```

## External Dependencies

### Web-Specific (in `web/` directory)
- **PDF.js** (`web/pdfjs/`) - PDF rendering engine
  - `custom_viewer.html` - Custom viewer with Flutter integration
  - `flutter_bridge.js` - Flutter↔PDF.js communication bridge
  - Handles: PDF streaming, text selection, highlights, bookmarks

- **EPUB.js** (`web/epubjs/`) - EPUB rendering engine
  - `custom_epub_viewer.html` - EPUB viewer
  - `flutter_epub_bridge.js` - Flutter↔EPUB.js bridge
  - CDN: JSZip, EPUB.js library

### Flutter Packages (pubspec.yaml)
- **State**: flutter_riverpod, riverpod_annotation
- **Navigation**: go_router
- **Network**: dio, http
- **Storage**: hive, hive_flutter, shared_preferences, flutter_secure_storage
- **Firebase**: firebase_core, firebase_auth
- **UI**: google_fonts, cached_network_image, flutter_animate, confetti, shimmer, lottie
- **File Handling**: file_picker, url_launcher

## Communication Patterns

### Flutter ↔ JavaScript Bridge (iframe postMessage)

**Flutter → JavaScript:**
```dart
_iframeElement.contentWindow.postMessage({
  'type': 'loadPDF' | 'loadEPUB' | 'goToPage' | 'displayNotes' | 'bookmarkStateUpdate',
  // ... data
}, '*');
```

**JavaScript → Flutter:**
```javascript
window.parent.postMessage({
  type: 'pdfReady' | 'bookReady' | 'pageChange' | 'textSelection' | 'highlight' | 
        'noteClicked' | 'askAI' | 'defineWord' | 'toggleBookmark' | 'deleteHighlight',
  // ... data
}, '*');
```

### Provider Communication

- Providers are **isolated** - no direct provider-to-provider calls
- Communication via:
  1. **Shared state** (providers read from each other using ref.watch/ref.read)
  2. **Callbacks** (widgets pass data up via callbacks)
  3. **Events** (some providers listen to Firebase Auth state changes)

## Caching Strategy

### Local Storage (Hive)
- **Books**: Cached for offline access
- **Notes**: Synced with backend, cached locally
- **Progress**: Cached, synced periodically
- **User Profile**: Cached

### In-Memory State
- **Riverpod**: Auto-caching via provider state
- **Dio**: HTTP response caching (implicit)

## Summary Statistics

- **Total API Endpoints**: 71 methods in ApiService
- **Total Providers**: 9 Riverpod providers
- **Total Screens**: 12 screen widgets
- **Total Reusable Widgets**: 40+ custom widgets
- **Lines of Code (estimated)**:
  - Screens: ~8,000 lines
  - Widgets: ~6,000 lines
  - Providers: ~3,000 lines
  - Services: ~1,500 lines
  - Models: ~1,000 lines

## Identified Issues & Opportunities

### Duplication
1. **JSON transformation logic** repeated in ApiService (snake_case ↔ camelCase)
2. **Error handling** patterns duplicated across providers
3. **Loading/empty states** UI code duplicated across screens
4. **Card widgets** with similar layouts but different data

### Complexity
1. **reading_viewer.dart**: 1636 lines - needs decomposition
2. **reading_interface_mixin.dart**: 1084 lines - complex state management
3. **ApiService**: 1264 lines - could be split by domain

### Architecture Gaps
1. No unified error handling model across providers
2. No standardized loading state pattern
3. Inconsistent caching strategies
4. No service interfaces/abstractions
5. Theme constants scattered (app_theme.dart + app_constants.dart)

---
*Generated: 2025-11-01*
*Purpose: Foundation for refactoring efforts*

