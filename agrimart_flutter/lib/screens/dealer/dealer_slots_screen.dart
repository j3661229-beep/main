import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class DealerSlotsScreen extends StatefulWidget {
  const DealerSlotsScreen({super.key});
  @override
  State<DealerSlotsScreen> createState() => _DealerSlotsScreenState();
}

class _DealerSlotsScreenState extends State<DealerSlotsScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _slotDuration = 30; // minutes
  List<_SlotData> _generatedSlots = [];

  void _generateSlots() {
    HapticFeedback.mediumImpact();
    final slots = <_SlotData>[];
    var current = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
    final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);

    while (current.add(Duration(minutes: _slotDuration)).isBefore(end) || current.add(Duration(minutes: _slotDuration)).isAtSameMomentAs(end)) {
      final slotEnd = current.add(Duration(minutes: _slotDuration));
      slots.add(_SlotData(start: current, end: slotEnd, isActive: true));
      current = slotEnd;
    }
    setState(() => _generatedSlots = slots);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary)), child: child!),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Generate Slots'), backgroundColor: AppColors.primary),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Date picker
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.event, color: AppColors.primary, size: 20)),
                const SizedBox(width: 12),
                Text('Slot Configuration', style: AppTextStyles.headingMD),
              ]),
              const SizedBox(height: 20),

              // Date
              Text('Select Date', style: AppTextStyles.labelMD),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16), color: AppColors.surfaceVariant),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                    const SizedBox(width: 12),
                    Text(DateFormat('EEE, d MMMM yyyy').format(_selectedDate), style: AppTextStyles.headingSM),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Time range
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Start Time', style: AppTextStyles.labelMD),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _pickTime(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14), color: AppColors.surfaceVariant),
                      child: Text(_startTime.format(context), style: AppTextStyles.headingSM, textAlign: TextAlign.center),
                    ),
                  ),
                ])),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('→', style: TextStyle(fontSize: 20, color: AppColors.textTertiary))),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('End Time', style: AppTextStyles.labelMD),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _pickTime(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14), color: AppColors.surfaceVariant),
                      child: Text(_endTime.format(context), style: AppTextStyles.headingSM, textAlign: TextAlign.center),
                    ),
                  ),
                ])),
              ]),
              const SizedBox(height: 20),

              // Duration
              Text('Slot Duration', style: AppTextStyles.labelMD),
              const SizedBox(height: 8),
              Row(children: [15, 30, 45, 60].map((min) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _slotDuration = min),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _slotDuration == min ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _slotDuration == min ? AppColors.primary : AppColors.border),
                    ),
                    child: Text('${min}m', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _slotDuration == min ? Colors.white : AppColors.textPrimary)),
                  ),
                ),
              )).toList()),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton.icon(
                  onPressed: _generateSlots,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate Slots', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),

          if (_generatedSlots.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Generated Slots (${_generatedSlots.length})', style: AppTextStyles.headingMD),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.successSurface, borderRadius: BorderRadius.circular(20)),
                child: Text('${_generatedSlots.where((s) => s.isActive).length} active', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
              ),
            ]),
            const SizedBox(height: 16),
            ...List.generate(_generatedSlots.length, (i) {
              final slot = _generatedSlots[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.softShadow,
                  border: Border.all(color: slot.isActive ? AppColors.primaryBorder : AppColors.border.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: slot.isActive ? AppColors.success : AppColors.textTertiary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 14),
                  Text('${DateFormat('hh:mm a').format(slot.start)} — ${DateFormat('hh:mm a').format(slot.end)}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: slot.isActive ? AppColors.textPrimary : AppColors.textTertiary)),
                  const Spacer(),
                  Switch(
                    value: slot.isActive,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _generatedSlots[i] = _SlotData(start: slot.start, end: slot.end, isActive: v)),
                  ),
                ]),
              );
            }),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SlotData {
  final DateTime start, end;
  final bool isActive;
  const _SlotData({required this.start, required this.end, required this.isActive});
}
