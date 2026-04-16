class Post {
  final String id;
  final String userId;
  final String? imageUrl;
  final String? caption;
  final String? location;
  final List<String> hashtags;
  int likesCount;
  int commentsCount;
  bool isLiked;
  final DateTime createdAt;
  final String? authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;

  Post({
    required this.id,
    required this.userId,
    this.imageUrl,
    this.caption,
    this.location,
    this.hashtags = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.authorName,
    this.authorUsername,
    this.authorAvatarUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final user = json['Users'] as Map<String, dynamic>?;
    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      caption: json['caption'] as String?,
      location: json['location'] as String?,
      hashtags: (json['hashtags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: user?['username'] as String?,
      authorUsername: user?['username'] as String?,
      authorAvatarUrl: user?['profile_pic'] as String?,
    );
  }
}

class TrendingDestination {
  final String id;
  final String name;
  final String location;
  final String? imageUrl;
  final int trendingPercent;
  final double rating;
  final int postCount;

  TrendingDestination({
    required this.id,
    required this.name,
    required this.location,
    this.imageUrl,
    this.trendingPercent = 0,
    this.rating = 0,
    this.postCount = 0,
  });

  factory TrendingDestination.fromJson(Map<String, dynamic> json) {
    return TrendingDestination(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      imageUrl: json['image_url'] as String?,
      trendingPercent: (json['trending_percent'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      postCount: (json['post_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class Creator {
  final String userId;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final int followersCount;
  final int postsCount;
  bool isFollowing;

  Creator({
    required this.userId,
    required this.username,
    this.bio,
    this.avatarUrl,
    this.followersCount = 0,
    this.postsCount = 0,
    this.isFollowing = false,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String?,
      avatarUrl: json['profile_pic'] as String?,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PostComment {
  final String id;
  final String reelId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;

  PostComment({
    required this.id,
    required this.reelId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final user = json['Users'] as Map<String, dynamic>?;
    return PostComment(
      id: json['id'] as String,
      reelId: json['reel_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: user?['username'] as String?,
      authorAvatarUrl: user?['profile_pic'] as String?,
    );
  }
}
