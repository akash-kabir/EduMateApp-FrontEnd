# EduMate - Flutter Frontend

EduMate is a dark-mode-first Flutter app for campus life: authentication, profile setup, class schedule, events/news posts, map navigation, and admin upload tools.

## Current Status (March 2026)

This README reflects the current codebase in this repository.

Recent additions and fixes include:
- Event/news feed redesign with compact cards and expandable details
- Create-post flow with optional image support
- Signed Cloudinary upload flow (frontend uploads directly to Cloudinary)
- Profile details screen redesign and data consistency fixes
- Role normalization and stronger session cleanup on logout
- Create Post visibility gated by user role (`society_head`)

## Tech Stack

- Flutter (Dart)
- Cupertino + Material widgets
- Provider (animation state)
- HTTP REST integration
- SharedPreferences for local persistence
- Mapbox (map rendering)
- Geolocator + Connectivity
- Image Picker

## Key Features

### 1) Authentication and Profile
- Multi-step signup (`signup_screen1`, `signup_screen2`)
- Username/email availability checks
- Login with `usernameOrEmail`
- Profile setup with KIIT email prefill support
- Profile details view with grouped personal/academic/account info
- Role-aware behavior (`student`, `society_head`, etc.)

### 2) Home and Utilities
- Personalized home greeting
- Profile setup reminder dialog
- Quick navigation from home to schedule/events
- CGPA calculator screen

### 3) Schedule Module
- Branch/class-based schedule loading
- Saved class preference persistence
- Backend schedule fetch with cache fallback

### 4) Events and News Module
- Feed with filters (`all`, `news`, `event`)
- Role-gated create-post button for society heads
- Instagram-style event card layout with:
  - author header
  - optional image (4:3)
  - compact heading card
  - conditional More/Less visibility
- Adaptive body behavior:
  - if image exists, body appears in expandable section
  - if image is absent, body appears below heading

### 5) Post Creation and Media Upload
- News/Event post creation with validation
- Event metadata support (date/time ranges, location)
- Optional image selection and preview
- Signed upload flow:
  1. App requests signature from backend (`/api/upload/signature`)
  2. App uploads directly to Cloudinary
  3. Returned secure URL is included in post payload

### 6) Map and Navigation
- Mapbox-powered campus map
- Campus search and suggestions
- Current location tracking
- Route drawing and reroute logic

### 7) Admin Area
- Admin splash and admin login flow
- Admin upload screens for curriculum and schedule

## Project Structure (Current)

```text
lib/
|- main.dart
|- main_page.dart
|- config.dart
|- poi.dart
|- animated_background/
|  |- animated_circle_gradient.dart
|- app_navigation/
|  |- nav_bar.dart
|- constants/
|  |- app_constants.dart
|- mixins/
|  |- form_error_state_mixin.dart
|- provider/
|  |- animation_provider.dart
|- services/
|  |- api_service.dart
|  |- map_service.dart
|  |- navigation_service.dart
|  |- shared_preferences_service.dart
|- theme/
|  |- app_theme.dart
|- utils/
|  |- validators.dart
|- widgets/
|  |- auth_background_wrapper.dart
|- screens/
|  |- admin/
|  |  |- adminsplash/
|  |  |  |- admin_splash_screen.dart
|  |  |- admin_auth/
|  |  |  |- admin_login_screen.dart
|  |  |- admin_main_app.dart
|  |  |- admin_screens/
|  |     |- admin_home_screen.dart
|  |     |- admin_upload_screen.dart
|  |- auth/
|  |  |- auth_background_wrapper.dart
|  |  |- getting_started_screen.dart
|  |  |- login_screen.dart
|  |  |- signup_screen1.dart
|  |  |- signup_screen2.dart
|  |- event/
|  |  |- create_post_screen.dart
|  |  |- event_card.dart
|  |  |- event_screen.dart
|  |- home/
|  |  |- home_screen.dart
|  |  |- cgpa_calculator/
|  |     |- cgpa_calculator_screen.dart
|  |- map/
|  |  |- map_screen.dart
|  |- profile/
|  |  |- profile_details_screen.dart
|  |  |- profile_screen.dart
|  |- profile_setup/
|  |  |- profile_setup_screen.dart
|  |- schedule/
|  |  |- schedule_screen.dart
|  |- splash/
|     |- splash_screen.dart
|     |- splash_screen_loading.dart
|     |- splash_progress_bar.dart
|     |- components/
|        |- splash_progress_bar.dart
```

## Dependencies (from `pubspec.yaml`)

| Package | Version | Purpose |
|---|---:|---|
| cupertino_icons | ^1.0.8 | Cupertino icon set |
| http | ^1.1.0 | REST calls |
| shared_preferences | ^2.2.2 | Local persistence |
| provider | ^6.0.0 | State management |
| file_picker | ^10.3.8 | File selection |
| mapbox_maps_flutter | ^2.18.0 | Map rendering |
| geolocator | ^14.0.2 | Device location |
| connectivity_plus | ^7.0.0 | Network status checks |
| image_picker | ^1.1.2 | Image selection for posts |

## Setup

### Prerequisites
- Flutter SDK compatible with Dart SDK `^3.10.4`
- Android Studio/Xcode for emulator/device

### Install

```bash
git clone <your-repo-url>
cd EduMateApp-FrontEnd/edumate
flutter pub get
```

### Run

```bash
flutter run
```

## API Configuration

Base API endpoint is configured in `lib/config.dart`:
- `Config.BASE_URL`

Main modules use these endpoint groups:
- users/auth/profile
- posts
- upload signature
- curriculum
- schedule

## Environment Notes

Image posting relies on backend + Cloudinary setup.
Backend should expose signature endpoint:
- `GET /api/upload/signature`

Expected Cloudinary environment variables (backend):
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

## Known Notes

- App is locked to portrait orientation.
- Theme mode is dark-only in current implementation.
- Some legacy/placeholder folders exist (for example empty `cards` folders); architecture above reflects what currently exists on disk.

## Troubleshooting

### Build issues
```bash
flutter clean
flutter pub get
flutter run
```

### API issues
- Verify backend is reachable at `Config.BASE_URL`
- Verify auth token exists in SharedPreferences after login
- Verify role is correct if Create Post button is missing

### Map issues
- Ensure Mapbox keys are correctly configured on backend and delivered to app

## Contributing

1. Create a feature branch
2. Commit focused changes
3. Open a pull request with clear scope and test notes

## License

This project is licensed under the MIT License.
