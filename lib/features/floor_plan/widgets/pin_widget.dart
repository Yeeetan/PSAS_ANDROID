import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class PinWidget extends StatelessWidget {
  final String label;
  final bool hasActiveDevice;
  final bool editMode;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PinWidget({
    super.key,
    required this.label,
    required this.hasActiveDevice,
    required this.onTap,
    this.editMode = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Circle marker
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: hasActiveDevice ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasActiveDevice ? AppColors.primaryDark : AppColors.border,
                    width: 2,
                  ),
                  boxShadow: const [BoxShadow(color: Color(0x29000000), blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Icon(
                  Icons.home_outlined, size: 18,
                  color: hasActiveDevice ? Colors.white : AppColors.textSecondary,
                ),
              ),
              // Delete button (edit mode only)
              if (editMode)
                Positioned(
                  top: -5, right: -5,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 18, height: 18,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 11, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          // Triangle pointer
          CustomPaint(
            size: const Size(10, 6),
            painter: _TrianglePainter(
              color: hasActiveDevice ? AppColors.primary : Colors.white,
              strokeColor: hasActiveDevice ? AppColors.primaryDark : AppColors.border,
            ),
          ),
          // Label pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color strokeColor;
  const _TrianglePainter({required this.color, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = strokeColor);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_) => false;
}