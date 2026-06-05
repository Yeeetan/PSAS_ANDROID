class PinModel {
  final String id;
  final double xPct;
  final double yPct;
  final String label;
  final String icon;
  final List<String> linkedDeviceIds;

  const PinModel({
    required this.id,
    required this.xPct,
    required this.yPct,
    required this.label,
    this.icon = 'room',
    this.linkedDeviceIds = const [],
  });

  factory PinModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final linked = map['linked_devices'] as Map<dynamic, dynamic>? ?? {};
    return PinModel(
      id:              id,
      xPct:            (map['x_pct'] as num?)?.toDouble() ?? 0.5,
      yPct:            (map['y_pct'] as num?)?.toDouble() ?? 0.5,
      label:           map['label'] as String? ?? 'Pin',
      icon:            map['icon']  as String? ?? 'room',
      linkedDeviceIds: linked.keys.cast<String>().toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'x_pct':          xPct,
    'y_pct':          yPct,
    'label':          label,
    'icon':           icon,
    'linked_devices': {for (final id in linkedDeviceIds) id: true},
  };
}