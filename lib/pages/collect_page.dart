import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muteng_app_ios/app_theme.dart';
import 'package:muteng_app_ios/models/collect_item.dart';
import 'package:muteng_app_ios/storage/local_storage.dart';
import 'player_page.dart';

/// 收藏页：收藏列表 + 取消收藏 + 跳转播放
class CollectPage extends StatefulWidget {
  const CollectPage({super.key});

  @override
  State<CollectPage> createState() => _CollectPageState();
}

class _CollectPageState extends State<CollectPage> {
  List<CollectItem> _list = [];

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  void _loadList() {
    final raw = LocalStorage.getCollectList();
    final details = LocalStorage.getCollectDetails();
    _list = raw.map((key) {
      final d = details[key];
      if (d != null) return CollectItem.fromJson({...d, 'key': key});
      // 兜底：只有 key，没有详情
      final parts = key.split('_');
      return CollectItem(key: key, title: parts.length > 1 ? parts[1] : key);
    }).toList()
      ..reverse();
  }

  Future<void> _removeCollect(CollectItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: Text('确定取消收藏「${item.title}」？'),
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

    final raw = LocalStorage.getCollectList().where((k) => k != item.key).toList();
    LocalStorage.setCollectList(raw);
    final details = LocalStorage.getCollectDetails()..remove(item.key);
    LocalStorage.setCollectDetails(details);
    _loadList();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已取消收藏')));
    }
  }

  void _goPlayer(CollectItem item) {
    final d = jsonEncode({
      'id': item.vodId.isNotEmpty ? item.vodId : item.key,
      'title': item.title,
      'poster': item.poster,
      'sourceKey': item.sourceKey,
      'sourceName': item.sub,
      'sourceUrl': item.sourceUrl,
      'isTv': item.isTv,
    });
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerPage(d: d)));
  }

  String _formatTime(int ts) {
    if (ts == 0) return '';
    return DateFormat('MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ts));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      body: _list.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⭐', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 12),
                  Text('还没有收藏内容', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  SizedBox(height: 6),
                  Text('在播放页点击收藏即可', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                  child: Row(
                    children: [
                      const Text('⭐ 我的收藏',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const Spacer(),
                      Text('${_list.length}部', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _list.length,
                    itemBuilder: (context, i) {
                      final item = _list[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CollectCard(
                          item: item,
                          time: _formatTime(item.time),
                          onPlay: () => _goPlayer(item),
                          onRemove: () => _removeCollect(item),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _CollectCard extends StatelessWidget {
  final CollectItem item;
  final String time;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  const _CollectCard({
    required this.item,
    required this.time,
    required this.onPlay,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
      ),
      child: Row(
        children: [
          // 海报 + 删除按钮
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: item.poster.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.poster,
                        width: 72,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const ColoredBox(color: AppColors.border, child: SizedBox.expand()),
                        errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.border, child: SizedBox.expand()),
                      )
                    : const ColoredBox(color: AppColors.border, child: SizedBox(width: 72, height: 100)),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // 信息区
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                if (item.sub.isNotEmpty)
                  const SizedBox(height: 4),
                if (item.sub.isNotEmpty)
                  Text(
                    item.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onPlay,
                      child: const Text('▶ 播放',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9))),
                    ),
                    const Spacer(),
                    if (time.isNotEmpty)
                      Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
