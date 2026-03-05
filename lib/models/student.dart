class Student {
  final int idStudent;
  final String matricule;
  final String nom;
  final String prenom;

  Student({
    required this.idStudent,
    required this.matricule,
    required this.nom,
    required this.prenom,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      idStudent: json['idStudent'] is int
          ? json['idStudent']
          : int.parse(json['idStudent'].toString()),
      matricule: json['matricule'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idStudent': idStudent,
      'matricule': matricule,
      'nom': nom,
      'prenom': prenom,
    };
  }
}
