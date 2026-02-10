// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MatchesTable extends Matches
    with TableInfo<$MatchesTable, BasketballMatch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tournamentIdMeta = const VerificationMeta(
    'tournamentId',
  );
  @override
  late final GeneratedColumn<String> tournamentId = GeneratedColumn<String>(
    'tournament_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamANameMeta = const VerificationMeta(
    'teamAName',
  );
  @override
  late final GeneratedColumn<String> teamAName = GeneratedColumn<String>(
    'team_a_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamBNameMeta = const VerificationMeta(
    'teamBName',
  );
  @override
  late final GeneratedColumn<String> teamBName = GeneratedColumn<String>(
    'team_b_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _scoreAMeta = const VerificationMeta('scoreA');
  @override
  late final GeneratedColumn<int> scoreA = GeneratedColumn<int>(
    'score_a',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoreBMeta = const VerificationMeta('scoreB');
  @override
  late final GeneratedColumn<int> scoreB = GeneratedColumn<int>(
    'score_b',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    isSynced,
    tournamentId,
    teamAName,
    teamBName,
    scheduledDate,
    status,
    scoreA,
    scoreB,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'matches';
  @override
  VerificationContext validateIntegrity(
    Insertable<BasketballMatch> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('tournament_id')) {
      context.handle(
        _tournamentIdMeta,
        tournamentId.isAcceptableOrUnknown(
          data['tournament_id']!,
          _tournamentIdMeta,
        ),
      );
    }
    if (data.containsKey('team_a_name')) {
      context.handle(
        _teamANameMeta,
        teamAName.isAcceptableOrUnknown(data['team_a_name']!, _teamANameMeta),
      );
    } else if (isInserting) {
      context.missing(_teamANameMeta);
    }
    if (data.containsKey('team_b_name')) {
      context.handle(
        _teamBNameMeta,
        teamBName.isAcceptableOrUnknown(data['team_b_name']!, _teamBNameMeta),
      );
    } else if (isInserting) {
      context.missing(_teamBNameMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('score_a')) {
      context.handle(
        _scoreAMeta,
        scoreA.isAcceptableOrUnknown(data['score_a']!, _scoreAMeta),
      );
    }
    if (data.containsKey('score_b')) {
      context.handle(
        _scoreBMeta,
        scoreB.isAcceptableOrUnknown(data['score_b']!, _scoreBMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BasketballMatch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BasketballMatch(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      tournamentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tournament_id'],
      ),
      teamAName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_a_name'],
      )!,
      teamBName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_b_name'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      scoreA: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_a'],
      )!,
      scoreB: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_b'],
      )!,
    );
  }

  @override
  $MatchesTable createAlias(String alias) {
    return $MatchesTable(attachedDatabase, alias);
  }
}

class BasketballMatch extends DataClass implements Insertable<BasketballMatch> {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  final String? tournamentId;
  final String teamAName;
  final String teamBName;
  final DateTime scheduledDate;
  final String status;
  final int scoreA;
  final int scoreB;
  const BasketballMatch({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.isSynced,
    this.tournamentId,
    required this.teamAName,
    required this.teamBName,
    required this.scheduledDate,
    required this.status,
    required this.scoreA,
    required this.scoreB,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || tournamentId != null) {
      map['tournament_id'] = Variable<String>(tournamentId);
    }
    map['team_a_name'] = Variable<String>(teamAName);
    map['team_b_name'] = Variable<String>(teamBName);
    map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    map['status'] = Variable<String>(status);
    map['score_a'] = Variable<int>(scoreA);
    map['score_b'] = Variable<int>(scoreB);
    return map;
  }

  MatchesCompanion toCompanion(bool nullToAbsent) {
    return MatchesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isSynced: Value(isSynced),
      tournamentId: tournamentId == null && nullToAbsent
          ? const Value.absent()
          : Value(tournamentId),
      teamAName: Value(teamAName),
      teamBName: Value(teamBName),
      scheduledDate: Value(scheduledDate),
      status: Value(status),
      scoreA: Value(scoreA),
      scoreB: Value(scoreB),
    );
  }

  factory BasketballMatch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BasketballMatch(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      tournamentId: serializer.fromJson<String?>(json['tournamentId']),
      teamAName: serializer.fromJson<String>(json['teamAName']),
      teamBName: serializer.fromJson<String>(json['teamBName']),
      scheduledDate: serializer.fromJson<DateTime>(json['scheduledDate']),
      status: serializer.fromJson<String>(json['status']),
      scoreA: serializer.fromJson<int>(json['scoreA']),
      scoreB: serializer.fromJson<int>(json['scoreB']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'tournamentId': serializer.toJson<String?>(tournamentId),
      'teamAName': serializer.toJson<String>(teamAName),
      'teamBName': serializer.toJson<String>(teamBName),
      'scheduledDate': serializer.toJson<DateTime>(scheduledDate),
      'status': serializer.toJson<String>(status),
      'scoreA': serializer.toJson<int>(scoreA),
      'scoreB': serializer.toJson<int>(scoreB),
    };
  }

  BasketballMatch copyWith({
    String? id,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isSynced,
    Value<String?> tournamentId = const Value.absent(),
    String? teamAName,
    String? teamBName,
    DateTime? scheduledDate,
    String? status,
    int? scoreA,
    int? scoreB,
  }) => BasketballMatch(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
    tournamentId: tournamentId.present ? tournamentId.value : this.tournamentId,
    teamAName: teamAName ?? this.teamAName,
    teamBName: teamBName ?? this.teamBName,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    status: status ?? this.status,
    scoreA: scoreA ?? this.scoreA,
    scoreB: scoreB ?? this.scoreB,
  );
  BasketballMatch copyWithCompanion(MatchesCompanion data) {
    return BasketballMatch(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      tournamentId: data.tournamentId.present
          ? data.tournamentId.value
          : this.tournamentId,
      teamAName: data.teamAName.present ? data.teamAName.value : this.teamAName,
      teamBName: data.teamBName.present ? data.teamBName.value : this.teamBName,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      status: data.status.present ? data.status.value : this.status,
      scoreA: data.scoreA.present ? data.scoreA.value : this.scoreA,
      scoreB: data.scoreB.present ? data.scoreB.value : this.scoreB,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BasketballMatch(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('teamAName: $teamAName, ')
          ..write('teamBName: $teamBName, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('status: $status, ')
          ..write('scoreA: $scoreA, ')
          ..write('scoreB: $scoreB')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    isSynced,
    tournamentId,
    teamAName,
    teamBName,
    scheduledDate,
    status,
    scoreA,
    scoreB,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BasketballMatch &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced &&
          other.tournamentId == this.tournamentId &&
          other.teamAName == this.teamAName &&
          other.teamBName == this.teamBName &&
          other.scheduledDate == this.scheduledDate &&
          other.status == this.status &&
          other.scoreA == this.scoreA &&
          other.scoreB == this.scoreB);
}

class MatchesCompanion extends UpdateCompanion<BasketballMatch> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<bool> isSynced;
  final Value<String?> tournamentId;
  final Value<String> teamAName;
  final Value<String> teamBName;
  final Value<DateTime> scheduledDate;
  final Value<String> status;
  final Value<int> scoreA;
  final Value<int> scoreB;
  final Value<int> rowid;
  const MatchesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.tournamentId = const Value.absent(),
    this.teamAName = const Value.absent(),
    this.teamBName = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.status = const Value.absent(),
    this.scoreA = const Value.absent(),
    this.scoreB = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.tournamentId = const Value.absent(),
    required String teamAName,
    required String teamBName,
    required DateTime scheduledDate,
    this.status = const Value.absent(),
    this.scoreA = const Value.absent(),
    this.scoreB = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : teamAName = Value(teamAName),
       teamBName = Value(teamBName),
       scheduledDate = Value(scheduledDate);
  static Insertable<BasketballMatch> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<String>? tournamentId,
    Expression<String>? teamAName,
    Expression<String>? teamBName,
    Expression<DateTime>? scheduledDate,
    Expression<String>? status,
    Expression<int>? scoreA,
    Expression<int>? scoreB,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (tournamentId != null) 'tournament_id': tournamentId,
      if (teamAName != null) 'team_a_name': teamAName,
      if (teamBName != null) 'team_b_name': teamBName,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (status != null) 'status': status,
      if (scoreA != null) 'score_a': scoreA,
      if (scoreB != null) 'score_b': scoreB,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<bool>? isSynced,
    Value<String?>? tournamentId,
    Value<String>? teamAName,
    Value<String>? teamBName,
    Value<DateTime>? scheduledDate,
    Value<String>? status,
    Value<int>? scoreA,
    Value<int>? scoreB,
    Value<int>? rowid,
  }) {
    return MatchesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      tournamentId: tournamentId ?? this.tournamentId,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (tournamentId.present) {
      map['tournament_id'] = Variable<String>(tournamentId.value);
    }
    if (teamAName.present) {
      map['team_a_name'] = Variable<String>(teamAName.value);
    }
    if (teamBName.present) {
      map['team_b_name'] = Variable<String>(teamBName.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (scoreA.present) {
      map['score_a'] = Variable<int>(scoreA.value);
    }
    if (scoreB.present) {
      map['score_b'] = Variable<int>(scoreB.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('teamAName: $teamAName, ')
          ..write('teamBName: $teamBName, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('status: $status, ')
          ..write('scoreA: $scoreA, ')
          ..write('scoreB: $scoreB, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayersTable extends Players with TableInfo<$PlayersTable, Player> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamNameReferenceMeta = const VerificationMeta(
    'teamNameReference',
  );
  @override
  late final GeneratedColumn<String> teamNameReference =
      GeneratedColumn<String>(
        'team_name_reference',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    isSynced,
    fullName,
    photoPath,
    teamNameReference,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<Player> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('team_name_reference')) {
      context.handle(
        _teamNameReferenceMeta,
        teamNameReference.isAcceptableOrUnknown(
          data['team_name_reference']!,
          _teamNameReferenceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Player map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Player(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      teamNameReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_name_reference'],
      ),
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class Player extends DataClass implements Insertable<Player> {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  final String fullName;
  final String? photoPath;
  final String? teamNameReference;
  const Player({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.isSynced,
    required this.fullName,
    this.photoPath,
    this.teamNameReference,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || teamNameReference != null) {
      map['team_name_reference'] = Variable<String>(teamNameReference);
    }
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isSynced: Value(isSynced),
      fullName: Value(fullName),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      teamNameReference: teamNameReference == null && nullToAbsent
          ? const Value.absent()
          : Value(teamNameReference),
    );
  }

  factory Player.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Player(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      fullName: serializer.fromJson<String>(json['fullName']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      teamNameReference: serializer.fromJson<String?>(
        json['teamNameReference'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'fullName': serializer.toJson<String>(fullName),
      'photoPath': serializer.toJson<String?>(photoPath),
      'teamNameReference': serializer.toJson<String?>(teamNameReference),
    };
  }

  Player copyWith({
    String? id,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isSynced,
    String? fullName,
    Value<String?> photoPath = const Value.absent(),
    Value<String?> teamNameReference = const Value.absent(),
  }) => Player(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
    fullName: fullName ?? this.fullName,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    teamNameReference: teamNameReference.present
        ? teamNameReference.value
        : this.teamNameReference,
  );
  Player copyWithCompanion(PlayersCompanion data) {
    return Player(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      teamNameReference: data.teamNameReference.present
          ? data.teamNameReference.value
          : this.teamNameReference,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Player(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('fullName: $fullName, ')
          ..write('photoPath: $photoPath, ')
          ..write('teamNameReference: $teamNameReference')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    isSynced,
    fullName,
    photoPath,
    teamNameReference,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Player &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced &&
          other.fullName == this.fullName &&
          other.photoPath == this.photoPath &&
          other.teamNameReference == this.teamNameReference);
}

class PlayersCompanion extends UpdateCompanion<Player> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<bool> isSynced;
  final Value<String> fullName;
  final Value<String?> photoPath;
  final Value<String?> teamNameReference;
  final Value<int> rowid;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.fullName = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.teamNameReference = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayersCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    required String fullName,
    this.photoPath = const Value.absent(),
    this.teamNameReference = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fullName = Value(fullName);
  static Insertable<Player> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<String>? fullName,
    Expression<String>? photoPath,
    Expression<String>? teamNameReference,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (fullName != null) 'full_name': fullName,
      if (photoPath != null) 'photo_path': photoPath,
      if (teamNameReference != null) 'team_name_reference': teamNameReference,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<bool>? isSynced,
    Value<String>? fullName,
    Value<String?>? photoPath,
    Value<String?>? teamNameReference,
    Value<int>? rowid,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      fullName: fullName ?? this.fullName,
      photoPath: photoPath ?? this.photoPath,
      teamNameReference: teamNameReference ?? this.teamNameReference,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (teamNameReference.present) {
      map['team_name_reference'] = Variable<String>(teamNameReference.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('fullName: $fullName, ')
          ..write('photoPath: $photoPath, ')
          ..write('teamNameReference: $teamNameReference, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatchRostersTable extends MatchRosters
    with TableInfo<$MatchRostersTable, RosterEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchRostersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES matches (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _teamSideMeta = const VerificationMeta(
    'teamSide',
  );
  @override
  late final GeneratedColumn<String> teamSide = GeneratedColumn<String>(
    'team_side',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jerseyNumberMeta = const VerificationMeta(
    'jerseyNumber',
  );
  @override
  late final GeneratedColumn<int> jerseyNumber = GeneratedColumn<int>(
    'jersey_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCaptainMeta = const VerificationMeta(
    'isCaptain',
  );
  @override
  late final GeneratedColumn<bool> isCaptain = GeneratedColumn<bool>(
    'is_captain',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_captain" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    isSynced,
    matchId,
    playerId,
    teamSide,
    jerseyNumber,
    isCaptain,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'match_rosters';
  @override
  VerificationContext validateIntegrity(
    Insertable<RosterEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('team_side')) {
      context.handle(
        _teamSideMeta,
        teamSide.isAcceptableOrUnknown(data['team_side']!, _teamSideMeta),
      );
    } else if (isInserting) {
      context.missing(_teamSideMeta);
    }
    if (data.containsKey('jersey_number')) {
      context.handle(
        _jerseyNumberMeta,
        jerseyNumber.isAcceptableOrUnknown(
          data['jersey_number']!,
          _jerseyNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jerseyNumberMeta);
    }
    if (data.containsKey('is_captain')) {
      context.handle(
        _isCaptainMeta,
        isCaptain.isAcceptableOrUnknown(data['is_captain']!, _isCaptainMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {matchId, playerId},
  ];
  @override
  RosterEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RosterEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      teamSide: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_side'],
      )!,
      jerseyNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jersey_number'],
      )!,
      isCaptain: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_captain'],
      )!,
    );
  }

  @override
  $MatchRostersTable createAlias(String alias) {
    return $MatchRostersTable(attachedDatabase, alias);
  }
}

class RosterEntry extends DataClass implements Insertable<RosterEntry> {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  final String matchId;
  final String playerId;
  final String teamSide;
  final int jerseyNumber;
  final bool isCaptain;
  const RosterEntry({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.isSynced,
    required this.matchId,
    required this.playerId,
    required this.teamSide,
    required this.jerseyNumber,
    required this.isCaptain,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['match_id'] = Variable<String>(matchId);
    map['player_id'] = Variable<String>(playerId);
    map['team_side'] = Variable<String>(teamSide);
    map['jersey_number'] = Variable<int>(jerseyNumber);
    map['is_captain'] = Variable<bool>(isCaptain);
    return map;
  }

  MatchRostersCompanion toCompanion(bool nullToAbsent) {
    return MatchRostersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isSynced: Value(isSynced),
      matchId: Value(matchId),
      playerId: Value(playerId),
      teamSide: Value(teamSide),
      jerseyNumber: Value(jerseyNumber),
      isCaptain: Value(isCaptain),
    );
  }

  factory RosterEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RosterEntry(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      matchId: serializer.fromJson<String>(json['matchId']),
      playerId: serializer.fromJson<String>(json['playerId']),
      teamSide: serializer.fromJson<String>(json['teamSide']),
      jerseyNumber: serializer.fromJson<int>(json['jerseyNumber']),
      isCaptain: serializer.fromJson<bool>(json['isCaptain']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'matchId': serializer.toJson<String>(matchId),
      'playerId': serializer.toJson<String>(playerId),
      'teamSide': serializer.toJson<String>(teamSide),
      'jerseyNumber': serializer.toJson<int>(jerseyNumber),
      'isCaptain': serializer.toJson<bool>(isCaptain),
    };
  }

  RosterEntry copyWith({
    String? id,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isSynced,
    String? matchId,
    String? playerId,
    String? teamSide,
    int? jerseyNumber,
    bool? isCaptain,
  }) => RosterEntry(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
    matchId: matchId ?? this.matchId,
    playerId: playerId ?? this.playerId,
    teamSide: teamSide ?? this.teamSide,
    jerseyNumber: jerseyNumber ?? this.jerseyNumber,
    isCaptain: isCaptain ?? this.isCaptain,
  );
  RosterEntry copyWithCompanion(MatchRostersCompanion data) {
    return RosterEntry(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      teamSide: data.teamSide.present ? data.teamSide.value : this.teamSide,
      jerseyNumber: data.jerseyNumber.present
          ? data.jerseyNumber.value
          : this.jerseyNumber,
      isCaptain: data.isCaptain.present ? data.isCaptain.value : this.isCaptain,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RosterEntry(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('matchId: $matchId, ')
          ..write('playerId: $playerId, ')
          ..write('teamSide: $teamSide, ')
          ..write('jerseyNumber: $jerseyNumber, ')
          ..write('isCaptain: $isCaptain')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    isSynced,
    matchId,
    playerId,
    teamSide,
    jerseyNumber,
    isCaptain,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RosterEntry &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced &&
          other.matchId == this.matchId &&
          other.playerId == this.playerId &&
          other.teamSide == this.teamSide &&
          other.jerseyNumber == this.jerseyNumber &&
          other.isCaptain == this.isCaptain);
}

class MatchRostersCompanion extends UpdateCompanion<RosterEntry> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<bool> isSynced;
  final Value<String> matchId;
  final Value<String> playerId;
  final Value<String> teamSide;
  final Value<int> jerseyNumber;
  final Value<bool> isCaptain;
  final Value<int> rowid;
  const MatchRostersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.matchId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.teamSide = const Value.absent(),
    this.jerseyNumber = const Value.absent(),
    this.isCaptain = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchRostersCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    required String matchId,
    required String playerId,
    required String teamSide,
    required int jerseyNumber,
    this.isCaptain = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : matchId = Value(matchId),
       playerId = Value(playerId),
       teamSide = Value(teamSide),
       jerseyNumber = Value(jerseyNumber);
  static Insertable<RosterEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<String>? matchId,
    Expression<String>? playerId,
    Expression<String>? teamSide,
    Expression<int>? jerseyNumber,
    Expression<bool>? isCaptain,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (matchId != null) 'match_id': matchId,
      if (playerId != null) 'player_id': playerId,
      if (teamSide != null) 'team_side': teamSide,
      if (jerseyNumber != null) 'jersey_number': jerseyNumber,
      if (isCaptain != null) 'is_captain': isCaptain,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchRostersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<bool>? isSynced,
    Value<String>? matchId,
    Value<String>? playerId,
    Value<String>? teamSide,
    Value<int>? jerseyNumber,
    Value<bool>? isCaptain,
    Value<int>? rowid,
  }) {
    return MatchRostersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      teamSide: teamSide ?? this.teamSide,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      isCaptain: isCaptain ?? this.isCaptain,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (teamSide.present) {
      map['team_side'] = Variable<String>(teamSide.value);
    }
    if (jerseyNumber.present) {
      map['jersey_number'] = Variable<int>(jerseyNumber.value);
    }
    if (isCaptain.present) {
      map['is_captain'] = Variable<bool>(isCaptain.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchRostersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('matchId: $matchId, ')
          ..write('playerId: $playerId, ')
          ..write('teamSide: $teamSide, ')
          ..write('jerseyNumber: $jerseyNumber, ')
          ..write('isCaptain: $isCaptain, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GameEventsTable extends GameEvents
    with TableInfo<$GameEventsTable, GameEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES matches (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<int> period = GeneratedColumn<int>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clockTimeMeta = const VerificationMeta(
    'clockTime',
  );
  @override
  late final GeneratedColumn<String> clockTime = GeneratedColumn<String>(
    'clock_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    isSynced,
    matchId,
    playerId,
    type,
    period,
    clockTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('clock_time')) {
      context.handle(
        _clockTimeMeta,
        clockTime.isAcceptableOrUnknown(data['clock_time']!, _clockTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_clockTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period'],
      )!,
      clockTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clock_time'],
      )!,
    );
  }

  @override
  $GameEventsTable createAlias(String alias) {
    return $GameEventsTable(attachedDatabase, alias);
  }
}

class GameEvent extends DataClass implements Insertable<GameEvent> {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  final String matchId;
  final String? playerId;
  final String type;
  final int period;
  final String clockTime;
  const GameEvent({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.isSynced,
    required this.matchId,
    this.playerId,
    required this.type,
    required this.period,
    required this.clockTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['match_id'] = Variable<String>(matchId);
    if (!nullToAbsent || playerId != null) {
      map['player_id'] = Variable<String>(playerId);
    }
    map['type'] = Variable<String>(type);
    map['period'] = Variable<int>(period);
    map['clock_time'] = Variable<String>(clockTime);
    return map;
  }

  GameEventsCompanion toCompanion(bool nullToAbsent) {
    return GameEventsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isSynced: Value(isSynced),
      matchId: Value(matchId),
      playerId: playerId == null && nullToAbsent
          ? const Value.absent()
          : Value(playerId),
      type: Value(type),
      period: Value(period),
      clockTime: Value(clockTime),
    );
  }

  factory GameEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameEvent(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      matchId: serializer.fromJson<String>(json['matchId']),
      playerId: serializer.fromJson<String?>(json['playerId']),
      type: serializer.fromJson<String>(json['type']),
      period: serializer.fromJson<int>(json['period']),
      clockTime: serializer.fromJson<String>(json['clockTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'matchId': serializer.toJson<String>(matchId),
      'playerId': serializer.toJson<String?>(playerId),
      'type': serializer.toJson<String>(type),
      'period': serializer.toJson<int>(period),
      'clockTime': serializer.toJson<String>(clockTime),
    };
  }

  GameEvent copyWith({
    String? id,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isSynced,
    String? matchId,
    Value<String?> playerId = const Value.absent(),
    String? type,
    int? period,
    String? clockTime,
  }) => GameEvent(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
    matchId: matchId ?? this.matchId,
    playerId: playerId.present ? playerId.value : this.playerId,
    type: type ?? this.type,
    period: period ?? this.period,
    clockTime: clockTime ?? this.clockTime,
  );
  GameEvent copyWithCompanion(GameEventsCompanion data) {
    return GameEvent(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      type: data.type.present ? data.type.value : this.type,
      period: data.period.present ? data.period.value : this.period,
      clockTime: data.clockTime.present ? data.clockTime.value : this.clockTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameEvent(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('matchId: $matchId, ')
          ..write('playerId: $playerId, ')
          ..write('type: $type, ')
          ..write('period: $period, ')
          ..write('clockTime: $clockTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    isSynced,
    matchId,
    playerId,
    type,
    period,
    clockTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameEvent &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced &&
          other.matchId == this.matchId &&
          other.playerId == this.playerId &&
          other.type == this.type &&
          other.period == this.period &&
          other.clockTime == this.clockTime);
}

class GameEventsCompanion extends UpdateCompanion<GameEvent> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<bool> isSynced;
  final Value<String> matchId;
  final Value<String?> playerId;
  final Value<String> type;
  final Value<int> period;
  final Value<String> clockTime;
  final Value<int> rowid;
  const GameEventsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.matchId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.type = const Value.absent(),
    this.period = const Value.absent(),
    this.clockTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GameEventsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    required String matchId,
    this.playerId = const Value.absent(),
    required String type,
    required int period,
    required String clockTime,
    this.rowid = const Value.absent(),
  }) : matchId = Value(matchId),
       type = Value(type),
       period = Value(period),
       clockTime = Value(clockTime);
  static Insertable<GameEvent> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<String>? matchId,
    Expression<String>? playerId,
    Expression<String>? type,
    Expression<int>? period,
    Expression<String>? clockTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (matchId != null) 'match_id': matchId,
      if (playerId != null) 'player_id': playerId,
      if (type != null) 'type': type,
      if (period != null) 'period': period,
      if (clockTime != null) 'clock_time': clockTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GameEventsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<bool>? isSynced,
    Value<String>? matchId,
    Value<String?>? playerId,
    Value<String>? type,
    Value<int>? period,
    Value<String>? clockTime,
    Value<int>? rowid,
  }) {
    return GameEventsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      type: type ?? this.type,
      period: period ?? this.period,
      clockTime: clockTime ?? this.clockTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (period.present) {
      map['period'] = Variable<int>(period.value);
    }
    if (clockTime.present) {
      map['clock_time'] = Variable<String>(clockTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameEventsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('matchId: $matchId, ')
          ..write('playerId: $playerId, ')
          ..write('type: $type, ')
          ..write('period: $period, ')
          ..write('clockTime: $clockTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TournamentsTable extends Tournaments
    with TableInfo<$TournamentsTable, Tournament> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TournamentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 150,
    ),
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    isSynced,
    name,
    category,
    status,
    startDate,
    endDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tournaments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tournament> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tournament map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tournament(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
    );
  }

  @override
  $TournamentsTable createAlias(String alias) {
    return $TournamentsTable(attachedDatabase, alias);
  }
}

class Tournament extends DataClass implements Insertable<Tournament> {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  final String name;
  final String? category;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  const Tournament({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.isSynced,
    required this.name,
    this.category,
    required this.status,
    this.startDate,
    this.endDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    return map;
  }

  TournamentsCompanion toCompanion(bool nullToAbsent) {
    return TournamentsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isSynced: Value(isSynced),
      name: Value(name),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      status: Value(status),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
    );
  }

  factory Tournament.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tournament(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String?>(json['category']),
      status: serializer.fromJson<String>(json['status']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String?>(category),
      'status': serializer.toJson<String>(status),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
    };
  }

  Tournament copyWith({
    String? id,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isSynced,
    String? name,
    Value<String?> category = const Value.absent(),
    String? status,
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> endDate = const Value.absent(),
  }) => Tournament(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
    name: name ?? this.name,
    category: category.present ? category.value : this.category,
    status: status ?? this.status,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
  );
  Tournament copyWithCompanion(TournamentsCompanion data) {
    return Tournament(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      status: data.status.present ? data.status.value : this.status,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tournament(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    isSynced,
    name,
    category,
    status,
    startDate,
    endDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tournament &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced &&
          other.name == this.name &&
          other.category == this.category &&
          other.status == this.status &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate);
}

class TournamentsCompanion extends UpdateCompanion<Tournament> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<bool> isSynced;
  final Value<String> name;
  final Value<String?> category;
  final Value<String> status;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<int> rowid;
  const TournamentsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TournamentsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    required String name,
    this.category = const Value.absent(),
    this.status = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Tournament> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? status,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TournamentsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<bool>? isSynced,
    Value<String>? name,
    Value<String?>? category,
    Value<String>? status,
    Value<DateTime?>? startDate,
    Value<DateTime?>? endDate,
    Value<int>? rowid,
  }) {
    return TournamentsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TournamentsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MatchesTable matches = $MatchesTable(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $MatchRostersTable matchRosters = $MatchRostersTable(this);
  late final $GameEventsTable gameEvents = $GameEventsTable(this);
  late final $TournamentsTable tournaments = $TournamentsTable(this);
  late final MatchesDao matchesDao = MatchesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    matches,
    players,
    matchRosters,
    gameEvents,
    tournaments,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'matches',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('match_rosters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'players',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('match_rosters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'matches',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('game_events', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$MatchesTableCreateCompanionBuilder =
    MatchesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      Value<String?> tournamentId,
      required String teamAName,
      required String teamBName,
      required DateTime scheduledDate,
      Value<String> status,
      Value<int> scoreA,
      Value<int> scoreB,
      Value<int> rowid,
    });
typedef $$MatchesTableUpdateCompanionBuilder =
    MatchesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      Value<String?> tournamentId,
      Value<String> teamAName,
      Value<String> teamBName,
      Value<DateTime> scheduledDate,
      Value<String> status,
      Value<int> scoreA,
      Value<int> scoreB,
      Value<int> rowid,
    });

final class $$MatchesTableReferences
    extends BaseReferences<_$AppDatabase, $MatchesTable, BasketballMatch> {
  $$MatchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MatchRostersTable, List<RosterEntry>>
  _matchRostersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.matchRosters,
    aliasName: $_aliasNameGenerator(db.matches.id, db.matchRosters.matchId),
  );

  $$MatchRostersTableProcessedTableManager get matchRostersRefs {
    final manager = $$MatchRostersTableTableManager(
      $_db,
      $_db.matchRosters,
    ).filter((f) => f.matchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_matchRostersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GameEventsTable, List<GameEvent>>
  _gameEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.gameEvents,
    aliasName: $_aliasNameGenerator(db.matches.id, db.gameEvents.matchId),
  );

  $$GameEventsTableProcessedTableManager get gameEventsRefs {
    final manager = $$GameEventsTableTableManager(
      $_db,
      $_db.gameEvents,
    ).filter((f) => f.matchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_gameEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MatchesTableFilterComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamAName => $composableBuilder(
    column: $table.teamAName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamBName => $composableBuilder(
    column: $table.teamBName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreA => $composableBuilder(
    column: $table.scoreA,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreB => $composableBuilder(
    column: $table.scoreB,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> matchRostersRefs(
    Expression<bool> Function($$MatchRostersTableFilterComposer f) f,
  ) {
    final $$MatchRostersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.matchRosters,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchRostersTableFilterComposer(
            $db: $db,
            $table: $db.matchRosters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gameEventsRefs(
    Expression<bool> Function($$GameEventsTableFilterComposer f) f,
  ) {
    final $$GameEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gameEvents,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameEventsTableFilterComposer(
            $db: $db,
            $table: $db.gameEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamAName => $composableBuilder(
    column: $table.teamAName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamBName => $composableBuilder(
    column: $table.teamBName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreA => $composableBuilder(
    column: $table.scoreA,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreB => $composableBuilder(
    column: $table.scoreB,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get teamAName =>
      $composableBuilder(column: $table.teamAName, builder: (column) => column);

  GeneratedColumn<String> get teamBName =>
      $composableBuilder(column: $table.teamBName, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get scoreA =>
      $composableBuilder(column: $table.scoreA, builder: (column) => column);

  GeneratedColumn<int> get scoreB =>
      $composableBuilder(column: $table.scoreB, builder: (column) => column);

  Expression<T> matchRostersRefs<T extends Object>(
    Expression<T> Function($$MatchRostersTableAnnotationComposer a) f,
  ) {
    final $$MatchRostersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.matchRosters,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchRostersTableAnnotationComposer(
            $db: $db,
            $table: $db.matchRosters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> gameEventsRefs<T extends Object>(
    Expression<T> Function($$GameEventsTableAnnotationComposer a) f,
  ) {
    final $$GameEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gameEvents,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.gameEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatchesTable,
          BasketballMatch,
          $$MatchesTableFilterComposer,
          $$MatchesTableOrderingComposer,
          $$MatchesTableAnnotationComposer,
          $$MatchesTableCreateCompanionBuilder,
          $$MatchesTableUpdateCompanionBuilder,
          (BasketballMatch, $$MatchesTableReferences),
          BasketballMatch,
          PrefetchHooks Function({bool matchRostersRefs, bool gameEventsRefs})
        > {
  $$MatchesTableTableManager(_$AppDatabase db, $MatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> tournamentId = const Value.absent(),
                Value<String> teamAName = const Value.absent(),
                Value<String> teamBName = const Value.absent(),
                Value<DateTime> scheduledDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> scoreA = const Value.absent(),
                Value<int> scoreB = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
                tournamentId: tournamentId,
                teamAName: teamAName,
                teamBName: teamBName,
                scheduledDate: scheduledDate,
                status: status,
                scoreA: scoreA,
                scoreB: scoreB,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> tournamentId = const Value.absent(),
                required String teamAName,
                required String teamBName,
                required DateTime scheduledDate,
                Value<String> status = const Value.absent(),
                Value<int> scoreA = const Value.absent(),
                Value<int> scoreB = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
                tournamentId: tournamentId,
                teamAName: teamAName,
                teamBName: teamBName,
                scheduledDate: scheduledDate,
                status: status,
                scoreA: scoreA,
                scoreB: scoreB,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({matchRostersRefs = false, gameEventsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (matchRostersRefs) db.matchRosters,
                    if (gameEventsRefs) db.gameEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (matchRostersRefs)
                        await $_getPrefetchedData<
                          BasketballMatch,
                          $MatchesTable,
                          RosterEntry
                        >(
                          currentTable: table,
                          referencedTable: $$MatchesTableReferences
                              ._matchRostersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).matchRostersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.matchId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gameEventsRefs)
                        await $_getPrefetchedData<
                          BasketballMatch,
                          $MatchesTable,
                          GameEvent
                        >(
                          currentTable: table,
                          referencedTable: $$MatchesTableReferences
                              ._gameEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).gameEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.matchId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatchesTable,
      BasketballMatch,
      $$MatchesTableFilterComposer,
      $$MatchesTableOrderingComposer,
      $$MatchesTableAnnotationComposer,
      $$MatchesTableCreateCompanionBuilder,
      $$MatchesTableUpdateCompanionBuilder,
      (BasketballMatch, $$MatchesTableReferences),
      BasketballMatch,
      PrefetchHooks Function({bool matchRostersRefs, bool gameEventsRefs})
    >;
typedef $$PlayersTableCreateCompanionBuilder =
    PlayersCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      required String fullName,
      Value<String?> photoPath,
      Value<String?> teamNameReference,
      Value<int> rowid,
    });
typedef $$PlayersTableUpdateCompanionBuilder =
    PlayersCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      Value<String> fullName,
      Value<String?> photoPath,
      Value<String?> teamNameReference,
      Value<int> rowid,
    });

final class $$PlayersTableReferences
    extends BaseReferences<_$AppDatabase, $PlayersTable, Player> {
  $$PlayersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MatchRostersTable, List<RosterEntry>>
  _matchRostersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.matchRosters,
    aliasName: $_aliasNameGenerator(db.players.id, db.matchRosters.playerId),
  );

  $$MatchRostersTableProcessedTableManager get matchRostersRefs {
    final manager = $$MatchRostersTableTableManager(
      $_db,
      $_db.matchRosters,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_matchRostersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GameEventsTable, List<GameEvent>>
  _gameEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.gameEvents,
    aliasName: $_aliasNameGenerator(db.players.id, db.gameEvents.playerId),
  );

  $$GameEventsTableProcessedTableManager get gameEventsRefs {
    final manager = $$GameEventsTableTableManager(
      $_db,
      $_db.gameEvents,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_gameEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamNameReference => $composableBuilder(
    column: $table.teamNameReference,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> matchRostersRefs(
    Expression<bool> Function($$MatchRostersTableFilterComposer f) f,
  ) {
    final $$MatchRostersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.matchRosters,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchRostersTableFilterComposer(
            $db: $db,
            $table: $db.matchRosters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gameEventsRefs(
    Expression<bool> Function($$GameEventsTableFilterComposer f) f,
  ) {
    final $$GameEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gameEvents,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameEventsTableFilterComposer(
            $db: $db,
            $table: $db.gameEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamNameReference => $composableBuilder(
    column: $table.teamNameReference,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get teamNameReference => $composableBuilder(
    column: $table.teamNameReference,
    builder: (column) => column,
  );

  Expression<T> matchRostersRefs<T extends Object>(
    Expression<T> Function($$MatchRostersTableAnnotationComposer a) f,
  ) {
    final $$MatchRostersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.matchRosters,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchRostersTableAnnotationComposer(
            $db: $db,
            $table: $db.matchRosters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> gameEventsRefs<T extends Object>(
    Expression<T> Function($$GameEventsTableAnnotationComposer a) f,
  ) {
    final $$GameEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gameEvents,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.gameEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTable,
          Player,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (Player, $$PlayersTableReferences),
          Player,
          PrefetchHooks Function({bool matchRostersRefs, bool gameEventsRefs})
        > {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> teamNameReference = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
                fullName: fullName,
                photoPath: photoPath,
                teamNameReference: teamNameReference,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                required String fullName,
                Value<String?> photoPath = const Value.absent(),
                Value<String?> teamNameReference = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayersCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
                fullName: fullName,
                photoPath: photoPath,
                teamNameReference: teamNameReference,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({matchRostersRefs = false, gameEventsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (matchRostersRefs) db.matchRosters,
                    if (gameEventsRefs) db.gameEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (matchRostersRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          RosterEntry
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._matchRostersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).matchRostersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gameEventsRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          GameEvent
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._gameEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).gameEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTable,
      Player,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (Player, $$PlayersTableReferences),
      Player,
      PrefetchHooks Function({bool matchRostersRefs, bool gameEventsRefs})
    >;
typedef $$MatchRostersTableCreateCompanionBuilder =
    MatchRostersCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      required String matchId,
      required String playerId,
      required String teamSide,
      required int jerseyNumber,
      Value<bool> isCaptain,
      Value<int> rowid,
    });
typedef $$MatchRostersTableUpdateCompanionBuilder =
    MatchRostersCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      Value<String> matchId,
      Value<String> playerId,
      Value<String> teamSide,
      Value<int> jerseyNumber,
      Value<bool> isCaptain,
      Value<int> rowid,
    });

final class $$MatchRostersTableReferences
    extends BaseReferences<_$AppDatabase, $MatchRostersTable, RosterEntry> {
  $$MatchRostersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MatchesTable _matchIdTable(_$AppDatabase db) =>
      db.matches.createAlias(
        $_aliasNameGenerator(db.matchRosters.matchId, db.matches.id),
      );

  $$MatchesTableProcessedTableManager get matchId {
    final $_column = $_itemColumn<String>('match_id')!;

    final manager = $$MatchesTableTableManager(
      $_db,
      $_db.matches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_matchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlayersTable _playerIdTable(_$AppDatabase db) =>
      db.players.createAlias(
        $_aliasNameGenerator(db.matchRosters.playerId, db.players.id),
      );

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<String>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MatchRostersTableFilterComposer
    extends Composer<_$AppDatabase, $MatchRostersTable> {
  $$MatchRostersTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamSide => $composableBuilder(
    column: $table.teamSide,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCaptain => $composableBuilder(
    column: $table.isCaptain,
    builder: (column) => ColumnFilters(column),
  );

  $$MatchesTableFilterComposer get matchId {
    final $$MatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableFilterComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MatchRostersTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchRostersTable> {
  $$MatchRostersTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamSide => $composableBuilder(
    column: $table.teamSide,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCaptain => $composableBuilder(
    column: $table.isCaptain,
    builder: (column) => ColumnOrderings(column),
  );

  $$MatchesTableOrderingComposer get matchId {
    final $$MatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableOrderingComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MatchRostersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchRostersTable> {
  $$MatchRostersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get teamSide =>
      $composableBuilder(column: $table.teamSide, builder: (column) => column);

  GeneratedColumn<int> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCaptain =>
      $composableBuilder(column: $table.isCaptain, builder: (column) => column);

  $$MatchesTableAnnotationComposer get matchId {
    final $$MatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MatchRostersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatchRostersTable,
          RosterEntry,
          $$MatchRostersTableFilterComposer,
          $$MatchRostersTableOrderingComposer,
          $$MatchRostersTableAnnotationComposer,
          $$MatchRostersTableCreateCompanionBuilder,
          $$MatchRostersTableUpdateCompanionBuilder,
          (RosterEntry, $$MatchRostersTableReferences),
          RosterEntry,
          PrefetchHooks Function({bool matchId, bool playerId})
        > {
  $$MatchRostersTableTableManager(_$AppDatabase db, $MatchRostersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchRostersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchRostersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchRostersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String> matchId = const Value.absent(),
                Value<String> playerId = const Value.absent(),
                Value<String> teamSide = const Value.absent(),
                Value<int> jerseyNumber = const Value.absent(),
                Value<bool> isCaptain = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchRostersCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
                matchId: matchId,
                playerId: playerId,
                teamSide: teamSide,
                jerseyNumber: jerseyNumber,
                isCaptain: isCaptain,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                required String matchId,
                required String playerId,
                required String teamSide,
                required int jerseyNumber,
                Value<bool> isCaptain = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchRostersCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
                matchId: matchId,
                playerId: playerId,
                teamSide: teamSide,
                jerseyNumber: jerseyNumber,
                isCaptain: isCaptain,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MatchRostersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({matchId = false, playerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (matchId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.matchId,
                                referencedTable: $$MatchRostersTableReferences
                                    ._matchIdTable(db),
                                referencedColumn: $$MatchRostersTableReferences
                                    ._matchIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable: $$MatchRostersTableReferences
                                    ._playerIdTable(db),
                                referencedColumn: $$MatchRostersTableReferences
                                    ._playerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MatchRostersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatchRostersTable,
      RosterEntry,
      $$MatchRostersTableFilterComposer,
      $$MatchRostersTableOrderingComposer,
      $$MatchRostersTableAnnotationComposer,
      $$MatchRostersTableCreateCompanionBuilder,
      $$MatchRostersTableUpdateCompanionBuilder,
      (RosterEntry, $$MatchRostersTableReferences),
      RosterEntry,
      PrefetchHooks Function({bool matchId, bool playerId})
    >;
typedef $$GameEventsTableCreateCompanionBuilder =
    GameEventsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      required String matchId,
      Value<String?> playerId,
      required String type,
      required int period,
      required String clockTime,
      Value<int> rowid,
    });
typedef $$GameEventsTableUpdateCompanionBuilder =
    GameEventsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      Value<String> matchId,
      Value<String?> playerId,
      Value<String> type,
      Value<int> period,
      Value<String> clockTime,
      Value<int> rowid,
    });

final class $$GameEventsTableReferences
    extends BaseReferences<_$AppDatabase, $GameEventsTable, GameEvent> {
  $$GameEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MatchesTable _matchIdTable(_$AppDatabase db) => db.matches
      .createAlias($_aliasNameGenerator(db.gameEvents.matchId, db.matches.id));

  $$MatchesTableProcessedTableManager get matchId {
    final $_column = $_itemColumn<String>('match_id')!;

    final manager = $$MatchesTableTableManager(
      $_db,
      $_db.matches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_matchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlayersTable _playerIdTable(_$AppDatabase db) => db.players
      .createAlias($_aliasNameGenerator(db.gameEvents.playerId, db.players.id));

  $$PlayersTableProcessedTableManager? get playerId {
    final $_column = $_itemColumn<String>('player_id');
    if ($_column == null) return null;
    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GameEventsTableFilterComposer
    extends Composer<_$AppDatabase, $GameEventsTable> {
  $$GameEventsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clockTime => $composableBuilder(
    column: $table.clockTime,
    builder: (column) => ColumnFilters(column),
  );

  $$MatchesTableFilterComposer get matchId {
    final $$MatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableFilterComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $GameEventsTable> {
  $$GameEventsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clockTime => $composableBuilder(
    column: $table.clockTime,
    builder: (column) => ColumnOrderings(column),
  );

  $$MatchesTableOrderingComposer get matchId {
    final $$MatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableOrderingComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameEventsTable> {
  $$GameEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<String> get clockTime =>
      $composableBuilder(column: $table.clockTime, builder: (column) => column);

  $$MatchesTableAnnotationComposer get matchId {
    final $$MatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GameEventsTable,
          GameEvent,
          $$GameEventsTableFilterComposer,
          $$GameEventsTableOrderingComposer,
          $$GameEventsTableAnnotationComposer,
          $$GameEventsTableCreateCompanionBuilder,
          $$GameEventsTableUpdateCompanionBuilder,
          (GameEvent, $$GameEventsTableReferences),
          GameEvent,
          PrefetchHooks Function({bool matchId, bool playerId})
        > {
  $$GameEventsTableTableManager(_$AppDatabase db, $GameEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String> matchId = const Value.absent(),
                Value<String?> playerId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> period = const Value.absent(),
                Value<String> clockTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameEventsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
                matchId: matchId,
                playerId: playerId,
                type: type,
                period: period,
                clockTime: clockTime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                required String matchId,
                Value<String?> playerId = const Value.absent(),
                required String type,
                required int period,
                required String clockTime,
                Value<int> rowid = const Value.absent(),
              }) => GameEventsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
                matchId: matchId,
                playerId: playerId,
                type: type,
                period: period,
                clockTime: clockTime,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GameEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({matchId = false, playerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (matchId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.matchId,
                                referencedTable: $$GameEventsTableReferences
                                    ._matchIdTable(db),
                                referencedColumn: $$GameEventsTableReferences
                                    ._matchIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable: $$GameEventsTableReferences
                                    ._playerIdTable(db),
                                referencedColumn: $$GameEventsTableReferences
                                    ._playerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GameEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GameEventsTable,
      GameEvent,
      $$GameEventsTableFilterComposer,
      $$GameEventsTableOrderingComposer,
      $$GameEventsTableAnnotationComposer,
      $$GameEventsTableCreateCompanionBuilder,
      $$GameEventsTableUpdateCompanionBuilder,
      (GameEvent, $$GameEventsTableReferences),
      GameEvent,
      PrefetchHooks Function({bool matchId, bool playerId})
    >;
typedef $$TournamentsTableCreateCompanionBuilder =
    TournamentsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      required String name,
      Value<String?> category,
      Value<String> status,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<int> rowid,
    });
typedef $$TournamentsTableUpdateCompanionBuilder =
    TournamentsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      Value<String> name,
      Value<String?> category,
      Value<String> status,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<int> rowid,
    });

class $$TournamentsTableFilterComposer
    extends Composer<_$AppDatabase, $TournamentsTable> {
  $$TournamentsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TournamentsTableOrderingComposer
    extends Composer<_$AppDatabase, $TournamentsTable> {
  $$TournamentsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TournamentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TournamentsTable> {
  $$TournamentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);
}

class $$TournamentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TournamentsTable,
          Tournament,
          $$TournamentsTableFilterComposer,
          $$TournamentsTableOrderingComposer,
          $$TournamentsTableAnnotationComposer,
          $$TournamentsTableCreateCompanionBuilder,
          $$TournamentsTableUpdateCompanionBuilder,
          (
            Tournament,
            BaseReferences<_$AppDatabase, $TournamentsTable, Tournament>,
          ),
          Tournament,
          PrefetchHooks Function()
        > {
  $$TournamentsTableTableManager(_$AppDatabase db, $TournamentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TournamentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TournamentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TournamentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TournamentsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
                name: name,
                category: category,
                status: status,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                required String name,
                Value<String?> category = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TournamentsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
                name: name,
                category: category,
                status: status,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TournamentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TournamentsTable,
      Tournament,
      $$TournamentsTableFilterComposer,
      $$TournamentsTableOrderingComposer,
      $$TournamentsTableAnnotationComposer,
      $$TournamentsTableCreateCompanionBuilder,
      $$TournamentsTableUpdateCompanionBuilder,
      (
        Tournament,
        BaseReferences<_$AppDatabase, $TournamentsTable, Tournament>,
      ),
      Tournament,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MatchesTableTableManager get matches =>
      $$MatchesTableTableManager(_db, _db.matches);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$MatchRostersTableTableManager get matchRosters =>
      $$MatchRostersTableTableManager(_db, _db.matchRosters);
  $$GameEventsTableTableManager get gameEvents =>
      $$GameEventsTableTableManager(_db, _db.gameEvents);
  $$TournamentsTableTableManager get tournaments =>
      $$TournamentsTableTableManager(_db, _db.tournaments);
}
