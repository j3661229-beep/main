import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class DealerWorkingDaysScreen extends StatefulWidget {
  const DealerWorkingDaysScreen({super.key});
  @override
  State<DealerWorkingDaysScreen> createState() => _DealerWorkingDaysScreenState();
}

class _DealerWorkingDaysScreenState extends State<DealerWorkingDaysScreen> {
  final List<_DaySchedule> _schedule = [
    _DaySchedule(day: 'Monday', short: 'Mon', isOpen: true, open: const TimeOfDay(hour: 9, minute: 0), close: const TimeOfDay(hour: 18, minute: 0)),
    _DaySchedule(day: 'Tuesday', short: 'Tue', isOpen: true, open: const TimeOfDay(hour: 9, minute: 0), close: const TimeOfDay(hour: 18, minute: 0)),
    _DaySchedule(day: 'Wednesday', short: 'Wed', isOpen: true, open: const TimeOfDay(hour: 9, minute: 0), close: const TimeOfDay(hour: 18, minute: 0)),
    _DaySchedule(day: 'Thursday', short: 'Thu', isOpen: true, open: const TimeOfDay(hour: 9, minute: 0), close: const TimeOfDay(hour: 18, minute: 0)),
    _DaySchedule(day: 'Friday', short: 'Fri', isOpen: true, open: const TimeOfDay(hour: 9, minute: 0), close: const TimeOfDay(hour: 18, minute: 0)),
    _DaySchedule(day: 'Saturday', short: 'Sat', isOpen: true, open: const TimeOfDay(hour: 9, minute: 0), close: const TimeOfDay(hour: 14, minute: 0)),
    _DaySchedule(day: 'Sunday', short: 'Sun', isOpen: false, open: const TimeOfDay(hour: 10, minute: 0), close: const TimeOfDay(hour: 14, minute: 0)),
  ];

  Future<void> _pickTime(int index, bool isOpen) async {
    final current = isOpen ? _schedule[index].open : _schedule[index].close;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) {
      setState(() {
        final s = _schedule[index];
        _schedule[index] = _DaySchedule(
          day: s.day, short: s.short, isOpen: s.isOpen,
          open: isOpen ? picked : s.open,
          close: isOpen ? s.close : picked,
        );
      });
    }
  }

  void _saveSchedule() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Working schedule saved!'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final openDays = _schedule.where((s) => s.isOpen).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Working Days & Hours'), backgroundColor: AppColors.primary),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.primaryShadow),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.schedule, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Your Weekly Schedule', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$openDays days open • ${7 - openDays} days off', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),

          // Quick toggle row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quick Toggle', style: AppTextStyles.labelMD),
              const SizedBox(height: 12),
              Row(children: List.generate(7, (i) {
                final s = _schedule[i];
                return Expanded(child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _schedule[i] = _DaySchedule(day: s.day, short: s.short, isOpen: !s.isOpen, open: s.open, close: s.close);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: s.isOpen ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: s.isOpen ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(s.short, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.isOpen ? Colors.white : AppColors.textTertiary)),
                  ),
                ));
              })),
            ]),
          ),
          const SizedBox(height: 24),

          // Day cards
          ...List.generate(7, (i) {
            final s = _schedule[i];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.softShadow,
                border: Border.all(color: s.isOpen ? AppColors.primaryBorder : AppColors.border.withValues(alpha: 0.3)),
              ),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: s.isOpen ? AppColors.primarySurface : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(s.short, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: s.isOpen ? AppColors.primary : AppColors.textTertiary))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.day, style: AppTextStyles.headingSM.copyWith(color: s.isOpen ? AppColors.textPrimary : AppColors.textTertiary)),
                    Text(s.isOpen ? '${s.open.format(context)} — ${s.close.format(context)}' : 'Closed', style: AppTextStyles.caption),
                  ])),
                  Switch(
                    value: s.isOpen,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() {
                      _schedule[i] = _DaySchedule(day: s.day, short: s.short, isOpen: v, open: s.open, close: s.close);
                    }),
                  ),
                ]),
                if (s.isOpen) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: () => _pickTime(i, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.amber),
                          const SizedBox(width: 8),
                          Text(s.open.format(context), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ]),
                      ),
                    )),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('→', style: TextStyle(color: AppColors.textTertiary))),
                    Expanded(child: GestureDetector(
                      onTap: () => _pickTime(i, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.nights_stay_outlined, size: 16, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 8),
                          Text(s.close.format(context), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ]),
                      ),
                    )),
                  ]),
                ],
              ]),
            );
          }),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              onPressed: _saveSchedule,
              icon: const Icon(Icons.save),
              label: const Text('Save Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _DaySchedule {
  final String day, short;
  final bool isOpen;
  final TimeOfDay open, close;
  const _DaySchedule({required this.day, required this.short, required this.isOpen, required this.open, required this.close});
}
