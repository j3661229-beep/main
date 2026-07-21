import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/farm_profile_utils.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/auth_provider.dart';

class CropCalendarScreen extends ConsumerStatefulWidget {
  const CropCalendarScreen({super.key});

  @override
  ConsumerState<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends ConsumerState<CropCalendarScreen> {
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now().month - 1;
  }

  String _t(String en, String hi, String mr) {
    final code = ref.read(localeProvider).languageCode;
    if (code == 'hi') return hi;
    if (code == 'mr') return mr;
    return en;
  }

  List<String> get _monthLabels {
    final code = ref.read(localeProvider).languageCode;
    if (code == 'hi') {
      return ['जन', 'फर', 'मार्च', 'अप्र', 'मई', 'जून', 'जुल', 'अग', 'सित', 'अक्ट', 'नव', 'दिस'];
    }
    if (code == 'mr') {
      return ['जाने', 'फेब्रु', 'मार्च', 'एप्रि', 'मे', 'जून', 'जुलै', 'ऑग', 'सप्ट', 'ऑक्ट', 'नोव्ह', 'डिसे'];
    }
    return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final farmer = user?.farmer;
    final calendar = ref.watch(cropCalendarProvider(_selectedMonth));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F0),
      body: Column(
        children: [
          _CalendarHeader(
            onBack: () => context.pop(),
            title: _t('Crop Calendar', 'फसल कैलेंडर', 'पीक दिनदर्शिका'),
            subtitle: _t('Personal plan for your farm', 'आपके खेत के लिए योजना', 'तुमच्या शेतासाठी योजना'),
            onRefresh: () => ref.invalidate(cropCalendarProvider(_selectedMonth)),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.farmerAccent,
              onRefresh: () async => ref.invalidate(cropCalendarProvider(_selectedMonth)),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.rs(12), r.horizontalPadding, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FarmSummaryCard(
                            village: farmer?['village']?.toString() ?? '—',
                            district: user?.effectiveDistrict ?? farmer?['district']?.toString() ?? '—',
                            acres: FarmProfileUtils.farmSizeDisplay(farmer),
                            crops: FarmProfileUtils.cropsDisplay(farmer),
                            soil: farmer?['soilType']?.toString() ?? '—',
                            water: farmer?['waterSource']?.toString() ?? '—',
                            basedOnLabel: _t('Based on your farm profile', 'आपके खेत प्रोफ़ाइल पर आधारित', 'तुमच्या शेत प्रोफाइलवर आधारित'),
                          ),
                          SizedBox(height: r.rs(16)),
                          _MonthSelector(
                            labels: _monthLabels,
                            selected: _selectedMonth,
                            currentMonth: DateTime.now().month - 1,
                            onSelect: (i) => setState(() => _selectedMonth = i),
                          ),
                        ],
                      ),
                    ),
                  ),
                  calendar.when(
                    loading: () => SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(r.horizontalPadding),
                        child: Column(
                          children: [
                            ShimmerBox(height: r.rs(120), radius: 20),
                            SizedBox(height: r.rs(12)),
                            ShimmerBox(height: r.rs(88), radius: 16),
                            SizedBox(height: r.rs(12)),
                            ShimmerBox(height: r.rs(140), radius: 18),
                            SizedBox(height: r.rs(12)),
                            ShimmerBox(height: r.rs(140), radius: 18),
                          ],
                        ),
                      ),
                    ),
                    error: (e, _) => SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.all(r.horizontalPadding),
                        child: AppErrorState(
                          message: extractUserFacingError(e),
                          onRetry: () => ref.invalidate(cropCalendarProvider(_selectedMonth)),
                        ),
                      ),
                    ),
                    data: (data) {
                      if (data['error'] != null) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.all(r.horizontalPadding),
                            child: AppErrorState(
                              message: data['error'].toString(),
                              onRetry: () => ref.invalidate(cropCalendarProvider(_selectedMonth)),
                            ),
                          ),
                        );
                      }

                      final activities = (data['activities'] as List?) ?? [];
                      final deadlines = (data['governmentDeadlines'] as List?) ?? [];
                      final realWeather = data['realWeather'] as Map?;
                      final realMandi = data['realMandi'] as Map?;
                      final sources = data['dataSources'] as Map?;
                      final profile = (data['farmerProfile'] as Map?) ?? farmer;

                      return SliverPadding(
                        padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.rs(16), r.horizontalPadding, r.rs(32)),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _DataSourceStrip(
                              profile: sources?['profile'] == true,
                              weather: sources?['weather'] == true,
                              mandi: sources?['mandi'] == true,
                              label: _t('Data sources', 'डेटा स्रोत', 'डेटा स्रोत'),
                            ),
                            SizedBox(height: r.rs(14)),
                            if ((data['keyAlert'] ?? '').toString().isNotEmpty)
                              FadeInDown(
                                duration: const Duration(milliseconds: 350),
                                child: _KeyAlertCard(
                                  month: data['month']?.toString() ?? _monthLabels[_selectedMonth],
                                  district: data['district']?.toString() ?? profile?['district']?.toString() ?? '',
                                  alert: data['keyAlert'].toString(),
                                ),
                              ),
                            SizedBox(height: r.rs(14)),
                            _WeatherSection(
                              title: _t('Weather', 'मौसम', 'हवामान'),
                              aiSummary: data['weather']?.toString(),
                              realWeather: realWeather,
                              liveLabel: _t('Live from your farm GPS', 'आपके खेत GPS से', 'तुमच्या शेत GPS वरून'),
                            ),
                            SizedBox(height: r.rs(20)),
                            Text(
                              _t('This month\'s activities', 'इस महीने की गतिविधियाँ', 'या महिन्याची कामे'),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: r.sp(17),
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: r.rs(10)),
                            if (activities.isEmpty)
                              EmptyState(
                                emoji: '📅',
                                title: _t('No activities', 'कोई गतिविधि नहीं', 'कामे नाहीत'),
                                subtitle: _t('Try another month or refresh', 'दूसरा महीना चुनें', 'दुसरा महिना निवडा'),
                              )
                            else
                              ...activities.asMap().entries.map((entry) {
                                final item = entry.value as Map;
                                return FadeInUp(
                                  duration: Duration(milliseconds: 300 + entry.key * 60),
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: r.rs(10)),
                                    child: _ActivityCard(item: item),
                                  ),
                                );
                              }),
                            if (deadlines.isNotEmpty) ...[
                              SizedBox(height: r.rs(12)),
                              _SectionTitle(
                                icon: Icons.account_balance_rounded,
                                title: _t('Government deadlines', 'सरकारी अंतिम तिथि', 'शासकीय मुदत'),
                              ),
                              SizedBox(height: r.rs(8)),
                              ...deadlines.map((d) => _BulletRow(text: d.toString())),
                            ],
                            if ((data['mandiTip'] ?? '').toString().isNotEmpty ||
                                ((realMandi?['rows'] as List?)?.isNotEmpty ?? false)) ...[
                              SizedBox(height: r.rs(16)),
                              _MandiSection(
                                title: _t('Mandi advice', 'मंडी सलाह', 'मंडी सल्ला'),
                                tip: data['mandiTip']?.toString(),
                                rows: (realMandi?['rows'] as List?) ?? [],
                                liveLabel: _t('Live mandi prices', 'लाइव मंडी भाव', 'थेट मंडी भाव'),
                              ),
                            ],
                          ]),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final String title;
  final String subtitle;

  const _CalendarHeader({
    required this.onBack,
    required this.onRefresh,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(r.horizontalPadding, top + r.rs(8), r.horizontalPadding, r.rs(18)),
      decoration: const BoxDecoration(
        gradient: AppColors.farmerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: r.sp(20)),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              padding: EdgeInsets.all(r.rs(10)),
            ),
          ),
          SizedBox(width: r.rs(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('📅', style: TextStyle(fontSize: r.sp(22))),
                    SizedBox(width: r.rs(8)),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: r.sp(22),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.88), fontSize: r.sp(13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmSummaryCard extends StatelessWidget {
  final String village;
  final String district;
  final String acres;
  final String crops;
  final String soil;
  final String water;
  final String basedOnLabel;

  const _FarmSummaryCard({
    required this.village,
    required this.district,
    required this.acres,
    required this.crops,
    required this.soil,
    required this.water,
    required this.basedOnLabel,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;

    return Container(
      padding: EdgeInsets.all(r.rs(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.rs(20)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.farmerAccent.withValues(alpha: 0.06),
            blurRadius: r.rs(16),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(5)),
                decoration: BoxDecoration(
                  color: AppColors.farmerTint,
                  borderRadius: BorderRadius.circular(r.rs(20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.agriculture_rounded, size: r.sp(14), color: AppColors.farmerAccent),
                    SizedBox(width: r.rs(4)),
                    Text(
                      basedOnLabel,
                      style: GoogleFonts.inter(
                        fontSize: r.sp(11),
                        fontWeight: FontWeight.w600,
                        color: AppColors.farmerAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r.rs(12)),
          Text(
            '$village, $district',
            style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          SizedBox(height: r.rs(10)),
          Wrap(
            spacing: r.rs(8),
            runSpacing: r.rs(8),
            children: [
              _Chip(icon: Icons.square_foot_rounded, label: '$acres ac'),
              _Chip(icon: Icons.grass_rounded, label: crops),
              _Chip(icon: Icons.landslide_rounded, label: soil),
              _Chip(icon: Icons.water_drop_rounded, label: water),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(6)),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(r.rs(12)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: r.sp(14), color: AppColors.muted),
          SizedBox(width: r.rs(5)),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.ink, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final int currentMonth;
  final ValueChanged<int> onSelect;

  const _MonthSelector({
    required this.labels,
    required this.selected,
    required this.currentMonth,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;

    return SizedBox(
      height: r.rs(44),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => SizedBox(width: r.rs(8)),
        itemBuilder: (ctx, i) {
          final isSelected = i == selected;
          final isCurrent = i == currentMonth;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: r.rs(14), vertical: r.rs(10)),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.farmerAccent : Colors.white,
                borderRadius: BorderRadius.circular(r.rs(14)),
                border: Border.all(
                  color: isSelected
                      ? AppColors.farmerAccent
                      : isCurrent
                          ? AppColors.farmerAccent.withValues(alpha: 0.45)
                          : AppColors.border,
                  width: isCurrent && !isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                labels[i],
                style: GoogleFonts.inter(
                  fontSize: r.sp(13),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DataSourceStrip extends StatelessWidget {
  final bool profile;
  final bool weather;
  final bool mandi;
  final String label;

  const _DataSourceStrip({
    required this.profile,
    required this.weather,
    required this.mandi,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted, fontWeight: FontWeight.w600)),
        SizedBox(width: r.rs(8)),
        _SourceDot(active: profile, text: 'Farm'),
        SizedBox(width: r.rs(6)),
        _SourceDot(active: weather, text: 'Weather'),
        SizedBox(width: r.rs(6)),
        _SourceDot(active: mandi, text: 'Mandi'),
      ],
    );
  }
}

class _SourceDot extends StatelessWidget {
  final bool active;
  final String text;

  const _SourceDot({required this.active, required this.text});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.rs(8), vertical: r.rh(4)),
      decoration: BoxDecoration(
        color: active ? AppColors.successTint : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(r.rs(8)),
        border: Border.all(color: active ? AppColors.success.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: r.sp(12),
            color: active ? AppColors.success : AppColors.placeholder,
          ),
          SizedBox(width: r.rs(4)),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: r.sp(10),
              fontWeight: FontWeight.w600,
              color: active ? AppColors.success : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyAlertCard extends StatelessWidget {
  final String month;
  final String district;
  final String alert;

  const _KeyAlertCard({required this.month, required this.district, required this.alert});

  @override
  Widget build(BuildContext context) {
    final r = context.r;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.rs(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning.withValues(alpha: 0.15), AppColors.warningTint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(r.rs(20)),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('⚡', style: TextStyle(fontSize: r.sp(20))),
              SizedBox(width: r.rs(8)),
              Expanded(
                child: Text(
                  '$month • $district',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: r.sp(14), color: AppColors.ink),
                ),
              ),
            ],
          ),
          SizedBox(height: r.rs(8)),
          Text(
            alert,
            style: GoogleFonts.inter(fontSize: r.sp(14), height: 1.45, color: AppColors.ink, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _WeatherSection extends StatelessWidget {
  final String title;
  final String? aiSummary;
  final Map? realWeather;
  final String liveLabel;

  const _WeatherSection({
    required this.title,
    this.aiSummary,
    this.realWeather,
    required this.liveLabel,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final temp = realWeather?['tempC'];
    final desc = realWeather?['description']?.toString();
    final humidity = realWeather?['humidity'];
    final hasLive = temp != null || (desc?.isNotEmpty ?? false);

    return Container(
      padding: EdgeInsets.all(r.rs(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.rs(18)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.wb_sunny_rounded, title: title),
          if (hasLive) ...[
            SizedBox(height: r.rs(10)),
            Row(
              children: [
                Text('🌡️', style: TextStyle(fontSize: r.sp(28))),
                SizedBox(width: r.rs(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (temp != null)
                        Text(
                          '${(temp is num ? temp : double.tryParse(temp.toString()) ?? 0).round()}°C',
                          style: GoogleFonts.spaceGrotesk(fontSize: r.sp(24), fontWeight: FontWeight.w700),
                        ),
                      if (desc != null && desc.isNotEmpty)
                        Text(desc, style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted)),
                      if (humidity != null)
                        Text(
                          'Humidity $humidity%',
                          style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.placeholder),
                        ),
                    ],
                  ),
                ),
                BadgeChip(
                  label: liveLabel,
                  color: AppColors.infoTint,
                  textColor: AppColors.info,
                ),
              ],
            ),
          ],
          if (aiSummary != null && aiSummary!.isNotEmpty) ...[
            SizedBox(height: r.rs(10)),
            Text(
              aiSummary!,
              style: GoogleFonts.inter(fontSize: r.sp(13), height: 1.45, color: AppColors.ink),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map item;

  const _ActivityCard({required this.item});

  Color _urgencyColor(String urgency) {
    final u = urgency.toLowerCase();
    if (u.contains('critical') || u.contains('high')) return AppColors.danger;
    if (u.contains('medium')) return AppColors.warning;
    return AppColors.farmerAccent;
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final urgency = (item['urgency'] ?? '').toString();
    final color = _urgencyColor(urgency);
    final deadline = item['deadline']?.toString();
    final cost = item['estimatedCost']?.toString();
    final diy = item['doItYourself']?.toString();

    return Container(
      padding: EdgeInsets.all(r.rs(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.rs(18)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: r.rs(48),
            height: r.rs(48),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(r.rs(14)),
            ),
            child: Center(child: Text(item['emoji']?.toString() ?? '🌱', style: TextStyle(fontSize: r.sp(24)))),
          ),
          SizedBox(width: r.rs(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['crop'] ?? ''} — ${item['action'] ?? ''}',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: r.sp(15), color: AppColors.ink),
                ),
                SizedBox(height: r.rs(4)),
                Text(
                  item['description']?.toString() ?? '',
                  style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted, height: 1.45),
                ),
                if (urgency.isNotEmpty || deadline != null || cost != null) ...[
                  SizedBox(height: r.rs(10)),
                  Wrap(
                    spacing: r.rs(6),
                    runSpacing: r.rs(6),
                    children: [
                      if (urgency.isNotEmpty)
                        BadgeChip(label: urgency.toUpperCase(), color: color.withValues(alpha: 0.12), textColor: color),
                      if (deadline != null && deadline.isNotEmpty)
                        BadgeChip(label: deadline, color: AppColors.surfaceCard, textColor: AppColors.muted),
                      if (cost != null && cost.isNotEmpty)
                        BadgeChip(label: cost, color: AppColors.successTint, textColor: AppColors.success),
                      if (diy != null && diy.isNotEmpty)
                        BadgeChip(label: diy, color: AppColors.infoTint, textColor: AppColors.info),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MandiSection extends StatelessWidget {
  final String title;
  final String? tip;
  final List rows;
  final String liveLabel;

  const _MandiSection({
    required this.title,
    this.tip,
    required this.rows,
    required this.liveLabel,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;

    return Container(
      padding: EdgeInsets.all(r.rs(16)),
      decoration: BoxDecoration(
        color: AppColors.successTint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(r.rs(18)),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SectionTitle(icon: Icons.storefront_rounded, title: title)),
              if (rows.isNotEmpty)
                BadgeChip(label: liveLabel, color: AppColors.success.withValues(alpha: 0.15), textColor: AppColors.success),
            ],
          ),
          if (tip != null && tip!.isNotEmpty) ...[
            SizedBox(height: r.rs(8)),
            Text(tip!, style: GoogleFonts.inter(fontSize: r.sp(13), height: 1.45, color: AppColors.ink)),
          ],
          if (rows.isNotEmpty) ...[
            SizedBox(height: r.rs(12)),
            ...rows.map((row) {
              final m = row as Map;
              return Padding(
                padding: EdgeInsets.only(bottom: r.rs(6)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        m['crop']?.toString() ?? '',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: r.sp(13)),
                      ),
                    ),
                    Text(
                      '₹${m['modalPrice']}/${m['unit'] ?? 'q'}',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: r.sp(13), color: AppColors.success),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Row(
      children: [
        Icon(icon, size: r.sp(18), color: AppColors.farmerAccent),
        SizedBox(width: r.rs(8)),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: r.sp(15), color: AppColors.ink),
        ),
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String text;

  const _BulletRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: EdgeInsets.only(bottom: r.rh(6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.farmerAccent, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(fontSize: r.sp(13), height: 1.4, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
