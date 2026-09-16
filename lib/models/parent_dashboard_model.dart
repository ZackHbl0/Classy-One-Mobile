class ParentInfo {
  final int id;
  final String name;
  final String email;
  final String phone;

  ParentInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory ParentInfo.fromJson(Map<String, dynamic> json) {
    return ParentInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class ChildDetails {
  final int idStudent;
  final String matricule;
  final String nom;
  final String prenom;
  final String nomComplet;
  final String classe;
  final String? classeId;
  final String anneeScolaire;
  final String? telephone;

  ChildDetails({
    required this.idStudent,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.nomComplet,
    required this.classe,
    this.classeId,
    required this.anneeScolaire,
    this.telephone,
  });

  factory ChildDetails.fromJson(Map<String, dynamic> json) {
    return ChildDetails(
      idStudent: json['idStudent'] is int ? json['idStudent'] : int.tryParse(json['idStudent'].toString()) ?? 0,
      matricule: json['matricule'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      nomComplet: json['nom_complet'] ?? '${json['nom'] ?? ''} ${json['prenom'] ?? ''}'.trim(),
      classe: json['classe'] ?? 'Non assignée',
      classeId: json['classe_id']?.toString(),
      anneeScolaire: json['annee_scolaire'] ?? '',
      telephone: json['telephone'],
    );
  }
}

class AbsenceItem {
  final int id;
  final String? date;
  final String? dateFormatted;
  final String seance;
  final String matiere;
  final bool isJustified;
  final String? justificationReason;
  final String? studentExplanation;
  final String? status;
  final String professeur;

  AbsenceItem({
    required this.id,
    this.date,
    this.dateFormatted,
    required this.seance,
    required this.matiere,
    required this.isJustified,
    this.justificationReason,
    this.studentExplanation,
    this.status,
    required this.professeur,
  });

  factory AbsenceItem.fromJson(Map<String, dynamic> json) {
    return AbsenceItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      date: json['date'],
      dateFormatted: json['date_formatted'] ?? json['date'],
      seance: json['seance'] ?? '',
      matiere: json['matiere'] ?? 'Matière',
      isJustified: json['is_justified'] == true || json['is_justified'] == 1,
      justificationReason: json['justification_reason'],
      studentExplanation: json['student_explanation'],
      status: json['status'],
      professeur: json['professeur'] ?? 'Enseignant',
    );
  }
}

class ChildAttendance {
  final int totalAbsences;
  final int justifiedAbsences;
  final int unjustifiedAbsences;
  final List<AbsenceItem> history;

  ChildAttendance({
    required this.totalAbsences,
    required this.justifiedAbsences,
    required this.unjustifiedAbsences,
    required this.history,
  });

  factory ChildAttendance.fromJson(Map<String, dynamic> json) {
    return ChildAttendance(
      totalAbsences: json['total_absences'] ?? 0,
      justifiedAbsences: json['justified_absences'] ?? 0,
      unjustifiedAbsences: json['unjustified_absences'] ?? 0,
      history: (json['history'] as List<dynamic>?)
              ?.map((item) => AbsenceItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class GradeItem {
  final int id;
  final String subjectName;
  final double note;
  final String noteFormatted;
  final String type;
  final String status;
  final bool isPassing;
  final String? examDate;
  final String? examDateFormatted;
  final String semester;
  final String? comment;
  final String teacherName;
  final double coefficient;

  GradeItem({
    required this.id,
    required this.subjectName,
    required this.note,
    required this.noteFormatted,
    required this.type,
    required this.status,
    required this.isPassing,
    this.examDate,
    this.examDateFormatted,
    required this.semester,
    this.comment,
    required this.teacherName,
    this.coefficient = 1.0,
  });

  factory GradeItem.fromJson(Map<String, dynamic> json) {
    final noteVal = json['note'] != null ? (json['note'] as num).toDouble() : 0.0;
    return GradeItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      subjectName: json['subject_name'] ?? 'Matière',
      note: noteVal,
      noteFormatted: json['note_formatted'] ?? noteVal.toStringAsFixed(2),
      type: json['type'] ?? 'Contrôle',
      status: json['status'] ?? (noteVal >= 10 ? 'Admis' : 'Non admis'),
      isPassing: json['is_passing'] == true || noteVal >= 10,
      examDate: json['exam_date'],
      examDateFormatted: json['exam_date_formatted'] ?? json['exam_date'],
      semester: json['semester'] ?? 'Semestre 1',
      comment: json['comment'],
      teacherName: json['teacher_name'] ?? 'Professeur',
      coefficient: json['coefficient'] != null ? (json['coefficient'] as num).toDouble() : 1.0,
    );
  }
}

class ChildGrades {
  final double average;
  final String averageFormatted;
  final String? mention;
  final int totalGrades;
  final num passingRate;
  final double highestGrade;
  final double lowestGrade;
  final List<GradeItem> list;

  ChildGrades({
    required this.average,
    required this.averageFormatted,
    this.mention,
    required this.totalGrades,
    required this.passingRate,
    required this.highestGrade,
    required this.lowestGrade,
    required this.list,
  });

  factory ChildGrades.fromJson(Map<String, dynamic> json) {
    final avg = json['weighted_average'] != null
          ? (json['weighted_average'] as num).toDouble()
          : (json['average'] != null ? (json['average'] as num).toDouble() : 0.0);
    return ChildGrades(
      average: avg,
      averageFormatted: json['weighted_average_formatted'] ?? json['average_formatted'] ?? '${avg.toStringAsFixed(2)} / 20',
      mention: json['mention']?.toString() ?? json['status']?.toString(),
      totalGrades: json['total_grades'] ?? 0,
      passingRate: json['passing_rate'] ?? 0,
      highestGrade: json['highest_grade'] != null ? (json['highest_grade'] as num).toDouble() : 0.0,
      lowestGrade: json['lowest_grade'] != null ? (json['lowest_grade'] as num).toDouble() : 0.0,
      list: (json['list'] as List<dynamic>?)
              ?.map((item) => GradeItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PaymentTrancheItem {
  final int id;
  final String title;
  final String amount;
  final double amountRaw;
  final String dueDate;
  final String? dueDateRaw;
  final String status;

  PaymentTrancheItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.amountRaw,
    required this.dueDate,
    this.dueDateRaw,
    required this.status,
  });

  factory PaymentTrancheItem.fromJson(Map<String, dynamic> json) {
    return PaymentTrancheItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? 'Tranche',
      amount: json['amount'] ?? '0 MAD',
      amountRaw: json['amount_raw'] != null ? (json['amount_raw'] as num).toDouble() : 0.0,
      dueDate: json['dueDate'] ?? 'N/A',
      dueDateRaw: json['dueDate_raw'],
      status: json['status'] ?? 'En attente',
    );
  }
}

class ChildPayments {
  final double totalAmount;
  final double totalPaid;
  final double totalRemaining;
  final String overallStatus;
  final List<PaymentTrancheItem> tranches;

  ChildPayments({
    required this.totalAmount,
    required this.totalPaid,
    required this.totalRemaining,
    required this.overallStatus,
    required this.tranches,
  });

  factory ChildPayments.fromJson(Map<String, dynamic> json) {
    return ChildPayments(
      totalAmount: json['total_amount'] != null ? (json['total_amount'] as num).toDouble() : 0.0,
      totalPaid: json['total_paid'] != null ? (json['total_paid'] as num).toDouble() : 0.0,
      totalRemaining: json['total_remaining'] != null ? (json['total_remaining'] as num).toDouble() : 0.0,
      overallStatus: json['overall_status'] ?? 'À jour',
      tranches: (json['tranches'] as List<dynamic>?)
              ?.map((item) => PaymentTrancheItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ChildAnnouncement {
  final int id;
  final String titre;
  final String message;
  final String categorie;
  final String? pieceJointe;
  final String? createdAt;
  final String? dateRelative;

  ChildAnnouncement({
    required this.id,
    required this.titre,
    required this.message,
    required this.categorie,
    this.pieceJointe,
    this.createdAt,
    this.dateRelative,
  });

  factory ChildAnnouncement.fromJson(Map<String, dynamic> json) {
    return ChildAnnouncement(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      titre: json['titre'] ?? 'Annonce',
      message: json['message'] ?? '',
      categorie: json['categorie'] ?? 'Général',
      pieceJointe: json['pieceJointe'],
      createdAt: json['created_at'],
      dateRelative: json['date_relative'],
    );
  }
}

class ChildData {
  final ChildDetails details;
  final ChildAttendance attendance;
  final ChildGrades grades;
  final ChildPayments payments;
  final List<ChildAnnouncement> announcements;

  ChildData({
    required this.details,
    required this.attendance,
    required this.grades,
    required this.payments,
    required this.announcements,
  });

  factory ChildData.fromJson(Map<String, dynamic> json) {
    return ChildData(
      details: ChildDetails.fromJson(json['details'] as Map<String, dynamic>),
      attendance: ChildAttendance.fromJson(json['attendance'] as Map<String, dynamic>),
      grades: ChildGrades.fromJson(json['grades'] as Map<String, dynamic>),
      payments: ChildPayments.fromJson(json['payments'] as Map<String, dynamic>),
      announcements: (json['announcements'] as List<dynamic>?)
              ?.map((item) => ChildAnnouncement.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ParentDashboardResponse {
  final ParentInfo parent;
  final List<ChildData> children;

  ParentDashboardResponse({
    required this.parent,
    required this.children,
  });

  factory ParentDashboardResponse.fromJson(Map<String, dynamic> json) {
    return ParentDashboardResponse(
      parent: ParentInfo.fromJson(json['parent'] as Map<String, dynamic>),
      children: (json['children'] as List<dynamic>?)
              ?.map((item) => ChildData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
