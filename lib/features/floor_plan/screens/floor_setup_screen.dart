import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_service.dart';
import '../../../shared/services/storage_service.dart';
import '../models/floor_model.dart';

class FloorSetupScreen extends ConsumerStatefulWidget {
  const FloorSetupScreen({super.key});

  @override
  ConsumerState<FloorSetupScreen> createState() => _FloorSetupScreenState();
}

class _FloorSetupScreenState extends ConsumerState<FloorSetupScreen> {
  String? _uploadingFloorId;

  @override
  Widget build(BuildContext context) {
    final floorsAsync = ref.watch(floorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Floor setup'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showAddFloorDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add floor'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(
            child: floorsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (floors) => floors.isEmpty
                  ? const Center(child: Text('No floors yet.', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: floors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _floorCard(context, floors[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _floorCard(BuildContext context, FloorModel floor) {
    final isUploading = _uploadingFloorId == floor.id;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(8),
              image: floor.planImageUrl != null
                  ? DecorationImage(image: NetworkImage(floor.planImageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: floor.planImageUrl == null
                ? const Icon(Icons.image_outlined, color: AppColors.greenDark)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(floor.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text('${floor.pins.length} pin(s)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Upload
          isUploading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
            icon: const Icon(Icons.upload_file_rounded, size: 20, color: AppColors.textSecondary),
            tooltip: 'Upload floor plan image',
            onPressed: () => _uploadImage(floor.id),
          ),
          // Place pins
          IconButton(
            icon: const Icon(Icons.sensors, size: 20, color: AppColors.textSecondary),
            tooltip: 'Place Switches',
            onPressed: () => context.push('/pin-placement/${floor.id}'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadImage(String floorId) async {
    setState(() => _uploadingFloorId = floorId);
    try {
      final url = await StorageService.uploadFloorPlan(floorId);
      if (url != null) {
        await FirebaseService.upsertFloor(floorId, {'plan_image_url': url});
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Floor plan uploaded!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingFloorId = null);
    }
  }

  Future<void> _showAddFloorDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add floor'),
        content: TextField(controller: ctrl, autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Ground Floor')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final floors = ref.read(floorsProvider).valueOrNull ?? [];
              final id = 'floor_${floors.length + 1}';
              await FirebaseService.upsertFloor(id, {'name': ctrl.text.trim(), 'order': floors.length + 1});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}