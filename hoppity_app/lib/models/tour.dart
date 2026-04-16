class ItineraryDay {
  final int day;
  final String title;
  final String description;

  ItineraryDay({required this.day, required this.title, required this.description});

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
        day: (json['day'] as num?)?.toInt() ?? 1,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'day': day, 'title': title, 'description': description};
}

class Tour {
  final String id; // bigint stored as string
  final String title;
  final String? description;
  final String category;
  final String location;
  final String? state;
  final String durationDisplay;
  final double pricePerPerson;
  final int maxGroupSize;
  final int minGroupSize;
  final String difficulty;
  final List<String> highlights;
  final List<String> inclusions;
  final List<String> exclusions;
  final List<ItineraryDay> itineraryDays;
  final String? meetingPoint;
  final List<String> languages;
  final String? coverImageUrl;
  final List<String> images;
  final String? videoUrl;
  final double rating;
  final int reviewCount;
  final String? guideId;
  final String? guideName;
  final String? guideAvatarUrl;
  final String? blurb;
  final String? route;
  final bool isActive;
  bool isLiked;
  bool isSaved;
  int likesCount;

  Tour({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.location,
    this.state,
    required this.durationDisplay,
    required this.pricePerPerson,
    this.maxGroupSize = 15,
    this.minGroupSize = 1,
    this.difficulty = 'Moderate',
    this.highlights = const [],
    this.inclusions = const [],
    this.exclusions = const [],
    this.itineraryDays = const [],
    this.meetingPoint,
    this.languages = const ['English'],
    this.coverImageUrl,
    this.images = const [],
    this.videoUrl,
    this.rating = 0,
    this.reviewCount = 0,
    this.guideId,
    this.guideName,
    this.guideAvatarUrl,
    this.blurb,
    this.route,
    this.isActive = true,
    this.isLiked = false,
    this.isSaved = false,
    this.likesCount = 0,
  });

  factory Tour.fromJson(Map<String, dynamic> json) {
    final guide = json['Host_details'] as Map<String, dynamic>?;
    return Tour(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Unnamed Tour',
      description: json['blurb'] as String?,
      category: json['category'] as String? ?? 'Cultural',
      location: json['location'] as String? ?? '',
      state: json['state'] as String?,
      durationDisplay: json['duration_display'] as String? ?? json['duration'] as String? ?? '1 Day',
      pricePerPerson: (json['price_per_person'] as num?)?.toDouble() ??
          double.tryParse((json['price'] as String? ?? '0').replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
      maxGroupSize: (json['max_group_size'] as num?)?.toInt() ?? 15,
      minGroupSize: (json['min_group_size'] as num?)?.toInt() ?? 1,
      difficulty: json['difficulty'] as String? ?? 'Moderate',
      highlights: (json['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      inclusions: (json['inclusions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      exclusions: (json['exclusions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      itineraryDays: (json['itinerary_days'] as List<dynamic>?)
              ?.map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      meetingPoint: json['meeting_point'] as String?,
      languages: (json['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['English'],
      coverImageUrl: json['cover_image_url'] as String?,
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      videoUrl: json['video_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      guideId: guide?['user_id'] as String? ?? json['guide_id'] as String?,
      guideName: guide?['display_name'] as String? ?? guide?['host_name'] as String?,
      guideAvatarUrl: guide?['avatar_url'] as String?,
      blurb: json['blurb'] as String?,
      route: json['route'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Primary display image — cover first, then first in array, then null
  String? get primaryImage => coverImageUrl ?? (images.isNotEmpty ? images.first : null);

  /// Category color for the chip tag
  static Map<String, int> categoryColors = {
    'Heritage': 0xFF5D4037,
    'Trekking': 0xFF2E7D32,
    'Adventure': 0xFFE65100,
    'Wildlife': 0xFF4E342E,
    'Culinary': 0xFFAD1457,
    'Spiritual': 0xFF6A1B9A,
    'Cultural': 0xFF1565C0,
  };

  int get categoryColor => categoryColors[category] ?? 0xFF7C3AED;

  /// Difficulty color
  int get difficultyColor {
    switch (difficulty) {
      case 'Easy': return 0xFF2E7D32;
      case 'Challenging': return 0xFFB71C1C;
      default: return 0xFFE65100;
    }
  }
}
