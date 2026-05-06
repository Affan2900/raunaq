import 'package:flutter/material.dart';

/// Fixed event windows: 2pm–5pm and 7pm–10pm (local time).
enum EventTimeSlot {
  afternoon,
  evening,
}

extension EventTimeSlotMinutes on EventTimeSlot {
  /// Minutes from midnight for slot start (inclusive).
  int get startMin => switch (this) {
        EventTimeSlot.afternoon => 14 * 60,
        EventTimeSlot.evening => 19 * 60,
      };

  /// Minutes from midnight for slot end (exclusive convention matches prior app: end > start).
  int get endMin => switch (this) {
        EventTimeSlot.afternoon => 17 * 60,
        EventTimeSlot.evening => 22 * 60,
      };

  String get key => switch (this) {
        EventTimeSlot.afternoon => 'afternoon',
        EventTimeSlot.evening => 'evening',
      };
}

EventTimeSlot? timeSlotFromKey(String? k) {
  if (k == null) return null;
  switch (k) {
    case 'afternoon':
      return EventTimeSlot.afternoon;
    case 'evening':
      return EventTimeSlot.evening;
    default:
      return null;
  }
}

extension EventTimeSlotFormat on EventTimeSlot {
  /// Format using current locale (12h where applicable).
  String formatRange(BuildContext context) {
    final start = TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60);
    final end = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);
    return '${start.format(context)} – ${end.format(context)}';
  }
}

/// Infer slot from stored minutes; supports legacy arbitrary ranges with tolerance.
EventTimeSlot? inferSlotFromMinutes(int startMin, int endMin) {
  for (final slot in EventTimeSlot.values) {
    if (slot.startMin == startMin && slot.endMin == endMin) {
      return slot;
    }
  }
  const tol = 15;
  for (final slot in EventTimeSlot.values) {
    if ((startMin - slot.startMin).abs() <= tol &&
        (endMin - slot.endMin).abs() <= tol) {
      return slot;
    }
  }
  return null;
}

String formatPlanTimeDisplay(
  BuildContext context,
  int startMin,
  int endMin, {
  String? timeSlotKey,
}) {
  final fromKey = timeSlotFromKey(timeSlotKey);
  if (fromKey != null) {
    return fromKey.formatRange(context);
  }
  final inferred = inferSlotFromMinutes(startMin, endMin);
  if (inferred != null) {
    return inferred.formatRange(context);
  }
  final start = TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60);
  final end = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);
  return '${start.format(context)} – ${end.format(context)}';
}
