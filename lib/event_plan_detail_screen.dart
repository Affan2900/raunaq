import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:raunaq/add_event_plan_screen.dart';
import 'package:raunaq/event_plan_bookings.dart';
import 'package:raunaq/event_plan_rules.dart';
import 'package:raunaq/event_plan_slots.dart';

const _primaryColor = Color(0xFF00A2FF);

/// Maps Firestore field on plan doc -> categories collection doc id.
const List<({String field, String categoryDoc, String label})> _serviceRows = [
  (field: 'venueItemId', categoryDoc: 'venues', label: 'Venue'),
  (field: 'musicItemId', categoryDoc: 'music', label: 'Music'),
  (field: 'cateringItemId', categoryDoc: 'catering', label: 'Catering'),
  (field: 'photographyItemId', categoryDoc: 'photography', label: 'Photography'),
  (field: 'decorationItemId', categoryDoc: 'decoration', label: 'Decoration'),
];

Future<Map<String, String?>> _resolveItemNames(
  FirebaseFirestore firestore,
  Map<String, dynamic> data,
) async {
  Future<String?> one(String field, String categoryDoc) async {
    final id = data[field] as String?;
    if (id == null || id.isEmpty) return null;
    final snap = await firestore
        .collection('categories')
        .doc(categoryDoc)
        .collection('items')
        .doc(id)
        .get();
    return snap.data()?['name']?.toString();
  }

  final results = await Future.wait([
    for (final r in _serviceRows) one(r.field, r.categoryDoc),
  ]);

  final map = <String, String?>{};
  for (var i = 0; i < _serviceRows.length; i++) {
    map[_serviceRows[i].field] = results[i];
  }
  return map;
}

String _safeErrorMessage(Object e) {
  try {
    return e.toString();
  } catch (_) {
    return 'Something went wrong.';
  }
}

class EventPlanDetailScreen extends StatefulWidget {
  const EventPlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  State<EventPlanDetailScreen> createState() => _EventPlanDetailScreenState();
}

class _EventPlanDetailScreenState extends State<EventPlanDetailScreen> {
  /// True while we are deleting from this screen — avoids a second [Navigator.pop]
  /// when the stream rebuilds with a missing document (breaks Flutter Web).
  bool _deletingFromHere = false;

  Future<void> _confirmDelete(BuildContext context, String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel plan'),
        content: const Text(
          'This will permanently delete this plan and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep plan'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    setState(() => _deletingFromHere = true);

    try {
      await deleteAllBookingsForPlanId(FirebaseFirestore.instance, widget.planId);
      if (!context.mounted) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('eventPlans')
          .doc(widget.planId)
          .delete();
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _deletingFromHere = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: ${_safeErrorMessage(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Sign in required.')),
      );
    }

    final planRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('eventPlans')
        .doc(widget.planId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Plan details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: planRef.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
              final data = snap.data!.data() as Map<String, dynamic>?;
              if (data == null) return const SizedBox.shrink();
              final eventTs = data['eventDate'];
              DateTime? eventDay;
              if (eventTs is Timestamp) {
                final d = eventTs.toDate();
                eventDay = DateTime(d.year, d.month, d.day);
              }
              final canEdit = eventDay != null && planEditAllowed(eventDay);
              if (!canEdit) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => AddEventPlanScreen(planId: widget.planId),
                    ),
                  );
                },
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: planRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: _primaryColor));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Could not load this plan.'));
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            if (!_deletingFromHere) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.maybePop(context);
              });
            }
            return const Center(child: Text('This plan is no longer available.'));
          }

          final data = doc.data() as Map<String, dynamic>;

          final planName = data['planName']?.toString().trim();
          final eventTs = data['eventDate'];
          DateTime? eventDay;
          if (eventTs is Timestamp) {
            final d = eventTs.toDate();
            eventDay = DateTime(d.year, d.month, d.day);
          }

          final startMin = (data['startMin'] as num?)?.toInt() ?? 0;
          final endMin = (data['endMin'] as num?)?.toInt() ?? 0;
          final timeSlotKey = data['timeSlotKey'] as String?;

          final timeStr = formatPlanTimeDisplay(
            context,
            startMin,
            endMin,
            timeSlotKey: timeSlotKey,
          );
          final dateStr = eventDay != null
              ? '${eventDay.day}/${eventDay.month}/${eventDay.year}'
              : '—';

          final canEdit = eventDay != null && planEditAllowed(eventDay);

          final namesKey = _serviceRows
              .map((r) => '${r.field}=${data[r.field] ?? ''}')
              .join('|');

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (!canEdit && eventDay != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Editing is closed within 7 days of the event.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              _DetailTile(title: 'Plan name', value: planName?.isNotEmpty == true ? planName! : '—'),
              _DetailTile(title: 'Date', value: dateStr),
              _DetailTile(title: 'Time', value: timeStr),
              const SizedBox(height: 8),
              const Text(
                'Services',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, String?>>(
                key: ValueKey<String>(namesKey),
                future: _resolveItemNames(FirebaseFirestore.instance, data),
                builder: (context, nameSnap) {
                  if (nameSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: _primaryColor),
                      ),
                    );
                  }
                  final names = nameSnap.data ?? {};
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final r in _serviceRows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ServiceRow(
                            label: r.label,
                            value: () {
                              final id = data[r.field] as String?;
                              if (id == null || id.isEmpty) {
                                return 'Not selected';
                              }
                              final n = names[r.field];
                              return n?.isNotEmpty == true ? n! : 'Unknown item';
                            }(),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _confirmDelete(context, user.uid),
                  child: const Text('Cancel plan'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
