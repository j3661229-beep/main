import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_language_provider.dart';
import '../../core/utils/app_language.dart';
import 'auth_provider.dart';

const String _kYouTubeApiKey = AppConstants.youtubeApiKey;
final bool _hasApiKey = _kYouTubeApiKey.isNotEmpty;
const String _kYouTubeBase = 'https://www.googleapis.com/youtube/v3';

// ── Curated farming channels ────────────────────────────────────────────────
const List<Map<String, String>> kFarmingChannels = [
  {'id': 'UCPq63bfMdkPE5-Ow1UPF_cA', 'name': 'DD Kisan', 'emoji': '📺', 'lang': 'hi'},
  {'id': 'UCm8djSAzKtG9d_-8MXbOT5A', 'name': 'Krishi Jagran', 'emoji': '🌾', 'lang': 'hi'},
  {'id': 'UCBBe_JqGJoJNKpMBN6PXZIQ', 'name': 'Agrowon', 'emoji': '🌿', 'lang': 'mr'},
  {'id': 'UCT5EQaABmxLWFBw-vu6I9iw', 'name': 'Kheti Kisani', 'emoji': '🚜', 'lang': 'hi'},
];

const List<Map<String, dynamic>> kCuratedVideos = [
  {
    'videoId': 'IU-LzOblKHQ',
    'title': 'Tomato Farming – Complete Guide for High Yield',
    'titleHi': 'टमाटर की खेती – उच्च पैदावार गाइड',
    'titleMr': 'टोमॅटो लागवड – जास्त उत्पादन मार्गदर्शन',
    'channel': 'Krishi Jagran',
    'thumbnail': 'https://img.youtube.com/vi/IU-LzOblKHQ/mqdefault.jpg',
    'duration': '12:34',
    'category': 'Crop Care',
    'lang': 'hi',
  },
  {
    'videoId': 'vc77i5D8v9g',
    'title': 'Drip Irrigation System Setup | Save Water & Boost Yield',
    'titleHi': 'ड्रिप सिंचाई सेटअप | पानी बचाएं',
    'titleMr': 'ठिबक सिंचन | पाणी वाचवा',
    'channel': 'DD Kisan',
    'thumbnail': 'https://img.youtube.com/vi/vc77i5D8v9g/mqdefault.jpg',
    'duration': '8:22',
    'category': 'Irrigation',
    'lang': 'hi',
  },
  {
    'videoId': 'vDkb8Ox_vkI',
    'title': 'Organic Farming from Scratch | Zero Chemical Methods',
    'titleHi': 'जैविक खेती शुरुआत से',
    'titleMr': 'सेंद्रिय शेती – सुरुवातीपासून',
    'channel': 'Agrowon',
    'thumbnail': 'https://img.youtube.com/vi/vDkb8Ox_vkI/mqdefault.jpg',
    'duration': '15:10',
    'category': 'Organic',
    'lang': 'mr',
  },
  {
    'videoId': 'j7nEM0BZJGE',
    'title': 'PM Kisan Samman Nidhi – How to Apply & Check Status',
    'titleHi': 'PM Kisan – आवेदन और स्थिति',
    'titleMr': 'PM Kisan – अर्ज आणि स्थिती',
    'channel': 'Kheti Kisani',
    'thumbnail': 'https://img.youtube.com/vi/j7nEM0BZJGE/mqdefault.jpg',
    'duration': '6:45',
    'category': 'Schemes',
    'lang': 'hi',
  },
  {
    'videoId': 'oLLMVJQfGQ8',
    'title': 'Mandi Price Prediction – When to Sell Your Crop',
    'titleHi': 'मंडी भाव – कब बेचें',
    'titleMr': 'मंडी भाव – कधी विकावे',
    'channel': 'Krishi Jagran',
    'thumbnail': 'https://img.youtube.com/vi/oLLMVJQfGQ8/mqdefault.jpg',
    'duration': '9:17',
    'category': 'Mandi Tips',
    'lang': 'hi',
  },
  {
    'videoId': 'c7FexhS8bfQ',
    'title': 'Soil Health Card – How to Read & Use It',
    'titleHi': 'मृदा स्वास्थ्य कार्ड कैसे पढ़ें',
    'titleMr': 'माती आरोग्य कार्ड वाचणे',
    'channel': 'DD Kisan',
    'thumbnail': 'https://img.youtube.com/vi/c7FexhS8bfQ/mqdefault.jpg',
    'duration': '7:03',
    'category': 'Crop Care',
    'lang': 'hi',
  },
  {
    'videoId': 'LgTaKlb60uQ',
    'title': 'Wheat Farming Tips – From Sowing to Harvest',
    'titleHi': 'गेहूं की खेती – बुवाई से कटाई',
    'titleMr': 'गहू लागवड – पेरणी ते कापणी',
    'channel': 'Kheti Kisani',
    'thumbnail': 'https://img.youtube.com/vi/LgTaKlb60uQ/mqdefault.jpg',
    'duration': '11:58',
    'category': 'Crop Care',
    'lang': 'hi',
  },
  {
    'videoId': 'fEG0hFMRFZY',
    'title': 'Modern Farming Equipment in India 2024',
    'titleHi': 'आधुनिक खेती उपकरण 2024',
    'titleMr': 'आधुनिक शेती उपकरणे 2024',
    'channel': 'Agrowon',
    'thumbnail': 'https://img.youtube.com/vi/fEG0hFMRFZY/mqdefault.jpg',
    'duration': '14:29',
    'category': 'Technology',
    'lang': 'mr',
  },
];

class YoutubeLocaleContext {
  final AppLanguage language;
  final String district;
  final String state;
  final String? village;

  const YoutubeLocaleContext({
    required this.language,
    required this.district,
    required this.state,
    this.village,
  });
}

final youtubeLocaleProvider = Provider<YoutubeLocaleContext>((ref) {
  final user = ref.watch(authProvider).user;
  final lang = ref.watch(appLanguageProvider);
  final farmer = user?.farmer as Map?;
  return YoutubeLocaleContext(
    language: lang,
    district: user?.effectiveDistrict ?? 'Nashik',
    state: user?.state ?? 'Maharashtra',
    village: farmer?['village']?.toString(),
  );
});

List<Map<String, String>> farmingCategoriesFor(AppLanguage lang) {
  switch (lang.code) {
    case 'mr':
      return const [
        {'label': 'ट्रेंडिंग', 'query': 'शेती सल्ला भारत', 'emoji': '🔥'},
        {'label': 'पिक काळजी', 'query': 'पिक रोग उपचार', 'emoji': '🌱'},
        {'label': 'मंडी', 'query': 'मंडी भाव शेती', 'emoji': '💰'},
        {'label': 'सिंचन', 'query': 'ठिबक सिंचन शेती', 'emoji': '💧'},
        {'label': 'सेंद्रिय', 'query': 'सेंद्रिय शेती', 'emoji': '🍃'},
        {'label': 'योजना', 'query': 'PM Kisan शेतकरी योजना', 'emoji': '🏛️'},
        {'label': 'तंत्रज्ञान', 'query': 'आधुनिक शेती तंत्र', 'emoji': '🤖'},
      ];
    case 'hi':
      return const [
        {'label': 'ट्रेंडिंग', 'query': 'खेती सुझाव भारत', 'emoji': '🔥'},
        {'label': 'फसल देखभाल', 'query': 'फसल रोग इलाज', 'emoji': '🌱'},
        {'label': 'मंडी', 'query': 'मंडी भाव खेती', 'emoji': '💰'},
        {'label': 'सिंचाई', 'query': 'ड्रिप सिंचाई खेती', 'emoji': '💧'},
        {'label': 'जैविक', 'query': 'जैविक खेती', 'emoji': '🍃'},
        {'label': 'योजना', 'query': 'PM Kisan किसान योजना', 'emoji': '🏛️'},
        {'label': 'तकनीक', 'query': 'आधुनिक खेती तकनीक', 'emoji': '🤖'},
      ];
    default:
      return const [
        {'label': 'Trending', 'query': 'best farming tips india', 'emoji': '🔥'},
        {'label': 'Crop Care', 'query': 'crop disease treatment india', 'emoji': '🌱'},
        {'label': 'Mandi Tips', 'query': 'mandi prices india farming', 'emoji': '💰'},
        {'label': 'Irrigation', 'query': 'drip irrigation farming india', 'emoji': '💧'},
        {'label': 'Organic', 'query': 'organic farming india', 'emoji': '🍃'},
        {'label': 'Schemes', 'query': 'PM kisan yojana farming scheme', 'emoji': '🏛️'},
        {'label': 'Technology', 'query': 'modern farming technology india', 'emoji': '🤖'},
      ];
  }
}

List<String> popularSearchSuggestionsFor(AppLanguage lang) {
  switch (lang.code) {
    case 'mr':
      return const [
        'टोमॅटो लागवड', 'कांदा शेती', 'ठिबक सिंचन', 'सेंद्रिय शेती',
        'PM Kisan', 'गहू रोग', 'सोयाबीन', 'कापूस शेती',
      ];
    case 'hi':
      return const [
        'टमाटर की खेती', 'प्याज की खेती', 'ड्रिप सिंचाई', 'जैविक खेती',
        'PM Kisan', 'गेहूं रोग', 'सोयाबीन', 'कपास की खेती',
      ];
    default:
      return const [
        'Tomato farming', 'Onion farming', 'Drip irrigation', 'Organic farming',
        'PM Kisan', 'Wheat disease', 'Soybean', 'Cotton farming',
      ];
  }
}

/// Backward-compatible alias — prefer [farmingCategoriesFor] with locale.
List<Map<String, String>> get kFarmingCategories => farmingCategoriesFor(const AppLanguage('en'));

final _youtubeDio = Dio(BaseOptions(
  baseUrl: _kYouTubeBase,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 15),
));

List<Map<String, dynamic>> _curatedForLocale(YoutubeLocaleContext ctx) {
  final code = ctx.language.code;
  final langVideos = kCuratedVideos.where((v) => v['lang'] == code).toList();
  final pool = langVideos.isNotEmpty ? langVideos : kCuratedVideos;

  return pool.map((v) {
    final mapped = Map<String, dynamic>.from(v);
    if (code == 'hi' && v['titleHi'] != null) {
      mapped['title'] = v['titleHi'];
    } else if (code == 'mr' && v['titleMr'] != null) {
      mapped['title'] = v['titleMr'];
    }
    return mapped;
  }).toList();
}

String _buildSearchQuery(YoutubeLocaleContext ctx, String baseQuery) {
  final loc = ctx.language.youtubeLocationSuffix(
    district: ctx.district,
    state: ctx.state,
    village: ctx.village,
  );
  return '$baseQuery $loc'.trim();
}

Future<List<Map<String, dynamic>>> _searchYoutube(
  YoutubeLocaleContext ctx,
  String query, {
  int maxResults = 16,
}) async {
  final resp = await _youtubeDio.get('/search', queryParameters: {
    'part': 'snippet',
    'q': _buildSearchQuery(ctx, query),
    'type': 'video',
    'maxResults': maxResults,
    'relevanceLanguage': ctx.language.youtubeLang,
    'regionCode': 'IN',
    'key': _kYouTubeApiKey,
  });
  return _parseSearchResponse(resp.data);
}

final youtubeTrendingProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final ctx = ref.watch(youtubeLocaleProvider);

  if (!_hasApiKey) return _curatedForLocale(ctx);

  try {
    final query = ctx.language.youtubeTrendingQuery(
      district: ctx.district,
      state: ctx.state,
    );
    return await _searchYoutube(ctx, query, maxResults: 12);
  } catch (_) {
    return _curatedForLocale(ctx);
  }
});

final youtubeSearchQueryProvider = StateProvider<String>((ref) => '');

final youtubeSearchProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];

  await Future.delayed(const Duration(milliseconds: 400));
  if (ref.read(youtubeSearchQueryProvider) != query) return [];

  final ctx = ref.read(youtubeLocaleProvider);

  if (!_hasApiKey) {
    final q = query.toLowerCase();
    return _curatedForLocale(ctx)
        .where((v) =>
            v['title'].toString().toLowerCase().contains(q) ||
            v['channel'].toString().toLowerCase().contains(q) ||
            v['category'].toString().toLowerCase().contains(q))
        .toList();
  }

  try {
    return await _searchYoutube(ctx, query, maxResults: 20);
  } catch (_) {
    final q = query.toLowerCase();
    return _curatedForLocale(ctx)
        .where((v) =>
            v['title'].toString().toLowerCase().contains(q) ||
            v['category'].toString().toLowerCase().contains(q))
        .toList();
  }
});

final youtubeCategoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  final ctx = ref.watch(youtubeLocaleProvider);

  if (!_hasApiKey) return _curatedForLocale(ctx);

  try {
    return await _searchYoutube(ctx, query, maxResults: 16);
  } catch (_) {
    return _curatedForLocale(ctx);
  }
});

List<Map<String, dynamic>> _parseSearchResponse(dynamic data) {
  if (data == null || data['items'] == null) return [];
  final items = data['items'] as List;
  return items.map((item) {
    final snippet = item['snippet'] as Map? ?? {};
    final id = item['id'];
    final videoId =
        id is Map ? (id['videoId']?.toString() ?? '') : id.toString();
    final thumbnails = snippet['thumbnails'] as Map? ?? {};
    final thumb = (thumbnails['medium'] ?? thumbnails['default']) as Map? ?? {};
    return <String, dynamic>{
      'videoId': videoId,
      'title': snippet['title']?.toString() ?? 'Farming Video',
      'channel': snippet['channelTitle']?.toString() ?? 'AgriChannel',
      'thumbnail': thumb['url']?.toString() ??
          'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
      'duration': '',
      'publishedAt': snippet['publishedAt']?.toString() ?? '',
      'description': snippet['description']?.toString() ?? '',
    };
  }).toList();
}
