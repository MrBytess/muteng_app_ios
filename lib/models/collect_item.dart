/// 收藏条目
class CollectItem {
  final String key;
  final String vodId;
  final String title;
  final String poster;
  final String sub;
  final String sourceKey;
  final String sourceUrl;
  final bool isTv;
  final int time;

  CollectItem({
    required this.key,
    this.vodId = '',
    this.title = '',
    this.poster = '',
    this.sub = '',
    this.sourceKey = '',
    this.sourceUrl = '',
    this.isTv = false,
    this.time = 0,
  });

  factory CollectItem.fromJson(Map<String, dynamic> json) => CollectItem(
        key: json['key']?.toString() ?? '',
        vodId: json['vodId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        poster: json['poster']?.toString() ?? '',
        sub: json['sub']?.toString() ?? '',
        sourceKey: json['sourceKey']?.toString() ?? '',
        sourceUrl: json['sourceUrl']?.toString() ?? '',
        isTv: json['isTv'] ?? false,
        time: json['time'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'vodId': vodId,
        'title': title,
        'poster': poster,
        'sub': sub,
        'sourceKey': sourceKey,
        'sourceUrl': sourceUrl,
        'isTv': isTv,
        'time': time,
      };
}
