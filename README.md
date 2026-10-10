# SLA Task Tracker

A Flutter task tracker backed by a local SQLite database.

## Run the app

```sh
flutter pub get
flutter run
```

The app creates `sla_tasks.db` on first launch using the shared task and team
member schema. It starts empty; no sample tasks are inserted. Dashboard and Task
List read task records from this database and share one SLA calculation. The
Team tab manages team members; the Profile tab lets the signed-in user update
their display name.

## SLA calculation

The Task List and Dashboard use the same date-based calculation:

- A task with status `Completed` is **Completed**, regardless of its deadline.
- An incomplete task with a deadline before today is **Overdue**.
- An incomplete task due today or within the next two calendar days is **At
  Risk**.
- Any later incomplete task is **On Track**.

Deadlines are stored as `YYYY-MM-DD`. The SQLite plugin targets Android, iOS,
and macOS.
