import 'package:flutter/material.dart';
import 'package:muteng_app_ios/api/api_client.dart';
import 'package:muteng_app_ios/app_theme.dart';
import 'package:muteng_app_ios/models/banner_item.dart';
import 'package:muteng_app_ios/models/movie.dart';
import 'search_page.dart';

/// 首页（竖屏）：Logo + 搜索框 + 一级分类 Tabs + Banner + 排序 + 影片网格
class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  static const _tabs = [
    {'name': '热门', 'tags': '', 'type': 'movie'},
    {'name': '电影', 'tags': '电影', 'type': 'movie'},
    {'name': '电视剧', 'tags': '电视剧', 'type': 'tv'},
    {'name': '综艺', 'tags': '综艺', 'type': 'movie'},
    {'name': '动漫', 'tags': '动画', 'type': 'movie'},
  ];
  static const _sortList = ['热度', '最新', '评分'];
  static const _sortParams = ['recommend', 'time', 'rank'];

  final ApiClient _api = ApiClient();
  int _activeCategory = 0;
  int _activeSubCategory = 0;
  int _sortMode = 0;

  // 每个 tab 的豆瓣子分类
  final Map<int, List<String>> _subMap = {};
  bool _loading = false;
  List<Movie> _movies = [];
  List<BannerItem> _banners = [];
  late PageController _bannerCtrl;
  int _bannerIdx = 0;

  @override
  void initState() {
    super.initState();
    _bannerCtrl = PageController();
    _loadBanners();
    _loadSubTags();
    _loadMovies();
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    super.dispose();
  }

  List<String> get _subList => _subMap[_activeCategory] ?? ['全部'];

  String get _contentTitle {
    final sub = _subList[_activeSubCategory];
    return sub != '全部' ? sub : _tabs[_activeCategory]['name'];
  }

  Future<void> _loadBanners() async {
    try {
      final res = await _api.get('/douban/search', params: {
        'type': 'movie',
        'tag': '热门',
        'sort': 'recommend',
        'page_limit': '5',
        'page_start': '0',
      });
      final list = (res['subjects'] ?? res['items'] ?? []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _banners = list.take(5).map((it) {
            return BannerItem(
              id: it['id']?.toString() ?? '',
              title: it['title']?.toString() ?? '',
              image: _proxyImage(it['cover']?.toString() ?? '', it['url']?.toString() ?? ''),
              rating: (it['rate'] ?? it['rating'])?.toString() ?? '',
              tag: '热播',
            );
          }).toList();
        });
      }
    } catch (_) {
      // banner 加载失败保持空
    }
  }

  String _proxyImage(String cover, String url) {
    if (cover.isEmpty) return '';
    return '${ApiClient.baseUrl}/proxy/image-proxy?url=${Uri.encodeComponent(cover)}&referer=${Uri.encodeComponent(url)}';
  }

  Future<void> _loadSubTags() async {
    for (var i = 0; i < _tabs.length; i++) {
      try {
        final res = await _api.get('/douban/tags', params: {'type': _tabs[i]['type']});
        final tags = ((res['tags'] ?? []) as List)
            .cast<String>()
            .where((s) => s != '全部' && s != '热门')
            .take(12)
            .toList();
        if (mounted) setState(() => _subMap[i] = ['全部', ...tags]);
      } catch (_) {
        if (mounted) setState(() => _subMap[i] = ['全部']);
      }
    }
  }

  Future<void> _loadMovies() async {
    final tab = _tabs[_activeCategory];
    final sub = _subList[_activeSubCategory];
    setState(() => _loading = true);
    try {
      final res = await _api.get('/douban/search', params: {
        'type': tab['type'],
        'tag': sub != '全部' ? sub : (tab['tags']?.isNotEmpty ?? false) ? tab['tags'] : '热门',
        'sort': _sortParams[_sortMode],
        'page_limit': '10',
        'page_start': '0',
      });
      final items = (res['subjects'] ?? res['items'] ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _movies = items.map(Movie.fromDouban).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _movies = [];
        _loading = false;
      });
    }
  }

  void _switchCategory(int i) {
    if (i == _activeCategory) return;
    setState(() {
      _activeCategory = i;
      _activeSubCategory = 0;
    });
    _loadMovies();
  }

  void _switchSub(int i) {
    if (i == _activeSubCategory) return;
    setState(() => _activeSubCategory = i);
    _loadMovies();
  }

  void _switchSort(int i) {
    if (i == _sortMode) return;
    setState(() => _sortMode = i);
    _loadMovies();
  }

  void _goToSearch(String kw) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchPage(initialKeyword: kw),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: ListView(
        children: [
          // ── 顶部 Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                const Text(
                  '木藤',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 4),
                const Text(
                  '影视',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const Spacer(),
                // 搜索框
                GestureDetector(
                  onTap: () => _goToSearch(''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 16, color: AppColors.textTertiary),
                        SizedBox(width: 6),
                        Text('电影、电视剧、综艺…',
                            style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 一级分类 Tabs（下划线风格） ──
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, i) {
                final on = i == _activeCategory;
                return GestureDetector(
                  onTap: () => _switchCategory(i),
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _tabs[i]['name'],
                          style: TextStyle(
                            fontSize: on ? 17 : 14,
                            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                            color: on ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: on ? 28 : 0,
                          height: on ? 2 : 0,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Banner 轮播 ──
          if (_banners.isNotEmpty)
            PageView.builder(
              controller: _bannerCtrl,
              itemCount: _banners.length,
              onPageChanged: (i) => setState(() => _bannerIdx = i),
              itemBuilder: (context, i) {
                final b = _banners[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 170,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          b.image.isNotEmpty
                              ? Image.network(b.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => ColoredBox(color: AppColors.border))
                              : const ColoredBox(color: AppColors.border),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.pageBg,
                                  Color(0x80F0F4FA),
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.4, 0.7],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(b.tag,
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  b.title,
                                  style: const TextStyle(
                                      fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                                if (b.rating.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(b.rating,
                                        style: const TextStyle(fontSize: 12, color: AppColors.scoreGold)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // ── Banner 指示点 ──
          if (_banners.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (i) {
                  final on = i == _bannerIdx;
                  return Container(
                    width: on ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: on ? AppColors.primary : const Color(0x403B82F6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

          // ── 子分类 Pills ──
          if (_subList.length > 1)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _subList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, i) {
                  final on = i == _activeSubCategory;
                  return GestureDetector(
                    onTap: () => _switchSub(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: on ? const Color(0x1F3B82F6) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: on ? const Color(0x403B82F6) : AppColors.border),
                      ),
                      child: Text(
                        _subList[i],
                        style: TextStyle(
                          fontSize: 11,
                          color: on ? const Color(0xFF2563EB) : AppColors.textSecondary,
                          fontWeight: on ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── 内容标题 + 排序 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  _contentTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const Spacer(),
                for (var i = 0; i < _sortList.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () => _switchSort(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: i == _sortMode ? AppColors.primary : const Color(0xFFE6EEFB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _sortList[i],
                          style: TextStyle(
                            fontSize: 11,
                            color: i == _sortMode ? Colors.white : const Color(0xFF8AA2C0),
                            fontWeight: i == _sortMode ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── 影片网格 / 加载态 / 空态 ──
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Text('⏳', style: TextStyle(fontSize: 36)),
                  SizedBox(height: 12),
                  Text('正在加载影片…', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                ],
              ),
            )
          else if (_movies.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Text('🎬', style: TextStyle(fontSize: 36)),
                  SizedBox(height: 12),
                  Text('暂无相关影片', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in _movies)
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 24) / 2,
                      child: _MovieCard(movie: m, onTap: () => _goToSearch(m.title)),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// 影片卡片（海报 + 评分角标 + 标题 + subtitle）
class _MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _MovieCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: movie.poster.isNotEmpty
                    ? Image.network(movie.poster,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(height: 150, width: double.infinity, child: ColoredBox(color: AppColors.border)))
                    : const SizedBox(
                        height: 150, width: double.infinity, child: ColoredBox(color: AppColors.border)),
              ),
              if (movie.score.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xEEFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(color: AppColors.scoreGold, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          movie.score,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.scoreGold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              movie.sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
