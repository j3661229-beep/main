import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/utils/responsive.dart';

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
    final r = context.r;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.dealerAccent,
        foregroundColor: Colors.white,
        title: Text('Generate Slots', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: EdgeInsets.all(r.rs(20)),
        children: [
          // Config card
          Container(
            padding: EdgeInsets.all(r.rs(20)),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(r.rs(20)),
              boxShadow: AppColors.softShadow,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: EdgeInsets.all(r.rs(10)),
                    decoration: BoxDecoration(color: AppColors.dealerTint, borderRadius: BorderRadius.circular(r.rs(12))),
                    child: Icon(Icons.event_rounded, color: AppColors.dealerAccent, size: r.sp(20)),
                  ),
                  SizedBox(width: r.rs(12)),
                  Text('Slot Configuration', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink)),
                ]),
                SizedBox(height: r.rh(20)),

                // Date
                Text('Select Date', style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.muted)),
                SizedBox(height: r.rh(8)),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: r.rs(18), vertical: r.rh(14)),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(r.rs(14)), color: AppColors.background),
                    child: Row(children: [
                      Icon(Icons.calendar_today_rounded, color: AppColors.dealerAccent, size: r.sp(18)),
                      SizedBox(width: r.rs(12)),
                      Text(DateFormat('EEE, d MMMM yyyy').format(_selectedDate), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w600, color: AppColors.ink)),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ]),
                  ),
                ),
                SizedBox(height: r.rh(20)),

                // Time range
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Start Time', style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.muted)),
                    SizedBox(height: r.rh(6)),
                    GestureDetector(
                      onTap: () => _pickTime(true),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: r.rs(16), vertical: r.rh(14)),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(r.rs(12)), color: AppColors.background),
                        child: Text(_startTime.format(context), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w700, color: AppColors.dealerAccent), textAlign: TextAlign.center),
                      ),
                    ),
                  ])),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.rs(12)),
                    child: Text('→', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(20), color: AppColors.muted)),
                  ),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('End Time', style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.muted)),
                    SizedBox(height: r.rh(6)),
                    GestureDetector(
                      onTap: () => _pickTime(false),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: r.rs(16), vertical: r.rh(14)),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(r.rs(12)), color: AppColors.background),
                        child: Text(_endTime.format(context), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w700, color: AppColors.dealerAccent), textAlign: TextAlign.center),
                      ),
                    ),
                  ])),
                ]),
                SizedBox(height: r.rh(20)),

                // Duration chips
                Text('Slot Duration', style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.muted)),
                SizedBox(height: r.rh(8)),
                Row(children: [15, 30, 45, 60].map((min) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _slotDuration = min),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(right: r.rs(8)),
                      padding: EdgeInsets.symmetric(vertical: r.rh(12)),
                      decoration: BoxDecoration(
                        color: _slotDuration == min ? AppColors.dealerAccent : AppColors.background,
                        borderRadius: BorderRadius.circular(r.rs(12)),
                        border: Border.all(color: _slotDuration == min ? AppColors.dealerAccent : AppColors.border),
                      ),
                      child: Text('${min}m',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: r.sp(14), color: _slotDuration == min ? Colors.white : AppColors.ink),
                      ),
                    ),
                  ),
                )).toList()),
                SizedBox(height: r.rh(24)),

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
            SizedBox(height: r.rh(24)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Generated Slots (${_generatedSlots.length})', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(15), fontWeight: FontWeight.w700, color: AppColors.ink)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(4)),
                decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(r.rs(20))),
                child: Text('${_generatedSlots.where((s) => s.isActive).length} active', style: GoogleFonts.inter(fontSize: r.sp(11), fontWeight: FontWeight.w700, color: AppColors.success)),
              ),
            ]),
            SizedBox(height: r.rh(12)),
            ...List.generate(_generatedSlots.length, (i) {
              final slot = _generatedSlots[i];
              return Container(
                margin: EdgeInsets.only(bottom: r.rh(10)),
                padding: EdgeInsets.symmetric(horizontal: r.rs(18), vertical: r.rh(14)),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(r.rs(14)),
                  boxShadow: AppColors.softShadow,
                  border: Border.all(color: slot.isActive ? AppColors.dealerAccent.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: slot.isActive ? AppColors.success : AppColors.muted, shape: BoxShape.circle)),
                  SizedBox(width: r.rs(14)),
                  Text(
                    '${DateFormat('hh:mm a').format(slot.start)} — ${DateFormat('hh:mm a').format(slot.end)}',
                    style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w700, color: slot.isActive ? AppColors.ink : AppColors.muted),
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
          SizedBox(height: r.rh(40)),
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

