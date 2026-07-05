import 'package:agrimart/l10n/app_localizations.dart';
import '../constants/farm_tools.dart';

String farmToolCategoryL10n(AppLocalizations l10n, String category) {
  switch (category) {
    case 'Market Intel':
      return l10n.categoryMarketIntel;
    case 'AI & Advisory':
      return l10n.categoryAiAdvisory;
    case 'Schemes & Finance':
      return l10n.categorySchemesFinance;
    case 'Trade & Rent':
      return l10n.categoryTradeRent;
    default:
      return category;
  }
}

String farmToolLabelL10n(AppLocalizations l10n, FarmToolItem tool) {
  switch (tool.route) {
    case '/farmer/price-alerts':
      return l10n.priceAlerts;
    case '/farmer/schemes':
      return l10n.govtSchemes;
    case '/farmer/soil':
      return l10n.soilAnalysis;
    case '/farmer/kisan-ai':
      return l10n.kisanAi;
    case '/farmer/crop-calendar':
      return l10n.cropAdvisor;
    case '/farmer/pmfby':
      return 'PMFBY';
    case '/farmer/fpo-bulk':
      return 'FPO Bulk';
    case '/farmer/equipment':
      return tool.label;
    case '/farmer/trade/bookings':
      return l10n.myTradeBookings;
    case '/farmer/crop-advisor':
      return l10n.cropAdvisor;
    case '/farmer/advisory':
      return l10n.farmAdvisory;
    default:
      return tool.label;
  }
}

String farmToolSubtitleL10n(AppLocalizations l10n, FarmToolItem tool) => tool.subtitle;
