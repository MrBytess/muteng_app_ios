/// 观看历史条目
class HistoryItem {
  final String id;
  final String title;
  final String poster;
  final String sub;
  final String sourceKey;
  final int time;
  final int totalSeconds;
  final int playedSeconds;
  final int progress;

  HistoryItem({
    required this.id,
    required this.title,
    this.poster = '',
    this.sub = '',
    this.sourceKey = '',
    this.time = 0,
    this.totalSeconds = 0,
    this.playedSeconds = 0,
    this.progress = 0,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        poster: json['poster']?.toString() ?? '',
        sub: json['sub']?.toString() ?? '',
        sourceKey: json['sourceKey']?.toString() ?? '',
        time: json['time'] ?? 0,
        totalSeconds: json['totalSeconds'] ?? 0,
        playedSeconds: json['playedSeconds'] ?? 0,
        progress: json['progress'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'poster': poster,
        'sub': sub,
        'sourceKey': sourceKey,
        'time': time,
        'totalSeconds': totalSeconds,
        'playedSeconds': playedSeconds,
        'progress': progress,
      };
}
