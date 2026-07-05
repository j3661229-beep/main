import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _favoritesKey = 'farm_tool_favorites';
const _recentKey = 'farm_tool_recent';

class FarmToolsPrefsNotifier extends StateNotifier<({List<String> favorites, List<String> recent})> {
  FarmToolsPrefsNotifier() : super((favorites: [], recent: [])) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (
      favorites: prefs.getStringList(_favoritesKey) ?? [],
      recent: prefs.getStringList(_recentKey) ?? [],
    );
  }

  Future<void> toggleFavorite(String route) async {
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(state.favorites);
    if (list.contains(route)) {
      list.remove(route);
    } else {
      list.add(route);
    }
    await prefs.setStringList(_favoritesKey, list);
    state = (favorites: list, recent: state.recent);
  }

  Future<void> markRecent(String route) async {
    final prefs = await SharedPreferences.getInstance();
    final list = [route, ...state.recent.where((r) => r != route)].take(6).toList();
    await prefs.setStringList(_recentKey, list);
    state = (favorites: state.favorites, recent: list);
  }

  bool isFavorite(String route) => state.favorites.contains(route);
}

final farmToolsPrefsProvider =
    StateNotifierProvider<FarmToolsPrefsNotifier, ({List<String> favorites, List<String> recent})>(
  (ref) => FarmToolsPrefsNotifier(),
);
