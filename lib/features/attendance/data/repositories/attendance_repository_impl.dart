import 'package:fpdart/fpdart.dart' hide Order;
import 'package:syncup/core/error/failures.dart';
import 'package:syncup/core/storage/models/subject_ob.dart';
import 'package:syncup/core/storage/models/attendance_session_ob.dart';
import 'package:syncup/core/storage/object_box_store.dart';
import 'package:syncup/core/sync/connectivity_service.dart';
import 'package:syncup/core/sync/sync_manager.dart';
import 'package:syncup/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:syncup/features/attendance/data/models/subject_dto.dart';
import 'package:syncup/features/attendance/data/models/attendance_session_dto.dart';
import 'package:syncup/features/attendance/domain/entities/subject.dart';
import 'package:syncup/features/attendance/domain/entities/attendance_session.dart';
import 'package:syncup/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:syncup/objectbox.g.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource _remote;
  final ObjectBoxStore _store;
  final SyncManager _syncManager;
  final ConnectivityService _connectivity;

  AttendanceRepositoryImpl(
      this._remote, this._store, this._syncManager, this._connectivity);

  // ─── helpers ───

  Box<SubjectOB> get _subjectBox => _store.box<SubjectOB>();
  Box<AttendanceSessionOB> get _sessionBox =>
      _store.box<AttendanceSessionOB>();

  Subject _subjectObToDomain(SubjectOB ob) => Subject(
        id: ob.id,
        userId: ob.userId,
        name: ob.name,
        code: ob.code,
        thresholdPct: ob.thresholdPct,
        createdAt: ob.updatedAt, // SubjectOB only has updatedAt
        updatedAt: ob.updatedAt,
      );

  SubjectOB _subjectDomainToOb(Subject s, {bool isSynced = false}) {
    final q = _subjectBox.query(SubjectOB_.id.equals(s.id)).build();
    final existing = q.findFirst();
    q.close();
    return SubjectOB(
      obId: existing?.obId ?? 0,
      id: s.id,
      userId: s.userId,
      name: s.name,
      code: s.code,
      thresholdPct: s.thresholdPct,
      isSynced: isSynced,
      updatedAt: s.updatedAt,
    );
  }

  AttendanceSession _sessionObToDomain(AttendanceSessionOB ob) =>
      AttendanceSession(
        id: ob.id,
        subjectId: ob.subjectId,
        sessionDate: ob.sessionDate,
        status: AttendanceStatus.values.byName(ob.status),
        createdAt: ob.createdAt,
        updatedAt: ob.updatedAt,
      );

  AttendanceSessionOB _sessionDomainToOb(AttendanceSession s,
      {bool isSynced = false}) {
    final q = _sessionBox.query(AttendanceSessionOB_.id.equals(s.id)).build();
    final existing = q.findFirst();
    q.close();
    return AttendanceSessionOB(
      obId: existing?.obId ?? 0,
      id: s.id,
      subjectId: s.subjectId,
      sessionDate: s.sessionDate,
      status: s.status.name,
      isSynced: isSynced,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
    );
  }

  /// Fire-and-forget: saves locally first, then tries remote in background.
  void _pushOrEnqueueAsync({
    required String operationType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    required Future<void> Function() remoteFn,
  }) {
    () async {
      if (await _connectivity.checkConnectivity()) {
        try {
          await remoteFn();
          // Mark as synced
          if (entityType == 'subject') {
            final q =
                _subjectBox.query(SubjectOB_.id.equals(entityId)).build();
            final local = q.findFirst();
            q.close();
            if (local != null) {
              local.isSynced = true;
              _subjectBox.put(local);
            }
          } else {
            final q = _sessionBox
                .query(AttendanceSessionOB_.id.equals(entityId))
                .build();
            final local = q.findFirst();
            q.close();
            if (local != null) {
              local.isSynced = true;
              _sessionBox.put(local);
            }
          }
        } catch (_) {
          await _syncManager.enqueue(
            operationType: operationType,
            entityType: entityType,
            entityId: entityId,
            payload: payload,
          );
        }
      } else {
        await _syncManager.enqueue(
          operationType: operationType,
          entityType: entityType,
          entityId: entityId,
          payload: payload,
        );
      }
    }();
  }

  // ─── Subject methods ───

  @override
  Future<Either<Failure, List<Subject>>> getSubjects(String userId) async {
    try {
      final q = _subjectBox
          .query(SubjectOB_.userId.equals(userId))
          .order(SubjectOB_.name)
          .build();
      final all = q.find();
      q.close();
      return Right(all.map(_subjectObToDomain).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Subject>> createSubject(Subject subject) async {
    try {
      _subjectBox.put(_subjectDomainToOb(subject));
      final json = SubjectDto.fromDomain(subject).toJson();
      _pushOrEnqueueAsync(
        operationType: 'CREATE',
        entityType: 'subject',
        entityId: subject.id,
        payload: json,
        remoteFn: () => _remote.createSubject(json),
      );
      return Right(subject);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Subject>> updateSubject(Subject subject) async {
    try {
      final updated = subject.copyWith(updatedAt: DateTime.now());
      _subjectBox.put(_subjectDomainToOb(updated));
      final json = SubjectDto.fromDomain(updated).toJson();
      _pushOrEnqueueAsync(
        operationType: 'UPDATE',
        entityType: 'subject',
        entityId: subject.id,
        payload: json,
        remoteFn: () => _remote.updateSubject(subject.id, json),
      );
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSubject(String subjectId) async {
    try {
      // Delete subject
      final q = _subjectBox.query(SubjectOB_.id.equals(subjectId)).build();
      final local = q.findFirst();
      q.close();
      if (local != null) _subjectBox.remove(local.obId);

      // Delete all sessions for this subject
      final sq = _sessionBox
          .query(AttendanceSessionOB_.subjectId.equals(subjectId))
          .build();
      final sessions = sq.find();
      sq.close();
      for (final s in sessions) {
        _sessionBox.remove(s.obId);
      }

      _pushOrEnqueueAsync(
        operationType: 'DELETE',
        entityType: 'subject',
        entityId: subjectId,
        payload: {'id': subjectId},
        remoteFn: () => _remote.deleteSubject(subjectId),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Session methods ───

  @override
  Future<Either<Failure, List<AttendanceSession>>> getSessionsForSubject(
      String subjectId) async {
    try {
      final q = _sessionBox
          .query(AttendanceSessionOB_.subjectId.equals(subjectId))
          .order(AttendanceSessionOB_.sessionDate, flags: Order.descending)
          .build();
      final all = q.find();
      q.close();
      return Right(all.map(_sessionObToDomain).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AttendanceSession>> logSession(
      AttendanceSession session) async {
    try {
      _sessionBox.put(_sessionDomainToOb(session));
      final json = AttendanceSessionDto.fromDomain(session).toJson();
      _pushOrEnqueueAsync(
        operationType: 'CREATE',
        entityType: 'attendance_session',
        entityId: session.id,
        payload: json,
        remoteFn: () => _remote.logSession(session.subjectId, json),
      );
      return Right(session);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSession(String sessionId) async {
    try {
      final q =
          _sessionBox.query(AttendanceSessionOB_.id.equals(sessionId)).build();
      final local = q.findFirst();
      q.close();
      if (local != null) {
        final subjectId = local.subjectId;
        _sessionBox.remove(local.obId);
        _pushOrEnqueueAsync(
          operationType: 'DELETE',
          entityType: 'attendance_session',
          entityId: sessionId,
          payload: {'id': sessionId},
          remoteFn: () => _remote.deleteSession(subjectId, sessionId),
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
