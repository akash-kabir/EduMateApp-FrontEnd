# EduMate - Flutter Frontend Application

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-red.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

A modern, feature-rich Flutter education platform with beautiful glassmorphic UI, smooth animations, and comprehensive authentication system.

[Features](#-features) • [Installation](#-installation) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## ✨ Overview

EduMate is a production-ready Flutter application showcasing modern mobile development practices. It features a seamless user experience with glassmorphic design patterns, sophisticated animations, and a robust authentication system with both user and admin portals.

**Perfect for:**
- 🎓 Educational platforms
- 👥 Multi-role authentication systems
- 🎨 UI/UX inspiration with Glassmorphism
- 📚 Learning advanced Flutter concepts

### 🎉 Latest Updates (January 2026)

✨ **New Features & Improvements:**
- ✅ **Two-Tier Splash Architecture** - Separate splash for initial launch and post-auth loading
- ✅ **Smart Loading Progress Bar** - Visual API loading with 20%→30%→60%→80%→100% progression
- ✅ **New User Handling** - Graceful 30%→100% jump when profile API fails for new users
- ✅ **Shared Preferences Caching** - Eliminated repeated getInstance() calls for performance
- ✅ **Greeting Calculation Memoization** - Cached greeting only recalculated on state changes
- ✅ **HTTP Connection Pooling** - Static persistent _httpClient for connection reuse
- ✅ **Centralized Color Constants** - AppColors class with primaryBlue and adminPrimaryRed
- ✅ **Profile Setup Constants** - ProfileSetupConstants with email domain, year calculations, branches, semesters
- ✅ **Extracted AuthBackgroundWrapper** - Removed 45+ lines of duplicate animated background code
- ✅ **Comprehensive Code Audit** - Identified and documented all code quality issues (CODE_AUDIT_REPORT.md)
- ✅ **Production-Ready** - Zero compilation errors, clean codebase with no debug code

**Performance Improvements:**
- 🚀 Reduced API response time by connection pooling
- 🚀 Eliminated unnecessary SharedPreferences lookups
- 🚀 Removed hardcoded color values for better maintainability
- 🚀 Extracted duplicate code for 45% size reduction in some screens

**Code Quality Enhancements:**
- 📊 Removed all debug print statements from production code
- 📊 Eliminated unused imports across all screens
- 📊 Created ProfileSetupConstants for all hardcoded profile values
- 📊 Centralized color definitions to AppColors class
- 📊 Generated WIDGET_REFACTORING_RECOMMENDATIONS.md for future optimization

### 🎉 Latest Updates (March 2026)

✨ **Posts, Media & Role Reliability Enhancements:**
- ✅ **Instagram-Style Events/News Feed** - Refined post cards with author header, gradient headline card, image support, and expandable details
- ✅ **Smart Body Placement** - Body text now auto-adjusts: visible below heading when image is absent, collapsible when image is present
- ✅ **Context-Aware More/Less Control** - "More" is hidden when no extra content exists (no body collapse content and no event metadata)
- ✅ **Profile Details Overhaul** - Improved profile details UI with grouped sections, quick stats, and cleaner academic/personal data presentation
- ✅ **Role Normalization Fixes** - Role handling normalized to avoid case-related mismatches across login/profile/event permissions
- ✅ **Session Cleanup Hardening** - Logout now fully clears user session preferences to prevent stale role/profile state
- ✅ **Cloudinary Media Pipeline** - Added secure signed upload flow (frontend uploads directly to Cloudinary using backend signature endpoint)

**Backend/Integration Notes:**
- 🔐 Added signed media upload endpoint for Cloudinary (`/api/upload/signature`)
- 🖼️ Post model supports optional `imageUrl` for event/news media cards
- 🧭 Event creation flow supports optional 4:3 image uploads with preview before publish

---

## 🎯 Key Features

### 🔐 Authentication System
- **Multi-step User Registration** - First name/last name → Email, username, password
- **Smart Form Validation** - Real-time validation with visual feedback
- **Username/Email Availability** - API integration to check availability with loading indicators
- **Password Strength Meter** - Visual indicator (Weak/Medium/Strong) with requirements checklist
- **Advanced Password Requirements**
  - Minimum 8 characters
  - Uppercase letters (A-Z)
  - Lowercase letters (a-z)
  - Numbers (0-9)
  - Special characters (!@#$%^&*)
- **Secure Login** - Support for both username and email login
- **Password Visibility Toggle** - Easy password management
- **Profile Setup Screen** - Academic details collection (year, semester, branch)
- **KIIT Email Auto-Detection** - Automatic roll number extraction from KIIT email addresses

### 📱 Loading & Progress
- **Two-Tier Splash System** - Smart initial splash + API loading splash
- **Visual Progress Bar** - Real-time API loading progress with percentage display
- **Intelligent New User Handling** - Auto-jumps to 100% when profile API fails
- **Smooth Progress Transitions** - Staged loading (20% → 30% → 60% → 80% → 100%)
- **Post-Auth Home Screen** - Instant render with cached data
- **Dynamic Island Interface** - Minimized/maximized states with profile setup detection

### 👨‍💼 Admin Portal
- **Dedicated Admin Splash Screen** - Red-themed branding with animated progress
- **Admin Authentication** - Separate admin login flow with enhanced security
- **Admin Dashboard Ready** - Foundation for advanced admin features

### 📰 Events & Posts
- **Create Post Screen (Society Head)** - News/Event creation with title, body, links, location, date/time and optional media
- **Cloudinary Signed Uploads** - Direct client upload using backend-generated signature
- **4:3 Media Support** - Feed-ready image ratio for consistent cards
- **Adaptive Card Behavior** - Heading-focused compact card with dynamic body placement and conditional expand controls
- **Role-Gated Publishing** - Create-post action shown only for eligible roles

### 🎨 Premium UI/UX
- **Glassmorphic Design** - Modern frosted glass effects using BackdropFilter
- **Smooth Animations**
  - Page entrance with scale + fade (1200ms)
  - Text reveal animation (800ms)
  - Continuous background circle pulse (5000ms)
  - Page transition fades (300ms)
- **Dark Mode First** - Eye-friendly dark theme throughout
- **Responsive Layouts** - Pixel-perfect on all device sizes
- **Smart Keyboard Handling** - Automatic padding without scaffold shrinking
- **Portrait-Only Mode** - Optimized single-orientation experience

### ⚙️ Technical Excellence
- **Provider State Management** - Centralized global animation controller
- **Restful API Integration** - Seamless backend communication with connection pooling
- **Local Data Persistence** - Token storage with SharedPreferences caching
- **Form Error Animations** - Engaging error state feedback
- **Code Optimization** - Constants extraction, code deduplication, reusable widgets
- **Role/Session Consistency** - Normalized role values and robust logout clearing to avoid stale auth state
- **Performance Features**
  - HTTP connection pooling for faster requests
  - Shared preferences instance caching to reduce I/O
  - Greeting calculation memoization
  - Optimized widget rebuilds with Provider

---

## 📁 Project Architecture

```
lib/
├── main.dart                              # Application entry point
├── config.dart                            # API endpoints configuration
├── main_page.dart                         # Main user dashboard
│
├── constants/
│   └── app_constants.dart                 # 100+ centralized constants
│                                          # Colors, sizes, durations, spacing
│                                          # ProfileSetupConstants, AppColors
│
├── theme/
│   └── app_theme.dart                     # Dark theme configuration
│                                          # References AppColors constants
│
├── provider/
│   └── animation_provider.dart            # Global animation state management
│
├── mixins/
│   └── form_error_state_mixin.dart        # Reusable error handling logic
│
├── services/
│   └── api_service.dart                   # API client with connection pooling
│                                          # Static _httpClient for reuse
│
├── utils/
│   └── validators.dart                    # Email, username, password validators
│
├── widgets/
│   ├── auth_background_wrapper.dart       # Extracted animated background
│   └── glass_button.dart                  # Glassmorphic button component
│
├── screens/
│   ├── splash/
│   │   ├── splash_screen.dart             # Initial app splash (token check)
│   │   ├── splash_screen_with_api_loading.dart  # Post-auth loading splash
│   │   └── components/
│   │       └── splash_progress_bar.dart   # API loading orchestration
│   │
│   ├── auth/
│   │   ├── getting_started_screen.dart    # Entry point with navigation
│   │   ├── signup_screen1.dart            # Step 1: Name input
│   │   ├── signup_screen2.dart            # Step 2: Credentials input
│   │   └── login_screen.dart              # User login form
│   │
│   ├── profile_setup/
│   │   └── profile_setup_screen.dart      # KIIT email auto-detection & form
│   │
│   ├── home/
│   │   ├── home_screen.dart               # Main dashboard with cached prefs
│   │   └── dynamic_island/
│   │       ├── dynamic_island.dart        # Minimized/maximized container
│   │       ├── island_behavior.dart       # State management
│   │       └── states/
│   │           ├── normal/
│   │           ├── minimized/
│   │           ├── maximized/
│   │           └── profile_setup/
│   │
│   └── admin/
│       ├── admin_splash/
│       │   └── admin_splash_screen.dart   # Admin portal splash
│       └── admin_auth/
│           └── admin_login_screen.dart    # Admin login form
│
└── animated_background/
    └── animated_circle_gradient.dart      # Reusable animated background widget
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK** 3.0 or higher
- **Dart** 3.0 or higher
- **Android Studio** / **Xcode** (for device/emulator)
- **Git** for version control

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/EduMate.git
   cd EduMate/EduMateApp-FrontEnd/app
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoints** (`lib/config.dart`)
   ```dart
   class Config {
     static const String BASE_URL = 'https://your-api.com';
     static const String loginEndpoint = '$BASE_URL/api/auth/login';
     static const String registerEndpoint = '$BASE_URL/api/auth/register';
   }
   ```

4. **Run the application**
   ```bash
   # Debug mode
   flutter run

   # Release mode
   flutter run --release
   ```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | ^6.1.5 | State management |
| `http` | ^1.1.0 | HTTP requests |
| `shared_preferences` | ^2.2.2 | Local data persistence |
| `image_picker` | ^1.1.2 | Image selection for post media |
| `flutter_cupertino_localizations` | ^1.0.0 | iOS localization |

### Installing Dependencies
```bash
flutter pub get
```

---

## 🔧 Core API Reference

### AnimationProvider
Global animation state management with centralized controllers.

```dart
// Usage in widgets
final provider = Provider.of<AnimationProvider>(context);

// Methods
provider.startPageEntranceAnimations();    // Start all animations
provider.resetPageEntranceAnimations();    // Reset to initial state
provider.updateTickerProvider(vsync);      // Update ticker provider

// Getters
provider.backgroundCircleController        // 5-second pulse animation
provider.pageEntranceController            // Scale + fade animation
provider.textRevealController              // Text reveal animation
provider.fadeAnimation                     // Opacity animation
provider.scaleAnimation                    // Scale animation
provider.revealAnimation                   # Width reveal animation
```

### ApiService
Centralized API client for authentication operations.

```dart
// Register new user
final response = await ApiService.register(
  firstName: 'John',
  lastName: 'Doe',
  username: 'johndoe',
  email: 'john@example.com',
  password: 'SecurePass123!',
);

// Login user
final response = await ApiService.login(
  usernameOrEmail: 'johndoe',
  password: 'SecurePass123!',
);

// Check username availability
final response = await ApiService.checkUsernameAvailability('johndoe');

// Check email availability
final response = await ApiService.checkEmailAvailability('john@example.com');
```

### FormErrorStateMixin
Reusable mixin for consistent form error handling across all screens.

```dart
// Apply to any state class
class _SignupScreenState extends State<SignupScreen> with FormErrorStateMixin {
  
  @override
  void initState() {
    super.initState();
    // ErrorAnimationController automatically initialized
  }
  
  // Methods available
  setUsernameError(true);      // Trigger error animation
  setPasswordError(true);
  setEmailError(true);
  resetAllErrors();            // Clear all errors
  
  // Properties
  isUsernameError              // Check error state
  isPasswordError
  isEmailError
}
```

### Validators
Utility functions for input validation.

```dart
// Email validation
Validators.validateEmail('test@example.com');  // Returns error message or null

// Username validation (3+ alphanumeric characters)
Validators.validateUsername('johndoe');

// Password strength assessment
Validators.getPasswordStrength('Pass123!');    // Returns 'weak' | 'medium' | 'strong'

// Password requirements validation
Validators.validatePasswordRequirements('Pass123!');  // Returns detailed requirements
```

---

## 🎨 Design System

### Color Palette

| Theme | Color | Usage |
|-------|-------|-------|
| **Admin Primary** | `#FF1744` | Admin buttons, icons |
| **Admin Accent** | `#FF6B35` | Admin gradients |
| **User Primary** | `#9C27B0` | User theme primary |
| **User Secondary** | `#2196F3` | User theme secondary |
| **Success** | `#4CAF50` | Valid password states |
| **Warning** | `#FF9800` | Password strength medium |
| **Error** | `#F44336` | Invalid inputs |
| **Admin Primary** | `#FF1744` | Admin buttons, icons |
| **Admin Accent** | `#FF6B35` | Admin gradients |
| **User Primary** | `#9C27B0` | User theme primary |
| **User Secondary** | `#2196F3` | User theme secondary |
| **Success** | `#4CAF50` | Valid password states |
| **Warning** | `#FF9800` | Password strength medium |
| **Error** | `#F44336` | Invalid inputs |
| **Disabled** | `#BDBDBD` | Inactive states |
| **Background** | `#000000` | App background |
| **Text Primary** | `#FFFFFF` | Main text |
| **Text Secondary** | `#B3FFFFFF` | Secondary text |

### Typography

| Size | Font Weight | Usage |
|------|-------------|-------|
| 48px | Bold | Large headings |
| 36px | Bold | Admin title |
| 28px | Bold | Page titles |
| 26px | Bold | Form labels |
| 24px | Bold | Subheadings |
| 16px | Regular | Body text |
| 14px | Regular | Secondary text |
| 12px | Regular | Captions |

### Animation Timings

| Animation | Duration | Curve | Effect |
|-----------|----------|-------|--------|
| Page Entrance | 1200ms | EaseOut | Scale 0.9→1.0 + Fade |
| Text Reveal | 800ms | EaseInOut | Left-to-right clip |
| Background Circle | 5000ms | Linear | Continuous pulse |
| Page Transition | 300ms | Linear | Fade between screens |
| Form Error | 400ms | Linear | Shake animation |

---

## 🏗️ Architecture & Patterns

### State Management
- **Provider Pattern** - Centralized animation controller
- **Stateful Widgets** - Form management with local state
- **Mixins** - FormErrorStateMixin for error handling reuse

### Navigation
```
Splash Screen
    ↓
Getting Started Screen
    ├─→ Get Started ─→ Signup Step 1 ─→ Signup Step 2 ─→ Login
    ├─→ Admin Login ─→ Admin Splash ─→ Admin Login
    └─→ Exit ─→ Confirmation Dialog
```

### Code Optimization Features
1. **API Service Deduplication** - Shared `_makeGetRequest()` helper
2. **Animation Provider Consolidation** - Centralized animation management
3. **Constants Extraction** - 100+ design constants in `app_constants.dart`
4. **FormErrorStateMixin** - DRY error handling across all forms
5. **Import Cleanup** - Minimal, intentional imports
6. **Granular Widget Rebuilds** - Optimized Provider listeners

---

## 📱 Screen Gallery

### User Flow
- **Getting Started** - Glassmorphic entry with navigation options
- **Signup Step 1** - Name input with smooth scrolling
- **Signup Step 2** - Email, username, password with availability checking
- **Login** - Unified login for registered users
- **Main Dashboard** - Post-auth home screen

### Admin Flow
- **Admin Splash** - Custom branding with progress animation
- **Admin Login** - Red-themed admin authentication

---

## 🔐 Security Features

✅ **Password Validation**
- Minimum 8 characters enforced
- Special character requirement
- Uppercase and lowercase mix required
- Number requirement

✅ **Data Security**
- Tokens stored in SharedPreferences
- HTTPS API communication ready
- Input sanitization via validators

✅ **Device Security**
- Portrait orientation lock
- Prevents accidental data exposure
- Controlled keyboard interactions

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/validators_test.dart
```

---

## � Recent Improvements & Optimizations (January 2026)

### Architecture Enhancements
- **AuthBackgroundWrapper Widget** - Extracted duplicate animated background code from 3 auth screens
  - Reduced code duplication by 45 lines across signup_screen1, signup_screen2, login_screen
  - Single source of truth for background animation logic

- **Two-Tier Splash System** - Intelligent splash screen architecture
  - Initial SplashScreen for token checking and quick app launch
  - SplashScreenWithApiLoading for post-auth API calls
  - Separate SplashProgressBar component for orchestrating API calls

- **Smart New User Detection** - Graceful handling of new user profile creation
  - Progress bar reaches 30% (profile status check)
  - If API fails (new user): Jump to 100% and navigate to home
  - If API succeeds (existing user): Continue normal progression (30%→60%→80%→100%)

### Performance Optimizations

**1. HTTP Connection Pooling**
   - Static persistent `_httpClient` instance in ApiService
   - Connection reuse across multiple requests
   - Reduced overhead of creating new connections
   - See: `lib/services/api_service.dart` line 6

**2. SharedPreferences Caching**
   - Cache `_prefs` instance in home_screen.dart
   - Eliminates repeated `getInstance()` async calls
   - Direct property access instead of lookups
   - See: `lib/screens/home/home_screen.dart` lines 29-43

**3. Greeting Calculation Memoization**
   - Calculate `_cachedGreeting` once and store
   - Reuse on every build() call
   - Only recalculate when state changes
   - Reduces CPU usage and unnecessary recalculations
   - See: `lib/screens/home/home_screen.dart` lines 71-98

### Code Quality Improvements

**Debug Code Removal**
- ✅ Removed all `print()` statements from production code
  - `island_behavior.dart` lines 179, 183
- ✅ Removed debug buttons from home_screen.dart
  - "Logout (Debug)" button
  - "View API Loading Screen (Debug)" button
- ✅ No debug code in production builds

**Constants Centralization**
- ✅ **ProfileSetupConstants** - All profile setup hardcoded values
  - Email domain: `@kiit.ac.in`
  - Year base value: `2000`
  - Academic year start month: `6` (June)
  - Lists: academicYears, branches, semestersByYear
  - Range validation: min/max academic year
  - See: `lib/constants/app_constants.dart` lines 116-142

- ✅ **AppColors** - All color definitions
  - `primaryBlue: Color(0xFF007AFF)`
  - `adminPrimaryRed: Color(0xFFFF1744)`
  - Used in app_theme.dart and admin_splash_screen.dart
  - See: `lib/constants/app_constants.dart` lines 111-115

**Unused Code Removal**
- ✅ Removed unused imports:
  - `package:provider/provider.dart` from all 3 auth screens (moved to AuthBackgroundWrapper)
  - `../auth/getting_started_screen.dart` from home_screen.dart
  - `../splash/splash_screen_with_api_loading.dart` from home_screen.dart
- ✅ Removed unused `_logout()` method from home_screen.dart (debug code)

**Documentation**
- ✅ Generated `CODE_AUDIT_REPORT.md` with 118 comments analysis
- ✅ Generated `WIDGET_REFACTORING_RECOMMENDATIONS.md` for future optimizations
- ✅ Identified 14+ widgets to extract (Phase 1-3 refactoring plan)

### Code Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Total Dart Files | 35 | ✓ Manageable |
| Debug Code | 0 | ✓ Production Ready |
| Print Statements | 0 | ✓ Removed |
| Hardcoded Colors | 0 | ✓ Centralized |
| Duplicate Code Blocks | 0 | ✓ Extracted |
| Unused Imports | 0 | ✓ Cleaned |
| Compilation Errors | 0 | ✓ Zero |

### Documentation Files Created
1. **CODE_AUDIT_REPORT.md** - Comprehensive code quality analysis
2. **WIDGET_REFACTORING_RECOMMENDATIONS.md** - Detailed refactoring guide
   - Phase 1: signup_screen2.dart (771 → 400 lines)
   - Phase 2: profile_setup_screen.dart (503 → 300 lines)
   - Phase 3: Login screens refactoring

---

- **[Project Structure Guide](docs/PROJECT_STRUCTURE.md)**
- **[API Documentation](docs/API.md)**
- **[Contributing Guidelines](CONTRIBUTING.md)**
- **[Code Optimization Notes](OPTIMIZATIONS.md)**

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📋 Roadmap

- [ ] Password recovery/reset flow
- [ ] Two-factor authentication (2FA)
- [ ] Biometric authentication (fingerprint/face)
- [ ] Light theme variant
- [ ] Multi-language support (i18n)
- [ ] Admin dashboard with analytics
- [ ] User profile management
- [ ] Social login integration

---

## 🐛 Known Issues & Troubleshooting

### Common Issues

**Issue:** Flutter version mismatch
```bash
flutter upgrade
flutter pub get
```

**Issue:** Android build failure
```bash
flutter clean
flutter pub get
flutter run
```

**Issue:** API connection errors
- Verify `BASE_URL` in `lib/config.dart`
- Check network connectivity
- Ensure backend API is running

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Development Team** - EduMate Project

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Provider package for state management
- Community for continuous feedback and support

---

## 📞 Support & Contact

- **Issues:** [GitHub Issues](https://github.com/yourusername/EduMate/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/EduMate/discussions)
- **Email:** support@edumate.com

---

## 🌟 If you found this helpful, please star the repository!

<div align="center">

Made with ❤️ by the EduMate Team

[⬆ back to top](#-edumate---flutter-frontend-application)

</div>

### User Authentication
- ✅ **User Registration** - Multi-step signup with email/username availability checking
- ✅ **User Login** - Secure login with email/username support
- ✅ **Password Requirements** - Real-time password strength validation (8+ chars, uppercase, lowercase, numbers, special chars)
- ✅ **Password Visibility Toggle** - Show/hide password while typing
- ✅ **Form Validation** - Real-time email, username, and password validation
- ✅ **Error States** - Animated error handling with visual feedback

### Admin Portal
- ✅ **Admin Splash Screen** - Custom branding with animated progress bar
- ✅ **Admin Login** - Dedicated admin authentication with red theme
- ✅ **Admin Dashboard Ready** - Foundation for admin features

### UI/UX Features
- ✅ **Glassmorphic Design** - Frosted glass effect with BackdropFilter and blur
- ✅ **Smooth Animations** - Page entrance (scale+fade), text reveal, background circles
- ✅ **Dark Mode** - Dark-first design philosophy
- ✅ **Responsive Layout** - Adapts to all screen sizes
- ✅ **Keyboard Handling** - Smart padding when keyboard appears
- ✅ **Portrait Orientation Lock** - Portrait-only device orientation

### Technical Features
- ✅ **Provider State Management** - Global animation controller
- ✅ **API Integration** - Check username/email availability, register, login
- ✅ **Shared Preferences** - Local data persistence (token storage)
- ✅ **Error Animations** - Shake effects for form errors
- ✅ **Code Optimization** - Constants extraction, code deduplication, mixins

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── config.dart                        # API configuration
├── main_page.dart                     # Main user dashboard
├── constants/
│   └── app_constants.dart            # Centralized constants (colors, sizes, durations)
├── theme/
│   └── app_theme.dart                # Dark theme configuration
├── provider/
│   └── animation_provider.dart       # Global animation controller
├── mixins/
│   └── form_error_state_mixin.dart   # Reusable error state logic
├── services/
│   └── api_service.dart              # API calls (login, register, check availability)
├── utils/
│   └── validators.dart               # Email, username, password validators
├── screens/
│   ├── splash/
│   │   └── splash_screen.dart        # App splash screen
│   ├── auth/
│   │   ├── getting_started_screen.dart
│   │   ├── signup_screen1.dart       # First signup form (name input)
│   │   ├── signup_screen2.dart       # Second signup form (credentials)
│   │   ├── login_screen.dart         # User login form
│   │   └── widgets/
│   │       └── glass_button.dart     # Glassmorphic button widget
│   └── admin/
│       ├── adminsplash/
│       │   └── admin_splash_screen.dart
│       └── admin_auth/
│           └── admin_login_screen.dart
└── animated_background/
    └── animated_circle_gradient.dart # Reusable animated background widget
```


## 🚀 Core Functions & Methods

### AnimationProvider (`lib/provider/animation_provider.dart`)
```dart
// Start page entrance animations
provider.startPageEntranceAnimations();

// Reset animations
provider.resetPageEntranceAnimations();

// Update ticker provider
provider.updateTickerProvider(vsync);

// Access animations
provider.backgroundCircleController
provider.pageEntranceController
provider.textRevealController
provider.fadeAnimation
provider.scaleAnimation
provider.revealAnimation
```

### ApiService (`lib/services/api_service.dart`)
```dart
// Check if username is available
ApiService.checkUsernameAvailability(String username)

// Check if email is available
ApiService.checkEmailAvailability(String email)

// Register new user
ApiService.register({
  required String firstName,
  required String lastName,
  required String username,
  required String email,
  required String password,
})

// Login user
ApiService.login({
  required String usernameOrEmail,
  required String password,
})
```

### FormErrorStateMixin (`lib/mixins/form_error_state_mixin.dart`)
```dart
// Set error states
setUsernameError(bool hasError)
setPasswordError(bool hasError)
setEmailError(bool hasError)

// Reset all errors
resetAllErrors()

// Access error states
isUsernameError
isPasswordError
isEmailError
```

### Validators (`lib/utils/validators.dart`)
```dart
// Validate email format
Validators.validateEmail(String email)

// Validate username (alphanumeric, 3+ chars)
Validators.validateUsername(String username)

// Get password strength (weak/medium/strong)
Validators.getPasswordStrength(String password)

// Validate password requirements
Validators.validatePasswordRequirements(String password)
```

## 🎨 Color Scheme

### Admin Theme
- Primary: `#FF1744` (Red)
- Orange Accent: `#FF6B35`
- Background: Black
- Text: White

### User Theme
- Primary: Purple
- Secondary: Blue
- Background: Black
- Text: White/White70

### Validation Colors
- Success: Green `#4CAF50`
- Warning: Orange `#FF9800`
- Error: Red `#F44336`
- Disabled: Gray `#BDBDBD`

## 📐 Typography

| Size | Name | Usage |
|------|------|-------|
| 48px | Heading 1 | Large titles |
| 36px | Heading 2 | Admin text |
| 28px | Heading 3 | Page titles |
| 26px | Heading 4 | Form labels |
| 24px | Subheading | Edumate text |
| 16px | Body | Regular text |
| 14px | Small | Secondary text |
| 12px | Caption | Hints |

## ⏱️ Animation Timings

| Animation | Duration | Curve |
|-----------|----------|-------|
| Page Entrance | 1200ms | EaseOut |
| Text Reveal | 800ms | EaseInOut |
| Background Circle | 5000ms | Linear (looped) |
| Page Transition | 300ms | Linear |
| Form Error Shake | 400ms | Linear |

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK (3.0+)
- Dart (3.0+)
- Android Studio / Xcode (for iOS)

### Installation
```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Run in release mode
flutter run --release
```

### Environment Configuration
Update `lib/config.dart` with your API endpoints:
```dart
class Config {
  static const String BASE_URL = 'your_api_url';
  static const String loginEndpoint = '$BASE_URL/api/auth/login';
  static const String registerEndpoint = '$BASE_URL/api/auth/register';
}
```

## 📦 Dependencies

```yaml
provider: ^6.1.5        # State management
http: ^1.1.0           # HTTP requests
shared_preferences: ^2.2.0  # Local storage
flutter_cupertino_localizations: ^1.0.0
```

## 🔐 Security Features

- ✅ Password validation (8+ characters required)
- ✅ Special character requirement for passwords
- ✅ Username/email availability checking
- ✅ Token storage in SharedPreferences
- ✅ Portrait orientation lock (prevents security issues)

## 🎯 Navigation Flow

```
Splash Screen
    ↓
Getting Started
    ├── Get Started → Signup Screen 1 → Signup Screen 2 → Login (after signup)
    ├── Admin Login → Admin Splash → Admin Login
    └── Exit → Confirm Dialog → Exit App
```

## 📝 Code Quality

### Optimizations Implemented
1. ✅ **API Service Refactoring** - Eliminated duplicate code with helper methods
2. ✅ **Animation Provider Consolidation** - Centralized animation management
3. ✅ **Import Cleanup** - Removed unused imports
4. ✅ **Widget Rebuilds** - Optimized Provider listeners
5. ✅ **Error States Mixin** - Reusable error logic across forms
6. ✅ **Magic Numbers Extraction** - Constants file with 100+ values

See `OPTIMIZATIONS.md` for detailed optimization documentation.

## 🐛 Known Issues / Future Enhancements

- [ ] Admin dashboard implementation
- [ ] Password recovery flow
- [ ] Two-factor authentication
- [ ] Biometric login
- [ ] Dark/Light theme toggle
- [ ] Multi-language support

## 📄 License

This project is part of the EduMate platform.

## 👨‍💻 Development Notes

- **Framework**: Flutter (cross-platform)
- **Language**: Dart
- **State Management**: Provider
- **Device Orientation**: Portrait only
- **Dark Mode**: Enabled by default
- **Min SDK**: Android 21, iOS 11.0

For more information about Flutter development, visit [flutter.dev](https://flutter.dev)

