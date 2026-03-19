class AnnouncementModel {
  final int id;
  final String title;
  final String description;
  final String mediaUrl;
  final String mediaType;
  final String aspectRatio;
  final bool isActive;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.mediaType,
    required this.aspectRatio,
    required this.isActive,
    required this.isPublished,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      mediaUrl: json['media_url'] as String,
      mediaType: json['media_type'] as String,
      aspectRatio: json['aspect_ratio'] as String,
      isActive: json['is_active'] as bool,
      isPublished: json['is_published'] as bool,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'aspect_ratio': aspectRatio,
      'is_active': isActive,
      'published_at': publishedAt?.toIso8601String(),
    };
  }
}
