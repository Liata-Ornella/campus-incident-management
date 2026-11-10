# Campus Incident Management

A Flutter-based campus incident reporting and management application that helps students report safety concerns and enables staff to monitor, review, and manage incidents.

## Features

### Student Features
- Student registration and login.
- Submit campus incident reports.
- Select an incident category.
- Add photographs from the gallery.
- Capture incident photographs directly using the camera.
- View personal incident history.
- Track incident status.

### Staff Features
- Staff login and dashboard.
- View all submitted incident reports.
- Search and filter incidents.
- View incident descriptions and attached photographs.
- Update incident statuses:
  - Submitted
  - Under Review
  - In Progress
  - Resolved
- Monitor incident statistics.

## Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Mobile application development |
| Dart | Programming language |
| Firebase Authentication | User authentication |
| Cloud Firestore | Incident and user data storage |
| Cloudinary | Photograph uploads |
| Image Picker | Camera and gallery access |

## Project Structure

```text
lib/
├── main.dart
├── firebase_options.dart
├── services.dart
├── auth_screens.dart
└── campus_screens.dart

test/
└── widget_test.dart
```

## Getting Started

### Prerequisites
- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android emulator or physical device
- Firebase project

### Installation

1. Clone the repository:

```bash
git clone https://github.com/Liata-Ornella/campus-incident-management.git
```

2. Navigate into the project:

```bash
cd campus-incident-management
```

3. Install dependencies:

```bash
flutter pub get
```

4. Configure Firebase for your own project using FlutterFire CLI:

```bash
dart pub global run flutterfire_cli:flutterfire configure
```

5. Configure your Cloudinary upload settings in `services.dart`.

6. Run the application:

```bash
flutter run
```

## Testing

Run the following commands:

```bash
flutter analyze
flutter test
```

## Application Workflow

1. Students log in and submit incident reports.
2. Optional photographs are uploaded to Cloudinary.
3. Incident information is stored in Firebase Firestore.
4. Staff access the dashboard to review reports.
5. Staff update incident statuses.
6. Students can track the progress of their reports.

## Author

**Liata Ornella Sifa**

GitHub: [@Liata-Ornella](https://github.com/Liata-Ornella)

## License

This project is available for educational and demonstration purposes.
