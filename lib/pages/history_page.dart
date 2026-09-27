import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muteng_app_ios/app_theme.dart';
import 'package:muteng_app_ios/models/history_item.dart';
import 'package:muteng_app_ios/storage/local_storage.dart';
import 'player_page.dart';

/// 播放历史页：按时间分组 + 进度条 + 时长展示
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryItem> _list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _list = LocalStorage.getWatchHistList().map(HistoryItem.fromJson).toList();
  }

  List<_Group> get _grouped {
    if (_list.isEmpty) return [];
    final now = DateTime.now().millisecondsSinceEpoch;
    const day = 86400000;
    final defs = [
      {'label': '今天', 'min': now - day, 'max': null as int?},
      {'label': '昨天', 'min': now - day * 2, 'max': now - day},
      {'label': '最近7天', 'min': now - day * 7, 'max': now - day * 2},
      {'label': '最近30天', 'min': now - day * 30, 'max': now - day * 7},
    ];
    final groups = defs.map((g) {
      final min = g['min'] as int;
      final max = g['max'] as int?;
      final items = _list.where((h) => h.time >= min && (max == null || h.time < max)).toList();
      return _Group(label: g['label']!, items: items);
    }).where((g) => g.items.isNotEmpty).toList();
    return groups;
  }

  String _formatTime(int ts) {
    if (ts == 0) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ts));
  }

  String _formatDur(int seconds) {
    if (seconds == 0) return '00:00';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String pad(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${pad(m)}:${pad(s)}' : '${pad(m)}:${pad(s)}';
  }

  void _goPlayer(HistoryItem item) {
    final d = jsonEncode({
      'id': item.id,
      'title': item.title,
      'poster': item.poster,
      'sourceKey': item.sourceKey,
      'isTv': false,
    });
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerPage(d: d)));
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除历史'),
        content: const Text('确定清除所有观看历史？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定', style: TextStyle(color: AppColors.dangerRed)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    LocalStorage.clearWatchHistList();
    setState(() => _list = []);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          // ── 顶部 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            child: Row(
              children: [
                const Text('🕒 观看历史',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const Spacer(),
                if (_list.isNotEmpty)
                  GestureDetector(
                    onTap: _clearAll,
                    child: const Text('全部清除', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                  ),
              ],
            ),
          ),

          if (groups.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎬', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 12),
                    Text('还没有观看记录', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                    SizedBox(height: 6),
                    Text('去首页找部影片看看吧', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: groups.length,
                itemBuilder: (context, gi) {
                  final g = groups[gi];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                        child: Row(
                          children: [
                            Text(g.label,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text('${g.items.length}部',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                      _GroupCards(items: g.items, onPlay: _goPlayer, formatTime: _formatTime, formatDur: _formatDur),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Group {
  final String label;
  final List<HistoryItem> items;
  _Group({required this.label, required this.items});
}

/// 一组历史卡片（两列）
class _GroupCards extends StatelessWidget {
  final List<HistoryItem> items;
  final void Function(HistoryItem) onPlay;
  final String Function(int) formatTime;
  final String Function(int) formatDur;

  const _GroupCards(
      {required this.items,
      required this.onPlay,
      required this.formatTime,
      required this.formatDur});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 24) / 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: _HistCard(item: item, onPlay: () => onPlay(item), formatTime: formatTime, formatDur: formatDur),
            ),
        ],
      ),
    );
  }
}

class _HistCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onPlay;
  final String Function(int) formatTime;
  final String Function(int) formatDur;

  const _HistCard({
    required this.item,
    required this.onPlay,
    required this.formatTime,
    required this.formatDur,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
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
            // 海报 + 进度条
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: item.poster.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.poster,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ColoredBox(color: AppColors.border, child: SizedBox.expand()),
                          errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.border, child: SizedBox.expand()),
                        )
                      : const ColoredBox(color: AppColors.border, child: SizedBox(height: 120, width: double.infinity)),
                ),
                // 进度条
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    child: SizedBox(
                      height: 4,
                      child: Stack(
                        children: [
                          const Positioned.fill(child: ColoredBox(color: Color(0x263B82F6))),
                          FractionalSizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: item.progress / 100.0,
                            child: ColoredBox(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(formatTime(item.time),
                          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                      const Spacer(),
                      Text('${item.progress}%',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${formatDur(item.playedSeconds)} / ${formatDur(item.totalSeconds)}',
                    style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
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
