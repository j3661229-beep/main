import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/shared_widgets.dart';

class DealerSlotsScreen extends StatefulWidget {
  const DealerSlotsScreen({super.key});
  @override
  State<DealerSlotsScreen> createState() => _DealerSlotsScreenState();
}

class _DealerSlotsScreenState extends State<DealerSlotsScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime   = const TimeOfDay(hour: 17, minute: 0);
  int _slotDuration    = 30;
  List<_SlotData> _generatedSlots = [];

  void _generateSlots() {
    HapticFeedback.mediumImpact();
    final slots = <_SlotData>[];
    var current = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
    final end   = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour,   _endTime.minute);

    while (true) {
      final slotEnd = current.add(Duration(minutes: _slotDuration));
      if (slotEnd.isAfter(end)) break;
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.dealerAccent)),
        child: child!,
      ),
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
        else         _endTime   = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.dealerAccent,
        foregroundColor: Colors.white,
        title: Text('Generate Slots', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Config card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.softShadow,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.dealerTint, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.event_rounded, color: AppColors.dealerAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Slot Configuration', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ]),
                const SizedBox(height: 20),

                // Date
                Text('Select Date', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14), color: AppColors.background),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.dealerAccent, size: 18),
                      const SizedBox(width: 12),
                      Text(DateFormat('EEE, d MMMM yyyy').format(_selectedDate), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // Time range
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Start Time', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _pickTime(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12), color: AppColors.background),
                        child: Text(_startTime.format(context), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dealerAccent), textAlign: TextAlign.center),
                      ),
                    ),
                  ])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('→', style: GoogleFonts.spaceGrotesk(fontSize: 20, color: AppColors.muted)),
                  ),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('End Time', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _pickTime(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12), color: AppColors.background),
                        child: Text(_endTime.format(context), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dealerAccent), textAlign: TextAlign.center),
                      ),
                    ),
                  ])),
                ]),
                const SizedBox(height: 20),

                // Duration chips
                Text('Slot Duration', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                const SizedBox(height: 8),
                Row(children: [15, 30, 45, 60].map((min) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _slotDuration = min),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _slotDuration == min ? AppColors.dealerAccent : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _slotDuration == min ? AppColors.dealerAccent : AppColors.border),
                      ),
                      child: Text('${min}m',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14, color: _slotDuration == min ? Colors.white : AppColors.ink),
                      ),
                    ),
                  ),
                )).toList()),
                const SizedBox(height: 24),

                AppButton(
                  label: 'Generate Slots',
                  onTap: _generateSlots,
                  color: AppColors.dealerAccent,
                  icon: Icons.auto_awesome_rounded,
                ),
              ],
            ),
          ),

          // Generated slots list
          if (_generatedSlots.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Generated Slots (${_generatedSlots.length})', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(20)),
                child: Text('${_generatedSlots.where((s) => s.isActive).length} active', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
              ),
            ]),
            const SizedBox(height: 12),
            ...List.generate(_generatedSlots.length, (i) {
              final slot = _generatedSlots[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.softShadow,
                  border: Border.all(color: slot.isActive ? AppColors.dealerAccent.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: slot.isActive ? AppColors.success : AppColors.muted, shape: BoxShape.circle)),
                  const SizedBox(width: 14),
                  Text(
                    '${DateFormat('hh:mm a').format(slot.start)} — ${DateFormat('hh:mm a').format(slot.end)}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: slot.isActive ? AppColors.ink : AppColors.muted),
                  ),
                  const Spacer(),
                  Switch(
                    value: slot.isActive,
                    activeColor: AppColors.dealerAccent,
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

