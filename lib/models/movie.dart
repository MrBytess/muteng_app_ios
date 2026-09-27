/// 影片数据模型
class Movie {
  final String id;
  final String vodId;
  final String title;
  final String sub;
  final String poster;
  final String score;
  final String sourceKey;
  final String sourceName;
  final String sourceUrl;
  final bool isTv;
  final String type_name;
  final String vod_year;
  final String vod_class;
  final String vod_content;

  Movie({
    required this.id,
    required this.title,
    this.vodId = '',
    this.sub = '',
    this.poster = '',
    this.score = '',
    this.sourceKey = '',
    this.sourceName = '',
    this.sourceUrl = '',
    this.isTv = false,
    this.type_name = '',
    this.vod_year = '',
    this.vod_class = '',
    this.vod_content = '',
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    final sourceCode = json['source_code']?.toString() ?? '';
    final vodId = json['vod_id']?.toString() ?? '';
    final typeName = json['type_name']?.toString() ?? '';
    return Movie(
      id: '$sourceCode${vodId.isNotEmpty ? '_$vodId' : ''}',
      vodId: vodId,
      title: json['vod_name']?.toString() ?? '',
      sub: [
        json['type_name']?.toString() ?? '',
        json['vod_year']?.toString() ?? '',
        json['vod_area']?.toString() ?? '',
        json['source_name']?.toString() ?? '',
      ]
          .where((s) => s.isNotEmpty)
          .join(' · '),
      poster: json['vod_pic']?.toString() ?? '',
      score: json['rating']?.toString() ?? '',
      sourceKey: sourceCode,
      sourceName: json['source_name']?.toString() ?? '',
      sourceUrl: json['source_url']?.toString() ?? '',
      isTv: RegExp(r'电视剧|连续剧|美剧|韩剧|日剧|泰剧|动漫|动画')
          .hasMatch(typeName),
      type_name: typeName,
      vod_year: json['vod_year']?.toString() ?? '',
      vod_class: json['vod_class']?.toString() ?? '',
      vod_content: json['vod_content']?.toString() ?? '',
    );
  }

  /// 从豆瓣搜索结果映射
  factory Movie.fromDouban(Map<String, dynamic> it) {
    final cover = it['cover']?.toString() ?? '';
    final url = it['url']?.toString() ?? '';
    final year = it['year']?.toString() ?? '';
    final type = it['type']?.toString() ?? '';
    final proxyImage = cover.isNotEmpty
        ? 'https://film.mutengyy.site/proxy/image-proxy?url=${Uri.encodeComponent(cover)}&referer=${Uri.encodeComponent(url)}'
        : '';
    return Movie(
      id: it['id']?.toString() ?? '',
      title: it['title']?.toString() ?? '',
      sub: [year, type].where((s) => s.isNotEmpty).join(' · '),
      poster: proxyImage,
      score: it['rating']?.toString() ?? '',
      sourceKey: 'douban',
      sourceName: '豆瓣',
      isTv: it['isTv'] == true,
      type_name: type,
      vod_year: year,
      vod_content: it['desc']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'vodId': vodId,
        'title': title,
        'sub': sub,
        'poster': poster,
        'score': score,
        'sourceKey': sourceKey,
        'sourceName': sourceName,
        'sourceUrl': sourceUrl,
        'isTv': isTv,
        'type_name': type_name,
        'vod_year': vod_year,
        'vod_class': vod_class,
        'vod_content': vod_content,
      };

  factory Movie.fromMap(Map<String, dynamic> map) => Movie(
        id: map['id']?.toString() ?? '',
        vodId: map['vodId']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        sub: map['sub']?.toString() ?? '',
        poster: map['poster']?.toString() ?? '',
        score: map['score']?.toString() ?? '',
        sourceKey: map['sourceKey']?.toString() ?? '',
        sourceName: map['sourceName']?.toString() ?? '',
        sourceUrl: map['sourceUrl']?.toString() ?? '',
        isTv: map['isTv'] ?? false,
        type_name: map['type_name']?.toString() ?? '',
        vod_year: map['vod_year']?.toString() ?? '',
        vod_class: map['vod_class']?.toString() ?? '',
        vod_content: map['vod_content']?.toString() ?? '',
      );
}
