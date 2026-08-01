# EduMate Feature Architecture & Directory Mapping

This document describes the modular architecture of EduMate. The application is structured around a folder-per-feature directory layout inside the `lib/features/` folder to maintain separation of concerns, high modularity, and easy scalability.

---

## 1. Feature Directory & Component Mapping

### 📂 Splash (`lib/features/splash`)
* **Purpose:** Handles the initial application startup, splash screens, database warming, and session status verification.
* **Directory Structure:**
  ```text
  lib/features/splash/
  ├── screens/
  │   ├── splash_screen.dart           # Main startup screen with logo animation
  │   └── splash_screen_loading.dart   # Interactive db/session loader view
  └── widgets/
      └── splash_progress_bar.dart     # Custom visual loading indicator
  ```
* **Implementation Details:**
  * Queries `SharedPreferencesService.getToken()` asynchronously. 
  * If a valid JWT token exists, it routes directly to `MainPage` (Dashboard).
  * If the token is absent or invalid, it routes the user to the onboarding `GettingStartedScreen`.

---

### 📂 Auth & Profile (`lib/features/auth_and_profile`)
* **Purpose:** User onboarding, account registration, multi-factor verification, and profile management.
* **Directory Structure:**
  ```text
  lib/features/auth_and_profile/
  ├── screens/
  │   ├── auth/
  │   │   ├── forgot_password_screen.dart # Sends reset OTP to email
  │   │   ├── getting_started_screen.dart  # Onboarding splash and legal agreements
  │   │   ├── login_screen.dart            # Credential collector & validator
  │   │   ├── otp_verification_screen.dart # Handles OTP code entry
  │   │   ├── reset_password_screen.dart   # Lets user specify new password
  │   │   ├── signup_screen1.dart          # Primary registration fields
  │   │   └── signup_screen2.dart          # Secondary registration (Roll No/Branch)
  │   ├── profile/
  │   │   └── profile_details_screen.dart  # Detailed profile inspector
  │   └── profile_setup/
  │       ├── profile_setup_constants.dart # Config constants for profile options
  │       ├── profile_setup_dialog_flow.dart # Step-by-step setup guides
  │       └── profile_setup_logic.dart     # Helper functions for setups
  ├── services/
  │   └── token_refresh_service.dart       # JWT interceptor and silent renewal
  └── widgets/
      └── auth_background_wrapper.dart     # Sleek dark/ambient background panel
  ```
* **Implementation Details:**
  * Uses the `TokenRefreshService` as the API layer. It intercepts `401 Unauthorized` responses on outgoing requests, attempts to fetch a renewed JWT from the backend refresh token, and replays the original request to prevent session disruption.
  * Standardizes text fields with `AuthPalette.coral` cursor colors.

---

### 📂 SAPSync (`lib/features/sapsync`)
* **Purpose:** Syncs attendance statistics and official student schedules on-device directly from the university portal.
* **Directory Structure:**
  ```text
  lib/features/sapsync/
  ├── models/
  │   └── attendance_record.dart         # Data model representation for attendance
  ├── provider/
  │   └── sap_provider.dart              # Scraper controller & parsing state provider
  ├── screens/
  │   ├── sap_attendance_screen.dart     # Comprehensive attendance details screen
  │   └── sap_setup_screen.dart          # Portal credentials setup modal
  ├── services/
  │   ├── sap_auth_service.dart          # Encodes and validates portal accounts
  │   ├── sap_database_helper.dart       # Saves parsed portal data locally
  │   └── sap_webview_scraper.dart       # Webview crawler executing extracting scripts
  └── widgets/
      ├── sapsync_entry_card.dart        # Dashboard portal sync widget trigger
      ├── sap_hero_visualization.dart    # Dashboard graphical attendance hero card
      ├── sap_skeleton_loader.dart       # Loading skeleton overlay while scraping
      └── sleek_attendance_card.dart     # Subject attendance tracking card
  ```
* **Implementation & Security Model:**
  * **100% Mobile-Only:** No credentials are sent to the EduMate backend. Portal passwords are saved locally on-device inside the keystore/keychain using `FlutterSecureStorage`. All portal scraping occurs locally, adhering strictly to a zero-trust architecture.

---

### 📂 Schedule (`lib/features/schedule`)
* **Purpose:** Offline-first schedule timeline visualizer.
* **Directory Structure:**
  ```text
  lib/features/schedule/
  ├── provider/
  │   └── schedule_provider.dart         # State provider for active schedules
  ├── screens/
  │   ├── schedule_logic_mixin.dart      # Business logic mixin for databases
  │   ├── schedule_screen.dart           # Primary timetable viewing canvas
  │   └── schedule_settings_modal.dart   # Select branch/semester options
  ├── services/
  │   ├── schedule_database_helper.dart  # Offline SQLite helper for timetables
  │   └── schedule_sync_service.dart     # Syncs backend calendar changes to SQLite
  └── widgets/
      ├── schedule_class_card.dart       # Individual lecture information card
      ├── schedule_timeline.dart         # Daily timeline path track
      └── week_calendar_grid.dart        # Horizontal calendar week picker
  ```
* **Implementation Details:**
  * Saves active branch, section, and elective selections in `SharedPreferences`.
  * Integrates with `ScheduleDatabaseHelper` to read offline schedules instantly upon loading.

---

### 📂 CGPA & Home (`lib/features/home`)
* **Purpose:** Main greeting page, dashboard hub, and academic calculator utilities.
* **Directory Structure:**
  ```text
  lib/features/home/
  ├── screens/
  │   ├── cgpa_calculator_screen.dart    # Slider-based CGPA projection screen
  │   ├── holiday_list_screen.dart       # Local holiday event list screen
  │   ├── home_screen.dart               # Core student greeting dashboard
  │   └── post_management_screen.dart    # Admin dashboard post feed shortcut
  ├── services/
  │   └── home_schedule_service.dart     # Service coordinating home widget calendar items
  └── widgets/
      ├── dashboard_action_card.dart     # Shortcut grid options (CGPA, Map, etc.)
      └── todays_schedule_card.dart      # Carousel listing remaining today lectures
  ```

---

### 📂 Events (`lib/features/events`)
* **Purpose:** Campus social feed and administrative announcements.
* **Directory Structure:**
  ```text
  lib/features/events/
  ├── screens/
  │   ├── create_post_screen.dart        # Editor allowing media attachments
  │   ├── event_screen.dart              # Social events & announcements feed
  │   └── post_detail_screen.dart        # Full screen view for posts
  └── widgets/
      └── event_card.dart                # Individual event card widget with 4:3 image
  ```
* **Implementation Details:**
  * **Direct Cloudinary Uploads:** Uses a signed upload architecture. Before uploading an image, the app requests a signature from the backend (`GET /api/upload/signature`), then posts the image directly to Cloudinary from the phone. The resulting image URL is submitted along with the post data to MongoDB, minimizing server bandwidth usage.

---

### 📂 Navigation (`lib/features/navigation`)
* **Purpose:** Campus search, location discovery, and routing.
* **Directory Structure:**
  ```text
  lib/features/navigation/
  ├── models/
  │   └── poi_model.dart                 # Point of Interest data model (coords, type)
  ├── screens/
  │   ├── map_action_buttons.dart        # Recenter and navigation toggle layer
  │   ├── map_screen.dart                # Mapbox map viewport screen
  │   └── map_search_bar.dart            # Auto-complete campus location search bar
  ├── services/
  │   ├── map_navigation_store.dart      # Navigation coordinate store state
  │   ├── map_route_service.dart         # Pathfinding route logic using maps
  │   ├── map_service.dart               # Handles Mapbox tokens and configurations
  │   ├── navigation_manager.dart        # Tracks turn-by-turn positions
  │   └── poi_service.dart               # Fetches Points of Interest from database
  └── widgets/
      ├── map_skeleton_loader.dart       # Mockup loader displaying map loading
      └── navigation_status_card.dart    # Route duration and distance indicator card
  ```
* **Implementation Details:**
  * Uses the `geolocator` plugin to request coarse and precise coordinates. Recenters and tracks user movement dynamically on the custom campus coordinate grid.

---

### 📂 Friends (`lib/features/friends`)
* **Purpose:** Timetable comparison and scheduling coordination among peers.
* **Directory Structure:**
  ```text
  lib/features/friends/
  ├── models/
  │   └── friend_model.dart              # Class structure representing a classmate
  ├── screens/
  │   ├── friends_schedule_screen.dart   # Gantt visualizer container screen
  │   └── friends_settings_screen.dart   # Management options for added peers
  ├── services/
  │   ├── friends_schedule_service.dart  # Coordinates schedule compare APIs
  │   └── friends_storage_service.dart   # Local sqlite list for added friends
  └── widgets/
      ├── add_friend_dialog_flow.dart    # Input roll number search dialog
      └── friends_gantt_chart.dart       # Gantt horizontal timeline compare card
  ```

---

### 📂 Settings (`lib/features/settings`)
* **Purpose:** Privacy settings, SAPSync credential clearing, and account purging.
* **Directory Structure:**
  ```text
  lib/features/settings/
  └── screens/
      └── settings_screen.dart           # Custom toggle preferences screen
  ```
* **Implementation Details:**
  * **Google Play Compliance:** Implements a strict account deletion process. Deletes all remote posts and user entries on the MongoDB server via `TokenRefreshService.authenticatedDelete(Config.profileEndpoint)`. Upon confirmation, clears local secure credentials, database caches, and logs the user out.

---

### 📂 Admin (`lib/features/admin`)
* **Purpose:** Administrative operations, data loading, class schedules and branch updates.
* **Directory Structure:**
  ```text
  lib/features/admin/
  ├── admin_home_screen.dart             # Admin controls homepage panel
  ├── admin_main_app.dart                # Administrative navigation wrapper
  ├── admin_settings_screen.dart         # Admin options screen
  ├── curriculum/
  │   ├── curriculum_editor_screen.dart  # Form to edit subjects, credits, and syllabi
  │   └── curriculum_management_screen.dart # Branch curriculum manager dashboard
  ├── general/
  │   ├── admin_holiday_management.dart  # Upload/replace holiday list JSONs
  │   ├── admin_poi_management.dart      # Create/delete map points of interest
  │   ├── admin_post_management.dart     # Delete flagged or outdated social posts
  │   └── admin_upload_screen.dart       # Generic JSON batch uploader view
  ├── schedule/
  │   ├── admin_elective_management.dart  # Configure elective groups and divisions
  │   ├── schedule_editor_screen.dart    # Class time block configurator
  │   └── schedule_management_screen.dart # Visual schedule timetable grid manager
  └── users/
      ├── admin_student_data_management.dart # Student attendance database controller
      ├── admin_user_details_screen.dart # Detail card showing registered account fields
      └── admin_user_management.dart     # Normal student/admin roles auditor list
  ```

---

### 📂 Feedback (`lib/features/feedback`)
* **Purpose:** Allows students to report bugs or request features.
* **Directory Structure:**
  ```text
  lib/features/feedback/
  └── screens/
      └── feedback_screen.dart           # Standard bug submission form
  ```

---

### 📂 PWA (`lib/features/pwa`)
* **Purpose:** Handles Progressive Web App wrapper files.
* **Directory Structure:**
  ```text
  lib/features/pwa/
  └── screens/
      └── pwa_install_screen.dart        # Screen promoting Web installer setups
  ```

---

## 3. Shared Assets & Core Libraries (`lib/shared`)

All shared classes that do not belong to a single feature are placed inside `lib/shared/`:
* **`config.dart`:** Exposes global configuration parameters, API urls (`BASE_URL`), and standard endpoint routing.
* **`provider/`:** State containers for animation triggers and global themes.
* **`services/`:** Standard utility layers such as `SharedPreferencesService` (managing user metadata) and SQLite Helpers.
* **`utils/`:** Form validators, date parse formatters, and device metrics.
* **`widgets/`:** Houses cross-feature UI widgets like glassmorphic dialogues, custom buttons, custom headers, and text formatting tools.
