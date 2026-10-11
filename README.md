# SLA Task Tracker

A Flutter mobile application designed to help software development teams organize tasks, assign responsibilities, monitor deadlines, and track project progress using Service Level Agreement (SLA) indicators.

## Project Overview

SLA Task Tracker helps small development teams manage their work in one place. Team members can create and update tasks, assign responsibilities, track deadlines, and monitor task completion.

The application uses a local SQLite database to store information and provides a consistent, user-friendly interface built with Flutter.

## Project Objectives

- Improve task organization and team collaboration.
- Allow users to create, edit, assign, and delete tasks.
- Track task deadlines and completion status.
- Identify overdue and at-risk tasks automatically.
- Provide a dashboard for monitoring project progress.
- Store task and team information locally using SQLite.

## Main Features

### 1. User Authentication
- User registration and sign-in.
- Input validation.
- Password hashing for improved security.
- User profile and logout functionality.

### 2. Project Dashboard
- Overview of tasks and project progress.
- Task statistics based on completion and SLA status.
- Quick access to important application sections.

### 3. Task Management
- Create, view, edit, and delete tasks.
- Assign tasks to team members.
- Set task priorities and deadlines.
- Update task status: To Do, In Progress, or Completed.
- Search and filter tasks.

### 4. SLA Deadline Tracking
Tasks are automatically classified according to their status and deadline:

| SLA Status | Description |
|---|---|
| Completed | The task has been marked as completed. |
| Overdue | The task is incomplete and its deadline has passed. |
| At Risk | The task is incomplete and is due within the next two calendar days. |
| On Track | The task is incomplete and its deadline is more than two days away. |

### 5. Team Management
- View team members and their roles.
- Manage team member information.
- Assign tasks to specific members.

### 6. User Profile
- View account information.
- Access task-related information.
- Update profile information where supported.
- Log out securely.

## Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Mobile application development |
| Dart | Application programming language |
| SQLite | Local database |
| sqflite | SQLite integration |
| Git and GitHub | Version control and team collaboration |
| VS Code / Android Studio | Development and testing |

## Installation and Setup

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android emulator or compatible device

### Run the Application

Clone the repository:

```bash
git clone https://github.com/EKIRABO/flutter-sla-task-tracker.git
```

Navigate into the project:

```bash
cd flutter-sla-task-tracker
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## Project Structure

```text
lib/
├── database/
│   └── database_helper.dart
├── models/
│   ├── task_model.dart
│   └── team_member_model.dart
├── screens/
│   ├── dashboard_screen.dart
│   ├── profile_screen.dart
│   ├── sign_in_screen.dart
│   ├── sign_up_screen.dart
│   ├── task_details_screen.dart
│   ├── task_form_screen.dart
│   ├── task_list_screen.dart
│   ├── team_screen.dart
│   └── workspace_screen.dart
├── services/
│   └── auth_service.dart
├── theme/
│   └── app_theme.dart
├── widgets/
│   ├── app_bottom_navigation.dart
│   └── task_card.dart
└── main.dart
```

## Database and Data Persistence

The application uses SQLite to store tasks, team members, and user account information locally.

Database operations are handled through `database_helper.dart`, including creating, reading, updating, and deleting records.

The application also includes demonstration data consisting of 15 sample tasks and 6 sample team members. Stable identifiers help prevent duplicate demo records when the application restarts.

User-created tasks and account information are preserved.

## Application Architecture and State Management

The project separates responsibilities into screens, models, services, database utilities, themes, and reusable widgets.

Flutter's `StatefulWidget` and `setState()` are used where appropriate to update the interface in response to user interactions.

Database operations use asynchronous functions to load and save data.

## Testing

The team tests the following application functionality:

- User registration and sign-in.
- Form validation.
- Task creation, editing, and deletion.
- Task assignment.
- Search and filtering.
- SLA deadline calculations.
- Database persistence.
- Navigation between screens.
- Profile functionality.

## Team Collaboration

The application was developed collaboratively by four team members:

- **Bior:** Authentication, dashboard, and navigation.
- **Gael:** Task creation, editing, and form validation.
- **Kenia:** Database integration and team management.
- **Esther:** Task list, task details, SLA display, profile, integration, and testing.

GitHub was used to manage contributions, track changes, and integrate work from different branches.

## AI Usage Disclosure

AI tools were used as development and learning support where applicable. The team will document the specific tools used, their purposes, and how AI-assisted suggestions were reviewed and tested.

A detailed AI Usage Disclosure will be prepared separately based on each member's actual use of AI.

## Conclusion

SLA Task Tracker demonstrates how Flutter and SQLite can be combined to create a practical task management application.

The project brings together task organization, team responsibilities, local data persistence, and automatic deadline tracking in one application.