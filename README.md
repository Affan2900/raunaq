# Raunaq

Raunaq is a dynamic event planning application built with Flutter and Firebase. It serves as a marketplace for event services, allowing users to browse categories like Venues, Catering, Music, Decoration, and Photography.

### Features
- **Authentication**: Secure Login and Sign-Up integrated with Firebase Auth.
- **Dynamic Content**: Service listings managed through Cloud Firestore.
- **Role-Based Views**: Owners can manage (Add/Delete) their specific listings, while users can browse and register for services.
- **Real-time Bookings**: Users can register for services with preferred dates and times.
- **Responsive Animations**: A premium UI experience with animated transitions and interactive elements.

## Getting Started

To run this project locally, follow these steps:

1. **Install Dependencies**:
   Open your terminal in the project root and run:
   ```bash
   flutter pub get
   ```

2. **Launch the App**:
   Ensure you have a simulator running or a device connected, then run:
   ```bash
   flutter run
   ```

3. **Firebase Configuration**:
   This project requires a `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to connect to the Firebase backend. Ensure these are placed in their respective platform directories.

For more help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev/).
