import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../models/log_model.dart';
import '../../features/floor_plan/models/floor_model.dart';
import '../../features/automation/models/routine_model.dart';

// ──────────────────────────────────────────────
// CONSTANT
// ──────────────────────────────────────────────
const kHomeId = 'home_abc789';

// ──────────────────────────────────────────────
// AUTH
// ──────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) =>
    FirebaseAuth.instance.authStateChanges());

// ──────────────────────────────────────────────
// DEVICES  (real-time stream)
// ──────────────────────────────────────────────
final devicesProvider = StreamProvider<List<DeviceModel>>((ref) {
  final db = FirebaseDatabase.instance.ref('devices/$kHomeId');
  return db.onValue.map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return [];
    return data.entries
        .map((e) => DeviceModel.fromMap(e.key as String, e.value as Map))
        .toList();
  });
});

// ──────────────────────────────────────────────
// FLOORS + PINS  (real-time stream)
// ──────────────────────────────────────────────
final floorsProvider = StreamProvider<List<FloorModel>>((ref) {
  final db = FirebaseDatabase.instance.ref('homes/$kHomeId/floors');
  return db.onValue.map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return [];
    return data.entries
        .map((e) => FloorModel.fromMap(e.key as String, e.value as Map))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  });
});

// ──────────────────────────────────────────────
// INTERACTION LOGS  (last 30, real-time)
// ──────────────────────────────────────────────
final logsProvider = StreamProvider<List<LogModel>>((ref) {
  final db = FirebaseDatabase.instance
      .ref('interaction_logs/$kHomeId')
      .limitToLast(30);
  return db.onValue.map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return [];
    return data.values
        .map((v) => LogModel.fromMap(v as Map))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  });
});

// ──────────────────────────────────────────────
// AUTOMATION RULES  (real-time stream)
// ──────────────────────────────────────────────
final routinesProvider = StreamProvider<List<RoutineModel>>((ref) {
  final db = FirebaseDatabase.instance.ref('automation_rules/$kHomeId');
  return db.onValue.map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return [];
    return data.entries
        .map((e) => RoutineModel.fromMap(e.key as String, e.value as Map))
        .toList();
  });
});

// ──────────────────────────────────────────────
// AI INBOX  (pending items only)
// ──────────────────────────────────────────────
final aiInboxProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = FirebaseDatabase.instance.ref('ai_inbox/$kHomeId');
  return db.onValue.map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return [];
    return data.entries
        .where((e) => (e.value as Map)['status'] == 'pending')
        .map((e) {
      final m = Map<String, dynamic>.from(e.value as Map);
      m['id'] = e.key;
      return m;
    })
        .toList();
  });
});

// ──────────────────────────────────────────────
// HUB HEARTBEAT
// ──────────────────────────────────────────────
final hubHeartbeatProvider = StreamProvider<int?>((ref) {
  final db = FirebaseDatabase.instance.ref('homes/$kHomeId/hub_heartbeat');
  return db.onValue.map((event) => event.snapshot.value as int?);
});

// ──────────────────────────────────────────────
// WRITE OPERATIONS
// ──────────────────────────────────────────────
class FirebaseService {
  static final _db   = FirebaseDatabase.instance.ref();
  static final _auth = FirebaseAuth.instance;

  // Toggle a single device and log the event
  static Future<void> toggleDevice(String deviceId, bool isOn) async {
    final state = isOn ? 'ON' : 'OFF';
    await _db.child('devices/$kHomeId/$deviceId/state').set(state);
    await _db.child('interaction_logs/$kHomeId').push().set({
      'timestamp':    DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'device_id':    deviceId,
      'state':        state,
      'trigger_type': 'APP_COMMAND',
    });
  }

  // Turn ALL devices off in a single RTDB multi-path update
  static Future<void> turnAllOff(List<DeviceModel> devices) async {
    final updates = <String, dynamic>{
      for (final d in devices) 'devices/$kHomeId/${d.id}/state': 'OFF',
    };
    await _db.update(updates);
    await _db.child('interaction_logs/$kHomeId').push().set({
      'timestamp':    DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'device_id':    'ALL',
      'state':        'OFF',
      'trigger_type': 'APP_COMMAND',
    });
  }

  // Floor CRUD
  static Future<void> upsertFloor(String floorId, Map<String, dynamic> data) async =>
      _db.child('homes/$kHomeId/floors/$floorId').update(data);

  // Pin CRUD
  static Future<void> upsertPin(String floorId, String pinId, Map<String, dynamic> data) async =>
      _db.child('homes/$kHomeId/floors/$floorId/pins/$pinId').set(data);

  static Future<void> deletePin(String floorId, String pinId) async =>
      _db.child('homes/$kHomeId/floors/$floorId/pins/$pinId').remove();

  // Routine CRUD
  static Future<void> upsertRoutine(String routineId, Map<String, dynamic> data) async =>
      _db.child('automation_rules/$kHomeId/$routineId').set(data);

  static Future<void> deleteRoutine(String routineId) async =>
      _db.child('automation_rules/$kHomeId/$routineId').remove();

  static Future<void> setRoutineStatus(String routineId, bool active) async =>
      _db.child('automation_rules/$kHomeId/$routineId/status')
          .set(active ? 'active' : 'inactive');

  // AI Inbox actions
  static Future<void> approveInboxRule(
      String pendingId, Map<String, dynamic> suggestedRule) async {
    final newRef = _db.child('automation_rules/$kHomeId').push();
    await newRef.set({...suggestedRule, 'status': 'active', 'source': 'AI_GENERATED'});
    await _db.child('ai_inbox/$kHomeId/$pendingId/status').set('approved');
  }

  static Future<void> rejectInboxRule(String pendingId) async =>
      _db.child('ai_inbox/$kHomeId/$pendingId/status').set('rejected');

  // Auth
  static Future<void> signOut() => _auth.signOut();
}