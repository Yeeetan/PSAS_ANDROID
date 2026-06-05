import 'package:intl/intl.dart';

class LogModel {
  final String deviceId;
  final String state;
  final String triggerType;
  final int timestamp;

  const LogModel({
    required this.deviceId,
    required this.state,
    required this.triggerType,
    required this.timestamp,
  });

  factory LogModel.fromMap(Map<dynamic, dynamic> map) => LogModel(
    deviceId:    map['device_id']    as String? ?? '',
    state:       map['state']        as String? ?? '',
    triggerType: map['trigger_type'] as String? ?? '',
    timestamp:   map['timestamp']    as int?    ?? 0,
  );

  String get formattedTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('hh:mm a').format(dt);
  }

  String get readableTrigger =>
      triggerType.replaceAll('_', ' ').toLowerCase();
}