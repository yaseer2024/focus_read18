class Book {
  final String id;
  final String title;
  final String path;
  int lastPage;
  int totalPages;

  // 🔥 NEW: streak data
  int streak;
  String? lastReadDate;

  Book({
    required this.id,
    required this.title,
    required this.path,
    this.lastPage = 0,
    this.totalPages = 0,
    this.streak = 0,
    this.lastReadDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'lastPage': lastPage,
      'totalPages': totalPages,
      'streak': streak,
      'lastReadDate': lastReadDate,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown',
      path: json['path'] ?? '',
      lastPage: json['lastPage'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      streak: json['streak'] ?? 0,
      lastReadDate: json['lastReadDate'],
    );
  }

  double get progress {
    if (totalPages == 0) return 0;
    return (lastPage + 1) / totalPages;
  }

  String get progressPercent {
    return '${(progress * 100).toInt()}%';
  }
}