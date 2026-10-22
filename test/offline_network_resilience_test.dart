import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/offline_cache_service.dart';
import 'package:flutter_application_1/services/http_retry_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineCacheService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('can cache, retrieve, and check timestamp of timetable payload', () async {
      final sampleTimetable = {
        'success': true,
        'data': [
          {'id': 1, 'matiere': 'Mathématiques', 'salle': 'Salle A1', 'jour': 'Lundi'},
          {'id': 2, 'matiere': 'Informatique', 'salle': 'Lab 3', 'jour': 'Mardi'},
        ]
      };

      await OfflineCacheService.setCache('planning_101', sampleTimetable);

      final hasCache = await OfflineCacheService.hasCache('planning_101');
      expect(hasCache, isTrue);

      final cachedData = await OfflineCacheService.getCache('planning_101');
      expect(cachedData, isNotNull);
      expect(cachedData['success'], isTrue);
      expect((cachedData['data'] as List).length, equals(2));

      final timeFormatted = await OfflineCacheService.getFormattedCacheTime('planning_101');
      expect(timeFormatted, equals('à l\'instant'));
    });

    test('can cache and retrieve student grades summary', () async {
      final sampleGrades = {
        'success': true,
        'statistics': {'gpa': 16.5, 'mention': 'Très Bien'},
        'data': [
          {'matiere': 'Physique', 'note': 17.0, 'coef': 3},
        ]
      };

      await OfflineCacheService.setCache('grades_101', sampleGrades);

      final cached = await OfflineCacheService.getCache('grades_101');
      expect(cached, isNotNull);
      expect(cached['statistics']['gpa'], equals(16.5));
    });

    test('can remove specific key and clear all caches', () async {
      await OfflineCacheService.setCache('test_1', {'key': 'val1'});
      await OfflineCacheService.setCache('test_2', {'key': 'val2'});

      expect(await OfflineCacheService.hasCache('test_1'), isTrue);
      await OfflineCacheService.removeCache('test_1');
      expect(await OfflineCacheService.hasCache('test_1'), isFalse);
      expect(await OfflineCacheService.hasCache('test_2'), isTrue);

      await OfflineCacheService.clearAll();
      expect(await OfflineCacheService.hasCache('test_2'), isFalse);
    });
  });

  group('HttpRetryHelper Tests', () {
    test('succeeds on first attempt without delay', () async {
      int calls = 0;
      final result = await HttpRetryHelper.retry<String>(() async {
        calls++;
        return 'SUCCESS';
      });

      expect(result, equals('SUCCESS'));
      expect(calls, equals(1));
    });

    test('retries on network exception and recovers', () async {
      int calls = 0;
      final result = await HttpRetryHelper.retry<String>(
        () async {
          calls++;
          if (calls < 2) {
            throw const FormatException('Connection refused');
          }
          return 'RECOVERED';
        },
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 50),
      );

      expect(result, equals('RECOVERED'));
      expect(calls, equals(2));
    });
  });
}