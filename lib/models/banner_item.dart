/// Banner 条目
class BannerItem {
  final String id;
  final String title;
  final String image;
  final String rating;
  final String tag;

  BannerItem({
    required this.id,
    required this.title,
    required this.image,
    this.rating = '',
    this.tag = '热播',
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) => BannerItem(
        id: json['id']?.toString() ?? json['url']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        image: json['cover']?.toString() ?? '',
        rating: json['rate']?.toString() ?? '',
        tag: json['tag']?.toString() ?? '热播',
      );
}
