class DeviceModel {
  final String id;
  final String name;
  final String room;
  final String floorId;
  final String pinId;
  final String state;
  final String type;
  final bool isVirtual;


  const DeviceModel({
    required this.id,
    required this.name,
    this.room    = '',
    this.floorId = '',
    this.pinId   = '',
    required this.state,
    this.type = 'switch',
    this.isVirtual = false,
  });

  bool get isOn => state == 'ON';

  factory DeviceModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return DeviceModel(
      id:      id,
      name:    map['name']     as String? ?? id,
      room:    map['room']     as String? ?? '',
      floorId: map['floor_id'] as String? ?? '',
      pinId:   map['pin_id']   as String? ?? '',
      state:   map['state']    as String? ?? 'OFF',
      type:    map['type']     as String? ?? 'switch',
      isVirtual: map['isVirtual']  as bool?   ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'name':     name,
    'room':     room,
    'floor_id': floorId,
    'pin_id':   pinId,
    'state':    state,
    'type':     type,
    'isVirtual': isVirtual,
  };

  DeviceModel copyWith({String? state}) => DeviceModel(
    id:      id,
    name:    name,
    room:    room,
    floorId: floorId,
    pinId:   pinId,
    state:   state ?? this.state,
    type:    type,
    isVirtual: isVirtual ?? this.isVirtual,
  );
}