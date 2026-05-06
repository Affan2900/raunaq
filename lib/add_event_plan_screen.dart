import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:raunaq/event_plan_bookings.dart';
import 'package:raunaq/event_plan_rules.dart';
import 'package:raunaq/event_plan_slots.dart';

/// Optional Firestore fields on category `items` docs:
/// `availStartMin`, `availEndMin` — minutes from midnight (0–1439) for when the
/// vendor can serve. If either is missing, the item is treated as available
/// for any time range.

class _CatMeta {
  const _CatMeta({required this.firestoreDoc, required this.label});

  final String firestoreDoc;
  final String label;
}

const _primaryColor = Color(0xFF00A2FF);

const List<_CatMeta> _categories = [
  _CatMeta(firestoreDoc: 'venues', label: 'Venue'),
  _CatMeta(firestoreDoc: 'music', label: 'Music'),
  _CatMeta(firestoreDoc: 'catering', label: 'Catering'),
  _CatMeta(firestoreDoc: 'photography', label: 'Photography'),
  _CatMeta(firestoreDoc: 'decoration', label: 'Decoration'),
];

class _VendorOption {
  _VendorOption({required this.id, required this.name});

  final String id;
  final String name;
}

bool _itemAvailableForRange(
  Map<String, dynamic> data,
  int eventStart,
  int eventEnd,
) {
  final dynamic rawA = data['availStartMin'];
  final dynamic rawB = data['availEndMin'];
  if (rawA == null || rawB == null) return true;
  final int availStart = (rawA as num).toInt().clamp(0, 1439);
  final int availEnd = (rawB as num).toInt().clamp(0, 1439);
  if (availEnd <= availStart) return true;
  return eventStart < availEnd && eventEnd > availStart;
}

class AddEventPlanScreen extends StatefulWidget {
  const AddEventPlanScreen({super.key, this.planId});

  /// When set, screen loads this plan and updates it on save instead of creating.
  final String? planId;

  @override
  State<AddEventPlanScreen> createState() => _AddEventPlanScreenState();
}

class _AddEventPlanScreenState extends State<AddEventPlanScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _planNameController = TextEditingController();

  bool _loadingBootstrap = false;

  int _step = 0;

  DateTime _eventDate = DateTime.now();
  EventTimeSlot _selectedSlot = EventTimeSlot.afternoon;

  bool _loadingVendors = false;
  String? _loadError;

  /// category firestore doc id -> options
  final Map<String, List<_VendorOption>> _optionsByCategory = {};

  /// category firestore doc id -> selected item id
  final Map<String, String?> _selection = {
    for (final c in _categories) c.firestoreDoc: null,
  };

  bool get _isEdit => widget.planId != null;

  String get _saveButtonLabel => _isEdit ? 'Save changes' : 'Save plan';

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadingBootstrap = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingPlan());
    }
  }

  Future<void> _loadExistingPlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.planId == null) {
      if (mounted) {
        setState(() => _loadingBootstrap = false);
      }
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('eventPlans')
          .doc(widget.planId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          setState(() => _loadingBootstrap = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan not found.')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final d = doc.data()!;
      _planNameController.text = d['planName']?.toString() ?? '';

      final eventTs = d['eventDate'];
      if (eventTs is Timestamp) {
        final dt = eventTs.toDate();
        _eventDate = DateTime(dt.year, dt.month, dt.day);
      }

      final sm = d['startMin'];
      final em = d['endMin'];
      if (sm is num && em is num) {
        _selectedSlot = timeSlotFromKey(d['timeSlotKey'] as String?) ??
            inferSlotFromMinutes(
              sm.toInt(),
              em.toInt(),
            ) ??
            EventTimeSlot.afternoon;
      } else {
        _selectedSlot = timeSlotFromKey(d['timeSlotKey'] as String?) ??
            EventTimeSlot.afternoon;
      }

      _selection['venues'] = d['venueItemId'] as String?;
      _selection['music'] = d['musicItemId'] as String?;
      _selection['catering'] = d['cateringItemId'] as String?;
      _selection['photography'] = d['photographyItemId'] as String?;
      _selection['decoration'] = d['decorationItemId'] as String?;

      if (!planEditAllowed(_eventDate)) {
        if (mounted) {
          setState(() => _loadingBootstrap = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Editing is closed within 7 days of the event.',
              ),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      if (mounted) setState(() => _loadingBootstrap = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loadingBootstrap = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load plan: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickDate() async {
    final firstDate = _isEdit ? DateTime(2020) : DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 365 * 2));
    var initial = _eventDate;
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _goToVendorStep() async {
    final planName = _planNameController.text.trim();
    if (planName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan name.')),
      );
      return;
    }

    setState(() {
      _loadingVendors = true;
      _loadError = null;
      _optionsByCategory.clear();
    });

    final eventStart = _selectedSlot.startMin;
    final eventEnd = _selectedSlot.endMin;

    try {
      final compact = dateCompactFromDateTime(
        DateTime(_eventDate.year, _eventDate.month, _eventDate.day),
      );
      final occupied = await fetchOccupiedItemKeys(
        firestore: _firestore,
        dateCompact: compact,
        slotKey: _selectedSlot.key,
        excludePlanId: widget.planId,
      );

      for (final c in _categories) {
        final snap = await _firestore
            .collection('categories')
            .doc(c.firestoreDoc)
            .collection('items')
            .get();

        final list = snap.docs
            .where(
              (doc) {
                final occKey = '${c.firestoreDoc}_${doc.id}';
                if (occupied.contains(occKey)) return false;
                return _itemAvailableForRange(
                  doc.data(),
                  eventStart,
                  eventEnd,
                );
              },
            )
            .map(
              (doc) => _VendorOption(
                id: doc.id,
                name: doc.data()['name']?.toString() ?? 'Untitled',
              ),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        _optionsByCategory[c.firestoreDoc] = list;

        final sel = _selection[c.firestoreDoc];
        if (sel != null && !list.any((o) => o.id == sel)) {
          _selection[c.firestoreDoc] = null;
        }
      }

      if (mounted) {
        setState(() {
          _step = 1;
          _loadingVendors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingVendors = false;
          _loadError = e.toString();
        });
      }
    }
  }

  Future<void> _savePlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be signed in.')));
      return;
    }

    final startMin = _selectedSlot.startMin;
    final endMin = _selectedSlot.endMin;

    try {
      final payload = <String, dynamic>{
        'planName': _planNameController.text.trim(),
        'eventDate': Timestamp.fromDate(
          DateTime(
            _eventDate.year,
            _eventDate.month,
            _eventDate.day,
          ),
        ),
        'startMin': startMin,
        'endMin': endMin,
        'timeSlotKey': _selectedSlot.key,
        'venueItemId': _selection['venues'],
        'musicItemId': _selection['music'],
        'cateringItemId': _selection['catering'],
        'photographyItemId': _selection['photography'],
        'decorationItemId': _selection['decoration'],
      };

      if (!_isEdit) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await savePlanWithBookings(
        firestore: _firestore,
        userId: user.uid,
        planPayload: payload,
        existingPlanId: widget.planId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Plan updated.' : 'Plan saved.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('already booked')
            ? 'One or more services are already booked for that date and time.'
            : 'Could not save: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  @override
  void dispose() {
    _planNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingBootstrap) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _step == 0
              ? (_isEdit ? 'Edit plan' : 'Event time')
              : 'Choose services',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _step == 0 ? _buildTimeStep() : _buildVendorStep(),
    );
  }

  Widget _buildTimeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'When is your event?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick the date and one of two time slots. Vendors shown next match that window and exclude items already booked.',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _planNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Plan name',
              hintText: 'e.g. Summer wedding reception',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
              prefixIcon: const Icon(Icons.edit_outlined, color: _primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined, color: _primaryColor),
            title: const Text('Date'),
            subtitle: Text(
              '${_eventDate.day}/${_eventDate.month}/${_eventDate.year}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDate,
          ),
          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Time slot',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<EventTimeSlot>(
            segments: [
              ButtonSegment<EventTimeSlot>(
                value: EventTimeSlot.afternoon,
                label: Text(EventTimeSlot.afternoon.formatRange(context)),
              ),
              ButtonSegment<EventTimeSlot>(
                value: EventTimeSlot.evening,
                label: Text(EventTimeSlot.evening.formatRange(context)),
              ),
            ],
            selected: {_selectedSlot},
            onSelectionChanged: (Set<EventTimeSlot> next) {
              if (next.isEmpty) return;
              setState(() => _selectedSlot = next.first);
            },
          ),
          const Spacer(),
          FilledButton(
            onPressed: _loadingVendors ? null : _goToVendorStep,
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _loadingVendors
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Continue'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVendorStep() {
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(_loadError!, textAlign: TextAlign.center)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _planNameController.text.trim(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_eventDate.day}/${_eventDate.month}/${_eventDate.year} · '
                '${_selectedSlot.formatRange(context)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              for (final c in _categories) ...[
                _buildCategoryDropdown(c),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: FilledButton(
            onPressed: _savePlan,
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(_saveButtonLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(_CatMeta c) {
    final options = _optionsByCategory[c.firestoreDoc] ?? [];
    final value = _selection[c.firestoreDoc];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          c.label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        if (options.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'No options available for this time window.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          )
        else
          InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value != null && options.any((o) => o.id == value)
                    ? value
                    : null,
                hint: Text('Select ${c.label.toLowerCase()}'),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: [
                  for (final o in options)
                    DropdownMenuItem<String>(
                      value: o.id,
                      child: Text(
                        o.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) =>
                    setState(() => _selection[c.firestoreDoc] = v),
              ),
            ),
          ),
      ],
    );
  }
}
