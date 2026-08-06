import 'dart:convert';

import '../storage/app_database.dart';

enum OutboxStatus { pending, processing, completed, failed }

OutboxStatus outboxStatusFromString(String value) => switch (value) {
  'processing' => OutboxStatus.processing,
  'completed' => OutboxStatus.completed,
  'failed' => OutboxStatus.failed,
  _ => OutboxStatus.pending,
};

/// An in-memory view of an [OutboxEntries] row — the row's JSON payload
/// decoded, its status as an enum, everything else passed through.
class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.entityType,
    required this.operationType,
    required this.payload,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    required this.nextAttemptAt,
    this.lastErrorMessage,
    this.lastErrorCode,
    this.resultEntityId,
  });

  factory OutboxEntry.fromRow(OutboxEntryRow row) => OutboxEntry(
    id: row.id,
    entityType: row.entityType,
    operationType: row.operationType,
    payload: jsonDecode(row.payloadJson) as Map<String, dynamic>,
    status: outboxStatusFromString(row.status),
    retryCount: row.retryCount,
    createdAt: row.createdAt,
    nextAttemptAt: row.nextAttemptAt,
    lastErrorMessage: row.lastErrorMessage,
    lastErrorCode: row.lastErrorCode,
    resultEntityId: row.resultEntityId,
  );

  final String id;
  final String entityType;
  final String operationType;
  final Map<String, dynamic> payload;
  final OutboxStatus status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime nextAttemptAt;
  final String? lastErrorMessage;
  final String? lastErrorCode;
  final String? resultEntityId;
}
