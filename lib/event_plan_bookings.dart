import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raunaq/event_plan_slots.dart';

const String serviceBookingsCollection = 'serviceBookings';

/// Maps plan document field -> categories/{doc} id (same as detail screen).
const List<({String planField, String categoryDoc})> _planFieldCategories = [
  (planField: 'venueItemId', categoryDoc: 'venues'),
  (planField: 'musicItemId', categoryDoc: 'music'),
  (planField: 'cateringItemId', categoryDoc: 'catering'),
  (planField: 'photographyItemId', categoryDoc: 'photography'),
  (planField: 'decorationItemId', categoryDoc: 'decoration'),
];

String dateCompactFromDateTime(DateTime localDay) {
  final y = localDay.year;
  final m = localDay.month.toString().padLeft(2, '0');
  final d = localDay.day.toString().padLeft(2, '0');
  return '$y$m$d';
}

String slotKeyFromPlanMap(Map<String, dynamic> data) {
  final k = data['timeSlotKey'] as String?;
  if (k == null || k.isEmpty) {
    final sm = (data['startMin'] as num?)?.toInt() ?? 0;
    final em = (data['endMin'] as num?)?.toInt() ?? 0;
    return inferSlotFromMinutes(sm, em)?.key ?? 'afternoon';
  }
  return k;
}

DocumentReference<Map<String, dynamic>> bookingRef(
  FirebaseFirestore fs,
  String categoryDoc,
  String itemId,
  String dateCompact,
  String slotKey,
) {
  final id = '${categoryDoc}_${itemId}_${dateCompact}_$slotKey';
  return fs.collection(serviceBookingsCollection).doc(id);
}

/// All deterministic booking refs for a plan payload (non-null items only).
List<DocumentReference<Map<String, dynamic>>> bookingRefsForPayload({
  required FirebaseFirestore firestore,
  required Map<String, dynamic> planData,
}) {
  final eventTs = planData['eventDate'];
  if (eventTs is! Timestamp) return [];
  final dt = eventTs.toDate();
  final localDay = DateTime(dt.year, dt.month, dt.day);
  final compact = dateCompactFromDateTime(localDay);
  final slotKey = slotKeyFromPlanMap(planData);

  final refs = <DocumentReference<Map<String, dynamic>>>[];
  for (final row in _planFieldCategories) {
    final id = planData[row.planField] as String?;
    if (id != null && id.isNotEmpty) {
      refs.add(
        bookingRef(firestore, row.categoryDoc, id, compact, slotKey),
      );
    }
  }
  return refs;
}

Map<String, dynamic> bookingDocPayload({
  required String userId,
  required String planId,
  required String categoryDoc,
  required String itemId,
  required String dateCompact,
  required String slotKey,
  required Timestamp eventDateTs,
  required int startMin,
  required int endMin,
}) {
  return {
    'userId': userId,
    'planId': planId,
    'categoryDoc': categoryDoc,
    'itemId': itemId,
    'dateCompact': dateCompact,
    'slotKey': slotKey,
    'eventDate': eventDateTs,
    'startMin': startMin,
    'endMin': endMin,
  };
}

/// Deletes all [serviceBookings] documents tagged with [planId].
Future<void> deleteAllBookingsForPlanId(
  FirebaseFirestore firestore,
  String planId,
) async {
  final snap = await firestore
      .collection(serviceBookingsCollection)
      .where('planId', isEqualTo: planId)
      .get();
  if (snap.docs.isEmpty) return;
  final batch = firestore.batch();
  for (final d in snap.docs) {
    batch.delete(d.reference);
  }
  await batch.commit();
}

/// Item keys `${categoryDoc}_${itemId}` booked by other plans for this date/slot.
Future<Set<String>> fetchOccupiedItemKeys({
  required FirebaseFirestore firestore,
  required String dateCompact,
  required String slotKey,
  String? excludePlanId,
}) async {
  final snap = await firestore
      .collection(serviceBookingsCollection)
      .where('dateCompact', isEqualTo: dateCompact)
      .where('slotKey', isEqualTo: slotKey)
      .get();

  final result = <String>{};
  for (final d in snap.docs) {
    final data = d.data();
    final pid = data['planId'] as String?;
    if (excludePlanId != null && pid == excludePlanId) continue;
    final cat = data['categoryDoc'] as String?;
    final item = data['itemId'] as String?;
    if (cat != null && item != null && item.isNotEmpty) {
      result.add('${cat}_$item');
    }
  }
  return result;
}

/// Creates or updates a plan and syncs booking locks in one transaction.
Future<void> savePlanWithBookings({
  required FirebaseFirestore firestore,
  required String userId,
  required Map<String, dynamic> planPayload,
  String? existingPlanId,
}) async {
  final plansCol = firestore
      .collection('users')
      .doc(userId)
      .collection('eventPlans');

  final DocumentReference<Map<String, dynamic>> planRef = existingPlanId != null
      ? plansCol.doc(existingPlanId)
      : plansCol.doc();

  final planId = planRef.id;

  final eventTs = planPayload['eventDate'];
  if (eventTs is! Timestamp) {
    throw StateError('eventDate required');
  }
  final dt = eventTs.toDate();
  final localDay = DateTime(dt.year, dt.month, dt.day);
  final compact = dateCompactFromDateTime(localDay);
  final slotKey = slotKeyFromPlanMap(planPayload);
  final startMin = (planPayload['startMin'] as num).toInt();
  final endMin = (planPayload['endMin'] as num).toInt();

  await firestore.runTransaction((txn) async {
    List<DocumentReference<Map<String, dynamic>>> oldRefs = [];

    if (existingPlanId != null) {
      final prevSnap = await txn.get(planRef);
      if (prevSnap.exists && prevSnap.data() != null) {
        oldRefs = bookingRefsForPayload(
          firestore: firestore,
          planData: prevSnap.data()!,
        );
      }
    }

    final newRefs = <DocumentReference<Map<String, dynamic>>>[];
    final newPayloads = <DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>{};

    for (final row in _planFieldCategories) {
      final itemId = planPayload[row.planField] as String?;
      if (itemId == null || itemId.isEmpty) continue;
      final ref = bookingRef(firestore, row.categoryDoc, itemId, compact, slotKey);
      newRefs.add(ref);
      newPayloads[ref] = bookingDocPayload(
        userId: userId,
        planId: planId,
        categoryDoc: row.categoryDoc,
        itemId: itemId,
        dateCompact: compact,
        slotKey: slotKey,
        eventDateTs: Timestamp.fromDate(localDay),
        startMin: startMin,
        endMin: endMin,
      );
    }

    final oldSet = oldRefs.toSet();
    final newSet = newRefs.toSet();

    for (final r in oldSet.difference(newSet)) {
      txn.delete(r);
    }

    for (final r in newRefs) {
      final snap = await txn.get(r);
      if (snap.exists) {
        final holder = snap.data()?['planId'] as String?;
        if (holder != null && holder != planId) {
          throw Exception(
            'A selected service is already booked for this date and time.',
          );
        }
      }
    }

    if (existingPlanId != null) {
      txn.update(planRef, planPayload);
    } else {
      txn.set(planRef, planPayload);
    }

    for (final r in newRefs) {
      txn.set(r, newPayloads[r]!);
    }
  });
}
