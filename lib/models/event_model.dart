class EventModel {
  final int id;
  final String title;
  final String description;
  final DateTime? dateEvent;
  final String location;
  final String? imageUrl;
  final String category;
  final bool isConfirmed;
  final int participants;
  final String price;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.dateEvent,
    required this.location,
    this.imageUrl,
    required this.category,
    required this.isConfirmed,
    required this.participants,
    required this.price,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateEvent: json['date_event'] != null
          ? DateTime.tryParse(json['date_event'])
          : null,
      location: json['location'] ?? '',
      imageUrl: json['image_url'],
      category: json['category'] ?? 'Académique',
      isConfirmed: json['isConfirmed'] ?? false,
      participants: json['participants'] ?? 0,
      price: json['price'] ?? 'Gratuit',
    );
  }
}
