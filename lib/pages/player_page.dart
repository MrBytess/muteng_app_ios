import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:muteng_app_ios/api/api_client.dart';
import 'package:muteng_app_ios/app_theme.dart';
import 'package:muteng_app_ios/storage/local_storage.dart';
import 'package:video_player/video_player.dart';

/// 播放器页（对应 uni-app pages/player/player.vue）
/// 支持 d=JSON 字符串模式与直参模式
class PlayerPage extends StatefulWidget {
  final String? d;
  final String? id;
  final String? title;
  final String? poster;
  final String? sourceKey;
  final String? sourceName;
  final String? sourceUrl;
  final bool? isTv;

  const PlayerPage({
    Key? key,
    this.d,
    this.id,
    this.title,
    this.poster,
    this.sourceKey,
    this.sourceName,
    this.sourceUrl,
    this.isTv,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  // ── 影片信息 ──
  String movieTitle = '';
  String poster = '';
  String videoUrl = '';
  List<String> episodes = [];
  int activeEpisode = 0;
  int activeTab = 0;
  static const int _tabSize = 50; // 每个 Tab 最多 50 集

  bool detailLoading = false;
  String detailError = '';
  String description = '';
  List<String> metaTags = [];
  bool isFav = false;

  // 收藏用的稳定 id（source_code_vod_id）
  String favKey = '';
  String vodId = '';
  String sourceKey = '';
  String sourceName = '';
  String sourceUrl = '';
  bool isTv = false;

  // ── 视频播放器状态 ──
  VideoPlayerController? _videoController;
  double _duration = 0;
  double _currentDuration = 0;
  int _lastHistoryUpdate = 0;

  // ── 分集 chunks ──
  List<_EpisodeChunk> get _episodeChunks {
    final chunks = <_EpisodeChunk>[];
    for (var i = 0; i < episodes.length; i += _tabSize) {
      chunks.add(_EpisodeChunk(
        start: i,
        length: _tabSize.clamp(0, episodes.length - i),
      ));
    }
    return chunks;
  }

  List<int> get _activeChunkIndexes {
    final c = _episodeChunks[activeTab];
    if (c == null || c.start + c.length > episodes.length) return [];
    final arr = <int>[];
    for (var i = 0; i < c.length; i++) {
      arr.add(c.start + i);
    }
    return arr;
  }

  @override
  void initState() {
    super.initState();
    _parseParams();
    _checkFav();
    _recordHistory();
    _loadDetail();
  }

  void _parseParams() {
    final d = widget.d;
    if (d != null && d.isNotEmpty) {
      try {
        final map = jsonDecode(d) as Map<String, dynamic>;
        movieTitle = map['title']?.toString() ?? '';
        poster = map['poster']?.toString() ?? '';
        sourceKey = map['sourceKey']?.toString() ?? '';
        sourceName = map['sourceName']?.toString() ?? '';
        sourceUrl = map['sourceUrl']?.toString() ?? '';
        isTv = map['isTv'] == true || map['isTv'] == '1';
        vodId = map['id']?.toString() ?? '';
        // favKey：sourceKey_vodId，缺 sourceKey 时直接 vodId
        if (vodId.isNotEmpty) {
          favKey = sourceKey.isNotEmpty ? '${sourceKey}_$vodId' : vodId;
        }
      } catch (_) {
        // JSON 解析失败 → 回退到直参
        _fallbackParams();
      }
    } else {
      _fallbackParams();
    }
  }

  void _fallbackParams() {
    final id = widget.id?.trim() ?? '';
    movieTitle = widget.title ?? movieTitle;
    poster = widget.poster ?? poster;
    sourceKey = widget.sourceKey ?? sourceKey;
    sourceName = widget.sourceName ?? sourceName;
    sourceUrl = widget.sourceUrl ?? sourceUrl;
    isTv = widget.isTv ?? isTv;
    vodId = id;
    if (id.isNotEmpty) {
      favKey = sourceKey.isNotEmpty ? '${sourceKey}_$id' : id;
    }
  }

  Future<void> _checkFav() async {
    if (favKey.isEmpty) return;
    final collected = LocalStorage.getCollectList();
    if (collected.contains(favKey)) {
      if (mounted) setState(() => isFav = true);
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      detailLoading = true;
      detailError = '';
    });
    try {
      final res = await ApiClient().get('/api/detail', params: {
        'id': vodId,
        'source': sourceKey,
      });
      final map = res is Map ? mapFromJsonSafe(res) : <String, dynamic>{};
      final ep = map['episodes'];
      final epList = ep is List ? ep.map((e) => e.toString()).toList() : <String>[];
      if (epList.isNotEmpty) {
        setState(() {
          episodes = epList;
          videoUrl = epList[0];
          activeEpisode = 0;
          activeTab = 0;
        });
      } else {
        setState(() => detailError = '该影片暂无可用分集资源');
      }

      final info = map['videoInfo'] is Map ? mapFromJsonSafe(map['videoInfo']) : <String, dynamic>{};
      setState(() {
        if (info['title']?.toString().isNotEmpty == true) movieTitle = info['title'].toString();
        if (info['cover']?.toString().isNotEmpty == true) poster = info['cover'].toString();
        description = info['desc']?.toString() ?? '';
        metaTags = [
          info['type']?.toString(),
          info['year']?.toString(),
          info['area']?.toString(),
          info['source_name']?.toString(),
        ].where((v) => v != null && v.isNotEmpty).toList();
      });
    } catch (err) {
      if (mounted) {
        setState(() {
          detailError = err.toString().replaceFirst('Exception: ', '');
          episodes = [];
        });
      }
    } finally {
      if (mounted) setState(() => detailLoading = false);
    }
  }

  void _pickEpisode(int globalIndex) {
    if (globalIndex == activeEpisode ||
        globalIndex < 0 ||
        globalIndex >= episodes.length) return;
    setState(() {
      activeEpisode = globalIndex;
      final targetTab = globalIndex ~/ _tabSize;
      if (targetTab != activeTab) activeTab = targetTab;
      videoUrl = episodes[globalIndex];
    });
    _initVideo();
    _updateHisTitle();
  }

  void _switchTab(int ci) {
    if (ci == activeTab) return;
    setState(() => activeTab = ci);
  }

  Future<void> _initVideo() async {
    if (videoUrl.isEmpty) return;
    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      if (!mounted) return;
      _videoController!.setLooping(true);
      _videoController!.setVolume(1.0);
      await _videoController!.play();
      _videoController!.addListener(_onVideoEvent);
      setState(() {
        _duration = _videoController!.value.duration.inSeconds.toDouble();
        _currentDuration = 0;
      });
      _onPlay();
    } catch (e) {
      if (mounted) {
        setState(() => detailError = '视频加载失败：$e');
      }
    }
  }

  void _onVideoEvent() {
    final c = _videoController;
    if (c == null) return;
    final dur = c.value.duration.inSeconds.toDouble();
    if (dur != _duration) {
      setState(() => _duration = dur);
    }
    final cur = c.value.position.inMilliseconds / 1000.0;
    if (cur != _currentDuration) {
      setState(() => _currentDuration = cur);
      _onTimeUpdate(cur);
    }
  }

  void _onPlay() {
    if (vodId.isEmpty) return;
    final totalSeconds = _duration.round();
    final playedSeconds = _currentDuration.round();
    final progress = totalSeconds > 0
        ? ((playedSeconds * 100) ~/ totalSeconds).clamp(0, 100)
        : 0;

    final list = LocalStorage.getWatchHistList();
    final idx =
        list.indexWhere((h) => h['id']?.toString() == vodId);
    if (idx >= 0) {
      list[idx]['id'] = vodId;
      list[idx]['time'] = DateTime.now().millisecondsSinceEpoch;
      list[idx]['totalSeconds'] = totalSeconds;
      list[idx]['playedSeconds'] = playedSeconds;
      list[idx]['progress'] = progress;
      if (movieTitle.isNotEmpty) list[idx]['title'] = _hisTitle();
      if (poster.isNotEmpty) list[idx]['poster'] = poster;
      if (sourceName.isNotEmpty) list[idx]['sub'] = sourceName;
      if (sourceKey.isNotEmpty) list[idx]['sourceKey'] = sourceKey;
      LocalStorage.setWatchHistList(list);
    } else {
      final entry = <String, dynamic>{
        'id': vodId,
        'title': _hisTitle(),
        'poster': poster,
        'sub': sourceName,
        'sourceKey': sourceKey,
        'time': DateTime.now().millisecondsSinceEpoch,
        'totalSeconds': totalSeconds,
        'playedSeconds': playedSeconds,
        'progress': progress,
      };
      list.insert(0, entry);
      LocalStorage.setWatchHistList(list);
    }
  }

  void _onPause() {
    _updateHistory();
  }

  void _onTimeUpdate(double currentTime) {
    _currentDuration = currentTime;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHistoryUpdate < 5000) return;
    _lastHistoryUpdate = now;
    _updateHistory();
  }

  void _updateHistory() {
    if (vodId.isEmpty || _duration <= 0) return;
    final list = LocalStorage.getWatchHistList();
    final idx = list.indexWhere((h) => h['id']?.toString() == vodId);
    if (idx < 0) return;
    final totalSeconds = _duration.round();
    final playedSeconds = _currentDuration.round();
    final progress = totalSeconds > 0
        ? ((playedSeconds * 100) ~/ totalSeconds).clamp(0, 100)
        : 0;
    list[idx]['totalSeconds'] = totalSeconds;
    list[idx]['playedSeconds'] = playedSeconds;
    list[idx]['progress'] = progress;
    list[idx]['time'] = DateTime.now().millisecondsSinceEpoch;
    LocalStorage.setWatchHistList(list);
  }

  void _recordHistory() {
    if (vodId.isEmpty) return;
    final list = LocalStorage.getWatchHistList();
    final existIdx =
        list.indexWhere((h) => h['id']?.toString() == vodId);
    if (existIdx >= 0) {
      // 已存在则不新增
      return;
    }
    final entry = <String, dynamic>{
      'id': vodId,
      'title': _hisTitle(),
      'poster': poster,
      'sub': sourceName,
      'sourceKey': sourceKey,
      'time': DateTime.now().millisecondsSinceEpoch,
      'totalSeconds': 0,
      'playedSeconds': 0,
      'progress': 0,
    };
    list.insert(0, entry);
    LocalStorage.setWatchHistList(list);
  }

  String _hisTitle() {
    return isTv && episodes.length > 1
        ? '$movieTitle 第${activeEpisode + 1}集'
        : movieTitle;
  }

  void _updateHisTitle() {
    if (vodId.isEmpty || !isTv || episodes.length <= 1) return;
    final list = LocalStorage.getWatchHistList();
    final idx = list.indexWhere((h) => h['id']?.toString() == vodId);
    if (idx < 0) return;
    list[idx]['title'] = _hisTitle();
    LocalStorage.setWatchHistList(list);
  }

  void _toggleFav() {
    if (favKey.isEmpty) return;
    final list = LocalStorage.getCollectList();
    final details = LocalStorage.getCollectDetails();
    if (isFav) {
      list.removeWhere((k) => k == favKey);
      details.remove(favKey);
      if (mounted) setState(() => isFav = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已取消收藏')));
    } else {
      list.add(favKey);
      details[favKey] = {
        'key': favKey,
        'vodId': vodId,
        'title': movieTitle,
        'poster': poster,
        'sub': sourceName,
        'sourceKey': sourceKey,
        'sourceUrl': sourceUrl,
        'isTv': isTv,
        'time': DateTime.now().millisecondsSinceEpoch,
      };
      if (mounted) setState(() => isFav = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('收藏成功')));
    }
    LocalStorage.setCollectList(list);
    LocalStorage.setCollectDetails(details);
  }

  void _shareMovie() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('分享功能开发中')));
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoEvent);
    _videoController?.dispose();
    super.dispose();
  }

  // ── 工具方法 ──
  Map<String, dynamic> mapFromJsonSafe(dynamic raw) {
    try {
      return Map<String, dynamic>.from(raw as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Stack(
        children: [
          // ── 主内容 ──
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildVideoArea()),
              if (episodes.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildEpisodeSection()),
              ]
              if (detailLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (detailError.isNotEmpty)
                SliverToBoxAdapter(child: _buildError(detailError)),
              SliverToBoxAdapter(child: _buildInfoSection()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.black.withOpacity(0.5),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  movieTitle.isEmpty ? '播放器' : movieTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            // 占位保持居中
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    final c = _videoController;
    return AspectRatio(
      aspectRatio: c != null && c.value.size != null
          ? c.value.aspectRatio
          : 16 / 9,
      child: Stack(
        children: [
          // 视频或占位
          c != null && c.value.isInitialized
              ? VideoPlayer(c)
              : Container(
                  color: const Color(0xFF16233A),
                  child: Center(
                    child: poster.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: poster,
                              fit: BoxFit.contain,
                              placeholder: (ctx, url) =>
                                  const Center(child: CircularProgressIndicator()),
                              errorWidget: (ctx, url, err) => const Icon(
                                Icons.movie,
                                color: AppColors.textTertiary,
                                size: 48,
                              ),
                            ),
                          )
                        : const Icon(Icons.movie,
                            color: AppColors.textTertiary, size: 48),
                  ),
                ),
          // 底部进度条
          if (c != null && c.value.isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(
                value: _duration > 0 ? _currentDuration / _duration : 0,
                backgroundColor: Colors.white24,
                color: AppColors.primary,
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEpisodeSection() {
    final chunks = _episodeChunks;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '分集（${episodes.length}）',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          // Tab 行
          if (chunks.length > 1)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chunks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, ci) {
                  final c = chunks[ci];
                  final isOn = ci == activeTab;
                  return GestureDetector(
                    onTap: () => _switchTab(ci),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOn
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.white,
                        border: Border.all(
                          color: isOn
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        '第${c.start + 1}-${c.start + c.length}集',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isOn ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          // 当前 tab 的集 chips，每行 5 个
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              _activeChunkIndexes.length,
              (i) {
                final globalIdx = _activeChunkIndexes[i];
                final isOn = globalIdx == activeEpisode;
                return GestureDetector(
                  onTap: () => _pickEpisode(globalIdx),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 32) / 5 - 5,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isOn
                          ? AppColors.primary.withOpacity(0.12)
                          : Colors.white,
                      border: Border.all(
                        color: isOn
                            ? AppColors.primary.withOpacity(0.25)
                            : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '第${globalIdx + 1}集',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isOn ? FontWeight.w600 : FontWeight.normal,
                        color: isOn ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题 + 操作按钮
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  movieTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ActBtn(
                label: isFav ? '★ 已收藏' : '☆ 收藏',
                isFav: isFav,
                onTap: _toggleFav,
              ),
              const SizedBox(width: 8),
              _ActBtn(label: '分享', onTap: _shareMovie),
            ],
          ),
          // metaTags
          if (metaTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metaTags
                  .map((t) => Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          t,
                          style:
                              const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ))
                  .toList(),
            ),
          ],
          // 剧情简介
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '剧情简介',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          msg,
          style: const TextStyle(fontSize: 14, color: AppColors.dangerRed),
        ),
      ),
    );
  }
}

class _EpisodeChunk {
  final int start;
  final int length;
  _EpisodeChunk({required this.start, required this.length});
}

class _ActBtn extends StatelessWidget {
  final String label;
  final bool isFav;
  final VoidCallback? onTap;

  const _ActBtn({
    Key? key,
    required this.label,
    this.isFav = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFavBtn = isFav || label.contains('收藏');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isFavBtn
              ? AppColors.scoreGold.withOpacity(0.08)
              : Colors.white,
          border: Border.all(
            color: isFavBtn
                ? AppColors.scoreGold.withOpacity(0.3)
                : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isFavBtn ? AppColors.scoreGold : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
