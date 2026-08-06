// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedProfilesTable extends CachedProfiles
    with TableInfo<$CachedProfilesTable, CachedProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileJsonMeta = const VerificationMeta(
    'profileJson',
  );
  @override
  late final GeneratedColumn<String> profileJson = GeneratedColumn<String>(
    'profile_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, profileJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('profile_json')) {
      context.handle(
        _profileJsonMeta,
        profileJson.isAcceptableOrUnknown(
          data['profile_json']!,
          _profileJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profileJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  CachedProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProfile(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      profileJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedProfilesTable createAlias(String alias) {
    return $CachedProfilesTable(attachedDatabase, alias);
  }
}

class CachedProfile extends DataClass implements Insertable<CachedProfile> {
  final String userId;
  final String profileJson;
  final DateTime updatedAt;
  const CachedProfile({
    required this.userId,
    required this.profileJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['profile_json'] = Variable<String>(profileJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedProfilesCompanion toCompanion(bool nullToAbsent) {
    return CachedProfilesCompanion(
      userId: Value(userId),
      profileJson: Value(profileJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProfile(
      userId: serializer.fromJson<String>(json['userId']),
      profileJson: serializer.fromJson<String>(json['profileJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'profileJson': serializer.toJson<String>(profileJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedProfile copyWith({
    String? userId,
    String? profileJson,
    DateTime? updatedAt,
  }) => CachedProfile(
    userId: userId ?? this.userId,
    profileJson: profileJson ?? this.profileJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedProfile copyWithCompanion(CachedProfilesCompanion data) {
    return CachedProfile(
      userId: data.userId.present ? data.userId.value : this.userId,
      profileJson: data.profileJson.present
          ? data.profileJson.value
          : this.profileJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfile(')
          ..write('userId: $userId, ')
          ..write('profileJson: $profileJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, profileJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProfile &&
          other.userId == this.userId &&
          other.profileJson == this.profileJson &&
          other.updatedAt == this.updatedAt);
}

class CachedProfilesCompanion extends UpdateCompanion<CachedProfile> {
  final Value<String> userId;
  final Value<String> profileJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedProfilesCompanion({
    this.userId = const Value.absent(),
    this.profileJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedProfilesCompanion.insert({
    required String userId,
    required String profileJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       profileJson = Value(profileJson),
       updatedAt = Value(updatedAt);
  static Insertable<CachedProfile> custom({
    Expression<String>? userId,
    Expression<String>? profileJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (profileJson != null) 'profile_json': profileJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedProfilesCompanion copyWith({
    Value<String>? userId,
    Value<String>? profileJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedProfilesCompanion(
      userId: userId ?? this.userId,
      profileJson: profileJson ?? this.profileJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (profileJson.present) {
      map['profile_json'] = Variable<String>(profileJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfilesCompanion(')
          ..write('userId: $userId, ')
          ..write('profileJson: $profileJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPreferencesTableTable extends CachedPreferencesTable
    with TableInfo<$CachedPreferencesTableTable, CachedPreferencesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preferencesJsonMeta = const VerificationMeta(
    'preferencesJson',
  );
  @override
  late final GeneratedColumn<String> preferencesJson = GeneratedColumn<String>(
    'preferences_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, preferencesJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_preferences_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPreferencesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('preferences_json')) {
      context.handle(
        _preferencesJsonMeta,
        preferencesJson.isAcceptableOrUnknown(
          data['preferences_json']!,
          _preferencesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_preferencesJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  CachedPreferencesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPreferencesTableData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      preferencesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferences_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedPreferencesTableTable createAlias(String alias) {
    return $CachedPreferencesTableTable(attachedDatabase, alias);
  }
}

class CachedPreferencesTableData extends DataClass
    implements Insertable<CachedPreferencesTableData> {
  final String userId;
  final String preferencesJson;
  final DateTime updatedAt;
  const CachedPreferencesTableData({
    required this.userId,
    required this.preferencesJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['preferences_json'] = Variable<String>(preferencesJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedPreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return CachedPreferencesTableCompanion(
      userId: Value(userId),
      preferencesJson: Value(preferencesJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedPreferencesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPreferencesTableData(
      userId: serializer.fromJson<String>(json['userId']),
      preferencesJson: serializer.fromJson<String>(json['preferencesJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'preferencesJson': serializer.toJson<String>(preferencesJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedPreferencesTableData copyWith({
    String? userId,
    String? preferencesJson,
    DateTime? updatedAt,
  }) => CachedPreferencesTableData(
    userId: userId ?? this.userId,
    preferencesJson: preferencesJson ?? this.preferencesJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedPreferencesTableData copyWithCompanion(
    CachedPreferencesTableCompanion data,
  ) {
    return CachedPreferencesTableData(
      userId: data.userId.present ? data.userId.value : this.userId,
      preferencesJson: data.preferencesJson.present
          ? data.preferencesJson.value
          : this.preferencesJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPreferencesTableData(')
          ..write('userId: $userId, ')
          ..write('preferencesJson: $preferencesJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, preferencesJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPreferencesTableData &&
          other.userId == this.userId &&
          other.preferencesJson == this.preferencesJson &&
          other.updatedAt == this.updatedAt);
}

class CachedPreferencesTableCompanion
    extends UpdateCompanion<CachedPreferencesTableData> {
  final Value<String> userId;
  final Value<String> preferencesJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedPreferencesTableCompanion({
    this.userId = const Value.absent(),
    this.preferencesJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPreferencesTableCompanion.insert({
    required String userId,
    required String preferencesJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       preferencesJson = Value(preferencesJson),
       updatedAt = Value(updatedAt);
  static Insertable<CachedPreferencesTableData> custom({
    Expression<String>? userId,
    Expression<String>? preferencesJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (preferencesJson != null) 'preferences_json': preferencesJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPreferencesTableCompanion copyWith({
    Value<String>? userId,
    Value<String>? preferencesJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedPreferencesTableCompanion(
      userId: userId ?? this.userId,
      preferencesJson: preferencesJson ?? this.preferencesJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (preferencesJson.present) {
      map['preferences_json'] = Variable<String>(preferencesJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPreferencesTableCompanion(')
          ..write('userId: $userId, ')
          ..write('preferencesJson: $preferencesJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OnboardingDraftsTable extends OnboardingDrafts
    with TableInfo<$OnboardingDraftsTable, OnboardingDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OnboardingDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _draftJsonMeta = const VerificationMeta(
    'draftJson',
  );
  @override
  late final GeneratedColumn<String> draftJson = GeneratedColumn<String>(
    'draft_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, step, draftJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'onboarding_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<OnboardingDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    } else if (isInserting) {
      context.missing(_stepMeta);
    }
    if (data.containsKey('draft_json')) {
      context.handle(
        _draftJsonMeta,
        draftJson.isAcceptableOrUnknown(data['draft_json']!, _draftJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_draftJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OnboardingDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OnboardingDraft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step'],
      )!,
      draftJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OnboardingDraftsTable createAlias(String alias) {
    return $OnboardingDraftsTable(attachedDatabase, alias);
  }
}

class OnboardingDraft extends DataClass implements Insertable<OnboardingDraft> {
  final String id;
  final int step;
  final String draftJson;
  final DateTime updatedAt;
  const OnboardingDraft({
    required this.id,
    required this.step,
    required this.draftJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['step'] = Variable<int>(step);
    map['draft_json'] = Variable<String>(draftJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OnboardingDraftsCompanion toCompanion(bool nullToAbsent) {
    return OnboardingDraftsCompanion(
      id: Value(id),
      step: Value(step),
      draftJson: Value(draftJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory OnboardingDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OnboardingDraft(
      id: serializer.fromJson<String>(json['id']),
      step: serializer.fromJson<int>(json['step']),
      draftJson: serializer.fromJson<String>(json['draftJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'step': serializer.toJson<int>(step),
      'draftJson': serializer.toJson<String>(draftJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OnboardingDraft copyWith({
    String? id,
    int? step,
    String? draftJson,
    DateTime? updatedAt,
  }) => OnboardingDraft(
    id: id ?? this.id,
    step: step ?? this.step,
    draftJson: draftJson ?? this.draftJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OnboardingDraft copyWithCompanion(OnboardingDraftsCompanion data) {
    return OnboardingDraft(
      id: data.id.present ? data.id.value : this.id,
      step: data.step.present ? data.step.value : this.step,
      draftJson: data.draftJson.present ? data.draftJson.value : this.draftJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OnboardingDraft(')
          ..write('id: $id, ')
          ..write('step: $step, ')
          ..write('draftJson: $draftJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, step, draftJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OnboardingDraft &&
          other.id == this.id &&
          other.step == this.step &&
          other.draftJson == this.draftJson &&
          other.updatedAt == this.updatedAt);
}

class OnboardingDraftsCompanion extends UpdateCompanion<OnboardingDraft> {
  final Value<String> id;
  final Value<int> step;
  final Value<String> draftJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OnboardingDraftsCompanion({
    this.id = const Value.absent(),
    this.step = const Value.absent(),
    this.draftJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OnboardingDraftsCompanion.insert({
    required String id,
    required int step,
    required String draftJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       step = Value(step),
       draftJson = Value(draftJson),
       updatedAt = Value(updatedAt);
  static Insertable<OnboardingDraft> custom({
    Expression<String>? id,
    Expression<int>? step,
    Expression<String>? draftJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (step != null) 'step': step,
      if (draftJson != null) 'draft_json': draftJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OnboardingDraftsCompanion copyWith({
    Value<String>? id,
    Value<int>? step,
    Value<String>? draftJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OnboardingDraftsCompanion(
      id: id ?? this.id,
      step: step ?? this.step,
      draftJson: draftJson ?? this.draftJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (draftJson.present) {
      map['draft_json'] = Variable<String>(draftJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OnboardingDraftsCompanion(')
          ..write('id: $id, ')
          ..write('step: $step, ')
          ..write('draftJson: $draftJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStatusRowsTable extends SyncStatusRows
    with TableInfo<$SyncStatusRowsTable, SyncStatusRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatusRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncingMeta = const VerificationMeta(
    'isSyncing',
  );
  @override
  late final GeneratedColumn<bool> isSyncing = GeneratedColumn<bool>(
    'is_syncing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_syncing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, lastSyncedAt, isSyncing];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_status_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStatusRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_syncing')) {
      context.handle(
        _isSyncingMeta,
        isSyncing.isAcceptableOrUnknown(data['is_syncing']!, _isSyncingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncStatusRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStatusRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      isSyncing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_syncing'],
      )!,
    );
  }

  @override
  $SyncStatusRowsTable createAlias(String alias) {
    return $SyncStatusRowsTable(attachedDatabase, alias);
  }
}

class SyncStatusRow extends DataClass implements Insertable<SyncStatusRow> {
  final String id;
  final DateTime? lastSyncedAt;
  final bool isSyncing;
  const SyncStatusRow({
    required this.id,
    this.lastSyncedAt,
    required this.isSyncing,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['is_syncing'] = Variable<bool>(isSyncing);
    return map;
  }

  SyncStatusRowsCompanion toCompanion(bool nullToAbsent) {
    return SyncStatusRowsCompanion(
      id: Value(id),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      isSyncing: Value(isSyncing),
    );
  }

  factory SyncStatusRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStatusRow(
      id: serializer.fromJson<String>(json['id']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      isSyncing: serializer.fromJson<bool>(json['isSyncing']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'isSyncing': serializer.toJson<bool>(isSyncing),
    };
  }

  SyncStatusRow copyWith({
    String? id,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    bool? isSyncing,
  }) => SyncStatusRow(
    id: id ?? this.id,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    isSyncing: isSyncing ?? this.isSyncing,
  );
  SyncStatusRow copyWithCompanion(SyncStatusRowsCompanion data) {
    return SyncStatusRow(
      id: data.id.present ? data.id.value : this.id,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      isSyncing: data.isSyncing.present ? data.isSyncing.value : this.isSyncing,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatusRow(')
          ..write('id: $id, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isSyncing: $isSyncing')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastSyncedAt, isSyncing);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStatusRow &&
          other.id == this.id &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.isSyncing == this.isSyncing);
}

class SyncStatusRowsCompanion extends UpdateCompanion<SyncStatusRow> {
  final Value<String> id;
  final Value<DateTime?> lastSyncedAt;
  final Value<bool> isSyncing;
  final Value<int> rowid;
  const SyncStatusRowsCompanion({
    this.id = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isSyncing = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatusRowsCompanion.insert({
    required String id,
    this.lastSyncedAt = const Value.absent(),
    this.isSyncing = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<SyncStatusRow> custom({
    Expression<String>? id,
    Expression<DateTime>? lastSyncedAt,
    Expression<bool>? isSyncing,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (isSyncing != null) 'is_syncing': isSyncing,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatusRowsCompanion copyWith({
    Value<String>? id,
    Value<DateTime?>? lastSyncedAt,
    Value<bool>? isSyncing,
    Value<int>? rowid,
  }) {
    return SyncStatusRowsCompanion(
      id: id ?? this.id,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSyncing: isSyncing ?? this.isSyncing,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (isSyncing.present) {
      map['is_syncing'] = Variable<bool>(isSyncing.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatusRowsCompanion(')
          ..write('id: $id, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isSyncing: $isSyncing, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedWorkoutSessionRowsTable extends CachedWorkoutSessionRows
    with TableInfo<$CachedWorkoutSessionRowsTable, CachedWorkoutSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedWorkoutSessionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionJsonMeta = const VerificationMeta(
    'sessionJson',
  );
  @override
  late final GeneratedColumn<String> sessionJson = GeneratedColumn<String>(
    'session_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sessionJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_workout_session_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedWorkoutSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_json')) {
      context.handle(
        _sessionJsonMeta,
        sessionJson.isAcceptableOrUnknown(
          data['session_json']!,
          _sessionJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedWorkoutSessionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedWorkoutSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedWorkoutSessionRowsTable createAlias(String alias) {
    return $CachedWorkoutSessionRowsTable(attachedDatabase, alias);
  }
}

class CachedWorkoutSessionRow extends DataClass
    implements Insertable<CachedWorkoutSessionRow> {
  final String id;
  final String sessionJson;
  final DateTime updatedAt;
  const CachedWorkoutSessionRow({
    required this.id,
    required this.sessionJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_json'] = Variable<String>(sessionJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedWorkoutSessionRowsCompanion toCompanion(bool nullToAbsent) {
    return CachedWorkoutSessionRowsCompanion(
      id: Value(id),
      sessionJson: Value(sessionJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedWorkoutSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedWorkoutSessionRow(
      id: serializer.fromJson<String>(json['id']),
      sessionJson: serializer.fromJson<String>(json['sessionJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionJson': serializer.toJson<String>(sessionJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedWorkoutSessionRow copyWith({
    String? id,
    String? sessionJson,
    DateTime? updatedAt,
  }) => CachedWorkoutSessionRow(
    id: id ?? this.id,
    sessionJson: sessionJson ?? this.sessionJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedWorkoutSessionRow copyWithCompanion(
    CachedWorkoutSessionRowsCompanion data,
  ) {
    return CachedWorkoutSessionRow(
      id: data.id.present ? data.id.value : this.id,
      sessionJson: data.sessionJson.present
          ? data.sessionJson.value
          : this.sessionJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedWorkoutSessionRow(')
          ..write('id: $id, ')
          ..write('sessionJson: $sessionJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedWorkoutSessionRow &&
          other.id == this.id &&
          other.sessionJson == this.sessionJson &&
          other.updatedAt == this.updatedAt);
}

class CachedWorkoutSessionRowsCompanion
    extends UpdateCompanion<CachedWorkoutSessionRow> {
  final Value<String> id;
  final Value<String> sessionJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedWorkoutSessionRowsCompanion({
    this.id = const Value.absent(),
    this.sessionJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedWorkoutSessionRowsCompanion.insert({
    required String id,
    required String sessionJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionJson = Value(sessionJson),
       updatedAt = Value(updatedAt);
  static Insertable<CachedWorkoutSessionRow> custom({
    Expression<String>? id,
    Expression<String>? sessionJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionJson != null) 'session_json': sessionJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedWorkoutSessionRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedWorkoutSessionRowsCompanion(
      id: id ?? this.id,
      sessionJson: sessionJson ?? this.sessionJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionJson.present) {
      map['session_json'] = Variable<String>(sessionJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedWorkoutSessionRowsCompanion(')
          ..write('id: $id, ')
          ..write('sessionJson: $sessionJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxEntryRowsTable extends OutboxEntryRows
    with TableInfo<$OutboxEntryRowsTable, OutboxEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntryRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMessageMeta = const VerificationMeta(
    'lastErrorMessage',
  );
  @override
  late final GeneratedColumn<String> lastErrorMessage = GeneratedColumn<String>(
    'last_error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultEntityIdMeta = const VerificationMeta(
    'resultEntityId',
  );
  @override
  late final GeneratedColumn<String> resultEntityId = GeneratedColumn<String>(
    'result_entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    operationType,
    payloadJson,
    status,
    retryCount,
    lastErrorMessage,
    lastErrorCode,
    resultEntityId,
    createdAt,
    nextAttemptAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entry_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error_message')) {
      context.handle(
        _lastErrorMessageMeta,
        lastErrorMessage.isAcceptableOrUnknown(
          data['last_error_message']!,
          _lastErrorMessageMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('result_entity_id')) {
      context.handle(
        _resultEntityIdMeta,
        resultEntityId.isAcceptableOrUnknown(
          data['result_entity_id']!,
          _resultEntityIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_message'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      resultEntityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_entity_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OutboxEntryRowsTable createAlias(String alias) {
    return $OutboxEntryRowsTable(attachedDatabase, alias);
  }
}

class OutboxEntryRow extends DataClass implements Insertable<OutboxEntryRow> {
  /// The idempotency key itself — also the primary key, so enqueueing twice
  /// with the same key (e.g. a UI double-submit) can never create two rows.
  final String id;
  final String entityType;
  final String operationType;
  final String payloadJson;
  final String status;
  final int retryCount;
  final String? lastErrorMessage;
  final String? lastErrorCode;
  final String? resultEntityId;
  final DateTime createdAt;
  final DateTime nextAttemptAt;
  final DateTime updatedAt;
  const OutboxEntryRow({
    required this.id,
    required this.entityType,
    required this.operationType,
    required this.payloadJson,
    required this.status,
    required this.retryCount,
    this.lastErrorMessage,
    this.lastErrorCode,
    this.resultEntityId,
    required this.createdAt,
    required this.nextAttemptAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastErrorMessage != null) {
      map['last_error_message'] = Variable<String>(lastErrorMessage);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    if (!nullToAbsent || resultEntityId != null) {
      map['result_entity_id'] = Variable<String>(resultEntityId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OutboxEntryRowsCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntryRowsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      status: Value(status),
      retryCount: Value(retryCount),
      lastErrorMessage: lastErrorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorMessage),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      resultEntityId: resultEntityId == null && nullToAbsent
          ? const Value.absent()
          : Value(resultEntityId),
      createdAt: Value(createdAt),
      nextAttemptAt: Value(nextAttemptAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OutboxEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntryRow(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastErrorMessage: serializer.fromJson<String?>(json['lastErrorMessage']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      resultEntityId: serializer.fromJson<String?>(json['resultEntityId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastErrorMessage': serializer.toJson<String?>(lastErrorMessage),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'resultEntityId': serializer.toJson<String?>(resultEntityId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OutboxEntryRow copyWith({
    String? id,
    String? entityType,
    String? operationType,
    String? payloadJson,
    String? status,
    int? retryCount,
    Value<String?> lastErrorMessage = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    Value<String?> resultEntityId = const Value.absent(),
    DateTime? createdAt,
    DateTime? nextAttemptAt,
    DateTime? updatedAt,
  }) => OutboxEntryRow(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    operationType: operationType ?? this.operationType,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastErrorMessage: lastErrorMessage.present
        ? lastErrorMessage.value
        : this.lastErrorMessage,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    resultEntityId: resultEntityId.present
        ? resultEntityId.value
        : this.resultEntityId,
    createdAt: createdAt ?? this.createdAt,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OutboxEntryRow copyWithCompanion(OutboxEntryRowsCompanion data) {
    return OutboxEntryRow(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastErrorMessage: data.lastErrorMessage.present
          ? data.lastErrorMessage.value
          : this.lastErrorMessage,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      resultEntityId: data.resultEntityId.present
          ? data.resultEntityId.value
          : this.resultEntityId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntryRow(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('resultEntityId: $resultEntityId, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    operationType,
    payloadJson,
    status,
    retryCount,
    lastErrorMessage,
    lastErrorCode,
    resultEntityId,
    createdAt,
    nextAttemptAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntryRow &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.lastErrorMessage == this.lastErrorMessage &&
          other.lastErrorCode == this.lastErrorCode &&
          other.resultEntityId == this.resultEntityId &&
          other.createdAt == this.createdAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.updatedAt == this.updatedAt);
}

class OutboxEntryRowsCompanion extends UpdateCompanion<OutboxEntryRow> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> lastErrorMessage;
  final Value<String?> lastErrorCode;
  final Value<String?> resultEntityId;
  final Value<DateTime> createdAt;
  final Value<DateTime> nextAttemptAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OutboxEntryRowsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.resultEntityId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxEntryRowsCompanion.insert({
    required String id,
    required String entityType,
    required String operationType,
    required String payloadJson,
    required String status,
    this.retryCount = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.resultEntityId = const Value.absent(),
    required DateTime createdAt,
    required DateTime nextAttemptAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       operationType = Value(operationType),
       payloadJson = Value(payloadJson),
       status = Value(status),
       createdAt = Value(createdAt),
       nextAttemptAt = Value(nextAttemptAt),
       updatedAt = Value(updatedAt);
  static Insertable<OutboxEntryRow> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? lastErrorMessage,
    Expression<String>? lastErrorCode,
    Expression<String>? resultEntityId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastErrorMessage != null) 'last_error_message': lastErrorMessage,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (resultEntityId != null) 'result_entity_id': resultEntityId,
      if (createdAt != null) 'created_at': createdAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxEntryRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? operationType,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<int>? retryCount,
    Value<String?>? lastErrorMessage,
    Value<String?>? lastErrorCode,
    Value<String?>? resultEntityId,
    Value<DateTime>? createdAt,
    Value<DateTime>? nextAttemptAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OutboxEntryRowsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      resultEntityId: resultEntityId ?? this.resultEntityId,
      createdAt: createdAt ?? this.createdAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastErrorMessage.present) {
      map['last_error_message'] = Variable<String>(lastErrorMessage.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (resultEntityId.present) {
      map['result_entity_id'] = Variable<String>(resultEntityId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntryRowsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('resultEntityId: $resultEntityId, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedFoodsTable extends CachedFoods
    with TableInfo<$CachedFoodsTable, CachedFood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alternateNameMeta = const VerificationMeta(
    'alternateName',
  );
  @override
  late final GeneratedColumn<String> alternateName = GeneratedColumn<String>(
    'alternate_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isOwnedByCurrentUserMeta =
      const VerificationMeta('isOwnedByCurrentUser');
  @override
  late final GeneratedColumn<bool> isOwnedByCurrentUser = GeneratedColumn<bool>(
    'is_owned_by_current_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_owned_by_current_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _servingDescriptionMeta =
      const VerificationMeta('servingDescription');
  @override
  late final GeneratedColumn<String> servingDescription =
      GeneratedColumn<String>(
        'serving_description',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _servingGramsMeta = const VerificationMeta(
    'servingGrams',
  );
  @override
  late final GeneratedColumn<double> servingGrams = GeneratedColumn<double>(
    'serving_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caloriesPerServingMeta =
      const VerificationMeta('caloriesPerServing');
  @override
  late final GeneratedColumn<double> caloriesPerServing =
      GeneratedColumn<double>(
        'calories_per_serving',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _proteinGramsPerServingMeta =
      const VerificationMeta('proteinGramsPerServing');
  @override
  late final GeneratedColumn<double> proteinGramsPerServing =
      GeneratedColumn<double>(
        'protein_grams_per_serving',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _carbGramsPerServingMeta =
      const VerificationMeta('carbGramsPerServing');
  @override
  late final GeneratedColumn<double> carbGramsPerServing =
      GeneratedColumn<double>(
        'carb_grams_per_serving',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fatGramsPerServingMeta =
      const VerificationMeta('fatGramsPerServing');
  @override
  late final GeneratedColumn<double> fatGramsPerServing =
      GeneratedColumn<double>(
        'fat_grams_per_serving',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fiberGramsPerServingMeta =
      const VerificationMeta('fiberGramsPerServing');
  @override
  late final GeneratedColumn<double> fiberGramsPerServing =
      GeneratedColumn<double>(
        'fiber_grams_per_serving',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sodiumMgPerServingMeta =
      const VerificationMeta('sodiumMgPerServing');
  @override
  late final GeneratedColumn<double> sodiumMgPerServing =
      GeneratedColumn<double>(
        'sodium_mg_per_serving',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isEstimatedMeta = const VerificationMeta(
    'isEstimated',
  );
  @override
  late final GeneratedColumn<bool> isEstimated = GeneratedColumn<bool>(
    'is_estimated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_estimated" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    alternateName,
    brand,
    sourceType,
    isOwnedByCurrentUser,
    servingDescription,
    servingGrams,
    caloriesPerServing,
    proteinGramsPerServing,
    carbGramsPerServing,
    fatGramsPerServing,
    fiberGramsPerServing,
    sodiumMgPerServing,
    isEstimated,
    archivedAt,
    syncStatus,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('alternate_name')) {
      context.handle(
        _alternateNameMeta,
        alternateName.isAcceptableOrUnknown(
          data['alternate_name']!,
          _alternateNameMeta,
        ),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('is_owned_by_current_user')) {
      context.handle(
        _isOwnedByCurrentUserMeta,
        isOwnedByCurrentUser.isAcceptableOrUnknown(
          data['is_owned_by_current_user']!,
          _isOwnedByCurrentUserMeta,
        ),
      );
    }
    if (data.containsKey('serving_description')) {
      context.handle(
        _servingDescriptionMeta,
        servingDescription.isAcceptableOrUnknown(
          data['serving_description']!,
          _servingDescriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_servingDescriptionMeta);
    }
    if (data.containsKey('serving_grams')) {
      context.handle(
        _servingGramsMeta,
        servingGrams.isAcceptableOrUnknown(
          data['serving_grams']!,
          _servingGramsMeta,
        ),
      );
    }
    if (data.containsKey('calories_per_serving')) {
      context.handle(
        _caloriesPerServingMeta,
        caloriesPerServing.isAcceptableOrUnknown(
          data['calories_per_serving']!,
          _caloriesPerServingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caloriesPerServingMeta);
    }
    if (data.containsKey('protein_grams_per_serving')) {
      context.handle(
        _proteinGramsPerServingMeta,
        proteinGramsPerServing.isAcceptableOrUnknown(
          data['protein_grams_per_serving']!,
          _proteinGramsPerServingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinGramsPerServingMeta);
    }
    if (data.containsKey('carb_grams_per_serving')) {
      context.handle(
        _carbGramsPerServingMeta,
        carbGramsPerServing.isAcceptableOrUnknown(
          data['carb_grams_per_serving']!,
          _carbGramsPerServingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carbGramsPerServingMeta);
    }
    if (data.containsKey('fat_grams_per_serving')) {
      context.handle(
        _fatGramsPerServingMeta,
        fatGramsPerServing.isAcceptableOrUnknown(
          data['fat_grams_per_serving']!,
          _fatGramsPerServingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fatGramsPerServingMeta);
    }
    if (data.containsKey('fiber_grams_per_serving')) {
      context.handle(
        _fiberGramsPerServingMeta,
        fiberGramsPerServing.isAcceptableOrUnknown(
          data['fiber_grams_per_serving']!,
          _fiberGramsPerServingMeta,
        ),
      );
    }
    if (data.containsKey('sodium_mg_per_serving')) {
      context.handle(
        _sodiumMgPerServingMeta,
        sodiumMgPerServing.isAcceptableOrUnknown(
          data['sodium_mg_per_serving']!,
          _sodiumMgPerServingMeta,
        ),
      );
    }
    if (data.containsKey('is_estimated')) {
      context.handle(
        _isEstimatedMeta,
        isEstimated.isAcceptableOrUnknown(
          data['is_estimated']!,
          _isEstimatedMeta,
        ),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedFood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFood(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      alternateName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alternate_name'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      isOwnedByCurrentUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_owned_by_current_user'],
      )!,
      servingDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_description'],
      )!,
      servingGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_grams'],
      ),
      caloriesPerServing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories_per_serving'],
      )!,
      proteinGramsPerServing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_grams_per_serving'],
      )!,
      carbGramsPerServing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb_grams_per_serving'],
      )!,
      fatGramsPerServing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_grams_per_serving'],
      )!,
      fiberGramsPerServing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_grams_per_serving'],
      ),
      sodiumMgPerServing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium_mg_per_serving'],
      ),
      isEstimated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimated'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedFoodsTable createAlias(String alias) {
    return $CachedFoodsTable(attachedDatabase, alias);
  }
}

class CachedFood extends DataClass implements Insertable<CachedFood> {
  /// Local id (an idempotency key) until synced, then the server id —
  /// reconciled in place by [reconcileFoodId] so anything referencing this
  /// row by id (a meal entry, a saved-meal item) can be updated too.
  final String id;
  final String userId;
  final String name;
  final String? alternateName;
  final String? brand;
  final String sourceType;
  final bool isOwnedByCurrentUser;
  final String servingDescription;
  final double? servingGrams;
  final double caloriesPerServing;
  final double proteinGramsPerServing;
  final double carbGramsPerServing;
  final double fatGramsPerServing;
  final double? fiberGramsPerServing;
  final double? sodiumMgPerServing;
  final bool isEstimated;
  final DateTime? archivedAt;
  final String syncStatus;
  final DateTime updatedAt;
  const CachedFood({
    required this.id,
    required this.userId,
    required this.name,
    this.alternateName,
    this.brand,
    required this.sourceType,
    required this.isOwnedByCurrentUser,
    required this.servingDescription,
    this.servingGrams,
    required this.caloriesPerServing,
    required this.proteinGramsPerServing,
    required this.carbGramsPerServing,
    required this.fatGramsPerServing,
    this.fiberGramsPerServing,
    this.sodiumMgPerServing,
    required this.isEstimated,
    this.archivedAt,
    required this.syncStatus,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || alternateName != null) {
      map['alternate_name'] = Variable<String>(alternateName);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['source_type'] = Variable<String>(sourceType);
    map['is_owned_by_current_user'] = Variable<bool>(isOwnedByCurrentUser);
    map['serving_description'] = Variable<String>(servingDescription);
    if (!nullToAbsent || servingGrams != null) {
      map['serving_grams'] = Variable<double>(servingGrams);
    }
    map['calories_per_serving'] = Variable<double>(caloriesPerServing);
    map['protein_grams_per_serving'] = Variable<double>(proteinGramsPerServing);
    map['carb_grams_per_serving'] = Variable<double>(carbGramsPerServing);
    map['fat_grams_per_serving'] = Variable<double>(fatGramsPerServing);
    if (!nullToAbsent || fiberGramsPerServing != null) {
      map['fiber_grams_per_serving'] = Variable<double>(fiberGramsPerServing);
    }
    if (!nullToAbsent || sodiumMgPerServing != null) {
      map['sodium_mg_per_serving'] = Variable<double>(sodiumMgPerServing);
    }
    map['is_estimated'] = Variable<bool>(isEstimated);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedFoodsCompanion toCompanion(bool nullToAbsent) {
    return CachedFoodsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      alternateName: alternateName == null && nullToAbsent
          ? const Value.absent()
          : Value(alternateName),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      sourceType: Value(sourceType),
      isOwnedByCurrentUser: Value(isOwnedByCurrentUser),
      servingDescription: Value(servingDescription),
      servingGrams: servingGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(servingGrams),
      caloriesPerServing: Value(caloriesPerServing),
      proteinGramsPerServing: Value(proteinGramsPerServing),
      carbGramsPerServing: Value(carbGramsPerServing),
      fatGramsPerServing: Value(fatGramsPerServing),
      fiberGramsPerServing: fiberGramsPerServing == null && nullToAbsent
          ? const Value.absent()
          : Value(fiberGramsPerServing),
      sodiumMgPerServing: sodiumMgPerServing == null && nullToAbsent
          ? const Value.absent()
          : Value(sodiumMgPerServing),
      isEstimated: Value(isEstimated),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedFood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFood(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      alternateName: serializer.fromJson<String?>(json['alternateName']),
      brand: serializer.fromJson<String?>(json['brand']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      isOwnedByCurrentUser: serializer.fromJson<bool>(
        json['isOwnedByCurrentUser'],
      ),
      servingDescription: serializer.fromJson<String>(
        json['servingDescription'],
      ),
      servingGrams: serializer.fromJson<double?>(json['servingGrams']),
      caloriesPerServing: serializer.fromJson<double>(
        json['caloriesPerServing'],
      ),
      proteinGramsPerServing: serializer.fromJson<double>(
        json['proteinGramsPerServing'],
      ),
      carbGramsPerServing: serializer.fromJson<double>(
        json['carbGramsPerServing'],
      ),
      fatGramsPerServing: serializer.fromJson<double>(
        json['fatGramsPerServing'],
      ),
      fiberGramsPerServing: serializer.fromJson<double?>(
        json['fiberGramsPerServing'],
      ),
      sodiumMgPerServing: serializer.fromJson<double?>(
        json['sodiumMgPerServing'],
      ),
      isEstimated: serializer.fromJson<bool>(json['isEstimated']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'alternateName': serializer.toJson<String?>(alternateName),
      'brand': serializer.toJson<String?>(brand),
      'sourceType': serializer.toJson<String>(sourceType),
      'isOwnedByCurrentUser': serializer.toJson<bool>(isOwnedByCurrentUser),
      'servingDescription': serializer.toJson<String>(servingDescription),
      'servingGrams': serializer.toJson<double?>(servingGrams),
      'caloriesPerServing': serializer.toJson<double>(caloriesPerServing),
      'proteinGramsPerServing': serializer.toJson<double>(
        proteinGramsPerServing,
      ),
      'carbGramsPerServing': serializer.toJson<double>(carbGramsPerServing),
      'fatGramsPerServing': serializer.toJson<double>(fatGramsPerServing),
      'fiberGramsPerServing': serializer.toJson<double?>(fiberGramsPerServing),
      'sodiumMgPerServing': serializer.toJson<double?>(sodiumMgPerServing),
      'isEstimated': serializer.toJson<bool>(isEstimated),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedFood copyWith({
    String? id,
    String? userId,
    String? name,
    Value<String?> alternateName = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    String? sourceType,
    bool? isOwnedByCurrentUser,
    String? servingDescription,
    Value<double?> servingGrams = const Value.absent(),
    double? caloriesPerServing,
    double? proteinGramsPerServing,
    double? carbGramsPerServing,
    double? fatGramsPerServing,
    Value<double?> fiberGramsPerServing = const Value.absent(),
    Value<double?> sodiumMgPerServing = const Value.absent(),
    bool? isEstimated,
    Value<DateTime?> archivedAt = const Value.absent(),
    String? syncStatus,
    DateTime? updatedAt,
  }) => CachedFood(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    alternateName: alternateName.present
        ? alternateName.value
        : this.alternateName,
    brand: brand.present ? brand.value : this.brand,
    sourceType: sourceType ?? this.sourceType,
    isOwnedByCurrentUser: isOwnedByCurrentUser ?? this.isOwnedByCurrentUser,
    servingDescription: servingDescription ?? this.servingDescription,
    servingGrams: servingGrams.present ? servingGrams.value : this.servingGrams,
    caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
    proteinGramsPerServing:
        proteinGramsPerServing ?? this.proteinGramsPerServing,
    carbGramsPerServing: carbGramsPerServing ?? this.carbGramsPerServing,
    fatGramsPerServing: fatGramsPerServing ?? this.fatGramsPerServing,
    fiberGramsPerServing: fiberGramsPerServing.present
        ? fiberGramsPerServing.value
        : this.fiberGramsPerServing,
    sodiumMgPerServing: sodiumMgPerServing.present
        ? sodiumMgPerServing.value
        : this.sodiumMgPerServing,
    isEstimated: isEstimated ?? this.isEstimated,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedFood copyWithCompanion(CachedFoodsCompanion data) {
    return CachedFood(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      alternateName: data.alternateName.present
          ? data.alternateName.value
          : this.alternateName,
      brand: data.brand.present ? data.brand.value : this.brand,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      isOwnedByCurrentUser: data.isOwnedByCurrentUser.present
          ? data.isOwnedByCurrentUser.value
          : this.isOwnedByCurrentUser,
      servingDescription: data.servingDescription.present
          ? data.servingDescription.value
          : this.servingDescription,
      servingGrams: data.servingGrams.present
          ? data.servingGrams.value
          : this.servingGrams,
      caloriesPerServing: data.caloriesPerServing.present
          ? data.caloriesPerServing.value
          : this.caloriesPerServing,
      proteinGramsPerServing: data.proteinGramsPerServing.present
          ? data.proteinGramsPerServing.value
          : this.proteinGramsPerServing,
      carbGramsPerServing: data.carbGramsPerServing.present
          ? data.carbGramsPerServing.value
          : this.carbGramsPerServing,
      fatGramsPerServing: data.fatGramsPerServing.present
          ? data.fatGramsPerServing.value
          : this.fatGramsPerServing,
      fiberGramsPerServing: data.fiberGramsPerServing.present
          ? data.fiberGramsPerServing.value
          : this.fiberGramsPerServing,
      sodiumMgPerServing: data.sodiumMgPerServing.present
          ? data.sodiumMgPerServing.value
          : this.sodiumMgPerServing,
      isEstimated: data.isEstimated.present
          ? data.isEstimated.value
          : this.isEstimated,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFood(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('alternateName: $alternateName, ')
          ..write('brand: $brand, ')
          ..write('sourceType: $sourceType, ')
          ..write('isOwnedByCurrentUser: $isOwnedByCurrentUser, ')
          ..write('servingDescription: $servingDescription, ')
          ..write('servingGrams: $servingGrams, ')
          ..write('caloriesPerServing: $caloriesPerServing, ')
          ..write('proteinGramsPerServing: $proteinGramsPerServing, ')
          ..write('carbGramsPerServing: $carbGramsPerServing, ')
          ..write('fatGramsPerServing: $fatGramsPerServing, ')
          ..write('fiberGramsPerServing: $fiberGramsPerServing, ')
          ..write('sodiumMgPerServing: $sodiumMgPerServing, ')
          ..write('isEstimated: $isEstimated, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    alternateName,
    brand,
    sourceType,
    isOwnedByCurrentUser,
    servingDescription,
    servingGrams,
    caloriesPerServing,
    proteinGramsPerServing,
    carbGramsPerServing,
    fatGramsPerServing,
    fiberGramsPerServing,
    sodiumMgPerServing,
    isEstimated,
    archivedAt,
    syncStatus,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFood &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.alternateName == this.alternateName &&
          other.brand == this.brand &&
          other.sourceType == this.sourceType &&
          other.isOwnedByCurrentUser == this.isOwnedByCurrentUser &&
          other.servingDescription == this.servingDescription &&
          other.servingGrams == this.servingGrams &&
          other.caloriesPerServing == this.caloriesPerServing &&
          other.proteinGramsPerServing == this.proteinGramsPerServing &&
          other.carbGramsPerServing == this.carbGramsPerServing &&
          other.fatGramsPerServing == this.fatGramsPerServing &&
          other.fiberGramsPerServing == this.fiberGramsPerServing &&
          other.sodiumMgPerServing == this.sodiumMgPerServing &&
          other.isEstimated == this.isEstimated &&
          other.archivedAt == this.archivedAt &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt);
}

class CachedFoodsCompanion extends UpdateCompanion<CachedFood> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> alternateName;
  final Value<String?> brand;
  final Value<String> sourceType;
  final Value<bool> isOwnedByCurrentUser;
  final Value<String> servingDescription;
  final Value<double?> servingGrams;
  final Value<double> caloriesPerServing;
  final Value<double> proteinGramsPerServing;
  final Value<double> carbGramsPerServing;
  final Value<double> fatGramsPerServing;
  final Value<double?> fiberGramsPerServing;
  final Value<double?> sodiumMgPerServing;
  final Value<bool> isEstimated;
  final Value<DateTime?> archivedAt;
  final Value<String> syncStatus;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedFoodsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.alternateName = const Value.absent(),
    this.brand = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.isOwnedByCurrentUser = const Value.absent(),
    this.servingDescription = const Value.absent(),
    this.servingGrams = const Value.absent(),
    this.caloriesPerServing = const Value.absent(),
    this.proteinGramsPerServing = const Value.absent(),
    this.carbGramsPerServing = const Value.absent(),
    this.fatGramsPerServing = const Value.absent(),
    this.fiberGramsPerServing = const Value.absent(),
    this.sodiumMgPerServing = const Value.absent(),
    this.isEstimated = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFoodsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    this.alternateName = const Value.absent(),
    this.brand = const Value.absent(),
    required String sourceType,
    this.isOwnedByCurrentUser = const Value.absent(),
    required String servingDescription,
    this.servingGrams = const Value.absent(),
    required double caloriesPerServing,
    required double proteinGramsPerServing,
    required double carbGramsPerServing,
    required double fatGramsPerServing,
    this.fiberGramsPerServing = const Value.absent(),
    this.sodiumMgPerServing = const Value.absent(),
    this.isEstimated = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       sourceType = Value(sourceType),
       servingDescription = Value(servingDescription),
       caloriesPerServing = Value(caloriesPerServing),
       proteinGramsPerServing = Value(proteinGramsPerServing),
       carbGramsPerServing = Value(carbGramsPerServing),
       fatGramsPerServing = Value(fatGramsPerServing),
       updatedAt = Value(updatedAt);
  static Insertable<CachedFood> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? alternateName,
    Expression<String>? brand,
    Expression<String>? sourceType,
    Expression<bool>? isOwnedByCurrentUser,
    Expression<String>? servingDescription,
    Expression<double>? servingGrams,
    Expression<double>? caloriesPerServing,
    Expression<double>? proteinGramsPerServing,
    Expression<double>? carbGramsPerServing,
    Expression<double>? fatGramsPerServing,
    Expression<double>? fiberGramsPerServing,
    Expression<double>? sodiumMgPerServing,
    Expression<bool>? isEstimated,
    Expression<DateTime>? archivedAt,
    Expression<String>? syncStatus,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (alternateName != null) 'alternate_name': alternateName,
      if (brand != null) 'brand': brand,
      if (sourceType != null) 'source_type': sourceType,
      if (isOwnedByCurrentUser != null)
        'is_owned_by_current_user': isOwnedByCurrentUser,
      if (servingDescription != null) 'serving_description': servingDescription,
      if (servingGrams != null) 'serving_grams': servingGrams,
      if (caloriesPerServing != null)
        'calories_per_serving': caloriesPerServing,
      if (proteinGramsPerServing != null)
        'protein_grams_per_serving': proteinGramsPerServing,
      if (carbGramsPerServing != null)
        'carb_grams_per_serving': carbGramsPerServing,
      if (fatGramsPerServing != null)
        'fat_grams_per_serving': fatGramsPerServing,
      if (fiberGramsPerServing != null)
        'fiber_grams_per_serving': fiberGramsPerServing,
      if (sodiumMgPerServing != null)
        'sodium_mg_per_serving': sodiumMgPerServing,
      if (isEstimated != null) 'is_estimated': isEstimated,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFoodsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String?>? alternateName,
    Value<String?>? brand,
    Value<String>? sourceType,
    Value<bool>? isOwnedByCurrentUser,
    Value<String>? servingDescription,
    Value<double?>? servingGrams,
    Value<double>? caloriesPerServing,
    Value<double>? proteinGramsPerServing,
    Value<double>? carbGramsPerServing,
    Value<double>? fatGramsPerServing,
    Value<double?>? fiberGramsPerServing,
    Value<double?>? sodiumMgPerServing,
    Value<bool>? isEstimated,
    Value<DateTime?>? archivedAt,
    Value<String>? syncStatus,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedFoodsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      alternateName: alternateName ?? this.alternateName,
      brand: brand ?? this.brand,
      sourceType: sourceType ?? this.sourceType,
      isOwnedByCurrentUser: isOwnedByCurrentUser ?? this.isOwnedByCurrentUser,
      servingDescription: servingDescription ?? this.servingDescription,
      servingGrams: servingGrams ?? this.servingGrams,
      caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
      proteinGramsPerServing:
          proteinGramsPerServing ?? this.proteinGramsPerServing,
      carbGramsPerServing: carbGramsPerServing ?? this.carbGramsPerServing,
      fatGramsPerServing: fatGramsPerServing ?? this.fatGramsPerServing,
      fiberGramsPerServing: fiberGramsPerServing ?? this.fiberGramsPerServing,
      sodiumMgPerServing: sodiumMgPerServing ?? this.sodiumMgPerServing,
      isEstimated: isEstimated ?? this.isEstimated,
      archivedAt: archivedAt ?? this.archivedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (alternateName.present) {
      map['alternate_name'] = Variable<String>(alternateName.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (isOwnedByCurrentUser.present) {
      map['is_owned_by_current_user'] = Variable<bool>(
        isOwnedByCurrentUser.value,
      );
    }
    if (servingDescription.present) {
      map['serving_description'] = Variable<String>(servingDescription.value);
    }
    if (servingGrams.present) {
      map['serving_grams'] = Variable<double>(servingGrams.value);
    }
    if (caloriesPerServing.present) {
      map['calories_per_serving'] = Variable<double>(caloriesPerServing.value);
    }
    if (proteinGramsPerServing.present) {
      map['protein_grams_per_serving'] = Variable<double>(
        proteinGramsPerServing.value,
      );
    }
    if (carbGramsPerServing.present) {
      map['carb_grams_per_serving'] = Variable<double>(
        carbGramsPerServing.value,
      );
    }
    if (fatGramsPerServing.present) {
      map['fat_grams_per_serving'] = Variable<double>(fatGramsPerServing.value);
    }
    if (fiberGramsPerServing.present) {
      map['fiber_grams_per_serving'] = Variable<double>(
        fiberGramsPerServing.value,
      );
    }
    if (sodiumMgPerServing.present) {
      map['sodium_mg_per_serving'] = Variable<double>(sodiumMgPerServing.value);
    }
    if (isEstimated.present) {
      map['is_estimated'] = Variable<bool>(isEstimated.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFoodsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('alternateName: $alternateName, ')
          ..write('brand: $brand, ')
          ..write('sourceType: $sourceType, ')
          ..write('isOwnedByCurrentUser: $isOwnedByCurrentUser, ')
          ..write('servingDescription: $servingDescription, ')
          ..write('servingGrams: $servingGrams, ')
          ..write('caloriesPerServing: $caloriesPerServing, ')
          ..write('proteinGramsPerServing: $proteinGramsPerServing, ')
          ..write('carbGramsPerServing: $carbGramsPerServing, ')
          ..write('fatGramsPerServing: $fatGramsPerServing, ')
          ..write('fiberGramsPerServing: $fiberGramsPerServing, ')
          ..write('sodiumMgPerServing: $sodiumMgPerServing, ')
          ..write('isEstimated: $isEstimated, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedFoodServingsTable extends CachedFoodServings
    with TableInfo<$CachedFoodServingsTable, CachedFoodServing> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFoodServingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, foodId, label, grams, isDefault];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_food_servings';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFoodServing> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedFoodServing map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFoodServing(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $CachedFoodServingsTable createAlias(String alias) {
    return $CachedFoodServingsTable(attachedDatabase, alias);
  }
}

class CachedFoodServing extends DataClass
    implements Insertable<CachedFoodServing> {
  final String id;
  final String foodId;
  final String label;
  final double? grams;
  final bool isDefault;
  const CachedFoodServing({
    required this.id,
    required this.foodId,
    required this.label,
    this.grams,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['food_id'] = Variable<String>(foodId);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || grams != null) {
      map['grams'] = Variable<double>(grams);
    }
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  CachedFoodServingsCompanion toCompanion(bool nullToAbsent) {
    return CachedFoodServingsCompanion(
      id: Value(id),
      foodId: Value(foodId),
      label: Value(label),
      grams: grams == null && nullToAbsent
          ? const Value.absent()
          : Value(grams),
      isDefault: Value(isDefault),
    );
  }

  factory CachedFoodServing.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFoodServing(
      id: serializer.fromJson<String>(json['id']),
      foodId: serializer.fromJson<String>(json['foodId']),
      label: serializer.fromJson<String>(json['label']),
      grams: serializer.fromJson<double?>(json['grams']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'foodId': serializer.toJson<String>(foodId),
      'label': serializer.toJson<String>(label),
      'grams': serializer.toJson<double?>(grams),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  CachedFoodServing copyWith({
    String? id,
    String? foodId,
    String? label,
    Value<double?> grams = const Value.absent(),
    bool? isDefault,
  }) => CachedFoodServing(
    id: id ?? this.id,
    foodId: foodId ?? this.foodId,
    label: label ?? this.label,
    grams: grams.present ? grams.value : this.grams,
    isDefault: isDefault ?? this.isDefault,
  );
  CachedFoodServing copyWithCompanion(CachedFoodServingsCompanion data) {
    return CachedFoodServing(
      id: data.id.present ? data.id.value : this.id,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      label: data.label.present ? data.label.value : this.label,
      grams: data.grams.present ? data.grams.value : this.grams,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFoodServing(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('label: $label, ')
          ..write('grams: $grams, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, foodId, label, grams, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFoodServing &&
          other.id == this.id &&
          other.foodId == this.foodId &&
          other.label == this.label &&
          other.grams == this.grams &&
          other.isDefault == this.isDefault);
}

class CachedFoodServingsCompanion extends UpdateCompanion<CachedFoodServing> {
  final Value<String> id;
  final Value<String> foodId;
  final Value<String> label;
  final Value<double?> grams;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const CachedFoodServingsCompanion({
    this.id = const Value.absent(),
    this.foodId = const Value.absent(),
    this.label = const Value.absent(),
    this.grams = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFoodServingsCompanion.insert({
    required String id,
    required String foodId,
    required String label,
    this.grams = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       foodId = Value(foodId),
       label = Value(label);
  static Insertable<CachedFoodServing> custom({
    Expression<String>? id,
    Expression<String>? foodId,
    Expression<String>? label,
    Expression<double>? grams,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (foodId != null) 'food_id': foodId,
      if (label != null) 'label': label,
      if (grams != null) 'grams': grams,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFoodServingsCompanion copyWith({
    Value<String>? id,
    Value<String>? foodId,
    Value<String>? label,
    Value<double?>? grams,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return CachedFoodServingsCompanion(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      label: label ?? this.label,
      grams: grams ?? this.grams,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFoodServingsCompanion(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('label: $label, ')
          ..write('grams: $grams, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedMealEntriesTable extends CachedMealEntries
    with TableInfo<$CachedMealEntriesTable, CachedMealEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMealEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodNameMeta = const VerificationMeta(
    'foodName',
  );
  @override
  late final GeneratedColumn<String> foodName = GeneratedColumn<String>(
    'food_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodBrandMeta = const VerificationMeta(
    'foodBrand',
  );
  @override
  late final GeneratedColumn<String> foodBrand = GeneratedColumn<String>(
    'food_brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _foodIsEstimatedMeta = const VerificationMeta(
    'foodIsEstimated',
  );
  @override
  late final GeneratedColumn<bool> foodIsEstimated = GeneratedColumn<bool>(
    'food_is_estimated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("food_is_estimated" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _foodServingIdMeta = const VerificationMeta(
    'foodServingId',
  );
  @override
  late final GeneratedColumn<String> foodServingId = GeneratedColumn<String>(
    'food_serving_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _foodServingLabelMeta = const VerificationMeta(
    'foodServingLabel',
  );
  @override
  late final GeneratedColumn<String> foodServingLabel = GeneratedColumn<String>(
    'food_serving_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mealTypeMeta = const VerificationMeta(
    'mealType',
  );
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
    'meal_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<double> calories = GeneratedColumn<double>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGramsMeta = const VerificationMeta(
    'proteinGrams',
  );
  @override
  late final GeneratedColumn<double> proteinGrams = GeneratedColumn<double>(
    'protein_grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbGramsMeta = const VerificationMeta(
    'carbGrams',
  );
  @override
  late final GeneratedColumn<double> carbGrams = GeneratedColumn<double>(
    'carb_grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGramsMeta = const VerificationMeta(
    'fatGrams',
  );
  @override
  late final GeneratedColumn<double> fatGrams = GeneratedColumn<double>(
    'fat_grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fiberGramsMeta = const VerificationMeta(
    'fiberGrams',
  );
  @override
  late final GeneratedColumn<double> fiberGrams = GeneratedColumn<double>(
    'fiber_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    userId,
    foodId,
    foodName,
    foodBrand,
    foodIsEstimated,
    foodServingId,
    foodServingLabel,
    mealType,
    date,
    quantity,
    calories,
    proteinGrams,
    carbGrams,
    fatGrams,
    fiberGrams,
    notes,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_meal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMealEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('food_name')) {
      context.handle(
        _foodNameMeta,
        foodName.isAcceptableOrUnknown(data['food_name']!, _foodNameMeta),
      );
    } else if (isInserting) {
      context.missing(_foodNameMeta);
    }
    if (data.containsKey('food_brand')) {
      context.handle(
        _foodBrandMeta,
        foodBrand.isAcceptableOrUnknown(data['food_brand']!, _foodBrandMeta),
      );
    }
    if (data.containsKey('food_is_estimated')) {
      context.handle(
        _foodIsEstimatedMeta,
        foodIsEstimated.isAcceptableOrUnknown(
          data['food_is_estimated']!,
          _foodIsEstimatedMeta,
        ),
      );
    }
    if (data.containsKey('food_serving_id')) {
      context.handle(
        _foodServingIdMeta,
        foodServingId.isAcceptableOrUnknown(
          data['food_serving_id']!,
          _foodServingIdMeta,
        ),
      );
    }
    if (data.containsKey('food_serving_label')) {
      context.handle(
        _foodServingLabelMeta,
        foodServingLabel.isAcceptableOrUnknown(
          data['food_serving_label']!,
          _foodServingLabelMeta,
        ),
      );
    }
    if (data.containsKey('meal_type')) {
      context.handle(
        _mealTypeMeta,
        mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mealTypeMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('protein_grams')) {
      context.handle(
        _proteinGramsMeta,
        proteinGrams.isAcceptableOrUnknown(
          data['protein_grams']!,
          _proteinGramsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinGramsMeta);
    }
    if (data.containsKey('carb_grams')) {
      context.handle(
        _carbGramsMeta,
        carbGrams.isAcceptableOrUnknown(data['carb_grams']!, _carbGramsMeta),
      );
    } else if (isInserting) {
      context.missing(_carbGramsMeta);
    }
    if (data.containsKey('fat_grams')) {
      context.handle(
        _fatGramsMeta,
        fatGrams.isAcceptableOrUnknown(data['fat_grams']!, _fatGramsMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGramsMeta);
    }
    if (data.containsKey('fiber_grams')) {
      context.handle(
        _fiberGramsMeta,
        fiberGrams.isAcceptableOrUnknown(data['fiber_grams']!, _fiberGramsMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMealEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMealEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      )!,
      foodName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_name'],
      )!,
      foodBrand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_brand'],
      ),
      foodIsEstimated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}food_is_estimated'],
      )!,
      foodServingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_serving_id'],
      ),
      foodServingLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_serving_label'],
      ),
      mealType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_type'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories'],
      )!,
      proteinGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_grams'],
      )!,
      carbGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb_grams'],
      )!,
      fatGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_grams'],
      )!,
      fiberGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_grams'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedMealEntriesTable createAlias(String alias) {
    return $CachedMealEntriesTable(attachedDatabase, alias);
  }
}

class CachedMealEntry extends DataClass implements Insertable<CachedMealEntry> {
  /// Local id until synced; [serverId] holds the authoritative id once the
  /// create has landed. Kept distinct (rather than overwriting [id]) so a
  /// delete enqueued against a not-yet-synced row can still find its own
  /// outbox entry (same id) to discard outright instead of sending a
  /// network call for something the server has never heard of.
  final String id;
  final String? serverId;
  final String userId;
  final String foodId;
  final String foodName;
  final String? foodBrand;
  final bool foodIsEstimated;
  final String? foodServingId;
  final String? foodServingLabel;
  final String mealType;
  final String date;
  final double quantity;
  final double calories;
  final double proteinGrams;
  final double carbGrams;
  final double fatGrams;
  final double? fiberGrams;
  final String? notes;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CachedMealEntry({
    required this.id,
    this.serverId,
    required this.userId,
    required this.foodId,
    required this.foodName,
    this.foodBrand,
    required this.foodIsEstimated,
    this.foodServingId,
    this.foodServingLabel,
    required this.mealType,
    required this.date,
    required this.quantity,
    required this.calories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    this.fiberGrams,
    this.notes,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['user_id'] = Variable<String>(userId);
    map['food_id'] = Variable<String>(foodId);
    map['food_name'] = Variable<String>(foodName);
    if (!nullToAbsent || foodBrand != null) {
      map['food_brand'] = Variable<String>(foodBrand);
    }
    map['food_is_estimated'] = Variable<bool>(foodIsEstimated);
    if (!nullToAbsent || foodServingId != null) {
      map['food_serving_id'] = Variable<String>(foodServingId);
    }
    if (!nullToAbsent || foodServingLabel != null) {
      map['food_serving_label'] = Variable<String>(foodServingLabel);
    }
    map['meal_type'] = Variable<String>(mealType);
    map['date'] = Variable<String>(date);
    map['quantity'] = Variable<double>(quantity);
    map['calories'] = Variable<double>(calories);
    map['protein_grams'] = Variable<double>(proteinGrams);
    map['carb_grams'] = Variable<double>(carbGrams);
    map['fat_grams'] = Variable<double>(fatGrams);
    if (!nullToAbsent || fiberGrams != null) {
      map['fiber_grams'] = Variable<double>(fiberGrams);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedMealEntriesCompanion toCompanion(bool nullToAbsent) {
    return CachedMealEntriesCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      userId: Value(userId),
      foodId: Value(foodId),
      foodName: Value(foodName),
      foodBrand: foodBrand == null && nullToAbsent
          ? const Value.absent()
          : Value(foodBrand),
      foodIsEstimated: Value(foodIsEstimated),
      foodServingId: foodServingId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodServingId),
      foodServingLabel: foodServingLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(foodServingLabel),
      mealType: Value(mealType),
      date: Value(date),
      quantity: Value(quantity),
      calories: Value(calories),
      proteinGrams: Value(proteinGrams),
      carbGrams: Value(carbGrams),
      fatGrams: Value(fatGrams),
      fiberGrams: fiberGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(fiberGrams),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedMealEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMealEntry(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      userId: serializer.fromJson<String>(json['userId']),
      foodId: serializer.fromJson<String>(json['foodId']),
      foodName: serializer.fromJson<String>(json['foodName']),
      foodBrand: serializer.fromJson<String?>(json['foodBrand']),
      foodIsEstimated: serializer.fromJson<bool>(json['foodIsEstimated']),
      foodServingId: serializer.fromJson<String?>(json['foodServingId']),
      foodServingLabel: serializer.fromJson<String?>(json['foodServingLabel']),
      mealType: serializer.fromJson<String>(json['mealType']),
      date: serializer.fromJson<String>(json['date']),
      quantity: serializer.fromJson<double>(json['quantity']),
      calories: serializer.fromJson<double>(json['calories']),
      proteinGrams: serializer.fromJson<double>(json['proteinGrams']),
      carbGrams: serializer.fromJson<double>(json['carbGrams']),
      fatGrams: serializer.fromJson<double>(json['fatGrams']),
      fiberGrams: serializer.fromJson<double?>(json['fiberGrams']),
      notes: serializer.fromJson<String?>(json['notes']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'userId': serializer.toJson<String>(userId),
      'foodId': serializer.toJson<String>(foodId),
      'foodName': serializer.toJson<String>(foodName),
      'foodBrand': serializer.toJson<String?>(foodBrand),
      'foodIsEstimated': serializer.toJson<bool>(foodIsEstimated),
      'foodServingId': serializer.toJson<String?>(foodServingId),
      'foodServingLabel': serializer.toJson<String?>(foodServingLabel),
      'mealType': serializer.toJson<String>(mealType),
      'date': serializer.toJson<String>(date),
      'quantity': serializer.toJson<double>(quantity),
      'calories': serializer.toJson<double>(calories),
      'proteinGrams': serializer.toJson<double>(proteinGrams),
      'carbGrams': serializer.toJson<double>(carbGrams),
      'fatGrams': serializer.toJson<double>(fatGrams),
      'fiberGrams': serializer.toJson<double?>(fiberGrams),
      'notes': serializer.toJson<String?>(notes),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedMealEntry copyWith({
    String? id,
    Value<String?> serverId = const Value.absent(),
    String? userId,
    String? foodId,
    String? foodName,
    Value<String?> foodBrand = const Value.absent(),
    bool? foodIsEstimated,
    Value<String?> foodServingId = const Value.absent(),
    Value<String?> foodServingLabel = const Value.absent(),
    String? mealType,
    String? date,
    double? quantity,
    double? calories,
    double? proteinGrams,
    double? carbGrams,
    double? fatGrams,
    Value<double?> fiberGrams = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CachedMealEntry(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    userId: userId ?? this.userId,
    foodId: foodId ?? this.foodId,
    foodName: foodName ?? this.foodName,
    foodBrand: foodBrand.present ? foodBrand.value : this.foodBrand,
    foodIsEstimated: foodIsEstimated ?? this.foodIsEstimated,
    foodServingId: foodServingId.present
        ? foodServingId.value
        : this.foodServingId,
    foodServingLabel: foodServingLabel.present
        ? foodServingLabel.value
        : this.foodServingLabel,
    mealType: mealType ?? this.mealType,
    date: date ?? this.date,
    quantity: quantity ?? this.quantity,
    calories: calories ?? this.calories,
    proteinGrams: proteinGrams ?? this.proteinGrams,
    carbGrams: carbGrams ?? this.carbGrams,
    fatGrams: fatGrams ?? this.fatGrams,
    fiberGrams: fiberGrams.present ? fiberGrams.value : this.fiberGrams,
    notes: notes.present ? notes.value : this.notes,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedMealEntry copyWithCompanion(CachedMealEntriesCompanion data) {
    return CachedMealEntry(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      userId: data.userId.present ? data.userId.value : this.userId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      foodName: data.foodName.present ? data.foodName.value : this.foodName,
      foodBrand: data.foodBrand.present ? data.foodBrand.value : this.foodBrand,
      foodIsEstimated: data.foodIsEstimated.present
          ? data.foodIsEstimated.value
          : this.foodIsEstimated,
      foodServingId: data.foodServingId.present
          ? data.foodServingId.value
          : this.foodServingId,
      foodServingLabel: data.foodServingLabel.present
          ? data.foodServingLabel.value
          : this.foodServingLabel,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      date: data.date.present ? data.date.value : this.date,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      calories: data.calories.present ? data.calories.value : this.calories,
      proteinGrams: data.proteinGrams.present
          ? data.proteinGrams.value
          : this.proteinGrams,
      carbGrams: data.carbGrams.present ? data.carbGrams.value : this.carbGrams,
      fatGrams: data.fatGrams.present ? data.fatGrams.value : this.fatGrams,
      fiberGrams: data.fiberGrams.present
          ? data.fiberGrams.value
          : this.fiberGrams,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMealEntry(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('foodId: $foodId, ')
          ..write('foodName: $foodName, ')
          ..write('foodBrand: $foodBrand, ')
          ..write('foodIsEstimated: $foodIsEstimated, ')
          ..write('foodServingId: $foodServingId, ')
          ..write('foodServingLabel: $foodServingLabel, ')
          ..write('mealType: $mealType, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('calories: $calories, ')
          ..write('proteinGrams: $proteinGrams, ')
          ..write('carbGrams: $carbGrams, ')
          ..write('fatGrams: $fatGrams, ')
          ..write('fiberGrams: $fiberGrams, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    serverId,
    userId,
    foodId,
    foodName,
    foodBrand,
    foodIsEstimated,
    foodServingId,
    foodServingLabel,
    mealType,
    date,
    quantity,
    calories,
    proteinGrams,
    carbGrams,
    fatGrams,
    fiberGrams,
    notes,
    syncStatus,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMealEntry &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.userId == this.userId &&
          other.foodId == this.foodId &&
          other.foodName == this.foodName &&
          other.foodBrand == this.foodBrand &&
          other.foodIsEstimated == this.foodIsEstimated &&
          other.foodServingId == this.foodServingId &&
          other.foodServingLabel == this.foodServingLabel &&
          other.mealType == this.mealType &&
          other.date == this.date &&
          other.quantity == this.quantity &&
          other.calories == this.calories &&
          other.proteinGrams == this.proteinGrams &&
          other.carbGrams == this.carbGrams &&
          other.fatGrams == this.fatGrams &&
          other.fiberGrams == this.fiberGrams &&
          other.notes == this.notes &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CachedMealEntriesCompanion extends UpdateCompanion<CachedMealEntry> {
  final Value<String> id;
  final Value<String?> serverId;
  final Value<String> userId;
  final Value<String> foodId;
  final Value<String> foodName;
  final Value<String?> foodBrand;
  final Value<bool> foodIsEstimated;
  final Value<String?> foodServingId;
  final Value<String?> foodServingLabel;
  final Value<String> mealType;
  final Value<String> date;
  final Value<double> quantity;
  final Value<double> calories;
  final Value<double> proteinGrams;
  final Value<double> carbGrams;
  final Value<double> fatGrams;
  final Value<double?> fiberGrams;
  final Value<String?> notes;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedMealEntriesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.foodName = const Value.absent(),
    this.foodBrand = const Value.absent(),
    this.foodIsEstimated = const Value.absent(),
    this.foodServingId = const Value.absent(),
    this.foodServingLabel = const Value.absent(),
    this.mealType = const Value.absent(),
    this.date = const Value.absent(),
    this.quantity = const Value.absent(),
    this.calories = const Value.absent(),
    this.proteinGrams = const Value.absent(),
    this.carbGrams = const Value.absent(),
    this.fatGrams = const Value.absent(),
    this.fiberGrams = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMealEntriesCompanion.insert({
    required String id,
    this.serverId = const Value.absent(),
    required String userId,
    required String foodId,
    required String foodName,
    this.foodBrand = const Value.absent(),
    this.foodIsEstimated = const Value.absent(),
    this.foodServingId = const Value.absent(),
    this.foodServingLabel = const Value.absent(),
    required String mealType,
    required String date,
    required double quantity,
    required double calories,
    required double proteinGrams,
    required double carbGrams,
    required double fatGrams,
    this.fiberGrams = const Value.absent(),
    this.notes = const Value.absent(),
    required String syncStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       foodId = Value(foodId),
       foodName = Value(foodName),
       mealType = Value(mealType),
       date = Value(date),
       quantity = Value(quantity),
       calories = Value(calories),
       proteinGrams = Value(proteinGrams),
       carbGrams = Value(carbGrams),
       fatGrams = Value(fatGrams),
       syncStatus = Value(syncStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedMealEntry> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? userId,
    Expression<String>? foodId,
    Expression<String>? foodName,
    Expression<String>? foodBrand,
    Expression<bool>? foodIsEstimated,
    Expression<String>? foodServingId,
    Expression<String>? foodServingLabel,
    Expression<String>? mealType,
    Expression<String>? date,
    Expression<double>? quantity,
    Expression<double>? calories,
    Expression<double>? proteinGrams,
    Expression<double>? carbGrams,
    Expression<double>? fatGrams,
    Expression<double>? fiberGrams,
    Expression<String>? notes,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (userId != null) 'user_id': userId,
      if (foodId != null) 'food_id': foodId,
      if (foodName != null) 'food_name': foodName,
      if (foodBrand != null) 'food_brand': foodBrand,
      if (foodIsEstimated != null) 'food_is_estimated': foodIsEstimated,
      if (foodServingId != null) 'food_serving_id': foodServingId,
      if (foodServingLabel != null) 'food_serving_label': foodServingLabel,
      if (mealType != null) 'meal_type': mealType,
      if (date != null) 'date': date,
      if (quantity != null) 'quantity': quantity,
      if (calories != null) 'calories': calories,
      if (proteinGrams != null) 'protein_grams': proteinGrams,
      if (carbGrams != null) 'carb_grams': carbGrams,
      if (fatGrams != null) 'fat_grams': fatGrams,
      if (fiberGrams != null) 'fiber_grams': fiberGrams,
      if (notes != null) 'notes': notes,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMealEntriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? serverId,
    Value<String>? userId,
    Value<String>? foodId,
    Value<String>? foodName,
    Value<String?>? foodBrand,
    Value<bool>? foodIsEstimated,
    Value<String?>? foodServingId,
    Value<String?>? foodServingLabel,
    Value<String>? mealType,
    Value<String>? date,
    Value<double>? quantity,
    Value<double>? calories,
    Value<double>? proteinGrams,
    Value<double>? carbGrams,
    Value<double>? fatGrams,
    Value<double?>? fiberGrams,
    Value<String?>? notes,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedMealEntriesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      foodBrand: foodBrand ?? this.foodBrand,
      foodIsEstimated: foodIsEstimated ?? this.foodIsEstimated,
      foodServingId: foodServingId ?? this.foodServingId,
      foodServingLabel: foodServingLabel ?? this.foodServingLabel,
      mealType: mealType ?? this.mealType,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbGrams: carbGrams ?? this.carbGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (foodName.present) {
      map['food_name'] = Variable<String>(foodName.value);
    }
    if (foodBrand.present) {
      map['food_brand'] = Variable<String>(foodBrand.value);
    }
    if (foodIsEstimated.present) {
      map['food_is_estimated'] = Variable<bool>(foodIsEstimated.value);
    }
    if (foodServingId.present) {
      map['food_serving_id'] = Variable<String>(foodServingId.value);
    }
    if (foodServingLabel.present) {
      map['food_serving_label'] = Variable<String>(foodServingLabel.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (calories.present) {
      map['calories'] = Variable<double>(calories.value);
    }
    if (proteinGrams.present) {
      map['protein_grams'] = Variable<double>(proteinGrams.value);
    }
    if (carbGrams.present) {
      map['carb_grams'] = Variable<double>(carbGrams.value);
    }
    if (fatGrams.present) {
      map['fat_grams'] = Variable<double>(fatGrams.value);
    }
    if (fiberGrams.present) {
      map['fiber_grams'] = Variable<double>(fiberGrams.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMealEntriesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('foodId: $foodId, ')
          ..write('foodName: $foodName, ')
          ..write('foodBrand: $foodBrand, ')
          ..write('foodIsEstimated: $foodIsEstimated, ')
          ..write('foodServingId: $foodServingId, ')
          ..write('foodServingLabel: $foodServingLabel, ')
          ..write('mealType: $mealType, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('calories: $calories, ')
          ..write('proteinGrams: $proteinGrams, ')
          ..write('carbGrams: $carbGrams, ')
          ..write('fatGrams: $fatGrams, ')
          ..write('fiberGrams: $fiberGrams, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSavedMealsTable extends CachedSavedMeals
    with TableInfo<$CachedSavedMealsTable, CachedSavedMeal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSavedMealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    userId,
    name,
    itemsJson,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_saved_meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSavedMeal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_itemsJsonMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedSavedMeal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSavedMeal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedSavedMealsTable createAlias(String alias) {
    return $CachedSavedMealsTable(attachedDatabase, alias);
  }
}

class CachedSavedMeal extends DataClass implements Insertable<CachedSavedMeal> {
  final String id;
  final String? serverId;
  final String userId;
  final String name;

  /// Encoded `List<Map>` of `{id, foodId, foodName, foodBrand,
  /// foodIsEstimated, foodServingId, foodServingLabel, quantity}` — items
  /// are only ever read/written as a whole, so a nested table would add
  /// join complexity with no real benefit here.
  final String itemsJson;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CachedSavedMeal({
    required this.id,
    this.serverId,
    required this.userId,
    required this.name,
    required this.itemsJson,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['items_json'] = Variable<String>(itemsJson);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedSavedMealsCompanion toCompanion(bool nullToAbsent) {
    return CachedSavedMealsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      userId: Value(userId),
      name: Value(name),
      itemsJson: Value(itemsJson),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedSavedMeal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSavedMeal(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedSavedMeal copyWith({
    String? id,
    Value<String?> serverId = const Value.absent(),
    String? userId,
    String? name,
    String? itemsJson,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CachedSavedMeal(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    itemsJson: itemsJson ?? this.itemsJson,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedSavedMeal copyWithCompanion(CachedSavedMealsCompanion data) {
    return CachedSavedMeal(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSavedMeal(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    userId,
    name,
    itemsJson,
    syncStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSavedMeal &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.itemsJson == this.itemsJson &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CachedSavedMealsCompanion extends UpdateCompanion<CachedSavedMeal> {
  final Value<String> id;
  final Value<String?> serverId;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> itemsJson;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedSavedMealsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSavedMealsCompanion.insert({
    required String id,
    this.serverId = const Value.absent(),
    required String userId,
    required String name,
    required String itemsJson,
    required String syncStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       itemsJson = Value(itemsJson),
       syncStatus = Value(syncStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedSavedMeal> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? itemsJson,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (itemsJson != null) 'items_json': itemsJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSavedMealsCompanion copyWith({
    Value<String>? id,
    Value<String?>? serverId,
    Value<String>? userId,
    Value<String>? name,
    Value<String>? itemsJson,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedSavedMealsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      itemsJson: itemsJson ?? this.itemsJson,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSavedMealsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedWaterEntriesTable extends CachedWaterEntries
    with TableInfo<$CachedWaterEntriesTable, CachedWaterEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedWaterEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMlMeta = const VerificationMeta(
    'amountMl',
  );
  @override
  late final GeneratedColumn<int> amountMl = GeneratedColumn<int>(
    'amount_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    userId,
    date,
    amountMl,
    loggedAt,
    syncStatus,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_water_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedWaterEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount_ml')) {
      context.handle(
        _amountMlMeta,
        amountMl.isAcceptableOrUnknown(data['amount_ml']!, _amountMlMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMlMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedWaterEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedWaterEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      amountMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_ml'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedWaterEntriesTable createAlias(String alias) {
    return $CachedWaterEntriesTable(attachedDatabase, alias);
  }
}

class CachedWaterEntry extends DataClass
    implements Insertable<CachedWaterEntry> {
  final String id;
  final String? serverId;
  final String userId;
  final String date;
  final int amountMl;
  final DateTime loggedAt;
  final String syncStatus;
  final DateTime updatedAt;
  const CachedWaterEntry({
    required this.id,
    this.serverId,
    required this.userId,
    required this.date,
    required this.amountMl,
    required this.loggedAt,
    required this.syncStatus,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['user_id'] = Variable<String>(userId);
    map['date'] = Variable<String>(date);
    map['amount_ml'] = Variable<int>(amountMl);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedWaterEntriesCompanion toCompanion(bool nullToAbsent) {
    return CachedWaterEntriesCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      userId: Value(userId),
      date: Value(date),
      amountMl: Value(amountMl),
      loggedAt: Value(loggedAt),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedWaterEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedWaterEntry(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      userId: serializer.fromJson<String>(json['userId']),
      date: serializer.fromJson<String>(json['date']),
      amountMl: serializer.fromJson<int>(json['amountMl']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'userId': serializer.toJson<String>(userId),
      'date': serializer.toJson<String>(date),
      'amountMl': serializer.toJson<int>(amountMl),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedWaterEntry copyWith({
    String? id,
    Value<String?> serverId = const Value.absent(),
    String? userId,
    String? date,
    int? amountMl,
    DateTime? loggedAt,
    String? syncStatus,
    DateTime? updatedAt,
  }) => CachedWaterEntry(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    userId: userId ?? this.userId,
    date: date ?? this.date,
    amountMl: amountMl ?? this.amountMl,
    loggedAt: loggedAt ?? this.loggedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedWaterEntry copyWithCompanion(CachedWaterEntriesCompanion data) {
    return CachedWaterEntry(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      userId: data.userId.present ? data.userId.value : this.userId,
      date: data.date.present ? data.date.value : this.date,
      amountMl: data.amountMl.present ? data.amountMl.value : this.amountMl,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedWaterEntry(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('date: $date, ')
          ..write('amountMl: $amountMl, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    userId,
    date,
    amountMl,
    loggedAt,
    syncStatus,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedWaterEntry &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.userId == this.userId &&
          other.date == this.date &&
          other.amountMl == this.amountMl &&
          other.loggedAt == this.loggedAt &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt);
}

class CachedWaterEntriesCompanion extends UpdateCompanion<CachedWaterEntry> {
  final Value<String> id;
  final Value<String?> serverId;
  final Value<String> userId;
  final Value<String> date;
  final Value<int> amountMl;
  final Value<DateTime> loggedAt;
  final Value<String> syncStatus;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedWaterEntriesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
    this.date = const Value.absent(),
    this.amountMl = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedWaterEntriesCompanion.insert({
    required String id,
    this.serverId = const Value.absent(),
    required String userId,
    required String date,
    required int amountMl,
    required DateTime loggedAt,
    required String syncStatus,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       date = Value(date),
       amountMl = Value(amountMl),
       loggedAt = Value(loggedAt),
       syncStatus = Value(syncStatus),
       updatedAt = Value(updatedAt);
  static Insertable<CachedWaterEntry> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? userId,
    Expression<String>? date,
    Expression<int>? amountMl,
    Expression<DateTime>? loggedAt,
    Expression<String>? syncStatus,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (userId != null) 'user_id': userId,
      if (date != null) 'date': date,
      if (amountMl != null) 'amount_ml': amountMl,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedWaterEntriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? serverId,
    Value<String>? userId,
    Value<String>? date,
    Value<int>? amountMl,
    Value<DateTime>? loggedAt,
    Value<String>? syncStatus,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedWaterEntriesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      amountMl: amountMl ?? this.amountMl,
      loggedAt: loggedAt ?? this.loggedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (amountMl.present) {
      map['amount_ml'] = Variable<int>(amountMl.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedWaterEntriesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('date: $date, ')
          ..write('amountMl: $amountMl, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedMacroTargetsTable extends CachedMacroTargets
    with TableInfo<$CachedMacroTargetsTable, CachedMacroTarget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMacroTargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calorieTargetMeta = const VerificationMeta(
    'calorieTarget',
  );
  @override
  late final GeneratedColumn<int> calorieTarget = GeneratedColumn<int>(
    'calorie_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGramsTargetMeta =
      const VerificationMeta('proteinGramsTarget');
  @override
  late final GeneratedColumn<int> proteinGramsTarget = GeneratedColumn<int>(
    'protein_grams_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbGramsTargetMeta = const VerificationMeta(
    'carbGramsTarget',
  );
  @override
  late final GeneratedColumn<int> carbGramsTarget = GeneratedColumn<int>(
    'carb_grams_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGramsTargetMeta = const VerificationMeta(
    'fatGramsTarget',
  );
  @override
  late final GeneratedColumn<int> fatGramsTarget = GeneratedColumn<int>(
    'fat_grams_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fiberGramsTargetMeta = const VerificationMeta(
    'fiberGramsTarget',
  );
  @override
  late final GeneratedColumn<int> fiberGramsTarget = GeneratedColumn<int>(
    'fiber_grams_target',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEstimatedDefaultMeta =
      const VerificationMeta('isEstimatedDefault');
  @override
  late final GeneratedColumn<bool> isEstimatedDefault = GeneratedColumn<bool>(
    'is_estimated_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_estimated_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _disclaimerMeta = const VerificationMeta(
    'disclaimer',
  );
  @override
  late final GeneratedColumn<String> disclaimer = GeneratedColumn<String>(
    'disclaimer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    calorieTarget,
    proteinGramsTarget,
    carbGramsTarget,
    fatGramsTarget,
    fiberGramsTarget,
    isEstimatedDefault,
    disclaimer,
    syncStatus,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_macro_targets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMacroTarget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('calorie_target')) {
      context.handle(
        _calorieTargetMeta,
        calorieTarget.isAcceptableOrUnknown(
          data['calorie_target']!,
          _calorieTargetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calorieTargetMeta);
    }
    if (data.containsKey('protein_grams_target')) {
      context.handle(
        _proteinGramsTargetMeta,
        proteinGramsTarget.isAcceptableOrUnknown(
          data['protein_grams_target']!,
          _proteinGramsTargetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinGramsTargetMeta);
    }
    if (data.containsKey('carb_grams_target')) {
      context.handle(
        _carbGramsTargetMeta,
        carbGramsTarget.isAcceptableOrUnknown(
          data['carb_grams_target']!,
          _carbGramsTargetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carbGramsTargetMeta);
    }
    if (data.containsKey('fat_grams_target')) {
      context.handle(
        _fatGramsTargetMeta,
        fatGramsTarget.isAcceptableOrUnknown(
          data['fat_grams_target']!,
          _fatGramsTargetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fatGramsTargetMeta);
    }
    if (data.containsKey('fiber_grams_target')) {
      context.handle(
        _fiberGramsTargetMeta,
        fiberGramsTarget.isAcceptableOrUnknown(
          data['fiber_grams_target']!,
          _fiberGramsTargetMeta,
        ),
      );
    }
    if (data.containsKey('is_estimated_default')) {
      context.handle(
        _isEstimatedDefaultMeta,
        isEstimatedDefault.isAcceptableOrUnknown(
          data['is_estimated_default']!,
          _isEstimatedDefaultMeta,
        ),
      );
    }
    if (data.containsKey('disclaimer')) {
      context.handle(
        _disclaimerMeta,
        disclaimer.isAcceptableOrUnknown(data['disclaimer']!, _disclaimerMeta),
      );
    } else if (isInserting) {
      context.missing(_disclaimerMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  CachedMacroTarget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMacroTarget(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      calorieTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calorie_target'],
      )!,
      proteinGramsTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein_grams_target'],
      )!,
      carbGramsTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carb_grams_target'],
      )!,
      fatGramsTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat_grams_target'],
      )!,
      fiberGramsTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fiber_grams_target'],
      ),
      isEstimatedDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimated_default'],
      )!,
      disclaimer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disclaimer'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedMacroTargetsTable createAlias(String alias) {
    return $CachedMacroTargetsTable(attachedDatabase, alias);
  }
}

class CachedMacroTarget extends DataClass
    implements Insertable<CachedMacroTarget> {
  final String userId;
  final int calorieTarget;
  final int proteinGramsTarget;
  final int carbGramsTarget;
  final int fatGramsTarget;
  final int? fiberGramsTarget;
  final bool isEstimatedDefault;
  final String disclaimer;
  final String syncStatus;
  final DateTime updatedAt;
  const CachedMacroTarget({
    required this.userId,
    required this.calorieTarget,
    required this.proteinGramsTarget,
    required this.carbGramsTarget,
    required this.fatGramsTarget,
    this.fiberGramsTarget,
    required this.isEstimatedDefault,
    required this.disclaimer,
    required this.syncStatus,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['calorie_target'] = Variable<int>(calorieTarget);
    map['protein_grams_target'] = Variable<int>(proteinGramsTarget);
    map['carb_grams_target'] = Variable<int>(carbGramsTarget);
    map['fat_grams_target'] = Variable<int>(fatGramsTarget);
    if (!nullToAbsent || fiberGramsTarget != null) {
      map['fiber_grams_target'] = Variable<int>(fiberGramsTarget);
    }
    map['is_estimated_default'] = Variable<bool>(isEstimatedDefault);
    map['disclaimer'] = Variable<String>(disclaimer);
    map['sync_status'] = Variable<String>(syncStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedMacroTargetsCompanion toCompanion(bool nullToAbsent) {
    return CachedMacroTargetsCompanion(
      userId: Value(userId),
      calorieTarget: Value(calorieTarget),
      proteinGramsTarget: Value(proteinGramsTarget),
      carbGramsTarget: Value(carbGramsTarget),
      fatGramsTarget: Value(fatGramsTarget),
      fiberGramsTarget: fiberGramsTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(fiberGramsTarget),
      isEstimatedDefault: Value(isEstimatedDefault),
      disclaimer: Value(disclaimer),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedMacroTarget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMacroTarget(
      userId: serializer.fromJson<String>(json['userId']),
      calorieTarget: serializer.fromJson<int>(json['calorieTarget']),
      proteinGramsTarget: serializer.fromJson<int>(json['proteinGramsTarget']),
      carbGramsTarget: serializer.fromJson<int>(json['carbGramsTarget']),
      fatGramsTarget: serializer.fromJson<int>(json['fatGramsTarget']),
      fiberGramsTarget: serializer.fromJson<int?>(json['fiberGramsTarget']),
      isEstimatedDefault: serializer.fromJson<bool>(json['isEstimatedDefault']),
      disclaimer: serializer.fromJson<String>(json['disclaimer']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'calorieTarget': serializer.toJson<int>(calorieTarget),
      'proteinGramsTarget': serializer.toJson<int>(proteinGramsTarget),
      'carbGramsTarget': serializer.toJson<int>(carbGramsTarget),
      'fatGramsTarget': serializer.toJson<int>(fatGramsTarget),
      'fiberGramsTarget': serializer.toJson<int?>(fiberGramsTarget),
      'isEstimatedDefault': serializer.toJson<bool>(isEstimatedDefault),
      'disclaimer': serializer.toJson<String>(disclaimer),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedMacroTarget copyWith({
    String? userId,
    int? calorieTarget,
    int? proteinGramsTarget,
    int? carbGramsTarget,
    int? fatGramsTarget,
    Value<int?> fiberGramsTarget = const Value.absent(),
    bool? isEstimatedDefault,
    String? disclaimer,
    String? syncStatus,
    DateTime? updatedAt,
  }) => CachedMacroTarget(
    userId: userId ?? this.userId,
    calorieTarget: calorieTarget ?? this.calorieTarget,
    proteinGramsTarget: proteinGramsTarget ?? this.proteinGramsTarget,
    carbGramsTarget: carbGramsTarget ?? this.carbGramsTarget,
    fatGramsTarget: fatGramsTarget ?? this.fatGramsTarget,
    fiberGramsTarget: fiberGramsTarget.present
        ? fiberGramsTarget.value
        : this.fiberGramsTarget,
    isEstimatedDefault: isEstimatedDefault ?? this.isEstimatedDefault,
    disclaimer: disclaimer ?? this.disclaimer,
    syncStatus: syncStatus ?? this.syncStatus,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedMacroTarget copyWithCompanion(CachedMacroTargetsCompanion data) {
    return CachedMacroTarget(
      userId: data.userId.present ? data.userId.value : this.userId,
      calorieTarget: data.calorieTarget.present
          ? data.calorieTarget.value
          : this.calorieTarget,
      proteinGramsTarget: data.proteinGramsTarget.present
          ? data.proteinGramsTarget.value
          : this.proteinGramsTarget,
      carbGramsTarget: data.carbGramsTarget.present
          ? data.carbGramsTarget.value
          : this.carbGramsTarget,
      fatGramsTarget: data.fatGramsTarget.present
          ? data.fatGramsTarget.value
          : this.fatGramsTarget,
      fiberGramsTarget: data.fiberGramsTarget.present
          ? data.fiberGramsTarget.value
          : this.fiberGramsTarget,
      isEstimatedDefault: data.isEstimatedDefault.present
          ? data.isEstimatedDefault.value
          : this.isEstimatedDefault,
      disclaimer: data.disclaimer.present
          ? data.disclaimer.value
          : this.disclaimer,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMacroTarget(')
          ..write('userId: $userId, ')
          ..write('calorieTarget: $calorieTarget, ')
          ..write('proteinGramsTarget: $proteinGramsTarget, ')
          ..write('carbGramsTarget: $carbGramsTarget, ')
          ..write('fatGramsTarget: $fatGramsTarget, ')
          ..write('fiberGramsTarget: $fiberGramsTarget, ')
          ..write('isEstimatedDefault: $isEstimatedDefault, ')
          ..write('disclaimer: $disclaimer, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    calorieTarget,
    proteinGramsTarget,
    carbGramsTarget,
    fatGramsTarget,
    fiberGramsTarget,
    isEstimatedDefault,
    disclaimer,
    syncStatus,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMacroTarget &&
          other.userId == this.userId &&
          other.calorieTarget == this.calorieTarget &&
          other.proteinGramsTarget == this.proteinGramsTarget &&
          other.carbGramsTarget == this.carbGramsTarget &&
          other.fatGramsTarget == this.fatGramsTarget &&
          other.fiberGramsTarget == this.fiberGramsTarget &&
          other.isEstimatedDefault == this.isEstimatedDefault &&
          other.disclaimer == this.disclaimer &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt);
}

class CachedMacroTargetsCompanion extends UpdateCompanion<CachedMacroTarget> {
  final Value<String> userId;
  final Value<int> calorieTarget;
  final Value<int> proteinGramsTarget;
  final Value<int> carbGramsTarget;
  final Value<int> fatGramsTarget;
  final Value<int?> fiberGramsTarget;
  final Value<bool> isEstimatedDefault;
  final Value<String> disclaimer;
  final Value<String> syncStatus;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedMacroTargetsCompanion({
    this.userId = const Value.absent(),
    this.calorieTarget = const Value.absent(),
    this.proteinGramsTarget = const Value.absent(),
    this.carbGramsTarget = const Value.absent(),
    this.fatGramsTarget = const Value.absent(),
    this.fiberGramsTarget = const Value.absent(),
    this.isEstimatedDefault = const Value.absent(),
    this.disclaimer = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMacroTargetsCompanion.insert({
    required String userId,
    required int calorieTarget,
    required int proteinGramsTarget,
    required int carbGramsTarget,
    required int fatGramsTarget,
    this.fiberGramsTarget = const Value.absent(),
    this.isEstimatedDefault = const Value.absent(),
    required String disclaimer,
    this.syncStatus = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       calorieTarget = Value(calorieTarget),
       proteinGramsTarget = Value(proteinGramsTarget),
       carbGramsTarget = Value(carbGramsTarget),
       fatGramsTarget = Value(fatGramsTarget),
       disclaimer = Value(disclaimer),
       updatedAt = Value(updatedAt);
  static Insertable<CachedMacroTarget> custom({
    Expression<String>? userId,
    Expression<int>? calorieTarget,
    Expression<int>? proteinGramsTarget,
    Expression<int>? carbGramsTarget,
    Expression<int>? fatGramsTarget,
    Expression<int>? fiberGramsTarget,
    Expression<bool>? isEstimatedDefault,
    Expression<String>? disclaimer,
    Expression<String>? syncStatus,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (calorieTarget != null) 'calorie_target': calorieTarget,
      if (proteinGramsTarget != null)
        'protein_grams_target': proteinGramsTarget,
      if (carbGramsTarget != null) 'carb_grams_target': carbGramsTarget,
      if (fatGramsTarget != null) 'fat_grams_target': fatGramsTarget,
      if (fiberGramsTarget != null) 'fiber_grams_target': fiberGramsTarget,
      if (isEstimatedDefault != null)
        'is_estimated_default': isEstimatedDefault,
      if (disclaimer != null) 'disclaimer': disclaimer,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMacroTargetsCompanion copyWith({
    Value<String>? userId,
    Value<int>? calorieTarget,
    Value<int>? proteinGramsTarget,
    Value<int>? carbGramsTarget,
    Value<int>? fatGramsTarget,
    Value<int?>? fiberGramsTarget,
    Value<bool>? isEstimatedDefault,
    Value<String>? disclaimer,
    Value<String>? syncStatus,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedMacroTargetsCompanion(
      userId: userId ?? this.userId,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      proteinGramsTarget: proteinGramsTarget ?? this.proteinGramsTarget,
      carbGramsTarget: carbGramsTarget ?? this.carbGramsTarget,
      fatGramsTarget: fatGramsTarget ?? this.fatGramsTarget,
      fiberGramsTarget: fiberGramsTarget ?? this.fiberGramsTarget,
      isEstimatedDefault: isEstimatedDefault ?? this.isEstimatedDefault,
      disclaimer: disclaimer ?? this.disclaimer,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (calorieTarget.present) {
      map['calorie_target'] = Variable<int>(calorieTarget.value);
    }
    if (proteinGramsTarget.present) {
      map['protein_grams_target'] = Variable<int>(proteinGramsTarget.value);
    }
    if (carbGramsTarget.present) {
      map['carb_grams_target'] = Variable<int>(carbGramsTarget.value);
    }
    if (fatGramsTarget.present) {
      map['fat_grams_target'] = Variable<int>(fatGramsTarget.value);
    }
    if (fiberGramsTarget.present) {
      map['fiber_grams_target'] = Variable<int>(fiberGramsTarget.value);
    }
    if (isEstimatedDefault.present) {
      map['is_estimated_default'] = Variable<bool>(isEstimatedDefault.value);
    }
    if (disclaimer.present) {
      map['disclaimer'] = Variable<String>(disclaimer.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMacroTargetsCompanion(')
          ..write('userId: $userId, ')
          ..write('calorieTarget: $calorieTarget, ')
          ..write('proteinGramsTarget: $proteinGramsTarget, ')
          ..write('carbGramsTarget: $carbGramsTarget, ')
          ..write('fatGramsTarget: $fatGramsTarget, ')
          ..write('fiberGramsTarget: $fiberGramsTarget, ')
          ..write('isEstimatedDefault: $isEstimatedDefault, ')
          ..write('disclaimer: $disclaimer, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingCelebrationsTable extends PendingCelebrations
    with TableInfo<$PendingCelebrationsTable, PendingCelebration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingCelebrationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _achievementIdMeta = const VerificationMeta(
    'achievementId',
  );
  @override
  late final GeneratedColumn<String> achievementId = GeneratedColumn<String>(
    'achievement_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _achievementKeyMeta = const VerificationMeta(
    'achievementKey',
  );
  @override
  late final GeneratedColumn<String> achievementKey = GeneratedColumn<String>(
    'achievement_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconAssetMeta = const VerificationMeta(
    'iconAsset',
  );
  @override
  late final GeneratedColumn<String> iconAsset = GeneratedColumn<String>(
    'icon_asset',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetStepsMeta = const VerificationMeta(
    'targetSteps',
  );
  @override
  late final GeneratedColumn<int> targetSteps = GeneratedColumn<int>(
    'target_steps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _earnedAtMeta = const VerificationMeta(
    'earnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> earnedAt = GeneratedColumn<DateTime>(
    'earned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    achievementId,
    achievementKey,
    title,
    description,
    iconAsset,
    category,
    targetSteps,
    earnedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_celebrations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingCelebration> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('achievement_id')) {
      context.handle(
        _achievementIdMeta,
        achievementId.isAcceptableOrUnknown(
          data['achievement_id']!,
          _achievementIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_achievementIdMeta);
    }
    if (data.containsKey('achievement_key')) {
      context.handle(
        _achievementKeyMeta,
        achievementKey.isAcceptableOrUnknown(
          data['achievement_key']!,
          _achievementKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_achievementKeyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('icon_asset')) {
      context.handle(
        _iconAssetMeta,
        iconAsset.isAcceptableOrUnknown(data['icon_asset']!, _iconAssetMeta),
      );
    } else if (isInserting) {
      context.missing(_iconAssetMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('target_steps')) {
      context.handle(
        _targetStepsMeta,
        targetSteps.isAcceptableOrUnknown(
          data['target_steps']!,
          _targetStepsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetStepsMeta);
    }
    if (data.containsKey('earned_at')) {
      context.handle(
        _earnedAtMeta,
        earnedAt.isAcceptableOrUnknown(data['earned_at']!, _earnedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_earnedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingCelebration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingCelebration(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      achievementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}achievement_id'],
      )!,
      achievementKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}achievement_key'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      iconAsset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_asset'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      targetSteps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_steps'],
      )!,
      earnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}earned_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingCelebrationsTable createAlias(String alias) {
    return $PendingCelebrationsTable(attachedDatabase, alias);
  }
}

class PendingCelebration extends DataClass
    implements Insertable<PendingCelebration> {
  final String id;
  final String userId;
  final String achievementId;
  final String achievementKey;
  final String title;
  final String description;
  final String iconAsset;
  final String category;
  final int targetSteps;
  final DateTime earnedAt;
  final DateTime createdAt;
  const PendingCelebration({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.achievementKey,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.category,
    required this.targetSteps,
    required this.earnedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['achievement_id'] = Variable<String>(achievementId);
    map['achievement_key'] = Variable<String>(achievementKey);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['icon_asset'] = Variable<String>(iconAsset);
    map['category'] = Variable<String>(category);
    map['target_steps'] = Variable<int>(targetSteps);
    map['earned_at'] = Variable<DateTime>(earnedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingCelebrationsCompanion toCompanion(bool nullToAbsent) {
    return PendingCelebrationsCompanion(
      id: Value(id),
      userId: Value(userId),
      achievementId: Value(achievementId),
      achievementKey: Value(achievementKey),
      title: Value(title),
      description: Value(description),
      iconAsset: Value(iconAsset),
      category: Value(category),
      targetSteps: Value(targetSteps),
      earnedAt: Value(earnedAt),
      createdAt: Value(createdAt),
    );
  }

  factory PendingCelebration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingCelebration(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      achievementId: serializer.fromJson<String>(json['achievementId']),
      achievementKey: serializer.fromJson<String>(json['achievementKey']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      iconAsset: serializer.fromJson<String>(json['iconAsset']),
      category: serializer.fromJson<String>(json['category']),
      targetSteps: serializer.fromJson<int>(json['targetSteps']),
      earnedAt: serializer.fromJson<DateTime>(json['earnedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'achievementId': serializer.toJson<String>(achievementId),
      'achievementKey': serializer.toJson<String>(achievementKey),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'iconAsset': serializer.toJson<String>(iconAsset),
      'category': serializer.toJson<String>(category),
      'targetSteps': serializer.toJson<int>(targetSteps),
      'earnedAt': serializer.toJson<DateTime>(earnedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingCelebration copyWith({
    String? id,
    String? userId,
    String? achievementId,
    String? achievementKey,
    String? title,
    String? description,
    String? iconAsset,
    String? category,
    int? targetSteps,
    DateTime? earnedAt,
    DateTime? createdAt,
  }) => PendingCelebration(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    achievementId: achievementId ?? this.achievementId,
    achievementKey: achievementKey ?? this.achievementKey,
    title: title ?? this.title,
    description: description ?? this.description,
    iconAsset: iconAsset ?? this.iconAsset,
    category: category ?? this.category,
    targetSteps: targetSteps ?? this.targetSteps,
    earnedAt: earnedAt ?? this.earnedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingCelebration copyWithCompanion(PendingCelebrationsCompanion data) {
    return PendingCelebration(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      achievementId: data.achievementId.present
          ? data.achievementId.value
          : this.achievementId,
      achievementKey: data.achievementKey.present
          ? data.achievementKey.value
          : this.achievementKey,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      iconAsset: data.iconAsset.present ? data.iconAsset.value : this.iconAsset,
      category: data.category.present ? data.category.value : this.category,
      targetSteps: data.targetSteps.present
          ? data.targetSteps.value
          : this.targetSteps,
      earnedAt: data.earnedAt.present ? data.earnedAt.value : this.earnedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingCelebration(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('achievementId: $achievementId, ')
          ..write('achievementKey: $achievementKey, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('iconAsset: $iconAsset, ')
          ..write('category: $category, ')
          ..write('targetSteps: $targetSteps, ')
          ..write('earnedAt: $earnedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    achievementId,
    achievementKey,
    title,
    description,
    iconAsset,
    category,
    targetSteps,
    earnedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingCelebration &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.achievementId == this.achievementId &&
          other.achievementKey == this.achievementKey &&
          other.title == this.title &&
          other.description == this.description &&
          other.iconAsset == this.iconAsset &&
          other.category == this.category &&
          other.targetSteps == this.targetSteps &&
          other.earnedAt == this.earnedAt &&
          other.createdAt == this.createdAt);
}

class PendingCelebrationsCompanion extends UpdateCompanion<PendingCelebration> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> achievementId;
  final Value<String> achievementKey;
  final Value<String> title;
  final Value<String> description;
  final Value<String> iconAsset;
  final Value<String> category;
  final Value<int> targetSteps;
  final Value<DateTime> earnedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PendingCelebrationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.achievementId = const Value.absent(),
    this.achievementKey = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.iconAsset = const Value.absent(),
    this.category = const Value.absent(),
    this.targetSteps = const Value.absent(),
    this.earnedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingCelebrationsCompanion.insert({
    required String id,
    required String userId,
    required String achievementId,
    required String achievementKey,
    required String title,
    required String description,
    required String iconAsset,
    required String category,
    required int targetSteps,
    required DateTime earnedAt,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       achievementId = Value(achievementId),
       achievementKey = Value(achievementKey),
       title = Value(title),
       description = Value(description),
       iconAsset = Value(iconAsset),
       category = Value(category),
       targetSteps = Value(targetSteps),
       earnedAt = Value(earnedAt),
       createdAt = Value(createdAt);
  static Insertable<PendingCelebration> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? achievementId,
    Expression<String>? achievementKey,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? iconAsset,
    Expression<String>? category,
    Expression<int>? targetSteps,
    Expression<DateTime>? earnedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (achievementId != null) 'achievement_id': achievementId,
      if (achievementKey != null) 'achievement_key': achievementKey,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (iconAsset != null) 'icon_asset': iconAsset,
      if (category != null) 'category': category,
      if (targetSteps != null) 'target_steps': targetSteps,
      if (earnedAt != null) 'earned_at': earnedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingCelebrationsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? achievementId,
    Value<String>? achievementKey,
    Value<String>? title,
    Value<String>? description,
    Value<String>? iconAsset,
    Value<String>? category,
    Value<int>? targetSteps,
    Value<DateTime>? earnedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingCelebrationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      achievementKey: achievementKey ?? this.achievementKey,
      title: title ?? this.title,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      category: category ?? this.category,
      targetSteps: targetSteps ?? this.targetSteps,
      earnedAt: earnedAt ?? this.earnedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (achievementId.present) {
      map['achievement_id'] = Variable<String>(achievementId.value);
    }
    if (achievementKey.present) {
      map['achievement_key'] = Variable<String>(achievementKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (iconAsset.present) {
      map['icon_asset'] = Variable<String>(iconAsset.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (targetSteps.present) {
      map['target_steps'] = Variable<int>(targetSteps.value);
    }
    if (earnedAt.present) {
      map['earned_at'] = Variable<DateTime>(earnedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingCelebrationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('achievementId: $achievementId, ')
          ..write('achievementKey: $achievementKey, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('iconAsset: $iconAsset, ')
          ..write('category: $category, ')
          ..write('targetSteps: $targetSteps, ')
          ..write('earnedAt: $earnedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCardioSessionRowsTable extends CachedCardioSessionRows
    with TableInfo<$CachedCardioSessionRowsTable, CachedCardioSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCardioSessionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionJsonMeta = const VerificationMeta(
    'sessionJson',
  );
  @override
  late final GeneratedColumn<String> sessionJson = GeneratedColumn<String>(
    'session_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sessionJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_cardio_session_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCardioSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_json')) {
      context.handle(
        _sessionJsonMeta,
        sessionJson.isAcceptableOrUnknown(
          data['session_json']!,
          _sessionJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCardioSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCardioSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedCardioSessionRowsTable createAlias(String alias) {
    return $CachedCardioSessionRowsTable(attachedDatabase, alias);
  }
}

class CachedCardioSessionRow extends DataClass
    implements Insertable<CachedCardioSessionRow> {
  final String id;
  final String sessionJson;
  final DateTime updatedAt;
  const CachedCardioSessionRow({
    required this.id,
    required this.sessionJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_json'] = Variable<String>(sessionJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedCardioSessionRowsCompanion toCompanion(bool nullToAbsent) {
    return CachedCardioSessionRowsCompanion(
      id: Value(id),
      sessionJson: Value(sessionJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedCardioSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCardioSessionRow(
      id: serializer.fromJson<String>(json['id']),
      sessionJson: serializer.fromJson<String>(json['sessionJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionJson': serializer.toJson<String>(sessionJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedCardioSessionRow copyWith({
    String? id,
    String? sessionJson,
    DateTime? updatedAt,
  }) => CachedCardioSessionRow(
    id: id ?? this.id,
    sessionJson: sessionJson ?? this.sessionJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedCardioSessionRow copyWithCompanion(
    CachedCardioSessionRowsCompanion data,
  ) {
    return CachedCardioSessionRow(
      id: data.id.present ? data.id.value : this.id,
      sessionJson: data.sessionJson.present
          ? data.sessionJson.value
          : this.sessionJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCardioSessionRow(')
          ..write('id: $id, ')
          ..write('sessionJson: $sessionJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCardioSessionRow &&
          other.id == this.id &&
          other.sessionJson == this.sessionJson &&
          other.updatedAt == this.updatedAt);
}

class CachedCardioSessionRowsCompanion
    extends UpdateCompanion<CachedCardioSessionRow> {
  final Value<String> id;
  final Value<String> sessionJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedCardioSessionRowsCompanion({
    this.id = const Value.absent(),
    this.sessionJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCardioSessionRowsCompanion.insert({
    required String id,
    required String sessionJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionJson = Value(sessionJson),
       updatedAt = Value(updatedAt);
  static Insertable<CachedCardioSessionRow> custom({
    Expression<String>? id,
    Expression<String>? sessionJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionJson != null) 'session_json': sessionJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCardioSessionRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedCardioSessionRowsCompanion(
      id: id ?? this.id,
      sessionJson: sessionJson ?? this.sessionJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionJson.present) {
      map['session_json'] = Variable<String>(sessionJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCardioSessionRowsCompanion(')
          ..write('id: $id, ')
          ..write('sessionJson: $sessionJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedProfilesTable cachedProfiles = $CachedProfilesTable(this);
  late final $CachedPreferencesTableTable cachedPreferencesTable =
      $CachedPreferencesTableTable(this);
  late final $OnboardingDraftsTable onboardingDrafts = $OnboardingDraftsTable(
    this,
  );
  late final $SyncStatusRowsTable syncStatusRows = $SyncStatusRowsTable(this);
  late final $CachedWorkoutSessionRowsTable cachedWorkoutSessionRows =
      $CachedWorkoutSessionRowsTable(this);
  late final $OutboxEntryRowsTable outboxEntryRows = $OutboxEntryRowsTable(
    this,
  );
  late final $CachedFoodsTable cachedFoods = $CachedFoodsTable(this);
  late final $CachedFoodServingsTable cachedFoodServings =
      $CachedFoodServingsTable(this);
  late final $CachedMealEntriesTable cachedMealEntries =
      $CachedMealEntriesTable(this);
  late final $CachedSavedMealsTable cachedSavedMeals = $CachedSavedMealsTable(
    this,
  );
  late final $CachedWaterEntriesTable cachedWaterEntries =
      $CachedWaterEntriesTable(this);
  late final $CachedMacroTargetsTable cachedMacroTargets =
      $CachedMacroTargetsTable(this);
  late final $PendingCelebrationsTable pendingCelebrations =
      $PendingCelebrationsTable(this);
  late final $CachedCardioSessionRowsTable cachedCardioSessionRows =
      $CachedCardioSessionRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedProfiles,
    cachedPreferencesTable,
    onboardingDrafts,
    syncStatusRows,
    cachedWorkoutSessionRows,
    outboxEntryRows,
    cachedFoods,
    cachedFoodServings,
    cachedMealEntries,
    cachedSavedMeals,
    cachedWaterEntries,
    cachedMacroTargets,
    pendingCelebrations,
    cachedCardioSessionRows,
  ];
}

typedef $$CachedProfilesTableCreateCompanionBuilder =
    CachedProfilesCompanion Function({
      required String userId,
      required String profileJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedProfilesTableUpdateCompanionBuilder =
    CachedProfilesCompanion Function({
      Value<String> userId,
      Value<String> profileJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedProfilesTable,
          CachedProfile,
          $$CachedProfilesTableFilterComposer,
          $$CachedProfilesTableOrderingComposer,
          $$CachedProfilesTableAnnotationComposer,
          $$CachedProfilesTableCreateCompanionBuilder,
          $$CachedProfilesTableUpdateCompanionBuilder,
          (
            CachedProfile,
            BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
          ),
          CachedProfile,
          PrefetchHooks Function()
        > {
  $$CachedProfilesTableTableManager(
    _$AppDatabase db,
    $CachedProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> profileJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion(
                userId: userId,
                profileJson: profileJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String profileJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion.insert(
                userId: userId,
                profileJson: profileJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedProfilesTable,
      CachedProfile,
      $$CachedProfilesTableFilterComposer,
      $$CachedProfilesTableOrderingComposer,
      $$CachedProfilesTableAnnotationComposer,
      $$CachedProfilesTableCreateCompanionBuilder,
      $$CachedProfilesTableUpdateCompanionBuilder,
      (
        CachedProfile,
        BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
      ),
      CachedProfile,
      PrefetchHooks Function()
    >;
typedef $$CachedPreferencesTableTableCreateCompanionBuilder =
    CachedPreferencesTableCompanion Function({
      required String userId,
      required String preferencesJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedPreferencesTableTableUpdateCompanionBuilder =
    CachedPreferencesTableCompanion Function({
      Value<String> userId,
      Value<String> preferencesJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedPreferencesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPreferencesTableTable> {
  $$CachedPreferencesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferencesJson => $composableBuilder(
    column: $table.preferencesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPreferencesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPreferencesTableTable> {
  $$CachedPreferencesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferencesJson => $composableBuilder(
    column: $table.preferencesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPreferencesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPreferencesTableTable> {
  $$CachedPreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get preferencesJson => $composableBuilder(
    column: $table.preferencesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedPreferencesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPreferencesTableTable,
          CachedPreferencesTableData,
          $$CachedPreferencesTableTableFilterComposer,
          $$CachedPreferencesTableTableOrderingComposer,
          $$CachedPreferencesTableTableAnnotationComposer,
          $$CachedPreferencesTableTableCreateCompanionBuilder,
          $$CachedPreferencesTableTableUpdateCompanionBuilder,
          (
            CachedPreferencesTableData,
            BaseReferences<
              _$AppDatabase,
              $CachedPreferencesTableTable,
              CachedPreferencesTableData
            >,
          ),
          CachedPreferencesTableData,
          PrefetchHooks Function()
        > {
  $$CachedPreferencesTableTableTableManager(
    _$AppDatabase db,
    $CachedPreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPreferencesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedPreferencesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedPreferencesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> preferencesJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPreferencesTableCompanion(
                userId: userId,
                preferencesJson: preferencesJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String preferencesJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedPreferencesTableCompanion.insert(
                userId: userId,
                preferencesJson: preferencesJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPreferencesTableTable,
      CachedPreferencesTableData,
      $$CachedPreferencesTableTableFilterComposer,
      $$CachedPreferencesTableTableOrderingComposer,
      $$CachedPreferencesTableTableAnnotationComposer,
      $$CachedPreferencesTableTableCreateCompanionBuilder,
      $$CachedPreferencesTableTableUpdateCompanionBuilder,
      (
        CachedPreferencesTableData,
        BaseReferences<
          _$AppDatabase,
          $CachedPreferencesTableTable,
          CachedPreferencesTableData
        >,
      ),
      CachedPreferencesTableData,
      PrefetchHooks Function()
    >;
typedef $$OnboardingDraftsTableCreateCompanionBuilder =
    OnboardingDraftsCompanion Function({
      required String id,
      required int step,
      required String draftJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$OnboardingDraftsTableUpdateCompanionBuilder =
    OnboardingDraftsCompanion Function({
      Value<String> id,
      Value<int> step,
      Value<String> draftJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$OnboardingDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $OnboardingDraftsTable> {
  $$OnboardingDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftJson => $composableBuilder(
    column: $table.draftJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OnboardingDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $OnboardingDraftsTable> {
  $$OnboardingDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftJson => $composableBuilder(
    column: $table.draftJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OnboardingDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OnboardingDraftsTable> {
  $$OnboardingDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<String> get draftJson =>
      $composableBuilder(column: $table.draftJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OnboardingDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OnboardingDraftsTable,
          OnboardingDraft,
          $$OnboardingDraftsTableFilterComposer,
          $$OnboardingDraftsTableOrderingComposer,
          $$OnboardingDraftsTableAnnotationComposer,
          $$OnboardingDraftsTableCreateCompanionBuilder,
          $$OnboardingDraftsTableUpdateCompanionBuilder,
          (
            OnboardingDraft,
            BaseReferences<
              _$AppDatabase,
              $OnboardingDraftsTable,
              OnboardingDraft
            >,
          ),
          OnboardingDraft,
          PrefetchHooks Function()
        > {
  $$OnboardingDraftsTableTableManager(
    _$AppDatabase db,
    $OnboardingDraftsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OnboardingDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OnboardingDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OnboardingDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> step = const Value.absent(),
                Value<String> draftJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OnboardingDraftsCompanion(
                id: id,
                step: step,
                draftJson: draftJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int step,
                required String draftJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OnboardingDraftsCompanion.insert(
                id: id,
                step: step,
                draftJson: draftJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OnboardingDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OnboardingDraftsTable,
      OnboardingDraft,
      $$OnboardingDraftsTableFilterComposer,
      $$OnboardingDraftsTableOrderingComposer,
      $$OnboardingDraftsTableAnnotationComposer,
      $$OnboardingDraftsTableCreateCompanionBuilder,
      $$OnboardingDraftsTableUpdateCompanionBuilder,
      (
        OnboardingDraft,
        BaseReferences<_$AppDatabase, $OnboardingDraftsTable, OnboardingDraft>,
      ),
      OnboardingDraft,
      PrefetchHooks Function()
    >;
typedef $$SyncStatusRowsTableCreateCompanionBuilder =
    SyncStatusRowsCompanion Function({
      required String id,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isSyncing,
      Value<int> rowid,
    });
typedef $$SyncStatusRowsTableUpdateCompanionBuilder =
    SyncStatusRowsCompanion Function({
      Value<String> id,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isSyncing,
      Value<int> rowid,
    });

class $$SyncStatusRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatusRowsTable> {
  $$SyncStatusRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSyncing => $composableBuilder(
    column: $table.isSyncing,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatusRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatusRowsTable> {
  $$SyncStatusRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSyncing => $composableBuilder(
    column: $table.isSyncing,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatusRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatusRowsTable> {
  $$SyncStatusRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSyncing =>
      $composableBuilder(column: $table.isSyncing, builder: (column) => column);
}

class $$SyncStatusRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStatusRowsTable,
          SyncStatusRow,
          $$SyncStatusRowsTableFilterComposer,
          $$SyncStatusRowsTableOrderingComposer,
          $$SyncStatusRowsTableAnnotationComposer,
          $$SyncStatusRowsTableCreateCompanionBuilder,
          $$SyncStatusRowsTableUpdateCompanionBuilder,
          (
            SyncStatusRow,
            BaseReferences<_$AppDatabase, $SyncStatusRowsTable, SyncStatusRow>,
          ),
          SyncStatusRow,
          PrefetchHooks Function()
        > {
  $$SyncStatusRowsTableTableManager(
    _$AppDatabase db,
    $SyncStatusRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatusRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatusRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatusRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isSyncing = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatusRowsCompanion(
                id: id,
                lastSyncedAt: lastSyncedAt,
                isSyncing: isSyncing,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isSyncing = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatusRowsCompanion.insert(
                id: id,
                lastSyncedAt: lastSyncedAt,
                isSyncing: isSyncing,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatusRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStatusRowsTable,
      SyncStatusRow,
      $$SyncStatusRowsTableFilterComposer,
      $$SyncStatusRowsTableOrderingComposer,
      $$SyncStatusRowsTableAnnotationComposer,
      $$SyncStatusRowsTableCreateCompanionBuilder,
      $$SyncStatusRowsTableUpdateCompanionBuilder,
      (
        SyncStatusRow,
        BaseReferences<_$AppDatabase, $SyncStatusRowsTable, SyncStatusRow>,
      ),
      SyncStatusRow,
      PrefetchHooks Function()
    >;
typedef $$CachedWorkoutSessionRowsTableCreateCompanionBuilder =
    CachedWorkoutSessionRowsCompanion Function({
      required String id,
      required String sessionJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedWorkoutSessionRowsTableUpdateCompanionBuilder =
    CachedWorkoutSessionRowsCompanion Function({
      Value<String> id,
      Value<String> sessionJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedWorkoutSessionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedWorkoutSessionRowsTable> {
  $$CachedWorkoutSessionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionJson => $composableBuilder(
    column: $table.sessionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedWorkoutSessionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedWorkoutSessionRowsTable> {
  $$CachedWorkoutSessionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionJson => $composableBuilder(
    column: $table.sessionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedWorkoutSessionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedWorkoutSessionRowsTable> {
  $$CachedWorkoutSessionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionJson => $composableBuilder(
    column: $table.sessionJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedWorkoutSessionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedWorkoutSessionRowsTable,
          CachedWorkoutSessionRow,
          $$CachedWorkoutSessionRowsTableFilterComposer,
          $$CachedWorkoutSessionRowsTableOrderingComposer,
          $$CachedWorkoutSessionRowsTableAnnotationComposer,
          $$CachedWorkoutSessionRowsTableCreateCompanionBuilder,
          $$CachedWorkoutSessionRowsTableUpdateCompanionBuilder,
          (
            CachedWorkoutSessionRow,
            BaseReferences<
              _$AppDatabase,
              $CachedWorkoutSessionRowsTable,
              CachedWorkoutSessionRow
            >,
          ),
          CachedWorkoutSessionRow,
          PrefetchHooks Function()
        > {
  $$CachedWorkoutSessionRowsTableTableManager(
    _$AppDatabase db,
    $CachedWorkoutSessionRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedWorkoutSessionRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedWorkoutSessionRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedWorkoutSessionRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedWorkoutSessionRowsCompanion(
                id: id,
                sessionJson: sessionJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedWorkoutSessionRowsCompanion.insert(
                id: id,
                sessionJson: sessionJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedWorkoutSessionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedWorkoutSessionRowsTable,
      CachedWorkoutSessionRow,
      $$CachedWorkoutSessionRowsTableFilterComposer,
      $$CachedWorkoutSessionRowsTableOrderingComposer,
      $$CachedWorkoutSessionRowsTableAnnotationComposer,
      $$CachedWorkoutSessionRowsTableCreateCompanionBuilder,
      $$CachedWorkoutSessionRowsTableUpdateCompanionBuilder,
      (
        CachedWorkoutSessionRow,
        BaseReferences<
          _$AppDatabase,
          $CachedWorkoutSessionRowsTable,
          CachedWorkoutSessionRow
        >,
      ),
      CachedWorkoutSessionRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxEntryRowsTableCreateCompanionBuilder =
    OutboxEntryRowsCompanion Function({
      required String id,
      required String entityType,
      required String operationType,
      required String payloadJson,
      required String status,
      Value<int> retryCount,
      Value<String?> lastErrorMessage,
      Value<String?> lastErrorCode,
      Value<String?> resultEntityId,
      required DateTime createdAt,
      required DateTime nextAttemptAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$OutboxEntryRowsTableUpdateCompanionBuilder =
    OutboxEntryRowsCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> operationType,
      Value<String> payloadJson,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastErrorMessage,
      Value<String?> lastErrorCode,
      Value<String?> resultEntityId,
      Value<DateTime> createdAt,
      Value<DateTime> nextAttemptAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$OutboxEntryRowsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxEntryRowsTable> {
  $$OutboxEntryRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultEntityId => $composableBuilder(
    column: $table.resultEntityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEntryRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxEntryRowsTable> {
  $$OutboxEntryRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultEntityId => $composableBuilder(
    column: $table.resultEntityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEntryRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxEntryRowsTable> {
  $$OutboxEntryRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultEntityId => $composableBuilder(
    column: $table.resultEntityId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OutboxEntryRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxEntryRowsTable,
          OutboxEntryRow,
          $$OutboxEntryRowsTableFilterComposer,
          $$OutboxEntryRowsTableOrderingComposer,
          $$OutboxEntryRowsTableAnnotationComposer,
          $$OutboxEntryRowsTableCreateCompanionBuilder,
          $$OutboxEntryRowsTableUpdateCompanionBuilder,
          (
            OutboxEntryRow,
            BaseReferences<
              _$AppDatabase,
              $OutboxEntryRowsTable,
              OutboxEntryRow
            >,
          ),
          OutboxEntryRow,
          PrefetchHooks Function()
        > {
  $$OutboxEntryRowsTableTableManager(
    _$AppDatabase db,
    $OutboxEntryRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntryRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntryRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntryRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> resultEntityId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEntryRowsCompanion(
                id: id,
                entityType: entityType,
                operationType: operationType,
                payloadJson: payloadJson,
                status: status,
                retryCount: retryCount,
                lastErrorMessage: lastErrorMessage,
                lastErrorCode: lastErrorCode,
                resultEntityId: resultEntityId,
                createdAt: createdAt,
                nextAttemptAt: nextAttemptAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String operationType,
                required String payloadJson,
                required String status,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> resultEntityId = const Value.absent(),
                required DateTime createdAt,
                required DateTime nextAttemptAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OutboxEntryRowsCompanion.insert(
                id: id,
                entityType: entityType,
                operationType: operationType,
                payloadJson: payloadJson,
                status: status,
                retryCount: retryCount,
                lastErrorMessage: lastErrorMessage,
                lastErrorCode: lastErrorCode,
                resultEntityId: resultEntityId,
                createdAt: createdAt,
                nextAttemptAt: nextAttemptAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEntryRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxEntryRowsTable,
      OutboxEntryRow,
      $$OutboxEntryRowsTableFilterComposer,
      $$OutboxEntryRowsTableOrderingComposer,
      $$OutboxEntryRowsTableAnnotationComposer,
      $$OutboxEntryRowsTableCreateCompanionBuilder,
      $$OutboxEntryRowsTableUpdateCompanionBuilder,
      (
        OutboxEntryRow,
        BaseReferences<_$AppDatabase, $OutboxEntryRowsTable, OutboxEntryRow>,
      ),
      OutboxEntryRow,
      PrefetchHooks Function()
    >;
typedef $$CachedFoodsTableCreateCompanionBuilder =
    CachedFoodsCompanion Function({
      required String id,
      required String userId,
      required String name,
      Value<String?> alternateName,
      Value<String?> brand,
      required String sourceType,
      Value<bool> isOwnedByCurrentUser,
      required String servingDescription,
      Value<double?> servingGrams,
      required double caloriesPerServing,
      required double proteinGramsPerServing,
      required double carbGramsPerServing,
      required double fatGramsPerServing,
      Value<double?> fiberGramsPerServing,
      Value<double?> sodiumMgPerServing,
      Value<bool> isEstimated,
      Value<DateTime?> archivedAt,
      Value<String> syncStatus,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedFoodsTableUpdateCompanionBuilder =
    CachedFoodsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<String?> alternateName,
      Value<String?> brand,
      Value<String> sourceType,
      Value<bool> isOwnedByCurrentUser,
      Value<String> servingDescription,
      Value<double?> servingGrams,
      Value<double> caloriesPerServing,
      Value<double> proteinGramsPerServing,
      Value<double> carbGramsPerServing,
      Value<double> fatGramsPerServing,
      Value<double?> fiberGramsPerServing,
      Value<double?> sodiumMgPerServing,
      Value<bool> isEstimated,
      Value<DateTime?> archivedAt,
      Value<String> syncStatus,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedFoodsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedFoodsTable> {
  $$CachedFoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alternateName => $composableBuilder(
    column: $table.alternateName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOwnedByCurrentUser => $composableBuilder(
    column: $table.isOwnedByCurrentUser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingDescription => $composableBuilder(
    column: $table.servingDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caloriesPerServing => $composableBuilder(
    column: $table.caloriesPerServing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinGramsPerServing => $composableBuilder(
    column: $table.proteinGramsPerServing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbGramsPerServing => $composableBuilder(
    column: $table.carbGramsPerServing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatGramsPerServing => $composableBuilder(
    column: $table.fatGramsPerServing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberGramsPerServing => $composableBuilder(
    column: $table.fiberGramsPerServing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodiumMgPerServing => $composableBuilder(
    column: $table.sodiumMgPerServing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEstimated => $composableBuilder(
    column: $table.isEstimated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedFoodsTable> {
  $$CachedFoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alternateName => $composableBuilder(
    column: $table.alternateName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOwnedByCurrentUser => $composableBuilder(
    column: $table.isOwnedByCurrentUser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingDescription => $composableBuilder(
    column: $table.servingDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caloriesPerServing => $composableBuilder(
    column: $table.caloriesPerServing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinGramsPerServing => $composableBuilder(
    column: $table.proteinGramsPerServing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbGramsPerServing => $composableBuilder(
    column: $table.carbGramsPerServing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatGramsPerServing => $composableBuilder(
    column: $table.fatGramsPerServing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberGramsPerServing => $composableBuilder(
    column: $table.fiberGramsPerServing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodiumMgPerServing => $composableBuilder(
    column: $table.sodiumMgPerServing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEstimated => $composableBuilder(
    column: $table.isEstimated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedFoodsTable> {
  $$CachedFoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get alternateName => $composableBuilder(
    column: $table.alternateName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOwnedByCurrentUser => $composableBuilder(
    column: $table.isOwnedByCurrentUser,
    builder: (column) => column,
  );

  GeneratedColumn<String> get servingDescription => $composableBuilder(
    column: $table.servingDescription,
    builder: (column) => column,
  );

  GeneratedColumn<double> get servingGrams => $composableBuilder(
    column: $table.servingGrams,
    builder: (column) => column,
  );

  GeneratedColumn<double> get caloriesPerServing => $composableBuilder(
    column: $table.caloriesPerServing,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinGramsPerServing => $composableBuilder(
    column: $table.proteinGramsPerServing,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbGramsPerServing => $composableBuilder(
    column: $table.carbGramsPerServing,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatGramsPerServing => $composableBuilder(
    column: $table.fatGramsPerServing,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fiberGramsPerServing => $composableBuilder(
    column: $table.fiberGramsPerServing,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sodiumMgPerServing => $composableBuilder(
    column: $table.sodiumMgPerServing,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEstimated => $composableBuilder(
    column: $table.isEstimated,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedFoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedFoodsTable,
          CachedFood,
          $$CachedFoodsTableFilterComposer,
          $$CachedFoodsTableOrderingComposer,
          $$CachedFoodsTableAnnotationComposer,
          $$CachedFoodsTableCreateCompanionBuilder,
          $$CachedFoodsTableUpdateCompanionBuilder,
          (
            CachedFood,
            BaseReferences<_$AppDatabase, $CachedFoodsTable, CachedFood>,
          ),
          CachedFood,
          PrefetchHooks Function()
        > {
  $$CachedFoodsTableTableManager(_$AppDatabase db, $CachedFoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedFoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> alternateName = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<bool> isOwnedByCurrentUser = const Value.absent(),
                Value<String> servingDescription = const Value.absent(),
                Value<double?> servingGrams = const Value.absent(),
                Value<double> caloriesPerServing = const Value.absent(),
                Value<double> proteinGramsPerServing = const Value.absent(),
                Value<double> carbGramsPerServing = const Value.absent(),
                Value<double> fatGramsPerServing = const Value.absent(),
                Value<double?> fiberGramsPerServing = const Value.absent(),
                Value<double?> sodiumMgPerServing = const Value.absent(),
                Value<bool> isEstimated = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFoodsCompanion(
                id: id,
                userId: userId,
                name: name,
                alternateName: alternateName,
                brand: brand,
                sourceType: sourceType,
                isOwnedByCurrentUser: isOwnedByCurrentUser,
                servingDescription: servingDescription,
                servingGrams: servingGrams,
                caloriesPerServing: caloriesPerServing,
                proteinGramsPerServing: proteinGramsPerServing,
                carbGramsPerServing: carbGramsPerServing,
                fatGramsPerServing: fatGramsPerServing,
                fiberGramsPerServing: fiberGramsPerServing,
                sodiumMgPerServing: sodiumMgPerServing,
                isEstimated: isEstimated,
                archivedAt: archivedAt,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                Value<String?> alternateName = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                required String sourceType,
                Value<bool> isOwnedByCurrentUser = const Value.absent(),
                required String servingDescription,
                Value<double?> servingGrams = const Value.absent(),
                required double caloriesPerServing,
                required double proteinGramsPerServing,
                required double carbGramsPerServing,
                required double fatGramsPerServing,
                Value<double?> fiberGramsPerServing = const Value.absent(),
                Value<double?> sodiumMgPerServing = const Value.absent(),
                Value<bool> isEstimated = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedFoodsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                alternateName: alternateName,
                brand: brand,
                sourceType: sourceType,
                isOwnedByCurrentUser: isOwnedByCurrentUser,
                servingDescription: servingDescription,
                servingGrams: servingGrams,
                caloriesPerServing: caloriesPerServing,
                proteinGramsPerServing: proteinGramsPerServing,
                carbGramsPerServing: carbGramsPerServing,
                fatGramsPerServing: fatGramsPerServing,
                fiberGramsPerServing: fiberGramsPerServing,
                sodiumMgPerServing: sodiumMgPerServing,
                isEstimated: isEstimated,
                archivedAt: archivedAt,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedFoodsTable,
      CachedFood,
      $$CachedFoodsTableFilterComposer,
      $$CachedFoodsTableOrderingComposer,
      $$CachedFoodsTableAnnotationComposer,
      $$CachedFoodsTableCreateCompanionBuilder,
      $$CachedFoodsTableUpdateCompanionBuilder,
      (
        CachedFood,
        BaseReferences<_$AppDatabase, $CachedFoodsTable, CachedFood>,
      ),
      CachedFood,
      PrefetchHooks Function()
    >;
typedef $$CachedFoodServingsTableCreateCompanionBuilder =
    CachedFoodServingsCompanion Function({
      required String id,
      required String foodId,
      required String label,
      Value<double?> grams,
      Value<bool> isDefault,
      Value<int> rowid,
    });
typedef $$CachedFoodServingsTableUpdateCompanionBuilder =
    CachedFoodServingsCompanion Function({
      Value<String> id,
      Value<String> foodId,
      Value<String> label,
      Value<double?> grams,
      Value<bool> isDefault,
      Value<int> rowid,
    });

class $$CachedFoodServingsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedFoodServingsTable> {
  $$CachedFoodServingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFoodServingsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedFoodServingsTable> {
  $$CachedFoodServingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFoodServingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedFoodServingsTable> {
  $$CachedFoodServingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$CachedFoodServingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedFoodServingsTable,
          CachedFoodServing,
          $$CachedFoodServingsTableFilterComposer,
          $$CachedFoodServingsTableOrderingComposer,
          $$CachedFoodServingsTableAnnotationComposer,
          $$CachedFoodServingsTableCreateCompanionBuilder,
          $$CachedFoodServingsTableUpdateCompanionBuilder,
          (
            CachedFoodServing,
            BaseReferences<
              _$AppDatabase,
              $CachedFoodServingsTable,
              CachedFoodServing
            >,
          ),
          CachedFoodServing,
          PrefetchHooks Function()
        > {
  $$CachedFoodServingsTableTableManager(
    _$AppDatabase db,
    $CachedFoodServingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFoodServingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFoodServingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedFoodServingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> foodId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double?> grams = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFoodServingsCompanion(
                id: id,
                foodId: foodId,
                label: label,
                grams: grams,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String foodId,
                required String label,
                Value<double?> grams = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFoodServingsCompanion.insert(
                id: id,
                foodId: foodId,
                label: label,
                grams: grams,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFoodServingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedFoodServingsTable,
      CachedFoodServing,
      $$CachedFoodServingsTableFilterComposer,
      $$CachedFoodServingsTableOrderingComposer,
      $$CachedFoodServingsTableAnnotationComposer,
      $$CachedFoodServingsTableCreateCompanionBuilder,
      $$CachedFoodServingsTableUpdateCompanionBuilder,
      (
        CachedFoodServing,
        BaseReferences<
          _$AppDatabase,
          $CachedFoodServingsTable,
          CachedFoodServing
        >,
      ),
      CachedFoodServing,
      PrefetchHooks Function()
    >;
typedef $$CachedMealEntriesTableCreateCompanionBuilder =
    CachedMealEntriesCompanion Function({
      required String id,
      Value<String?> serverId,
      required String userId,
      required String foodId,
      required String foodName,
      Value<String?> foodBrand,
      Value<bool> foodIsEstimated,
      Value<String?> foodServingId,
      Value<String?> foodServingLabel,
      required String mealType,
      required String date,
      required double quantity,
      required double calories,
      required double proteinGrams,
      required double carbGrams,
      required double fatGrams,
      Value<double?> fiberGrams,
      Value<String?> notes,
      required String syncStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedMealEntriesTableUpdateCompanionBuilder =
    CachedMealEntriesCompanion Function({
      Value<String> id,
      Value<String?> serverId,
      Value<String> userId,
      Value<String> foodId,
      Value<String> foodName,
      Value<String?> foodBrand,
      Value<bool> foodIsEstimated,
      Value<String?> foodServingId,
      Value<String?> foodServingLabel,
      Value<String> mealType,
      Value<String> date,
      Value<double> quantity,
      Value<double> calories,
      Value<double> proteinGrams,
      Value<double> carbGrams,
      Value<double> fatGrams,
      Value<double?> fiberGrams,
      Value<String?> notes,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedMealEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMealEntriesTable> {
  $$CachedMealEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodName => $composableBuilder(
    column: $table.foodName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodBrand => $composableBuilder(
    column: $table.foodBrand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get foodIsEstimated => $composableBuilder(
    column: $table.foodIsEstimated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodServingId => $composableBuilder(
    column: $table.foodServingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodServingLabel => $composableBuilder(
    column: $table.foodServingLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinGrams => $composableBuilder(
    column: $table.proteinGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbGrams => $composableBuilder(
    column: $table.carbGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatGrams => $composableBuilder(
    column: $table.fatGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberGrams => $composableBuilder(
    column: $table.fiberGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMealEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMealEntriesTable> {
  $$CachedMealEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodName => $composableBuilder(
    column: $table.foodName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodBrand => $composableBuilder(
    column: $table.foodBrand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get foodIsEstimated => $composableBuilder(
    column: $table.foodIsEstimated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodServingId => $composableBuilder(
    column: $table.foodServingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodServingLabel => $composableBuilder(
    column: $table.foodServingLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinGrams => $composableBuilder(
    column: $table.proteinGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbGrams => $composableBuilder(
    column: $table.carbGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatGrams => $composableBuilder(
    column: $table.fatGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberGrams => $composableBuilder(
    column: $table.fiberGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMealEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMealEntriesTable> {
  $$CachedMealEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get foodName =>
      $composableBuilder(column: $table.foodName, builder: (column) => column);

  GeneratedColumn<String> get foodBrand =>
      $composableBuilder(column: $table.foodBrand, builder: (column) => column);

  GeneratedColumn<bool> get foodIsEstimated => $composableBuilder(
    column: $table.foodIsEstimated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get foodServingId => $composableBuilder(
    column: $table.foodServingId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get foodServingLabel => $composableBuilder(
    column: $table.foodServingLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get proteinGrams => $composableBuilder(
    column: $table.proteinGrams,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbGrams =>
      $composableBuilder(column: $table.carbGrams, builder: (column) => column);

  GeneratedColumn<double> get fatGrams =>
      $composableBuilder(column: $table.fatGrams, builder: (column) => column);

  GeneratedColumn<double> get fiberGrams => $composableBuilder(
    column: $table.fiberGrams,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedMealEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMealEntriesTable,
          CachedMealEntry,
          $$CachedMealEntriesTableFilterComposer,
          $$CachedMealEntriesTableOrderingComposer,
          $$CachedMealEntriesTableAnnotationComposer,
          $$CachedMealEntriesTableCreateCompanionBuilder,
          $$CachedMealEntriesTableUpdateCompanionBuilder,
          (
            CachedMealEntry,
            BaseReferences<
              _$AppDatabase,
              $CachedMealEntriesTable,
              CachedMealEntry
            >,
          ),
          CachedMealEntry,
          PrefetchHooks Function()
        > {
  $$CachedMealEntriesTableTableManager(
    _$AppDatabase db,
    $CachedMealEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMealEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMealEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMealEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> foodId = const Value.absent(),
                Value<String> foodName = const Value.absent(),
                Value<String?> foodBrand = const Value.absent(),
                Value<bool> foodIsEstimated = const Value.absent(),
                Value<String?> foodServingId = const Value.absent(),
                Value<String?> foodServingLabel = const Value.absent(),
                Value<String> mealType = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> calories = const Value.absent(),
                Value<double> proteinGrams = const Value.absent(),
                Value<double> carbGrams = const Value.absent(),
                Value<double> fatGrams = const Value.absent(),
                Value<double?> fiberGrams = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMealEntriesCompanion(
                id: id,
                serverId: serverId,
                userId: userId,
                foodId: foodId,
                foodName: foodName,
                foodBrand: foodBrand,
                foodIsEstimated: foodIsEstimated,
                foodServingId: foodServingId,
                foodServingLabel: foodServingLabel,
                mealType: mealType,
                date: date,
                quantity: quantity,
                calories: calories,
                proteinGrams: proteinGrams,
                carbGrams: carbGrams,
                fatGrams: fatGrams,
                fiberGrams: fiberGrams,
                notes: notes,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> serverId = const Value.absent(),
                required String userId,
                required String foodId,
                required String foodName,
                Value<String?> foodBrand = const Value.absent(),
                Value<bool> foodIsEstimated = const Value.absent(),
                Value<String?> foodServingId = const Value.absent(),
                Value<String?> foodServingLabel = const Value.absent(),
                required String mealType,
                required String date,
                required double quantity,
                required double calories,
                required double proteinGrams,
                required double carbGrams,
                required double fatGrams,
                Value<double?> fiberGrams = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required String syncStatus,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedMealEntriesCompanion.insert(
                id: id,
                serverId: serverId,
                userId: userId,
                foodId: foodId,
                foodName: foodName,
                foodBrand: foodBrand,
                foodIsEstimated: foodIsEstimated,
                foodServingId: foodServingId,
                foodServingLabel: foodServingLabel,
                mealType: mealType,
                date: date,
                quantity: quantity,
                calories: calories,
                proteinGrams: proteinGrams,
                carbGrams: carbGrams,
                fatGrams: fatGrams,
                fiberGrams: fiberGrams,
                notes: notes,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMealEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMealEntriesTable,
      CachedMealEntry,
      $$CachedMealEntriesTableFilterComposer,
      $$CachedMealEntriesTableOrderingComposer,
      $$CachedMealEntriesTableAnnotationComposer,
      $$CachedMealEntriesTableCreateCompanionBuilder,
      $$CachedMealEntriesTableUpdateCompanionBuilder,
      (
        CachedMealEntry,
        BaseReferences<_$AppDatabase, $CachedMealEntriesTable, CachedMealEntry>,
      ),
      CachedMealEntry,
      PrefetchHooks Function()
    >;
typedef $$CachedSavedMealsTableCreateCompanionBuilder =
    CachedSavedMealsCompanion Function({
      required String id,
      Value<String?> serverId,
      required String userId,
      required String name,
      required String itemsJson,
      required String syncStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedSavedMealsTableUpdateCompanionBuilder =
    CachedSavedMealsCompanion Function({
      Value<String> id,
      Value<String?> serverId,
      Value<String> userId,
      Value<String> name,
      Value<String> itemsJson,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedSavedMealsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSavedMealsTable> {
  $$CachedSavedMealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSavedMealsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSavedMealsTable> {
  $$CachedSavedMealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSavedMealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSavedMealsTable> {
  $$CachedSavedMealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedSavedMealsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedSavedMealsTable,
          CachedSavedMeal,
          $$CachedSavedMealsTableFilterComposer,
          $$CachedSavedMealsTableOrderingComposer,
          $$CachedSavedMealsTableAnnotationComposer,
          $$CachedSavedMealsTableCreateCompanionBuilder,
          $$CachedSavedMealsTableUpdateCompanionBuilder,
          (
            CachedSavedMeal,
            BaseReferences<
              _$AppDatabase,
              $CachedSavedMealsTable,
              CachedSavedMeal
            >,
          ),
          CachedSavedMeal,
          PrefetchHooks Function()
        > {
  $$CachedSavedMealsTableTableManager(
    _$AppDatabase db,
    $CachedSavedMealsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSavedMealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSavedMealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSavedMealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSavedMealsCompanion(
                id: id,
                serverId: serverId,
                userId: userId,
                name: name,
                itemsJson: itemsJson,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> serverId = const Value.absent(),
                required String userId,
                required String name,
                required String itemsJson,
                required String syncStatus,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedSavedMealsCompanion.insert(
                id: id,
                serverId: serverId,
                userId: userId,
                name: name,
                itemsJson: itemsJson,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSavedMealsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedSavedMealsTable,
      CachedSavedMeal,
      $$CachedSavedMealsTableFilterComposer,
      $$CachedSavedMealsTableOrderingComposer,
      $$CachedSavedMealsTableAnnotationComposer,
      $$CachedSavedMealsTableCreateCompanionBuilder,
      $$CachedSavedMealsTableUpdateCompanionBuilder,
      (
        CachedSavedMeal,
        BaseReferences<_$AppDatabase, $CachedSavedMealsTable, CachedSavedMeal>,
      ),
      CachedSavedMeal,
      PrefetchHooks Function()
    >;
typedef $$CachedWaterEntriesTableCreateCompanionBuilder =
    CachedWaterEntriesCompanion Function({
      required String id,
      Value<String?> serverId,
      required String userId,
      required String date,
      required int amountMl,
      required DateTime loggedAt,
      required String syncStatus,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedWaterEntriesTableUpdateCompanionBuilder =
    CachedWaterEntriesCompanion Function({
      Value<String> id,
      Value<String?> serverId,
      Value<String> userId,
      Value<String> date,
      Value<int> amountMl,
      Value<DateTime> loggedAt,
      Value<String> syncStatus,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedWaterEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedWaterEntriesTable> {
  $$CachedWaterEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedWaterEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedWaterEntriesTable> {
  $$CachedWaterEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedWaterEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedWaterEntriesTable> {
  $$CachedWaterEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get amountMl =>
      $composableBuilder(column: $table.amountMl, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedWaterEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedWaterEntriesTable,
          CachedWaterEntry,
          $$CachedWaterEntriesTableFilterComposer,
          $$CachedWaterEntriesTableOrderingComposer,
          $$CachedWaterEntriesTableAnnotationComposer,
          $$CachedWaterEntriesTableCreateCompanionBuilder,
          $$CachedWaterEntriesTableUpdateCompanionBuilder,
          (
            CachedWaterEntry,
            BaseReferences<
              _$AppDatabase,
              $CachedWaterEntriesTable,
              CachedWaterEntry
            >,
          ),
          CachedWaterEntry,
          PrefetchHooks Function()
        > {
  $$CachedWaterEntriesTableTableManager(
    _$AppDatabase db,
    $CachedWaterEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedWaterEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedWaterEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedWaterEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> amountMl = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedWaterEntriesCompanion(
                id: id,
                serverId: serverId,
                userId: userId,
                date: date,
                amountMl: amountMl,
                loggedAt: loggedAt,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> serverId = const Value.absent(),
                required String userId,
                required String date,
                required int amountMl,
                required DateTime loggedAt,
                required String syncStatus,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedWaterEntriesCompanion.insert(
                id: id,
                serverId: serverId,
                userId: userId,
                date: date,
                amountMl: amountMl,
                loggedAt: loggedAt,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedWaterEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedWaterEntriesTable,
      CachedWaterEntry,
      $$CachedWaterEntriesTableFilterComposer,
      $$CachedWaterEntriesTableOrderingComposer,
      $$CachedWaterEntriesTableAnnotationComposer,
      $$CachedWaterEntriesTableCreateCompanionBuilder,
      $$CachedWaterEntriesTableUpdateCompanionBuilder,
      (
        CachedWaterEntry,
        BaseReferences<
          _$AppDatabase,
          $CachedWaterEntriesTable,
          CachedWaterEntry
        >,
      ),
      CachedWaterEntry,
      PrefetchHooks Function()
    >;
typedef $$CachedMacroTargetsTableCreateCompanionBuilder =
    CachedMacroTargetsCompanion Function({
      required String userId,
      required int calorieTarget,
      required int proteinGramsTarget,
      required int carbGramsTarget,
      required int fatGramsTarget,
      Value<int?> fiberGramsTarget,
      Value<bool> isEstimatedDefault,
      required String disclaimer,
      Value<String> syncStatus,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedMacroTargetsTableUpdateCompanionBuilder =
    CachedMacroTargetsCompanion Function({
      Value<String> userId,
      Value<int> calorieTarget,
      Value<int> proteinGramsTarget,
      Value<int> carbGramsTarget,
      Value<int> fatGramsTarget,
      Value<int?> fiberGramsTarget,
      Value<bool> isEstimatedDefault,
      Value<String> disclaimer,
      Value<String> syncStatus,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedMacroTargetsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMacroTargetsTable> {
  $$CachedMacroTargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calorieTarget => $composableBuilder(
    column: $table.calorieTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get proteinGramsTarget => $composableBuilder(
    column: $table.proteinGramsTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbGramsTarget => $composableBuilder(
    column: $table.carbGramsTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fatGramsTarget => $composableBuilder(
    column: $table.fatGramsTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fiberGramsTarget => $composableBuilder(
    column: $table.fiberGramsTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEstimatedDefault => $composableBuilder(
    column: $table.isEstimatedDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get disclaimer => $composableBuilder(
    column: $table.disclaimer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMacroTargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMacroTargetsTable> {
  $$CachedMacroTargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calorieTarget => $composableBuilder(
    column: $table.calorieTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get proteinGramsTarget => $composableBuilder(
    column: $table.proteinGramsTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbGramsTarget => $composableBuilder(
    column: $table.carbGramsTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fatGramsTarget => $composableBuilder(
    column: $table.fatGramsTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fiberGramsTarget => $composableBuilder(
    column: $table.fiberGramsTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEstimatedDefault => $composableBuilder(
    column: $table.isEstimatedDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get disclaimer => $composableBuilder(
    column: $table.disclaimer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMacroTargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMacroTargetsTable> {
  $$CachedMacroTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get calorieTarget => $composableBuilder(
    column: $table.calorieTarget,
    builder: (column) => column,
  );

  GeneratedColumn<int> get proteinGramsTarget => $composableBuilder(
    column: $table.proteinGramsTarget,
    builder: (column) => column,
  );

  GeneratedColumn<int> get carbGramsTarget => $composableBuilder(
    column: $table.carbGramsTarget,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fatGramsTarget => $composableBuilder(
    column: $table.fatGramsTarget,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fiberGramsTarget => $composableBuilder(
    column: $table.fiberGramsTarget,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEstimatedDefault => $composableBuilder(
    column: $table.isEstimatedDefault,
    builder: (column) => column,
  );

  GeneratedColumn<String> get disclaimer => $composableBuilder(
    column: $table.disclaimer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedMacroTargetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMacroTargetsTable,
          CachedMacroTarget,
          $$CachedMacroTargetsTableFilterComposer,
          $$CachedMacroTargetsTableOrderingComposer,
          $$CachedMacroTargetsTableAnnotationComposer,
          $$CachedMacroTargetsTableCreateCompanionBuilder,
          $$CachedMacroTargetsTableUpdateCompanionBuilder,
          (
            CachedMacroTarget,
            BaseReferences<
              _$AppDatabase,
              $CachedMacroTargetsTable,
              CachedMacroTarget
            >,
          ),
          CachedMacroTarget,
          PrefetchHooks Function()
        > {
  $$CachedMacroTargetsTableTableManager(
    _$AppDatabase db,
    $CachedMacroTargetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMacroTargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMacroTargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMacroTargetsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<int> calorieTarget = const Value.absent(),
                Value<int> proteinGramsTarget = const Value.absent(),
                Value<int> carbGramsTarget = const Value.absent(),
                Value<int> fatGramsTarget = const Value.absent(),
                Value<int?> fiberGramsTarget = const Value.absent(),
                Value<bool> isEstimatedDefault = const Value.absent(),
                Value<String> disclaimer = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMacroTargetsCompanion(
                userId: userId,
                calorieTarget: calorieTarget,
                proteinGramsTarget: proteinGramsTarget,
                carbGramsTarget: carbGramsTarget,
                fatGramsTarget: fatGramsTarget,
                fiberGramsTarget: fiberGramsTarget,
                isEstimatedDefault: isEstimatedDefault,
                disclaimer: disclaimer,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required int calorieTarget,
                required int proteinGramsTarget,
                required int carbGramsTarget,
                required int fatGramsTarget,
                Value<int?> fiberGramsTarget = const Value.absent(),
                Value<bool> isEstimatedDefault = const Value.absent(),
                required String disclaimer,
                Value<String> syncStatus = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedMacroTargetsCompanion.insert(
                userId: userId,
                calorieTarget: calorieTarget,
                proteinGramsTarget: proteinGramsTarget,
                carbGramsTarget: carbGramsTarget,
                fatGramsTarget: fatGramsTarget,
                fiberGramsTarget: fiberGramsTarget,
                isEstimatedDefault: isEstimatedDefault,
                disclaimer: disclaimer,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMacroTargetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMacroTargetsTable,
      CachedMacroTarget,
      $$CachedMacroTargetsTableFilterComposer,
      $$CachedMacroTargetsTableOrderingComposer,
      $$CachedMacroTargetsTableAnnotationComposer,
      $$CachedMacroTargetsTableCreateCompanionBuilder,
      $$CachedMacroTargetsTableUpdateCompanionBuilder,
      (
        CachedMacroTarget,
        BaseReferences<
          _$AppDatabase,
          $CachedMacroTargetsTable,
          CachedMacroTarget
        >,
      ),
      CachedMacroTarget,
      PrefetchHooks Function()
    >;
typedef $$PendingCelebrationsTableCreateCompanionBuilder =
    PendingCelebrationsCompanion Function({
      required String id,
      required String userId,
      required String achievementId,
      required String achievementKey,
      required String title,
      required String description,
      required String iconAsset,
      required String category,
      required int targetSteps,
      required DateTime earnedAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PendingCelebrationsTableUpdateCompanionBuilder =
    PendingCelebrationsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> achievementId,
      Value<String> achievementKey,
      Value<String> title,
      Value<String> description,
      Value<String> iconAsset,
      Value<String> category,
      Value<int> targetSteps,
      Value<DateTime> earnedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PendingCelebrationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingCelebrationsTable> {
  $$PendingCelebrationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get achievementId => $composableBuilder(
    column: $table.achievementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get achievementKey => $composableBuilder(
    column: $table.achievementKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconAsset => $composableBuilder(
    column: $table.iconAsset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSteps => $composableBuilder(
    column: $table.targetSteps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingCelebrationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingCelebrationsTable> {
  $$PendingCelebrationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get achievementId => $composableBuilder(
    column: $table.achievementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get achievementKey => $composableBuilder(
    column: $table.achievementKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconAsset => $composableBuilder(
    column: $table.iconAsset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSteps => $composableBuilder(
    column: $table.targetSteps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingCelebrationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingCelebrationsTable> {
  $$PendingCelebrationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get achievementId => $composableBuilder(
    column: $table.achievementId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get achievementKey => $composableBuilder(
    column: $table.achievementKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconAsset =>
      $composableBuilder(column: $table.iconAsset, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get targetSteps => $composableBuilder(
    column: $table.targetSteps,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get earnedAt =>
      $composableBuilder(column: $table.earnedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingCelebrationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingCelebrationsTable,
          PendingCelebration,
          $$PendingCelebrationsTableFilterComposer,
          $$PendingCelebrationsTableOrderingComposer,
          $$PendingCelebrationsTableAnnotationComposer,
          $$PendingCelebrationsTableCreateCompanionBuilder,
          $$PendingCelebrationsTableUpdateCompanionBuilder,
          (
            PendingCelebration,
            BaseReferences<
              _$AppDatabase,
              $PendingCelebrationsTable,
              PendingCelebration
            >,
          ),
          PendingCelebration,
          PrefetchHooks Function()
        > {
  $$PendingCelebrationsTableTableManager(
    _$AppDatabase db,
    $PendingCelebrationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingCelebrationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingCelebrationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingCelebrationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> achievementId = const Value.absent(),
                Value<String> achievementKey = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> iconAsset = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> targetSteps = const Value.absent(),
                Value<DateTime> earnedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingCelebrationsCompanion(
                id: id,
                userId: userId,
                achievementId: achievementId,
                achievementKey: achievementKey,
                title: title,
                description: description,
                iconAsset: iconAsset,
                category: category,
                targetSteps: targetSteps,
                earnedAt: earnedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String achievementId,
                required String achievementKey,
                required String title,
                required String description,
                required String iconAsset,
                required String category,
                required int targetSteps,
                required DateTime earnedAt,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingCelebrationsCompanion.insert(
                id: id,
                userId: userId,
                achievementId: achievementId,
                achievementKey: achievementKey,
                title: title,
                description: description,
                iconAsset: iconAsset,
                category: category,
                targetSteps: targetSteps,
                earnedAt: earnedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingCelebrationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingCelebrationsTable,
      PendingCelebration,
      $$PendingCelebrationsTableFilterComposer,
      $$PendingCelebrationsTableOrderingComposer,
      $$PendingCelebrationsTableAnnotationComposer,
      $$PendingCelebrationsTableCreateCompanionBuilder,
      $$PendingCelebrationsTableUpdateCompanionBuilder,
      (
        PendingCelebration,
        BaseReferences<
          _$AppDatabase,
          $PendingCelebrationsTable,
          PendingCelebration
        >,
      ),
      PendingCelebration,
      PrefetchHooks Function()
    >;
typedef $$CachedCardioSessionRowsTableCreateCompanionBuilder =
    CachedCardioSessionRowsCompanion Function({
      required String id,
      required String sessionJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedCardioSessionRowsTableUpdateCompanionBuilder =
    CachedCardioSessionRowsCompanion Function({
      Value<String> id,
      Value<String> sessionJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedCardioSessionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCardioSessionRowsTable> {
  $$CachedCardioSessionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionJson => $composableBuilder(
    column: $table.sessionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCardioSessionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCardioSessionRowsTable> {
  $$CachedCardioSessionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionJson => $composableBuilder(
    column: $table.sessionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCardioSessionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCardioSessionRowsTable> {
  $$CachedCardioSessionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionJson => $composableBuilder(
    column: $table.sessionJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedCardioSessionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCardioSessionRowsTable,
          CachedCardioSessionRow,
          $$CachedCardioSessionRowsTableFilterComposer,
          $$CachedCardioSessionRowsTableOrderingComposer,
          $$CachedCardioSessionRowsTableAnnotationComposer,
          $$CachedCardioSessionRowsTableCreateCompanionBuilder,
          $$CachedCardioSessionRowsTableUpdateCompanionBuilder,
          (
            CachedCardioSessionRow,
            BaseReferences<
              _$AppDatabase,
              $CachedCardioSessionRowsTable,
              CachedCardioSessionRow
            >,
          ),
          CachedCardioSessionRow,
          PrefetchHooks Function()
        > {
  $$CachedCardioSessionRowsTableTableManager(
    _$AppDatabase db,
    $CachedCardioSessionRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCardioSessionRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedCardioSessionRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedCardioSessionRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCardioSessionRowsCompanion(
                id: id,
                sessionJson: sessionJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedCardioSessionRowsCompanion.insert(
                id: id,
                sessionJson: sessionJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCardioSessionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCardioSessionRowsTable,
      CachedCardioSessionRow,
      $$CachedCardioSessionRowsTableFilterComposer,
      $$CachedCardioSessionRowsTableOrderingComposer,
      $$CachedCardioSessionRowsTableAnnotationComposer,
      $$CachedCardioSessionRowsTableCreateCompanionBuilder,
      $$CachedCardioSessionRowsTableUpdateCompanionBuilder,
      (
        CachedCardioSessionRow,
        BaseReferences<
          _$AppDatabase,
          $CachedCardioSessionRowsTable,
          CachedCardioSessionRow
        >,
      ),
      CachedCardioSessionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedProfilesTableTableManager get cachedProfiles =>
      $$CachedProfilesTableTableManager(_db, _db.cachedProfiles);
  $$CachedPreferencesTableTableTableManager get cachedPreferencesTable =>
      $$CachedPreferencesTableTableTableManager(
        _db,
        _db.cachedPreferencesTable,
      );
  $$OnboardingDraftsTableTableManager get onboardingDrafts =>
      $$OnboardingDraftsTableTableManager(_db, _db.onboardingDrafts);
  $$SyncStatusRowsTableTableManager get syncStatusRows =>
      $$SyncStatusRowsTableTableManager(_db, _db.syncStatusRows);
  $$CachedWorkoutSessionRowsTableTableManager get cachedWorkoutSessionRows =>
      $$CachedWorkoutSessionRowsTableTableManager(
        _db,
        _db.cachedWorkoutSessionRows,
      );
  $$OutboxEntryRowsTableTableManager get outboxEntryRows =>
      $$OutboxEntryRowsTableTableManager(_db, _db.outboxEntryRows);
  $$CachedFoodsTableTableManager get cachedFoods =>
      $$CachedFoodsTableTableManager(_db, _db.cachedFoods);
  $$CachedFoodServingsTableTableManager get cachedFoodServings =>
      $$CachedFoodServingsTableTableManager(_db, _db.cachedFoodServings);
  $$CachedMealEntriesTableTableManager get cachedMealEntries =>
      $$CachedMealEntriesTableTableManager(_db, _db.cachedMealEntries);
  $$CachedSavedMealsTableTableManager get cachedSavedMeals =>
      $$CachedSavedMealsTableTableManager(_db, _db.cachedSavedMeals);
  $$CachedWaterEntriesTableTableManager get cachedWaterEntries =>
      $$CachedWaterEntriesTableTableManager(_db, _db.cachedWaterEntries);
  $$CachedMacroTargetsTableTableManager get cachedMacroTargets =>
      $$CachedMacroTargetsTableTableManager(_db, _db.cachedMacroTargets);
  $$PendingCelebrationsTableTableManager get pendingCelebrations =>
      $$PendingCelebrationsTableTableManager(_db, _db.pendingCelebrations);
  $$CachedCardioSessionRowsTableTableManager get cachedCardioSessionRows =>
      $$CachedCardioSessionRowsTableTableManager(
        _db,
        _db.cachedCardioSessionRows,
      );
}
