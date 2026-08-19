// floor_plan/widgets/floor_plan_viewer.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../../../app/theme.dart';
import '../models/floor_model.dart';
import '../models/pin_model.dart';
import '../../../shared/models/device_model.dart';
import 'pin_widget.dart';
import 'device_bottom_sheet.dart';

class FloorPlanViewer extends StatelessWidget {
  final FloorModel floor;
  final List<DeviceModel> devices;
  final bool editMode;
  final void Function(double xPct, double yPct)? onLongPress;
  final void Function(PinModel)? onPinDelete;
  final void Function(PinModel pin, double xPct, double yPct)? onPinMoved; // NEW

  const FloorPlanViewer({
    super.key,
    required this.floor,
    required this.devices,
    this.editMode = false,
    this.onLongPress,
    this.onPinDelete,
    this.onPinMoved, // NEW
  });

  @override
  Widget build(BuildContext context) {
    // A floor plan photo is optional, not required, to start placing
    // switches -- the old early-return here made a brand-new floor (which
    // never has plan_image_url set until someone uploads one) render a
    // static placeholder with no GestureDetector at all, so long-press
    // could never register on it. Now it always renders an interactive
    // canvas -- the uploaded photo if there is one, otherwise a plain
    // blank surface -- either way wrapped in the same long-press handler.
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: editMode
                ? (d) => onLongPress?.call(
                (d.localPosition.dx / w).clamp(0.0, 1.0),
                (d.localPosition.dy / h).clamp(0.0, 1.0))
                : null,
            child: floor.planImageUrl != null
                ? PhotoView(
              imageProvider: floor.planImageUrl!.startsWith('http')
                  ? CachedNetworkImageProvider(floor.planImageUrl!) as ImageProvider
                  : FileImage(File(floor.planImageUrl!)),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration: const BoxDecoration(color: AppColors.surface),
            )
                : _blankCanvas(),
          ),
          // Pins (Now using _DraggablePin)
          ...floor.pins.map((pin) {
            final hasActive = pin.linkedDeviceIds
                .any((id) => devices.any((d) => d.id == id && d.isOn));
            return _DraggablePin(
              pin: pin,
              w: w,
              h: h,
              hasActiveDevice: hasActive,
              editMode: editMode,
              onTap: () {
                if (!editMode) DeviceBottomSheet.show(context, pin);
              },
              onDelete: () => onPinDelete?.call(pin),
              onDragEnd: onPinMoved != null ? (newX, newY) => onPinMoved!(pin, newX, newY) : null,
            );
          }),
          // Edit hint banner
          if (editMode)
            Positioned(
              bottom: 20, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Long-press to add • Drag to move',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _blankCanvas() => Container(
    width: double.infinity,
    height: double.infinity,
    color: AppColors.surface,
    child: !editMode ? _placeholder() : null,
  );

  Widget _placeholder() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.map_outlined, size: 64, color: AppColors.textHint),
        const SizedBox(height: 12),
        const Text('No floor plan uploaded', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        if (!editMode)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Go to Settings → Floor setup',
                style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          ),
      ],
    ),
  );
}

// NEW: Local stateful wrapper to handle smooth 60fps dragging
class _DraggablePin extends StatefulWidget {
  final PinModel pin;
  final double w;
  final double h;
  final bool hasActiveDevice;
  final bool editMode;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final void Function(double xPct, double yPct)? onDragEnd;

  const _DraggablePin({
    required this.pin, required this.w, required this.h,
    required this.hasActiveDevice, required this.editMode,
    required this.onTap, this.onDelete, this.onDragEnd,
  });

  @override
  State<_DraggablePin> createState() => _DraggablePinState();
}

class _DraggablePinState extends State<_DraggablePin> {
  double? dragX;
  double? dragY;

  final double dragSensitivity = 1.8;

  @override
  Widget build(BuildContext context) {
    // Use drag coordinates if currently dragging, otherwise use the saved Firebase percentages
    final currentX = dragX ?? (widget.pin.xPct * widget.w);
    final currentY = dragY ?? (widget.pin.yPct * widget.h);

    return Positioned(
      left: currentX - 19, // Center the pin (38 / 2)
      top: currentY - 19,
      child: GestureDetector(

        behavior: HitTestBehavior.opaque,

        onPanUpdate: widget.editMode ? (details) {
          setState(() {
            double newX = currentX + (details.delta.dx * dragSensitivity);
            double newY = currentY + (details.delta.dy * dragSensitivity);

            dragX = newX.clamp(0.0, widget.w);
            dragY = newY.clamp(0.0, widget.h);
          });
        } : null,
        onPanEnd: widget.editMode ? (_) {
          if (dragX != null && dragY != null) {
            final newXPct = (dragX! / widget.w).clamp(0.0, 1.0);
            final newYPct = (dragY! / widget.h).clamp(0.0, 1.0);
            widget.onDragEnd?.call(newXPct, newYPct);
          }
          setState(() { dragX = null; dragY = null; });
        } : null,
        child: PinWidget(
          label: widget.pin.label,
          hasActiveDevice: widget.hasActiveDevice,
          editMode: widget.editMode,
          onTap: widget.onTap,
          onDelete: widget.onDelete,
        ),
      ),
    );
  }
}