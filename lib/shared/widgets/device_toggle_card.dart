import 'package:flutter/material.dart';
import '../../shared/models/device_model.dart';
import '../../shared/services/firebase_service.dart';
import '../../app/theme.dart';

class DeviceToggleCard extends StatelessWidget {
  final DeviceModel device;
  final bool compact;
  const DeviceToggleCard({super.key, required this.device, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isOn = device.isOn;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOn ? AppColors.primary : AppColors.border,
          width: isOn ? 1.5 : 1,
        ),
      ),
      child: compact ? _compact(isOn) : _full(isOn),
    );
  }

  Widget _full(bool isOn) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _icon(isOn),
          Switch(
            value: isOn,
            onChanged: (v) => FirebaseService.toggleDevice(device.id, v),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(device.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(device.id, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          Text(isOn ? 'ON' : 'OFF',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: isOn ? AppColors.primaryDark : AppColors.textSecondary,
              )),
        ],
      ),
    ],
  );

  Widget _compact(bool isOn) => Row(
    children: [
      _icon(isOn, size: 28, iconSize: 14),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(device.room,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      Switch(
        value: isOn,
        onChanged: (v) => FirebaseService.toggleDevice(device.id, v),
        activeColor: AppColors.primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ],
  );

  Widget _icon(bool isOn, {double size = 32, double iconSize = 16}) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: isOn ? AppColors.greenLight : const Color(0xFFF1EFE8),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      Icons.lightbulb_outline_rounded, size: iconSize,
      color: isOn ? AppColors.greenDark : AppColors.textSecondary,
    ),
  );
}