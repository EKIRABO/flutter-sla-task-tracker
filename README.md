# SLA Task Tracker

A Flutter task tracker backed by a local SQLite database.

## Run the app

```sh
flutter pub get
flutter run
```

The app creates `sla_tasks.db` on first launch. It contains `tasks` and
`team_members` tables and starts empty; no sample tasks are inserted. Use the
Team tab to add members and the Tasks tab to add tasks. Tasks can be assigned to
a team member, searched and filtered by SLA, opened for details, edited, and
deleted. The Dashboard and Task List read the same records and use the same SLA
calculation.

## SLA calculation

The Task List and Dashboard use the same date-based calculation:

- A task with status `Completed` is **Completed**, regardless of its deadline.
- An incomplete task with a deadline before today is **Overdue**.
- An incomplete task due today or within the next two calendar days is **At
  Risk**.
- Any later incomplete task is **On Track**.

Deadlines are stored as `YYYY-MM-DD`. The SQLite plugin targets Android, iOS,
and macOS.
