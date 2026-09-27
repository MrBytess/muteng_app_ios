import 'package:flutter/material.dart';
import 'package:muteng_app_ios/api/api_client.dart';
import 'package:muteng_app_ios/app_theme.dart';
import 'package:muteng_app_ios/models/mp_item.dart';
import 'package:muteng_app_ios/pages/collect_page.dart';
import 'package:muteng_app_ios/storage/local_storage.dart';

/// 我的页：头像头部 + 快捷功能 + 小程序宿主（iOS 端简化为列表展示）
class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  final ApiClient _api = ApiClient();
  int _collectCount = 0;
  int _downloadCount = 0;
  List<MpItem> _mpList = [];
  bool _mpLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadMPList();
  }

  void _loadData() {
    _collectCount = LocalStorage.getCollectList().length;
    _downloadCount = LocalStorage.getDownloadList().length;
  }

  Future<void> _loadMPList() async {
    setState(() => _mpLoading = true);
    try {
      final res = await _api.get('/mp');
      final list = ((res['data'] ?? []) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _mpList = list.map(MpItem.fromJson).toList();
        _mpLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _mpLoading = false);
    }
  }

  void _goCollect() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CollectPage()));
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: const Text('确定要退出登录吗？将清除本地收藏、历史和缓存数据。'),
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
    LocalStorage.clearCollectList();
    LocalStorage.clearWatchHistList();
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已退出登录')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      body: Column(
        children: [
          // ── 蓝色头部 ──
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Row(
              children: [
                // 头像
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0x4DFFFFFF),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.movie, size: 32, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('木藤影视',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('本地存储，自由观看',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.qr_code, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),

          // ── 快捷功能 ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                _ScItem(
                  icon: Icons.star,
                  iconBg: const Color(0xFFF59E0B).withOpacity(0.1),
                  label: '收藏',
                  badge: _collectCount,
                  onTap: _goCollect,
                ),
                _ScItem(
                  icon: Icons.history,
                  iconBg: const Color(0xFF0EA5E9).withOpacity(0.1),
                  label: '历史',
                  onTap: () => ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('请切换到下方「历史」标签页查看'))),
                ),
                _ScItem(
                  icon: Icons.download,
                  iconBg: const Color(0xFF22C55E).withOpacity(0.1),
                  label: '缓存',
                  badge: _downloadCount,
                  green: true,
                  onTap: () => ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('下载功能开发中'))),
                ),
              ],
            ),
          ),

          // ── 小程序区域 ──
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 12),
            child: const Text('其他入口',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          if (_mpLoading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Text('加载中…', style: TextStyle(fontSize: 13, color: Color(0xFF0EA5E9))),
            )
          else if (_mpList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Text('暂无可用小程序', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final mp in _mpList)
                      GestureDetector(
                        onTap: () {
                          // iOS 端不支持 uniMP 小程序宿主，简化为打开下载链接提示
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('iOS 端暂不支持小程序，请在 App 端使用')));
                        },
                        child: SizedBox(
                          width: 96,
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: mp.appIcon.isNotEmpty
                                    ? Image.network(mp.appIcon,
                                        width: 44, height: 44, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(
                                                color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
                                            child: const Icon(Icons.apps, color: AppColors.textTertiary)))
                                    : Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                            color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
                                        child: const Icon(Icons.apps, color: AppColors.textTertiary)),
                              ),
                              const SizedBox(height: 6),
                              Text(mp.appName.isNotEmpty ? mp.appName : mp.appId,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text('未安装',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const Spacer(),

          // ── 底部 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
                  ),
                  child: const Center(
                    child: Text('木藤影视 v1.0.0',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _confirmLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
                    ),
                    child: Center(
                      child: Text('退出登录',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.dangerRed)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 快捷功能项
class _ScItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final int badge;
  final bool green;
  final VoidCallback onTap;

  const _ScItem({
    required this.icon,
    required this.iconBg,
    required this.label,
    this.badge = 0,
    this.green = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 22, color: green ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)),
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: green
                            ? const Color(0x1A22C55E)
                            : const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        '$badge',
                        style: TextStyle(
                            fontSize: 10,
                            color: green ? const Color(0xFF22C55E) : Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
