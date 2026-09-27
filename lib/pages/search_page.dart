import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:muteng_app_ios/api/api_client.dart';
import 'package:muteng_app_ios/app_theme.dart';
import 'package:muteng_app_ios/models/movie.dart';
import 'package:muteng_app_ios/storage/local_storage.dart';
import 'player_page.dart';

/// 搜索页：输入 + 片类型 Tab + 数据源 Tab + 热门推荐 + 搜索历史 + 结果列表
class SearchPage extends StatefulWidget {
  final String? initialKeyword;

  const SearchPage({super.key, this.initialKeyword});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const _hotTags = [
    '流浪地球3', '封神第二部', '灌篮高手',
    '三体', '热辣滚烫', '第二十条',
    '周处除三害', '沙丘2', '奥本海默',
  ];

  final ApiClient _api = ApiClient();
  final TextEditingController _ctrl = TextEditingController();

  // 片类型 Tab（本地过滤）
  static const _contentTabs = [
    {'name': '全部', 'keywords': <String>[]},
    {'name': '正片', 'keywords': <String>[]},
    {'name': '短剧', 'keywords': ['短剧']},
    {'name': '影视解说', 'keywords': ['解说', '解说员']},
  ];
  int _activeContentIdx = 0;

  // 数据源 Tab
  final List<Map<String, String?>> _sourceTabs = [];
  int _activeSourceIdx = 0;

  String _error = '';
  bool _hasSearched = false;
  bool _loading = false;
  List<Movie> _results = [];
  List<String> _histList = [];

  @override
  void initState() {
    super.initState();
    _histList = LocalStorage.getHistList();
    final kw = widget.initialKeyword;
    if (kw != null && kw.isNotEmpty) {
      _ctrl.text = kw;
      _doSearch();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Movie> get _filteredResults {
    var list = _results;
    final tab = _contentTabs[_activeContentIdx];
    if (tab['name'] == '正片') {
      list = list.where((r) => !RegExp(r'短剧|解说').hasMatch('${r.type_name} ${r.vod_class}')).toList();
    } else if (tab['keywords']!.isNotEmpty) {
      final kws = tab['keywords']!;
      list = list
          .where((r) {
            final hay = '${r.type_name} ${r.vod_class} ${r.title}';
            return kws.any((kw) => hay.contains(kw));
          })
          .toList();
    }
    if (_activeSourceIdx != 0 && _activeSourceIdx < _sourceTabs.length) {
      final code = _sourceTabs[_activeSourceIdx]['name']!;
      list = list.where((r) => r.sourceKey == code).toList();
    }
    return list;
  }

  Future<void> _doSearch() async {
    final kw = _ctrl.text.trim();
    if (kw.isEmpty || _loading) return;

    // 记录搜索历史
    if (!_histList.contains(kw)) {
      _histList = [kw, ..._histList];
      if (_histList.length > 10) _histList = _histList.sublist(0, 10);
      LocalStorage.setHistList(_histList);
    }

    setState(() {
      _hasSearched = true;
      _loading = true;
      _error = '';
    });

    try {
      final params = <String, String>{'wd': kw, 'source': 'aggregated'};
      final kws = _contentTabs[_activeContentIdx]['keywords']!;
      if (kws.isNotEmpty) params['typeFilter'] = kws.join(',');
      final res = await _api.get('/api/search', params: params);
      final raw = ((res['list'] ?? []) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _results = raw.map(Movie.fromJson).toList();
        _buildSourceTabs(raw);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _sourceTabs.clear();
        _activeSourceIdx = 0;
        _loading = false;
        _error = '搜索失败，请稍后重试';
      });
    }
  }

  void _buildSourceTabs(List<Map<String, dynamic>> raw) {
    final map = <String, String>{};
    for (final item in raw) {
      final code = item['source_code']?.toString() ?? '';
      final name = item['source_name']?.toString() ?? '';
      if (code.isNotEmpty && !map.containsKey(code)) map[code] = name;
    }
    _sourceTabs.clear();
    _sourceTabs.add({'name': '全部'});
    map.forEach((code, name) => _sourceTabs.add({'name': code, 'label': name}));
  }

  void _switchContent(int i) {
    setState(() => _activeContentIdx = i);
    if (_ctrl.text.trim().isNotEmpty) _doSearch();
  }

  void _clearKeyword() {
    _ctrl.clear();
    setState(() {
      _hasSearched = false;
      _results = [];
      _sourceTabs.clear();
      _activeSourceIdx = 0;
      _error = '';
    });
  }

  void _quickSearch(String name) {
    _ctrl.text = name;
    _doSearch();
  }

  void _refreshHot() {
    final shuffled = List.of(_histHotCache);
    shuffled.shuffle();
    setState(() {});
  }

  static List<String> _histHotCache = _hotTags;

  void _clearHist() {
    LocalStorage.clearHistList();
    setState(() => _histList = []);
  }

  void _goPlayer(Movie m) {
    final d = jsonEncode({
      'id': m.vodId.isNotEmpty ? m.vodId : m.id,
      'title': m.title,
      'poster': m.poster,
      'sourceKey': m.sourceKey,
      'sourceName': m.sourceName,
      'sourceUrl': m.sourceUrl,
      'isTv': m.isTv,
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerPage(d: d),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          // ── 顶部搜索栏 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: '搜索电影、电视剧…',
                              hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _doSearch(),
                          ),
                        ),
                        if (_ctrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textTertiary),
                            onPressed: _clearKeyword,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _doSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
                    ),
                    child: const Text('搜索',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),

          // ── 结果区 ──
          Expanded(
            child: _hasSearched || _loading
                ? _buildResults()
                : _buildPreSearch(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // 片类型 Tab
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _contentTabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final on = i == _activeContentIdx;
              return GestureDetector(
                onTap: () => _switchContent(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: on ? const Color(0x1F3B82F6) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: on ? const Color(0x403B82F6) : AppColors.border),
                  ),
                  child: Text(
                    _contentTabs[i]['name'],
                    style: TextStyle(
                      fontSize: 12,
                      color: on ? const Color(0xFF2563EB) : AppColors.textSecondary,
                      fontWeight: on ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 数据源 Tab（多于 1 个时展示）
        if (_sourceTabs.length > 1)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _sourceTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final on = i == _activeSourceIdx;
                final label = i == 0 ? '全部' : (_sourceTabs[i]['label'] ?? _sourceTabs[i]['name']);
                return GestureDetector(
                  onTap: () => setState(() => _activeSourceIdx = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: on ? const Color(0x1F3B82F6) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: on ? const Color(0x403B82F6) : AppColors.border),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: on ? const Color(0xFF2563EB) : AppColors.textSecondary,
                        fontWeight: on ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // 结果统计 / 加载态
        if (!_loading)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text('找到 ${_filteredResults.length} 部影片',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: Text('正在搜索…', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
          )
        else if (_filteredResults.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const Text('😢', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text('没有找到相关影片', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(_error.isNotEmpty ? _error : '换个关键词试试吧',
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _filteredResults)
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 36) / 2,
                  child: _ResultCard(movie: m, onTap: () => _goPlayer(m)),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildPreSearch() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        // 热门推荐
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Row(
            children: [
              Text('🔥 热门搜索', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Spacer(),
              Text('换一批', style: TextStyle(fontSize: 12, color: AppColors.primary)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _histHotCache)
                GestureDetector(
                  onTap: () => _quickSearch(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(t, style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                  ),
                ),
            ],
          ),
        ),

        // 搜索历史
        if (_histList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Row(
              children: [
                const Text('📜 搜索历史',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                GestureDetector(
                  onTap: _clearHist,
                  child: const Text('清除', style: TextStyle(fontSize: 12, color: AppColors.dangerRed)),
                ),
              ],
            ),
          ),
        if (_histList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in _histList)
                  GestureDetector(
                    onTap: () => _quickSearch(h),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(h, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 搜索结果卡片
class _ResultCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _ResultCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: movie.poster.isNotEmpty
                  ? Image.network(movie.poster,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox(height: 130, child: ColoredBox(color: AppColors.border)))
                  : const SizedBox(
                      height: 130, width: double.infinity, child: ColoredBox(color: AppColors.border)),
            ),
            Padding(
              padding: const EdgeInsets.all(7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    movie.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(movie.score,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.scoreGold)),
                      const Text('分', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x143B82F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(movie.sourceName,
                            style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
