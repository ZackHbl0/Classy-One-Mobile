import 'package:flutter/material.dart';

/// Model representing a student's grade for a course.
///
/// Mapped to the Laravel GradeController JSON response keys:
///   id, subject_name, note, note_formatted, type, status, color,
///   is_passing, exam_date, exam_date_formatted, semester, comment,
///   teacher_name, created_at
class Grade {
  final int id;
  final String courseName;      // API key: subject_name
  final double note;
  final double noteMax;         // Always 20 from our API
  final String status;          // 'Excellent', 'Très Bien', 'Bien', 'Passable', 'Insuffisant'
  final String? noteFormatted;  // API key: note_formatted
  final String? comment;
  final String? professor;      // API key: teacher_name
  final String dateEvaluation;  // API key: exam_date_formatted or exam_date
  final String? typeEvaluation; // API key: type
  final String? semester;
  final String? colorKey;       // API key: color ('success','info','primary','warning','danger')
  final bool isPassing;         // API key: is_passing

  Grade({
    required this.id,
    required this.courseName,
    required this.note,
    required this.noteMax,
    required this.status,
    this.noteFormatted,
    this.comment,
    this.professor,
    required this.dateEvaluation,
    this.typeEvaluation,
    this.semester,
    this.colorKey,
    this.isPassing = true,
  });

  /// Factory constructor to create a Grade from the Laravel API JSON.
  ///
  /// Handles all type-safety edge cases:
  /// - `note` may arrive as int, double, or String
  /// - nullable fields gracefully default
  factory Grade.fromJson(Map<String, dynamic> json) {
    // Safely parse numeric value that could be int, double, or String
    double _parseDouble(dynamic value, [double fallback = 0]) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? fallback;
    }

    return Grade(
      id: (json['id'] is int)
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      // Laravel sends "subject_name"; legacy keys as fallback
      courseName: json['subject_name']?.toString() ??
          json['cours']?.toString() ??
          json['course_name']?.toString() ??
          '',
      note: _parseDouble(json['note']),
      noteMax: _parseDouble(json['note_max'], 20),
      status: json['status']?.toString() ?? 'Passable',
      noteFormatted: json['note_formatted']?.toString(),
      comment: json['comment']?.toString() ?? json['commentaire']?.toString(),
      // Laravel sends "teacher_name"
      professor: json['teacher_name']?.toString() ??
          json['professeur']?.toString() ??
          json['professor']?.toString(),
      // Laravel sends "exam_date_formatted" (dd/mm/yyyy) or "exam_date" (yyyy-mm-dd)
      dateEvaluation: json['exam_date_formatted']?.toString() ??
          json['exam_date']?.toString() ??
          json['date_evaluation']?.toString() ??
          '',
      // Laravel sends "type" (e.g. "Contrôle 1", "Examen Final")
      typeEvaluation: json['type']?.toString() ??
          json['type_evaluation']?.toString(),
      semester: json['semester']?.toString(),
      colorKey: json['color']?.toString(),
      isPassing: json['is_passing'] == true ||
          json['is_passing'] == 1 ||
          json['is_passing'] == '1',
    );
  }

  /// Convert grade to percentage
  double get percentage => noteMax > 0 ? (note / noteMax) * 100 : 0;

  /// Get color based on status
  Color get statusColor {
    // First try the color key from the API
    if (colorKey != null) {
      switch (colorKey!) {
        case 'success':
          return const Color(0xFF10B981); // Green
        case 'info':
          return const Color(0xFF708C70); // Blue
        case 'primary':
          return const Color(0xFF8B5CF6); // Purple
        case 'warning':
          return const Color(0xFFFBBF24); // Amber
        case 'danger':
          return const Color(0xFFEF4444); // Red
      }
    }
    // Fall back to status-based color
    switch (status.toLowerCase()) {
      case 'excellent':
        return const Color(0xFF10B981); // Green
      case 'très bien':
      case 'tres bien':
        return const Color(0xFF708C70); // Blue
      case 'bien':
        return const Color(0xFF8B5CF6); // Purple
      case 'passable':
        return const Color(0xFFFBBF24); // Amber
      case 'insuffisant':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B); // Gray
    }
  }

  /// Get icon based on status
  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Icons.emoji_events_rounded; // Trophy
      case 'très bien':
      case 'tres bien':
        return Icons.star_rounded; // Star
      case 'bien':
        return Icons.thumb_up_rounded; // Thumbs up
      case 'passable':
        return Icons.trending_up_rounded; // Trending up
      case 'insuffisant':
        return Icons.trending_down_rounded; // Trending down
      default:
        return Icons.grade_rounded; // Grade
    }
  }

  /// Format note as string (e.g., "15.50 / 20")
  String get formattedNote =>
      '${note.toStringAsFixed(2)} / ${noteMax.toStringAsFixed(0)}';
}

/// Model representing the overall grade statistics / summary.
///
/// Mapped to the Laravel GradeController "statistics" object:
///   total_grades, average, average_formatted, passing_rate,
///   passing_rate_formatted, highest_grade, lowest_grade
class GradeSummary {
  final double moyenneGenerale;   // API key: average
  final int totalCourses;         // API key: total_grades
  final int coursesEvalues;       // same as total_grades (all returned are evaluated)
  final String status;            // computed from average
  final double passingRate;       // API key: passing_rate
  final double highestGrade;      // API key: highest_grade
  final double lowestGrade;       // API key: lowest_grade
  final Map<String, int> statusBreakdown;

  GradeSummary({
    required this.moyenneGenerale,
    required this.totalCourses,
    required this.coursesEvalues,
    required this.status,
    required this.statusBreakdown,
    this.passingRate = 0,
    this.highestGrade = 0,
    this.lowestGrade = 0,
  });

  /// Factory constructor to create GradeSummary from the "statistics" JSON
  /// returned by the Laravel API.
  factory GradeSummary.fromJson(Map<String, dynamic> json) {
    // Safely parse numeric value
    double _parseDouble(dynamic value, [double fallback = 0]) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? fallback;
    }

    int _parseInt(dynamic value, [int fallback = 0]) {
      if (value == null) return fallback;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? fallback;
    }

    final breakdown = <String, int>{};
    if (json['status_breakdown'] != null) {
      (json['status_breakdown'] as Map<String, dynamic>).forEach((key, value) {
        breakdown[key] = value is int
            ? value
            : int.tryParse(value.toString()) ?? 0;
      });
    }

    // Parse the average — Laravel sends it as "average"
    final average = _parseDouble(
      json['average'] ?? json['moyenne_generale'],
    );

    // Parse total count — Laravel sends it as "total_grades"
    final totalGrades = _parseInt(
      json['total_grades'] ?? json['total_courses'] ?? json['total_cours'],
    );

    // Compute status from average if not provided
    String computedStatus;
    if (json['status'] != null) {
      computedStatus = json['status'].toString();
    } else if (average >= 16) {
      computedStatus = 'Excellent';
    } else if (average >= 14) {
      computedStatus = 'Très Bien';
    } else if (average >= 12) {
      computedStatus = 'Bien';
    } else if (average >= 10) {
      computedStatus = 'Passable';
    } else {
      computedStatus = 'Insuffisant';
    }

    return GradeSummary(
      moyenneGenerale: average,
      totalCourses: totalGrades,
      coursesEvalues: _parseInt(
        json['courses_evalues'] ?? json['cours_evalues'] ?? totalGrades,
      ),
      status: computedStatus,
      statusBreakdown: breakdown,
      passingRate: _parseDouble(json['passing_rate']),
      highestGrade: _parseDouble(json['highest_grade']),
      lowestGrade: _parseDouble(json['lowest_grade']),
    );
  }

  /// Get color based on overall status
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'excellent':
        return const Color(0xFF10B981);
      case 'très bien':
      case 'tres bien':
        return const Color(0xFF708C70);
      case 'bien':
        return const Color(0xFF8B5CF6);
      case 'passable':
        return const Color(0xFFFBBF24);
      case 'insuffisant':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  /// Format moyenne as string (e.g., "15.45 / 20")
  String get formattedMoyenne => '${moyenneGenerale.toStringAsFixed(2)} / 20';
}
