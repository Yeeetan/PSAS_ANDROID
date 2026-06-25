//D:\CODES\PSAS_ANDROID\lib\features\automation\models\routine_model.dart
class RoutineAction {
  final String id;
  final int order;
  final String deviceId;
  final String state;
  final int offsetSeconds;

  const RoutineAction({
    required this.id,
    required this.order,
    required this.deviceId,
    required this.state,
    required this.offsetSeconds,
  });

  factory RoutineAction.fromMap(String id, Map<dynamic, dynamic> map) => RoutineAction(
    id:            id,
    order:         map['order']          as int?    ?? 0,
    deviceId:      map['device_id']      as String? ?? '',
    state:         map['state']          as String? ?? 'ON',
    offsetSeconds: map['offset_seconds'] as int?    ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'order':          order,
    'device_id':      deviceId,
    'state':          state,
    'offset_seconds': offsetSeconds,
  };

  String get formattedOffset {
    if (offsetSeconds == 0) return 'at start';
    final m = offsetSeconds ~/ 60;
    return '+${m}m';
  }
}

class RoutineModel {
  final String id;
  final String name;
  final String status;
  final String source;
  final String timeCategory;
  final List<String> contextTags;
  final bool aiFineTuneEnabled;
  final String baseTime;
  final String? aiAdjustedTime;
  final double? confidence;
  final List<RoutineAction> actions;

  const RoutineModel({
    required this.id,
    required this.name,
    this.status   = 'active',
    this.source   = 'USER_CREATED',
    required this.timeCategory,
    this.contextTags       = const [],
    this.aiFineTuneEnabled = false,
    required this.baseTime,
    this.aiAdjustedTime,
    this.confidence,
    this.actions = const [],
  });

  bool get isActive     => status == 'active';
  bool get isAiGenerated => source == 'AI_GENERATED';
  String get effectiveTime => aiAdjustedTime ?? baseTime;

  factory RoutineModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final actionsMap = map['actions'] as Map<dynamic, dynamic>? ?? {};
    final actions = actionsMap.entries
        .map((e) => RoutineAction.fromMap(e.key as String, e.value as Map))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    List<String> tags = [];
    final rawTags = map['context_tags'];
    if (rawTags is List)       tags = rawTags.cast<String>();
    else if (rawTags is Map)   tags = rawTags.values.cast<String>().toList();

    return RoutineModel(
      id:               id,
      name:             map['name']               as String? ?? 'Routine',
      status:           map['status']             as String? ?? 'active',
      source:           map['source']             as String? ?? 'USER_CREATED',
      timeCategory:     map['time_category']      as String? ?? 'morning',
      contextTags:      tags,
      aiFineTuneEnabled: map['ai_fine_tune_enabled'] as bool? ?? false,
      baseTime:         map['base_time']          as String? ?? '08:00',
      aiAdjustedTime:   map['ai_adjusted_time']   as String?,
      confidence:       (map['confidence']        as num?)?.toDouble(),
      actions:          actions,
    );
  }

  Map<String, dynamic> toMap() {
    final actionsMap = {
      for (int i = 0; i < actions.length; i++)
        'step_${(i + 1).toString().padLeft(3, '0')}': actions[i].toMap()
    };
    return {
      'name':                name,
      'status':              status,
      'source':              source,
      'time_category':       timeCategory,
      'context_tags':        contextTags,
      'ai_fine_tune_enabled': aiFineTuneEnabled,
      'base_time':           baseTime,
      if (aiAdjustedTime != null) 'ai_adjusted_time': aiAdjustedTime,
      if (confidence != null)     'confidence':       confidence,
      'actions':             actionsMap,
    };
  }
}