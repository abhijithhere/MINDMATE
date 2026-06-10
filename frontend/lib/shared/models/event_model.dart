class EventModel {
  final String title;
  final String time;
  final String category;
  final String? description;

  EventModel({required this.title, required this.time, required this.category, this.description});

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      title: json['title'] ?? 'Untitled',
      time: json['time'] ?? '',
      category: json['category'] ?? 'General',
      description: json['description'],
    );
  }
}