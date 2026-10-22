import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/course.dart';

void main() {
  group('Classy-One Mobile Model & Serialization Tests', () {
    test('Course.fromJson correctly deserializes full JSON payload', () {
      final json = {
        'id': 42,
        'matiere': 'Développement Flutter',
        'salle': 'Labo Mobile 3',
        'prof': 'Prof. Zakaria Mansouri',
        'label': 'Cours Actuel',
        'time': '08:30 - 10:30',
        'is_current': true,
      };

      final course = Course.fromJson(json);

      expect(course.id, 42);
      expect(course.matiere, 'Développement Flutter');
      expect(course.salle, 'Labo Mobile 3');
      expect(course.prof, 'Prof. Zakaria Mansouri');
      expect(course.label, 'Cours Actuel');
      expect(course.time, '08:30 - 10:30');
      expect(course.isCurrent, isTrue);
    });

    test('Course.fromJson provides robust fallbacks for null or missing values', () {
      final emptyJson = <String, dynamic>{};

      final course = Course.fromJson(emptyJson);

      expect(course.id, isNull);
      expect(course.matiere, isNotEmpty);
      expect(course.isCurrent, isFalse);
    });
  });

  group('Classy-One Mobile UI Widget Rendering Tests', () {
    testWidgets('Renders course card widget with all details correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                leading: const Icon(Icons.school, color: Colors.blue),
                title: const Text('Architecture Logicielle'),
                subtitle: const Text('Prof. Hassan Alami • Salle 102'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('En cours', style: TextStyle(color: Colors.green)),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Architecture Logicielle'), findsOneWidget);
      expect(find.text('Prof. Hassan Alami • Salle 102'), findsOneWidget);
      expect(find.text('En cours'), findsOneWidget);
      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('Verifies interactive button tap and state feedback', (WidgetTester tester) async {
      bool buttonTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('download_btn'),
                onPressed: () {
                  buttonTapped = true;
                },
                child: const Text('Télécharger Attestation'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Télécharger Attestation'), findsOneWidget);
      expect(buttonTapped, isFalse);

      await tester.tap(find.byKey(const Key('download_btn')));
      await tester.pump();

      expect(buttonTapped, isTrue);
    });
  });

  group('Classy-One Mobile Navigation Flow Tests', () {
    testWidgets('Navigation pushes detail screen and pops back to dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (context) => Scaffold(
                  appBar: AppBar(title: const Text('Dashboard')),
                  body: Center(
                    child: ElevatedButton(
                      child: const Text('Voir Mes Notes'),
                      onPressed: () => Navigator.pushNamed(context, '/grades'),
                    ),
                  ),
                ),
            '/grades': (context) => Scaffold(
                  appBar: AppBar(title: const Text('Détail des Notes')),
                  body: Center(
                    child: ElevatedButton(
                      child: const Text('Retour'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
          },
        ),
      );

      // Verify on Dashboard
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Voir Mes Notes'), findsOneWidget);
      expect(find.text('Détail des Notes'), findsNothing);

      // Tap to navigate to grades screen
      await tester.tap(find.text('Voir Mes Notes'));
      await tester.pumpAndSettle();

      // Verify on Grades detail screen
      expect(find.text('Détail des Notes'), findsOneWidget);
      expect(find.text('Retour'), findsOneWidget);

      // Tap to go back
      await tester.tap(find.text('Retour'));
      await tester.pumpAndSettle();

      // Verify back on Dashboard
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Détail des Notes'), findsNothing);
    });
  });
}
