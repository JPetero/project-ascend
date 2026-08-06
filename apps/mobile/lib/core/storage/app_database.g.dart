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

class $CachedDashboardFixturesTable extends CachedDashboardFixtures
    with TableInfo<$CachedDashboardFixturesTable, CachedDashboardFixture> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDashboardFixturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dashboardJsonMeta = const VerificationMeta(
    'dashboardJson',
  );
  @override
  late final GeneratedColumn<String> dashboardJson = GeneratedColumn<String>(
    'dashboard_json',
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
  List<GeneratedColumn> get $columns => [userId, dashboardJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_dashboard_fixtures';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDashboardFixture> instance, {
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
    if (data.containsKey('dashboard_json')) {
      context.handle(
        _dashboardJsonMeta,
        dashboardJson.isAcceptableOrUnknown(
          data['dashboard_json']!,
          _dashboardJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dashboardJsonMeta);
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
  CachedDashboardFixture map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDashboardFixture(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      dashboardJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dashboard_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedDashboardFixturesTable createAlias(String alias) {
    return $CachedDashboardFixturesTable(attachedDatabase, alias);
  }
}

class CachedDashboardFixture extends DataClass
    implements Insertable<CachedDashboardFixture> {
  final String userId;
  final String dashboardJson;
  final DateTime updatedAt;
  const CachedDashboardFixture({
    required this.userId,
    required this.dashboardJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['dashboard_json'] = Variable<String>(dashboardJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedDashboardFixturesCompanion toCompanion(bool nullToAbsent) {
    return CachedDashboardFixturesCompanion(
      userId: Value(userId),
      dashboardJson: Value(dashboardJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedDashboardFixture.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDashboardFixture(
      userId: serializer.fromJson<String>(json['userId']),
      dashboardJson: serializer.fromJson<String>(json['dashboardJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'dashboardJson': serializer.toJson<String>(dashboardJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedDashboardFixture copyWith({
    String? userId,
    String? dashboardJson,
    DateTime? updatedAt,
  }) => CachedDashboardFixture(
    userId: userId ?? this.userId,
    dashboardJson: dashboardJson ?? this.dashboardJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedDashboardFixture copyWithCompanion(
    CachedDashboardFixturesCompanion data,
  ) {
    return CachedDashboardFixture(
      userId: data.userId.present ? data.userId.value : this.userId,
      dashboardJson: data.dashboardJson.present
          ? data.dashboardJson.value
          : this.dashboardJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDashboardFixture(')
          ..write('userId: $userId, ')
          ..write('dashboardJson: $dashboardJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, dashboardJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDashboardFixture &&
          other.userId == this.userId &&
          other.dashboardJson == this.dashboardJson &&
          other.updatedAt == this.updatedAt);
}

class CachedDashboardFixturesCompanion
    extends UpdateCompanion<CachedDashboardFixture> {
  final Value<String> userId;
  final Value<String> dashboardJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedDashboardFixturesCompanion({
    this.userId = const Value.absent(),
    this.dashboardJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedDashboardFixturesCompanion.insert({
    required String userId,
    required String dashboardJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       dashboardJson = Value(dashboardJson),
       updatedAt = Value(updatedAt);
  static Insertable<CachedDashboardFixture> custom({
    Expression<String>? userId,
    Expression<String>? dashboardJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (dashboardJson != null) 'dashboard_json': dashboardJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedDashboardFixturesCompanion copyWith({
    Value<String>? userId,
    Value<String>? dashboardJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedDashboardFixturesCompanion(
      userId: userId ?? this.userId,
      dashboardJson: dashboardJson ?? this.dashboardJson,
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
    if (dashboardJson.present) {
      map['dashboard_json'] = Variable<String>(dashboardJson.value);
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
    return (StringBuffer('CachedDashboardFixturesCompanion(')
          ..write('userId: $userId, ')
          ..write('dashboardJson: $dashboardJson, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedProfilesTable cachedProfiles = $CachedProfilesTable(this);
  late final $CachedPreferencesTableTable cachedPreferencesTable =
      $CachedPreferencesTableTable(this);
  late final $CachedDashboardFixturesTable cachedDashboardFixtures =
      $CachedDashboardFixturesTable(this);
  late final $OnboardingDraftsTable onboardingDrafts = $OnboardingDraftsTable(
    this,
  );
  late final $SyncStatusRowsTable syncStatusRows = $SyncStatusRowsTable(this);
  late final $CachedWorkoutSessionRowsTable cachedWorkoutSessionRows =
      $CachedWorkoutSessionRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedProfiles,
    cachedPreferencesTable,
    cachedDashboardFixtures,
    onboardingDrafts,
    syncStatusRows,
    cachedWorkoutSessionRows,
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
typedef $$CachedDashboardFixturesTableCreateCompanionBuilder =
    CachedDashboardFixturesCompanion Function({
      required String userId,
      required String dashboardJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedDashboardFixturesTableUpdateCompanionBuilder =
    CachedDashboardFixturesCompanion Function({
      Value<String> userId,
      Value<String> dashboardJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedDashboardFixturesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedDashboardFixturesTable> {
  $$CachedDashboardFixturesTableFilterComposer({
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

  ColumnFilters<String> get dashboardJson => $composableBuilder(
    column: $table.dashboardJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedDashboardFixturesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedDashboardFixturesTable> {
  $$CachedDashboardFixturesTableOrderingComposer({
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

  ColumnOrderings<String> get dashboardJson => $composableBuilder(
    column: $table.dashboardJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedDashboardFixturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedDashboardFixturesTable> {
  $$CachedDashboardFixturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get dashboardJson => $composableBuilder(
    column: $table.dashboardJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedDashboardFixturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedDashboardFixturesTable,
          CachedDashboardFixture,
          $$CachedDashboardFixturesTableFilterComposer,
          $$CachedDashboardFixturesTableOrderingComposer,
          $$CachedDashboardFixturesTableAnnotationComposer,
          $$CachedDashboardFixturesTableCreateCompanionBuilder,
          $$CachedDashboardFixturesTableUpdateCompanionBuilder,
          (
            CachedDashboardFixture,
            BaseReferences<
              _$AppDatabase,
              $CachedDashboardFixturesTable,
              CachedDashboardFixture
            >,
          ),
          CachedDashboardFixture,
          PrefetchHooks Function()
        > {
  $$CachedDashboardFixturesTableTableManager(
    _$AppDatabase db,
    $CachedDashboardFixturesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDashboardFixturesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedDashboardFixturesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedDashboardFixturesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> dashboardJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedDashboardFixturesCompanion(
                userId: userId,
                dashboardJson: dashboardJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String dashboardJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedDashboardFixturesCompanion.insert(
                userId: userId,
                dashboardJson: dashboardJson,
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

typedef $$CachedDashboardFixturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedDashboardFixturesTable,
      CachedDashboardFixture,
      $$CachedDashboardFixturesTableFilterComposer,
      $$CachedDashboardFixturesTableOrderingComposer,
      $$CachedDashboardFixturesTableAnnotationComposer,
      $$CachedDashboardFixturesTableCreateCompanionBuilder,
      $$CachedDashboardFixturesTableUpdateCompanionBuilder,
      (
        CachedDashboardFixture,
        BaseReferences<
          _$AppDatabase,
          $CachedDashboardFixturesTable,
          CachedDashboardFixture
        >,
      ),
      CachedDashboardFixture,
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
  $$CachedDashboardFixturesTableTableManager get cachedDashboardFixtures =>
      $$CachedDashboardFixturesTableTableManager(
        _db,
        _db.cachedDashboardFixtures,
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
}
