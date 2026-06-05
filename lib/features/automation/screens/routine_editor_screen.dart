import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/services/firebase_service.dart';
import '../models/routine_model.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  final String? routineId;
  const RoutineEditorScreen({super.key, this.routineId});

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends ConsumerState<RoutineEditorScreen> {
  final _nameCtrl       = TextEditingController();
  String _timeCategory  = 'morning';
  String _baseTime      = '07:00';
  bool   _aiFineTune    = false;
  final  _contextTags   = <String>[];
  final  _actions       = <RoutineAction>[];
  bool   _saving        = false;
  bool   _loaded        = false;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  void _loadExisting(List<RoutineModel> routines) {
    if (_loaded || widget.routineId == null) return;
    try {
      final r = routines.firstWhere((r) => r.id == widget.routineId);
      _nameCtrl.text = r.name;
      _timeCategory  = r.timeCategory;
      _baseTime      = r.baseTime;
      _aiFineTune    = r.aiFineTuneEnabled;
      _contextTags.addAll(r.contextTags);
      _actions.addAll(r.actions);
    } catch (_) {}
    _loaded = true;
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final id = widget.routineId ?? 'rule_${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseService.upsertRoutine(id, RoutineModel(
        id: id, name: _nameCtrl.text.trim(),
        timeCategory: _timeCategory, baseTime: _baseTime,
        contextTags: List.from(_contextTags),
        aiFineTuneEnabled: _aiFineTune,
        source: 'USER_CREATED',
        actions: List.from(_actions),
      ).toMap());
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routines = ref.watch(routinesProvider).valueOrNull ?? [];
    final devices  = ref.watch(devicesProvider).valueOrNull ?? [];
    if (!_loaded) { _loadExisting(routines); }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routineId != null ? 'Edit routine' : 'New routine'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size(72, 36)),
              child: _saving
                  ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label('Routine name'),
          TextField(controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'e.g. Morning startup')),
          const SizedBox(height: 20),

          _label('Time'),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _timeCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['morning', 'afternoon', 'night']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _timeCategory = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final p  = _baseTime.split(':');
                    final t  = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])),
                    );
                    if (t != null) setState(() =>
                    _baseTime = '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(_baseTime, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _label('AI fine-tune'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: AppColors.aiPurple),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Allow AI to fine-tune time',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('ML model can shift your base time based on actual behavior.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch(value: _aiFineTune, onChanged: (v) => setState(() => _aiFineTune = v),
                    activeColor: AppColors.aiPurple),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _label('Context tags'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['weekday','weekend','holiday','rainy'].map((tag) => FilterChip(
              label: Text(tag),
              selected: _contextTags.contains(tag),
              onSelected: (v) => setState(() =>
              v ? _contextTags.add(tag) : _contextTags.remove(tag)),
              selectedColor: AppColors.greenLight,
              checkmarkColor: AppColors.greenDark,
            )).toList(),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('Actions'),
              TextButton.icon(
                onPressed: devices.isEmpty ? null : () => _addAction(context, devices),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add action', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          if (_actions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF1EFE8), borderRadius: BorderRadius.circular(8)),
              child: const Text('No actions yet. Add a device action.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ..._actions.asMap().entries.map((e) => _ActionRow(
            action: e.value, index: e.key,
            onDelete: () => setState(() => _actions.removeAt(e.key)),
          )),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
  );

  Future<void> _addAction(BuildContext context, List devices) async {
    String? devId; String state = 'ON'; int offsetMin = 0;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDs) => AlertDialog(
        title: const Text('Add action'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Device'),
            items: devices.map<DropdownMenuItem<String>>(
                    (d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
            onChanged: (v) => setDs(() => devId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: state,
            decoration: const InputDecoration(labelText: 'State'),
            items: ['ON','OFF'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setDs(() => state = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Delay (minutes after start)'),
            keyboardType: TextInputType.number, initialValue: '0',
            onChanged: (v) => offsetMin = int.tryParse(v) ?? 0,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: devId == null ? null : () {
              setState(() => _actions.add(RoutineAction(
                id: 'step_${_actions.length + 1}', order: _actions.length + 1,
                deviceId: devId!, state: state, offsetSeconds: offsetMin * 60,
              )));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      )),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final RoutineAction action;
  final int index;
  final VoidCallback onDelete;
  const _ActionRow({required this.action, required this.index, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(4)),
        child: Center(child: Text('${index+1}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.greenDark))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(action.deviceId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        Text('${action.state} · ${action.formattedOffset}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ])),
      IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
          onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
    ]),
  );
}