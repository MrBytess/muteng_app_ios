import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储封装
class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── 搜索历史 ──
  static List<String> getHistList() {
    final raw = _prefs?.getString('histList');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      return List<String>.from(list);
    } catch (_) {
      return [];
    }
  }

  static void setHistList(List<String> list) {
    _prefs?.setString('histList', jsonEncode(list));
  }

  static void clearHistList() {
    _prefs?.remove('histList');
  }

  // ── 观看历史 ──
  static List<Map<String, dynamic>> getWatchHistList() {
    final raw = _prefs?.getString('watchHistList');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      return List<Map<String, dynamic>>.from(list);
    } catch (_) {
      return [];
    }
  }

  static void setWatchHistList(List<Map<String, dynamic>> list) {
    _prefs?.setString('watchHistList', jsonEncode(list));
  }

  static void clearWatchHistList() {
    _prefs?.remove('watchHistList');
  }

  // ── 收藏 ──
  static List<String> getCollectList() {
    final raw = _prefs?.getString('collectList');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      return List<String>.from(list);
    } catch (_) {
      return [];
    }
  }

  static void setCollectList(List<String> list) {
    _prefs?.setString('collectList', jsonEncode(list));
  }

  static Map<String, dynamic> getCollectDetails() {
    final raw = _prefs?.getString('collectDetails');
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw);
      return Map<String, dynamic>.from(map);
    } catch (_) {
      return {};
    }
  }

  static void setCollectDetails(Map<String, dynamic> details) {
    _prefs?.setString('collectDetails', jsonEncode(details));
  }

  static void clearCollectList() {
    _prefs?.remove('collectList');
    _prefs?.remove('collectDetails');
  }

  // ── 下载列表 ──
  static List<String> getDownloadList() {
    final raw = _prefs?.getString('downloadList');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      return List<String>.from(list);
    } catch (_) {
      return [];
    }
  }
}
