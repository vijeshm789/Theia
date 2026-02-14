class NewsArticle {
  final String id;
  final String title;
  final String? description;
  final String source;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;

  const NewsArticle({
    required this.id,
    required this.title,
    this.description,
    required this.source,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] as String? ?? json['url'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      source: json['source'] is Map
          ? (json['source'] as Map)['name'] as String
          : json['source'] as String,
      url: json['url'] as String,
      imageUrl: json['urlToImage'] as String? ?? json['image_url'] as String?,
      publishedAt: DateTime.parse(json['publishedAt'] as String? ??
          json['published_at'] as String),
    );
  }

  factory NewsArticle.fromRss({
    required String title,
    required String link,
    String? description,
    String? source,
    DateTime? pubDate,
  }) {
    return NewsArticle(
      id: link,
      title: title,
      description: description,
      source: source ?? 'Google News',
      url: link,
      imageUrl: null,
      publishedAt: pubDate ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'source': source,
      'url': url,
      'image_url': imageUrl,
      'published_at': publishedAt.toIso8601String(),
    };
  }
}
