// Shared rules for event plans (edit window, etc.).

/// Whether edits are allowed: strictly before [eventDateOnly] local midnight minus 7 days.
bool planEditAllowed(DateTime eventDateOnly) {
  final eventDayStart = DateTime(
    eventDateOnly.year,
    eventDateOnly.month,
    eventDateOnly.day,
  );
  final deadline = eventDayStart.subtract(const Duration(days: 7));
  return DateTime.now().isBefore(deadline);
}
