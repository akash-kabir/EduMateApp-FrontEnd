# 🎓 EduMate - Campus Management & Engagement Platform

## Project Overview

**EduMate** is an MVP (Minimum Viable Product) campus management and engagement application built with Flutter. It serves as a centralized platform for students and faculty to manage academic activities, collaborate, and stay connected within their educational institution.

The app is designed to bridge communication gaps and streamline campus operations through an intuitive, user-friendly mobile interface.

---

## ✨ Core Features (MVP)

### 🔐 **Authentication System**
- **BCrypt Password Encryption**: Secure password hashing and storage
- **JWT Token-based Auth**: Stateless, token-based session management
- **Login/Signup**: Full user registration and authentication flow
- **Role-based Access**: Support for Student, Faculty, and Society Head roles

### 📅 **Calendar & Events Management**
- **Event Calendar**: Month-view calendar displaying all events, assignments, and holidays
- **Event Filtering**: Filter events by type (Holidays, Assignments, Events, Private Events)
- **Event Details**: View event information with time and date details
- **Multiple View Modes**: Supports month and week view for better event visualization

### 📢 **Events Feed Screen**
- **Dynamic Event Feed**: Browse all campus events and announcements
- **Event Filtering**: Filter by event type and category
- **Event Details Card**: View event information in an attractive card format
- **Create Events**: Faculty and Society Heads can create and publish events

### 👤 **User Profile Management**
- **Profile Display**: View user information including name, email, and role
- **User Data**: Local caching of user information
- **Role-based UI**: Different UI elements based on user role
- **Settings Access**: Quick access to app settings and preferences

### 🏢 **Campus Navigation & Facilities**
- **Campus Map**: Browse campus locations and facilities
- **Navigation**: Easy access to important campus areas
- **Faculty Directory**: View faculty members and their information

### ⏱️ **Timesheet Management**
- **Class Schedule**: View weekly class schedule for different batches
- **Multiple Class Support**: Pre-built schedules for CSE classes (7, 15, 16, 19, 25, 35, 51)
- **Time Tracking**: Track attendance and class timings

### 🌙 **Dark/Light Theme**
- **Theme Toggle**: Easy switching between dark and light modes
- **System Integration**: Option to follow system theme
- **Persistent Preference**: Theme preference saved locally

---

## 🛠️ Tech Stack

| Technology | Purpose |
|-----------|---------|
| **Flutter** | Cross-platform mobile app framework |
| **Dart** | Programming language |
| **Provider** | State management |
| **http** | HTTP client for API calls |
| **shared_preferences** | Local storage |
| **intl** | Date/time formatting |
| **url_launcher** | URL handling |
| **JWT** | Token-based authentication |
| **BCrypt** | Password hashing (backend) |

### Backend
- **Node.js/Express** REST API
- **JWT** authentication
- **MongoDB** database
- **Vercel** deployment (https://edu-mate-app-back-end.vercel.app)

---

## 📱 App Screens

1. **Splash Screen** - Initial loading screen
2. **Login/Signup Screen** - User authentication
3. **Home Screen** - Dashboard with class schedule
4. **Calendar Screen** - Event calendar with filtering
5. **Events Screen** - Event feed and discovery
6. **Profile Screen** - User profile management
7. **Settings Screen** - App preferences and theme
8. **Timesheet Screen** - Weekly class schedule
9. **Campus Navigation Screen** - Campus map and facilities
10. **Create Post Screen** - Create events/announcements (Faculty/Society Head only)
11. **Manage Posts Screen** - Manage published content

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.9.2)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/akash-kabir/EduMateApp.git
   cd EduMateApp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint** (if needed)
   - Update `BASE_URL` in `lib/config.dart`
   - Default: `https://edu-mate-app-back-end.vercel.app`

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```
lib/
├── main.dart                 # App entry point
├── main_page.dart            # Main navigation
├── config.dart               # Configuration & API endpoints
├── screens/                  # All UI screens
│   ├── accounts/            # Authentication screens
│   ├── calender_screen.dart
│   ├── events_screen.dart
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   └── ...
├── services/                # API service layer
│   └── api_service.dart
├── widgets/                 # Reusable components
│   ├── navigation/
│   ├── menu/
│   ├── profile_cards/
│   └── ...
├── theme/                   # App theming
│   ├── app_theme.dart
│   └── theme_provider.dart
└── schedule/               # Class schedules
    └── class_*_schedule.dart
```

---

## 🔑 Key Implementation Details

### Authentication Flow
```
User Input → Validation → BCrypt Hashing → API Request → 
JWT Token → SharedPreferences Storage → App Navigation
```

### State Management
- **Provider Pattern**: Used for theme management and state sharing
- **Local Storage**: SharedPreferences for user session and preferences
- **HTTP Caching**: Token-based API requests with local caching

### Security Features
- ✅ JWT token-based authentication
- ✅ BCrypt password hashing
- ✅ Secure token storage in SharedPreferences
- ✅ HTTPS API communication
- ✅ Role-based access control

---

## 📊 API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/users/register` | POST | User registration |
| `/api/users/login` | POST | User login |
| `/api/users/me` | GET | Get user profile |
| `/api/posts` | GET/POST | Events/posts management |

---

## 🎯 MVP Scope

This is a **Minimum Viable Product** focused on:
- ✅ Core authentication system
- ✅ Event management and discovery
- ✅ User profile management
- ✅ Calendar functionality
- ✅ Class scheduling


## 🔒 Security & Data Privacy

- User passwords are hashed using BCrypt
- JWT tokens are used for secure session management
- API requests use HTTPS

---

## 📝 Testing

Currently, manual testing is performed on:
- Android emulator
- Physical devices

---

## 👨‍💻 Developer

**Akash Kabir**
- GitHub: [@akash-kabir](https://github.com/akash-kabir)
- Project Repository: [EduMateApp](https://github.com/akash-kabir/EduMateApp)

---

**Last Updated**: October 2025  
**Version**: 1.0.3 (MVP)
