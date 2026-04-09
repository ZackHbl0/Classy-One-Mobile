class Course {
  final int? id;
  final String matiere;
  final String salle;
  final String prof;
  final String label;
  final String time;
  final bool isCurrent;

  Course({
    this.id,
    required this.matiere,
    required this.salle,
    required this.prof,
    required this.label,
    required this.time,
    required this.isCurrent,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      matiere: json['matiere'] ?? 'Pas de cours',
      salle: json['salle'] ?? 'Salle Non Spécifiée',
      prof: json['prof'] ?? 'Prof Non Assigné',
      label: json['label'] ?? 'Class',
      time: json['time'] ?? '--:--',
      isCurrent: json['is_current'] ?? false,
    );
  }
}
