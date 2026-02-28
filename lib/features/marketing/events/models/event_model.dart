class EventModel {
  final int id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String location;
  final String? imageUrl;
  final bool isUpcoming;
  final bool isPast;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? countdown;
  final int? daysUntil;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    this.imageUrl,
    required this.isUpcoming,
    required this.isPast,
    required this.createdAt,
    required this.updatedAt,
    this.countdown,
    this.daysUntil,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      location: json['location'] as String,
      imageUrl: json['image_url'] as String?,
      isUpcoming: json['is_upcoming'] as bool,
      isPast: json['is_past'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      countdown: json['countdown'] as Map<String, dynamic>?,
      daysUntil: json['days_until'] as int?,
    );
  }
}
