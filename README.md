# LocalLink 🔗

A modern, real-time messaging app for local network communication built with Flutter and Firebase.

## Features

- **Modern Dark UI** - Beautiful cyan/teal themed interface
- **Real-time Messaging** - Instant chat with Firebase Realtime Database
- **Local Network Discovery** - Find and connect with users on the same network
- **Secure Authentication** - Email/Phone + Password authentication
- **User Profiles** - Manage your account information
- **Responsive Design** - Smooth animations and intuitive UX

## Screenshots

- Sign Up & Login screens with gradient backgrounds
- Network setup with automatic user discovery
- Home page with live user list
- Real-time chat interface
- User profile management

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Firebase account
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/locallink.git
   cd locallink
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add an Android app to your Firebase project
   - Download `google-services.json` and place it in `android/app/`
   - Enable **Realtime Database** in Firebase Console
   - Update database rules (see below)

4. **Update Firebase URL**
   
   Replace the Firebase database URL in all files with your own:
   ```dart
   databaseURL: "https://YOUR-PROJECT-ID-default-rtdb.asia-southeast1.firebasedatabase.app"
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Firebase Configuration

### Database Structure

```
local-link-db
├── USERS
│   └── {userId}
│       ├── email
│       ├── phone
│       ├── password
│       ├── name
│       ├── ip_address
│       └── network_id
├── NETWORK_FRIENDS
│   └── {networkId}
│       └── {userId}
│           ├── user_id
│           ├── name
│           └── ip_address
├── NETWORK_INFO
│   └── {userId}
│       ├── password
│       ├── network_id
│       ├── ip_address
│       └── user_id
└── CHATS
    └── {networkId}
        └── {chatId}
            └── messages
                └── {timestamp}
                    ├── senderId
                    ├── senderName
                    ├── message
                    └── timestamp
```

### Database Rules

For development:
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

For production (recommended):
```json
{
  "rules": {
    "USERS": {
      "$userId": {
        ".read": true,
        ".write": true
      }
    },
    "NETWORK_FRIENDS": {
      ".read": true,
      ".write": true
    },
    "NETWORK_INFO": {
      "$userId": {
        ".read": true,
        ".write": true
      }
    },
    "CHATS": {
      ".read": true,
      ".write": true
    }
  }
}
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_database: ^10.4.0
  shared_preferences: ^2.2.2
```

## App Flow

1. **Sign Up** - Create account with email, phone, and password
2. **Set Password** - Create a secure password (8+ chars, uppercase, lowercase, number, special char)
3. **Network Setup** - Enter your local IP address and network SSID
4. **Name Confirmation** - Set your display name
5. **Home Page** - View all users on your network
6. **Chat** - Real-time messaging with network users
7. **Profile** - View and manage your account

## UI Theme

**Color Scheme:**
- Primary: Cyan `#06B6D4`
- Secondary: Teal `#14B8A6`
- Background: Dark Gray `#202225`, `#2C2F33`
- Text: White with varying opacity

**Design Features:**
- Gradient backgrounds and buttons
- Smooth fade-in animations
- Modern card-based layouts
- Dark mode throughout

## Password Requirements

- Minimum 8 characters
- At least one uppercase letter (A-Z)
- At least one lowercase letter (a-z)
- At least one number (0-9)
- At least one special character (!@#$%^&*)

## Validation

**Email:** Must contain `@` symbol
**Phone:** Must be exactly 10 digits



