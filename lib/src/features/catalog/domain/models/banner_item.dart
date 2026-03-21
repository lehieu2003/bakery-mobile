class BannerItem {
  const BannerItem({
    required this.id,
    required this.title,
    this.imageUrl,
    this.linkUrl,
    required this.isActive,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final String? linkUrl;
  final bool isActive;

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      linkUrl: json['linkUrl']?.toString(),
      isActive: json['isActive'] == true,
    );
  }
}
