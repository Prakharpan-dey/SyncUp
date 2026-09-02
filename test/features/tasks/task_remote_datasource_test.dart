import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncup/features/tasks/data/datasources/task_remote_datasource.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late TaskRemoteDataSource remote;

  setUp(() {
    dio = _MockDio();
    remote = TaskRemoteDataSource(dio);
  });

  Response<dynamic> ok(Map<String, dynamic> body) => Response(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 200,
        data: body,
      );

  group('completing a task', () {
    /// A PATCH cannot do this: `updateTaskSchema` has no `status` field, so Zod
    /// stripped it and the server's copy stayed pending — which is why no
    /// completion ever reached the feed.
    test('posts to the dedicated toggle endpoint', () async {
      when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
          .thenAnswer((_) async => ok({'id': 't1', 'status': 'completed'}));

      await remote.toggleTask('t1');

      final captured = verify(
        () => dio.post<dynamic>(captureAny(), data: captureAny(named: 'data')),
      ).captured;
      expect(captured[0], '/tasks/t1/toggle');
    });

    // The route answers 400 to a POST with no body at all.
    test('sends a body, even an empty one', () async {
      when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
          .thenAnswer((_) async => ok({'id': 't1'}));

      await remote.toggleTask('t1');

      final captured = verify(
        () => dio.post<dynamic>(any(), data: captureAny(named: 'data')),
      ).captured;
      expect(captured.single, isNotNull);
    });

    test('does not reach for patch', () async {
      when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
          .thenAnswer((_) async => ok({'id': 't1'}));

      await remote.toggleTask('t1');

      verifyNever(() => dio.patch<dynamic>(any(), data: any(named: 'data')));
    });
  });
}
