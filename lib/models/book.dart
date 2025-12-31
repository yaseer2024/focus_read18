class Book {
  final String id;
  final String title;
  final String path; // local file path (even for server books after download)

  int lastPage;
  int totalPages;

  // 🔥 Reading streak
  int streak;
  String? lastReadDate;

  // 🌐 NEW: remote or local
  bool isRemote;

  Book({
    required this.id,
    required this.title,
    required this.path,
    this.lastPage = 0,
    this.totalPages = 0,
    this.streak = 0,
    this.lastReadDate,
    this.isRemote = false, // 👈 default = LOCAL (CORE SAFE)
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
      'isRemote': isRemote,
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
      isRemote: json['isRemote'] ?? false, // 👈 backward compatible
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
