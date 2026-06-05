import 'pin_model.dart';

class FloorModel {
  final String id;
  final String name;
  final int order;
  final String? planImageUrl;
  final double planImageWidthPx;
  final double planImageHeightPx;
  final List<PinModel> pins;

  const FloorModel({
    required this.id,
    required this.name,
    required this.order,
    this.planImageUrl,
    this.planImageWidthPx  = 1200,
    this.planImageHeightPx = 800,
    this.pins = const [],
  });

  factory FloorModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final pinsMap = map['pins'] as Map<dynamic, dynamic>? ?? {};
    return FloorModel(
      id:                id,
      name:              map['name']                  as String? ?? 'Floor',
      order:             map['order']                 as int?    ?? 1,
      planImageUrl:      map['plan_image_url']        as String?,
      planImageWidthPx:  (map['plan_image_width_px']  as num?)?.toDouble() ?? 1200,
      planImageHeightPx: (map['plan_image_height_px'] as num?)?.toDouble() ?? 800,
      pins: pinsMap.entries
          .map((e) => PinModel.fromMap(e.key as String, e.value as Map))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name':                 name,
    'order':                order,
    if (planImageUrl != null) 'plan_image_url': planImageUrl,
    'plan_image_width_px':  planImageWidthPx,
    'plan_image_height_px': planImageHeightPx,
  };
}