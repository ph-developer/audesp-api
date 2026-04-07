// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _municipioMeta = const VerificationMeta(
    'municipio',
  );
  @override
  late final GeneratedColumn<String> municipio = GeneratedColumn<String>(
    'municipio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadeMeta = const VerificationMeta(
    'entidade',
  );
  @override
  late final GeneratedColumn<String> entidade = GeneratedColumn<String>(
    'entidade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAdminMeta = const VerificationMeta(
    'isAdmin',
  );
  @override
  late final GeneratedColumn<bool> isAdmin = GeneratedColumn<bool>(
    'is_admin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_admin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nome,
    email,
    municipio,
    entidade,
    isAdmin,
    passwordHash,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('municipio')) {
      context.handle(
        _municipioMeta,
        municipio.isAcceptableOrUnknown(data['municipio']!, _municipioMeta),
      );
    } else if (isInserting) {
      context.missing(_municipioMeta);
    }
    if (data.containsKey('entidade')) {
      context.handle(
        _entidadeMeta,
        entidade.isAcceptableOrUnknown(data['entidade']!, _entidadeMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadeMeta);
    }
    if (data.containsKey('is_admin')) {
      context.handle(
        _isAdminMeta,
        isAdmin.isAcceptableOrUnknown(data['is_admin']!, _isAdminMeta),
      );
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      municipio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipio'],
      )!,
      entidade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidade'],
      )!,
      isAdmin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_admin'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String nome;
  final String email;
  final String municipio;
  final String entidade;
  final bool isAdmin;

  /// SHA-256 da senha do sistema (null = ainda usa a senha padrão do .env).
  final String? passwordHash;
  final DateTime createdAt;
  const User({
    required this.id,
    required this.nome,
    required this.email,
    required this.municipio,
    required this.entidade,
    required this.isAdmin,
    this.passwordHash,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    map['email'] = Variable<String>(email);
    map['municipio'] = Variable<String>(municipio);
    map['entidade'] = Variable<String>(entidade);
    map['is_admin'] = Variable<bool>(isAdmin);
    if (!nullToAbsent || passwordHash != null) {
      map['password_hash'] = Variable<String>(passwordHash);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      nome: Value(nome),
      email: Value(email),
      municipio: Value(municipio),
      entidade: Value(entidade),
      isAdmin: Value(isAdmin),
      passwordHash: passwordHash == null && nullToAbsent
          ? const Value.absent()
          : Value(passwordHash),
      createdAt: Value(createdAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      email: serializer.fromJson<String>(json['email']),
      municipio: serializer.fromJson<String>(json['municipio']),
      entidade: serializer.fromJson<String>(json['entidade']),
      isAdmin: serializer.fromJson<bool>(json['isAdmin']),
      passwordHash: serializer.fromJson<String?>(json['passwordHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'email': serializer.toJson<String>(email),
      'municipio': serializer.toJson<String>(municipio),
      'entidade': serializer.toJson<String>(entidade),
      'isAdmin': serializer.toJson<bool>(isAdmin),
      'passwordHash': serializer.toJson<String?>(passwordHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  User copyWith({
    int? id,
    String? nome,
    String? email,
    String? municipio,
    String? entidade,
    bool? isAdmin,
    Value<String?> passwordHash = const Value.absent(),
    DateTime? createdAt,
  }) => User(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    email: email ?? this.email,
    municipio: municipio ?? this.municipio,
    entidade: entidade ?? this.entidade,
    isAdmin: isAdmin ?? this.isAdmin,
    passwordHash: passwordHash.present ? passwordHash.value : this.passwordHash,
    createdAt: createdAt ?? this.createdAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      email: data.email.present ? data.email.value : this.email,
      municipio: data.municipio.present ? data.municipio.value : this.municipio,
      entidade: data.entidade.present ? data.entidade.value : this.entidade,
      isAdmin: data.isAdmin.present ? data.isAdmin.value : this.isAdmin,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('email: $email, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('isAdmin: $isAdmin, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nome,
    email,
    municipio,
    entidade,
    isAdmin,
    passwordHash,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.email == this.email &&
          other.municipio == this.municipio &&
          other.entidade == this.entidade &&
          other.isAdmin == this.isAdmin &&
          other.passwordHash == this.passwordHash &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> nome;
  final Value<String> email;
  final Value<String> municipio;
  final Value<String> entidade;
  final Value<bool> isAdmin;
  final Value<String?> passwordHash;
  final Value<DateTime> createdAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.email = const Value.absent(),
    this.municipio = const Value.absent(),
    this.entidade = const Value.absent(),
    this.isAdmin = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    required String email,
    required String municipio,
    required String entidade,
    this.isAdmin = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : nome = Value(nome),
       email = Value(email),
       municipio = Value(municipio),
       entidade = Value(entidade);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<String>? email,
    Expression<String>? municipio,
    Expression<String>? entidade,
    Expression<bool>? isAdmin,
    Expression<String>? passwordHash,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (email != null) 'email': email,
      if (municipio != null) 'municipio': municipio,
      if (entidade != null) 'entidade': entidade,
      if (isAdmin != null) 'is_admin': isAdmin,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? nome,
    Value<String>? email,
    Value<String>? municipio,
    Value<String>? entidade,
    Value<bool>? isAdmin,
    Value<String?>? passwordHash,
    Value<DateTime>? createdAt,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      municipio: municipio ?? this.municipio,
      entidade: entidade ?? this.entidade,
      isAdmin: isAdmin ?? this.isAdmin,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (municipio.present) {
      map['municipio'] = Variable<String>(municipio.value);
    }
    if (entidade.present) {
      map['entidade'] = Variable<String>(entidade.value);
    }
    if (isAdmin.present) {
      map['is_admin'] = Variable<bool>(isAdmin.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('email: $email, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('isAdmin: $isAdmin, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EditaisTable extends Editais with TableInfo<$EditaisTable, Editai> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EditaisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _municipioMeta = const VerificationMeta(
    'municipio',
  );
  @override
  late final GeneratedColumn<String> municipio = GeneratedColumn<String>(
    'municipio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadeMeta = const VerificationMeta(
    'entidade',
  );
  @override
  late final GeneratedColumn<String> entidade = GeneratedColumn<String>(
    'entidade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoEditalMeta = const VerificationMeta(
    'codigoEdital',
  );
  @override
  late final GeneratedColumn<String> codigoEdital = GeneratedColumn<String>(
    'codigo_edital',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retificacaoMeta = const VerificationMeta(
    'retificacao',
  );
  @override
  late final GeneratedColumn<bool> retificacao = GeneratedColumn<bool>(
    'retificacao',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retificacao" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _pdfPathMeta = const VerificationMeta(
    'pdfPath',
  );
  @override
  late final GeneratedColumn<String> pdfPath = GeneratedColumn<String>(
    'pdf_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentoJsonMeta = const VerificationMeta(
    'documentoJson',
  );
  @override
  late final GeneratedColumn<String> documentoJson = GeneratedColumn<String>(
    'documento_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    municipio,
    entidade,
    codigoEdital,
    retificacao,
    status,
    pdfPath,
    documentoJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'editais';
  @override
  VerificationContext validateIntegrity(
    Insertable<Editai> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('municipio')) {
      context.handle(
        _municipioMeta,
        municipio.isAcceptableOrUnknown(data['municipio']!, _municipioMeta),
      );
    } else if (isInserting) {
      context.missing(_municipioMeta);
    }
    if (data.containsKey('entidade')) {
      context.handle(
        _entidadeMeta,
        entidade.isAcceptableOrUnknown(data['entidade']!, _entidadeMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadeMeta);
    }
    if (data.containsKey('codigo_edital')) {
      context.handle(
        _codigoEditalMeta,
        codigoEdital.isAcceptableOrUnknown(
          data['codigo_edital']!,
          _codigoEditalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codigoEditalMeta);
    }
    if (data.containsKey('retificacao')) {
      context.handle(
        _retificacaoMeta,
        retificacao.isAcceptableOrUnknown(
          data['retificacao']!,
          _retificacaoMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('pdf_path')) {
      context.handle(
        _pdfPathMeta,
        pdfPath.isAcceptableOrUnknown(data['pdf_path']!, _pdfPathMeta),
      );
    }
    if (data.containsKey('documento_json')) {
      context.handle(
        _documentoJsonMeta,
        documentoJson.isAcceptableOrUnknown(
          data['documento_json']!,
          _documentoJsonMeta,
        ),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Editai map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Editai(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      municipio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipio'],
      )!,
      entidade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidade'],
      )!,
      codigoEdital: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_edital'],
      )!,
      retificacao: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retificacao'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      pdfPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_path'],
      ),
      documentoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}documento_json'],
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
  $EditaisTable createAlias(String alias) {
    return $EditaisTable(attachedDatabase, alias);
  }
}

class Editai extends DataClass implements Insertable<Editai> {
  final int id;
  final String municipio;
  final String entidade;
  final String codigoEdital;
  final bool retificacao;
  final String status;
  final String? pdfPath;
  final String documentoJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Editai({
    required this.id,
    required this.municipio,
    required this.entidade,
    required this.codigoEdital,
    required this.retificacao,
    required this.status,
    this.pdfPath,
    required this.documentoJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['municipio'] = Variable<String>(municipio);
    map['entidade'] = Variable<String>(entidade);
    map['codigo_edital'] = Variable<String>(codigoEdital);
    map['retificacao'] = Variable<bool>(retificacao);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || pdfPath != null) {
      map['pdf_path'] = Variable<String>(pdfPath);
    }
    map['documento_json'] = Variable<String>(documentoJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EditaisCompanion toCompanion(bool nullToAbsent) {
    return EditaisCompanion(
      id: Value(id),
      municipio: Value(municipio),
      entidade: Value(entidade),
      codigoEdital: Value(codigoEdital),
      retificacao: Value(retificacao),
      status: Value(status),
      pdfPath: pdfPath == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfPath),
      documentoJson: Value(documentoJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Editai.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Editai(
      id: serializer.fromJson<int>(json['id']),
      municipio: serializer.fromJson<String>(json['municipio']),
      entidade: serializer.fromJson<String>(json['entidade']),
      codigoEdital: serializer.fromJson<String>(json['codigoEdital']),
      retificacao: serializer.fromJson<bool>(json['retificacao']),
      status: serializer.fromJson<String>(json['status']),
      pdfPath: serializer.fromJson<String?>(json['pdfPath']),
      documentoJson: serializer.fromJson<String>(json['documentoJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'municipio': serializer.toJson<String>(municipio),
      'entidade': serializer.toJson<String>(entidade),
      'codigoEdital': serializer.toJson<String>(codigoEdital),
      'retificacao': serializer.toJson<bool>(retificacao),
      'status': serializer.toJson<String>(status),
      'pdfPath': serializer.toJson<String?>(pdfPath),
      'documentoJson': serializer.toJson<String>(documentoJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Editai copyWith({
    int? id,
    String? municipio,
    String? entidade,
    String? codigoEdital,
    bool? retificacao,
    String? status,
    Value<String?> pdfPath = const Value.absent(),
    String? documentoJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Editai(
    id: id ?? this.id,
    municipio: municipio ?? this.municipio,
    entidade: entidade ?? this.entidade,
    codigoEdital: codigoEdital ?? this.codigoEdital,
    retificacao: retificacao ?? this.retificacao,
    status: status ?? this.status,
    pdfPath: pdfPath.present ? pdfPath.value : this.pdfPath,
    documentoJson: documentoJson ?? this.documentoJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Editai copyWithCompanion(EditaisCompanion data) {
    return Editai(
      id: data.id.present ? data.id.value : this.id,
      municipio: data.municipio.present ? data.municipio.value : this.municipio,
      entidade: data.entidade.present ? data.entidade.value : this.entidade,
      codigoEdital: data.codigoEdital.present
          ? data.codigoEdital.value
          : this.codigoEdital,
      retificacao: data.retificacao.present
          ? data.retificacao.value
          : this.retificacao,
      status: data.status.present ? data.status.value : this.status,
      pdfPath: data.pdfPath.present ? data.pdfPath.value : this.pdfPath,
      documentoJson: data.documentoJson.present
          ? data.documentoJson.value
          : this.documentoJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Editai(')
          ..write('id: $id, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('codigoEdital: $codigoEdital, ')
          ..write('retificacao: $retificacao, ')
          ..write('status: $status, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('documentoJson: $documentoJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    municipio,
    entidade,
    codigoEdital,
    retificacao,
    status,
    pdfPath,
    documentoJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Editai &&
          other.id == this.id &&
          other.municipio == this.municipio &&
          other.entidade == this.entidade &&
          other.codigoEdital == this.codigoEdital &&
          other.retificacao == this.retificacao &&
          other.status == this.status &&
          other.pdfPath == this.pdfPath &&
          other.documentoJson == this.documentoJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EditaisCompanion extends UpdateCompanion<Editai> {
  final Value<int> id;
  final Value<String> municipio;
  final Value<String> entidade;
  final Value<String> codigoEdital;
  final Value<bool> retificacao;
  final Value<String> status;
  final Value<String?> pdfPath;
  final Value<String> documentoJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EditaisCompanion({
    this.id = const Value.absent(),
    this.municipio = const Value.absent(),
    this.entidade = const Value.absent(),
    this.codigoEdital = const Value.absent(),
    this.retificacao = const Value.absent(),
    this.status = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.documentoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EditaisCompanion.insert({
    this.id = const Value.absent(),
    required String municipio,
    required String entidade,
    required String codigoEdital,
    this.retificacao = const Value.absent(),
    this.status = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.documentoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : municipio = Value(municipio),
       entidade = Value(entidade),
       codigoEdital = Value(codigoEdital);
  static Insertable<Editai> custom({
    Expression<int>? id,
    Expression<String>? municipio,
    Expression<String>? entidade,
    Expression<String>? codigoEdital,
    Expression<bool>? retificacao,
    Expression<String>? status,
    Expression<String>? pdfPath,
    Expression<String>? documentoJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (municipio != null) 'municipio': municipio,
      if (entidade != null) 'entidade': entidade,
      if (codigoEdital != null) 'codigo_edital': codigoEdital,
      if (retificacao != null) 'retificacao': retificacao,
      if (status != null) 'status': status,
      if (pdfPath != null) 'pdf_path': pdfPath,
      if (documentoJson != null) 'documento_json': documentoJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EditaisCompanion copyWith({
    Value<int>? id,
    Value<String>? municipio,
    Value<String>? entidade,
    Value<String>? codigoEdital,
    Value<bool>? retificacao,
    Value<String>? status,
    Value<String?>? pdfPath,
    Value<String>? documentoJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return EditaisCompanion(
      id: id ?? this.id,
      municipio: municipio ?? this.municipio,
      entidade: entidade ?? this.entidade,
      codigoEdital: codigoEdital ?? this.codigoEdital,
      retificacao: retificacao ?? this.retificacao,
      status: status ?? this.status,
      pdfPath: pdfPath ?? this.pdfPath,
      documentoJson: documentoJson ?? this.documentoJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (municipio.present) {
      map['municipio'] = Variable<String>(municipio.value);
    }
    if (entidade.present) {
      map['entidade'] = Variable<String>(entidade.value);
    }
    if (codigoEdital.present) {
      map['codigo_edital'] = Variable<String>(codigoEdital.value);
    }
    if (retificacao.present) {
      map['retificacao'] = Variable<bool>(retificacao.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (pdfPath.present) {
      map['pdf_path'] = Variable<String>(pdfPath.value);
    }
    if (documentoJson.present) {
      map['documento_json'] = Variable<String>(documentoJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EditaisCompanion(')
          ..write('id: $id, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('codigoEdital: $codigoEdital, ')
          ..write('retificacao: $retificacao, ')
          ..write('status: $status, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('documentoJson: $documentoJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LicitacoesTable extends Licitacoes
    with TableInfo<$LicitacoesTable, Licitacoe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LicitacoesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _editalIdMeta = const VerificationMeta(
    'editalId',
  );
  @override
  late final GeneratedColumn<int> editalId = GeneratedColumn<int>(
    'edital_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES editais (id)',
    ),
  );
  static const VerificationMeta _municipioMeta = const VerificationMeta(
    'municipio',
  );
  @override
  late final GeneratedColumn<String> municipio = GeneratedColumn<String>(
    'municipio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadeMeta = const VerificationMeta(
    'entidade',
  );
  @override
  late final GeneratedColumn<String> entidade = GeneratedColumn<String>(
    'entidade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoEditalMeta = const VerificationMeta(
    'codigoEdital',
  );
  @override
  late final GeneratedColumn<String> codigoEdital = GeneratedColumn<String>(
    'codigo_edital',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retificacaoMeta = const VerificationMeta(
    'retificacao',
  );
  @override
  late final GeneratedColumn<bool> retificacao = GeneratedColumn<bool>(
    'retificacao',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retificacao" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _documentoJsonMeta = const VerificationMeta(
    'documentoJson',
  );
  @override
  late final GeneratedColumn<String> documentoJson = GeneratedColumn<String>(
    'documento_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    editalId,
    municipio,
    entidade,
    codigoEdital,
    retificacao,
    status,
    documentoJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'licitacoes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Licitacoe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('edital_id')) {
      context.handle(
        _editalIdMeta,
        editalId.isAcceptableOrUnknown(data['edital_id']!, _editalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_editalIdMeta);
    }
    if (data.containsKey('municipio')) {
      context.handle(
        _municipioMeta,
        municipio.isAcceptableOrUnknown(data['municipio']!, _municipioMeta),
      );
    } else if (isInserting) {
      context.missing(_municipioMeta);
    }
    if (data.containsKey('entidade')) {
      context.handle(
        _entidadeMeta,
        entidade.isAcceptableOrUnknown(data['entidade']!, _entidadeMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadeMeta);
    }
    if (data.containsKey('codigo_edital')) {
      context.handle(
        _codigoEditalMeta,
        codigoEdital.isAcceptableOrUnknown(
          data['codigo_edital']!,
          _codigoEditalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codigoEditalMeta);
    }
    if (data.containsKey('retificacao')) {
      context.handle(
        _retificacaoMeta,
        retificacao.isAcceptableOrUnknown(
          data['retificacao']!,
          _retificacaoMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('documento_json')) {
      context.handle(
        _documentoJsonMeta,
        documentoJson.isAcceptableOrUnknown(
          data['documento_json']!,
          _documentoJsonMeta,
        ),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Licitacoe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Licitacoe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      editalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edital_id'],
      )!,
      municipio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipio'],
      )!,
      entidade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidade'],
      )!,
      codigoEdital: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_edital'],
      )!,
      retificacao: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retificacao'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      documentoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}documento_json'],
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
  $LicitacoesTable createAlias(String alias) {
    return $LicitacoesTable(attachedDatabase, alias);
  }
}

class Licitacoe extends DataClass implements Insertable<Licitacoe> {
  final int id;
  final int editalId;
  final String municipio;
  final String entidade;
  final String codigoEdital;
  final bool retificacao;
  final String status;
  final String documentoJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Licitacoe({
    required this.id,
    required this.editalId,
    required this.municipio,
    required this.entidade,
    required this.codigoEdital,
    required this.retificacao,
    required this.status,
    required this.documentoJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['edital_id'] = Variable<int>(editalId);
    map['municipio'] = Variable<String>(municipio);
    map['entidade'] = Variable<String>(entidade);
    map['codigo_edital'] = Variable<String>(codigoEdital);
    map['retificacao'] = Variable<bool>(retificacao);
    map['status'] = Variable<String>(status);
    map['documento_json'] = Variable<String>(documentoJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LicitacoesCompanion toCompanion(bool nullToAbsent) {
    return LicitacoesCompanion(
      id: Value(id),
      editalId: Value(editalId),
      municipio: Value(municipio),
      entidade: Value(entidade),
      codigoEdital: Value(codigoEdital),
      retificacao: Value(retificacao),
      status: Value(status),
      documentoJson: Value(documentoJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Licitacoe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Licitacoe(
      id: serializer.fromJson<int>(json['id']),
      editalId: serializer.fromJson<int>(json['editalId']),
      municipio: serializer.fromJson<String>(json['municipio']),
      entidade: serializer.fromJson<String>(json['entidade']),
      codigoEdital: serializer.fromJson<String>(json['codigoEdital']),
      retificacao: serializer.fromJson<bool>(json['retificacao']),
      status: serializer.fromJson<String>(json['status']),
      documentoJson: serializer.fromJson<String>(json['documentoJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'editalId': serializer.toJson<int>(editalId),
      'municipio': serializer.toJson<String>(municipio),
      'entidade': serializer.toJson<String>(entidade),
      'codigoEdital': serializer.toJson<String>(codigoEdital),
      'retificacao': serializer.toJson<bool>(retificacao),
      'status': serializer.toJson<String>(status),
      'documentoJson': serializer.toJson<String>(documentoJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Licitacoe copyWith({
    int? id,
    int? editalId,
    String? municipio,
    String? entidade,
    String? codigoEdital,
    bool? retificacao,
    String? status,
    String? documentoJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Licitacoe(
    id: id ?? this.id,
    editalId: editalId ?? this.editalId,
    municipio: municipio ?? this.municipio,
    entidade: entidade ?? this.entidade,
    codigoEdital: codigoEdital ?? this.codigoEdital,
    retificacao: retificacao ?? this.retificacao,
    status: status ?? this.status,
    documentoJson: documentoJson ?? this.documentoJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Licitacoe copyWithCompanion(LicitacoesCompanion data) {
    return Licitacoe(
      id: data.id.present ? data.id.value : this.id,
      editalId: data.editalId.present ? data.editalId.value : this.editalId,
      municipio: data.municipio.present ? data.municipio.value : this.municipio,
      entidade: data.entidade.present ? data.entidade.value : this.entidade,
      codigoEdital: data.codigoEdital.present
          ? data.codigoEdital.value
          : this.codigoEdital,
      retificacao: data.retificacao.present
          ? data.retificacao.value
          : this.retificacao,
      status: data.status.present ? data.status.value : this.status,
      documentoJson: data.documentoJson.present
          ? data.documentoJson.value
          : this.documentoJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Licitacoe(')
          ..write('id: $id, ')
          ..write('editalId: $editalId, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('codigoEdital: $codigoEdital, ')
          ..write('retificacao: $retificacao, ')
          ..write('status: $status, ')
          ..write('documentoJson: $documentoJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    editalId,
    municipio,
    entidade,
    codigoEdital,
    retificacao,
    status,
    documentoJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Licitacoe &&
          other.id == this.id &&
          other.editalId == this.editalId &&
          other.municipio == this.municipio &&
          other.entidade == this.entidade &&
          other.codigoEdital == this.codigoEdital &&
          other.retificacao == this.retificacao &&
          other.status == this.status &&
          other.documentoJson == this.documentoJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LicitacoesCompanion extends UpdateCompanion<Licitacoe> {
  final Value<int> id;
  final Value<int> editalId;
  final Value<String> municipio;
  final Value<String> entidade;
  final Value<String> codigoEdital;
  final Value<bool> retificacao;
  final Value<String> status;
  final Value<String> documentoJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LicitacoesCompanion({
    this.id = const Value.absent(),
    this.editalId = const Value.absent(),
    this.municipio = const Value.absent(),
    this.entidade = const Value.absent(),
    this.codigoEdital = const Value.absent(),
    this.retificacao = const Value.absent(),
    this.status = const Value.absent(),
    this.documentoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LicitacoesCompanion.insert({
    this.id = const Value.absent(),
    required int editalId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    this.retificacao = const Value.absent(),
    this.status = const Value.absent(),
    this.documentoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : editalId = Value(editalId),
       municipio = Value(municipio),
       entidade = Value(entidade),
       codigoEdital = Value(codigoEdital);
  static Insertable<Licitacoe> custom({
    Expression<int>? id,
    Expression<int>? editalId,
    Expression<String>? municipio,
    Expression<String>? entidade,
    Expression<String>? codigoEdital,
    Expression<bool>? retificacao,
    Expression<String>? status,
    Expression<String>? documentoJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (editalId != null) 'edital_id': editalId,
      if (municipio != null) 'municipio': municipio,
      if (entidade != null) 'entidade': entidade,
      if (codigoEdital != null) 'codigo_edital': codigoEdital,
      if (retificacao != null) 'retificacao': retificacao,
      if (status != null) 'status': status,
      if (documentoJson != null) 'documento_json': documentoJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LicitacoesCompanion copyWith({
    Value<int>? id,
    Value<int>? editalId,
    Value<String>? municipio,
    Value<String>? entidade,
    Value<String>? codigoEdital,
    Value<bool>? retificacao,
    Value<String>? status,
    Value<String>? documentoJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return LicitacoesCompanion(
      id: id ?? this.id,
      editalId: editalId ?? this.editalId,
      municipio: municipio ?? this.municipio,
      entidade: entidade ?? this.entidade,
      codigoEdital: codigoEdital ?? this.codigoEdital,
      retificacao: retificacao ?? this.retificacao,
      status: status ?? this.status,
      documentoJson: documentoJson ?? this.documentoJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (editalId.present) {
      map['edital_id'] = Variable<int>(editalId.value);
    }
    if (municipio.present) {
      map['municipio'] = Variable<String>(municipio.value);
    }
    if (entidade.present) {
      map['entidade'] = Variable<String>(entidade.value);
    }
    if (codigoEdital.present) {
      map['codigo_edital'] = Variable<String>(codigoEdital.value);
    }
    if (retificacao.present) {
      map['retificacao'] = Variable<bool>(retificacao.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (documentoJson.present) {
      map['documento_json'] = Variable<String>(documentoJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LicitacoesCompanion(')
          ..write('id: $id, ')
          ..write('editalId: $editalId, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('codigoEdital: $codigoEdital, ')
          ..write('retificacao: $retificacao, ')
          ..write('status: $status, ')
          ..write('documentoJson: $documentoJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AtasTable extends Atas with TableInfo<$AtasTable, Ata> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AtasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _editalIdMeta = const VerificationMeta(
    'editalId',
  );
  @override
  late final GeneratedColumn<int> editalId = GeneratedColumn<int>(
    'edital_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES editais (id)',
    ),
  );
  static const VerificationMeta _municipioMeta = const VerificationMeta(
    'municipio',
  );
  @override
  late final GeneratedColumn<String> municipio = GeneratedColumn<String>(
    'municipio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadeMeta = const VerificationMeta(
    'entidade',
  );
  @override
  late final GeneratedColumn<String> entidade = GeneratedColumn<String>(
    'entidade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoEditalMeta = const VerificationMeta(
    'codigoEdital',
  );
  @override
  late final GeneratedColumn<String> codigoEdital = GeneratedColumn<String>(
    'codigo_edital',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoAtaMeta = const VerificationMeta(
    'codigoAta',
  );
  @override
  late final GeneratedColumn<String> codigoAta = GeneratedColumn<String>(
    'codigo_ata',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retificacaoMeta = const VerificationMeta(
    'retificacao',
  );
  @override
  late final GeneratedColumn<bool> retificacao = GeneratedColumn<bool>(
    'retificacao',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retificacao" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _documentoJsonMeta = const VerificationMeta(
    'documentoJson',
  );
  @override
  late final GeneratedColumn<String> documentoJson = GeneratedColumn<String>(
    'documento_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    editalId,
    municipio,
    entidade,
    codigoEdital,
    codigoAta,
    retificacao,
    status,
    documentoJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'atas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ata> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('edital_id')) {
      context.handle(
        _editalIdMeta,
        editalId.isAcceptableOrUnknown(data['edital_id']!, _editalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_editalIdMeta);
    }
    if (data.containsKey('municipio')) {
      context.handle(
        _municipioMeta,
        municipio.isAcceptableOrUnknown(data['municipio']!, _municipioMeta),
      );
    } else if (isInserting) {
      context.missing(_municipioMeta);
    }
    if (data.containsKey('entidade')) {
      context.handle(
        _entidadeMeta,
        entidade.isAcceptableOrUnknown(data['entidade']!, _entidadeMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadeMeta);
    }
    if (data.containsKey('codigo_edital')) {
      context.handle(
        _codigoEditalMeta,
        codigoEdital.isAcceptableOrUnknown(
          data['codigo_edital']!,
          _codigoEditalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codigoEditalMeta);
    }
    if (data.containsKey('codigo_ata')) {
      context.handle(
        _codigoAtaMeta,
        codigoAta.isAcceptableOrUnknown(data['codigo_ata']!, _codigoAtaMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoAtaMeta);
    }
    if (data.containsKey('retificacao')) {
      context.handle(
        _retificacaoMeta,
        retificacao.isAcceptableOrUnknown(
          data['retificacao']!,
          _retificacaoMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('documento_json')) {
      context.handle(
        _documentoJsonMeta,
        documentoJson.isAcceptableOrUnknown(
          data['documento_json']!,
          _documentoJsonMeta,
        ),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ata map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ata(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      editalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edital_id'],
      )!,
      municipio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipio'],
      )!,
      entidade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidade'],
      )!,
      codigoEdital: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_edital'],
      )!,
      codigoAta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_ata'],
      )!,
      retificacao: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retificacao'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      documentoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}documento_json'],
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
  $AtasTable createAlias(String alias) {
    return $AtasTable(attachedDatabase, alias);
  }
}

class Ata extends DataClass implements Insertable<Ata> {
  final int id;
  final int editalId;
  final String municipio;
  final String entidade;
  final String codigoEdital;
  final String codigoAta;
  final bool retificacao;
  final String status;
  final String documentoJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Ata({
    required this.id,
    required this.editalId,
    required this.municipio,
    required this.entidade,
    required this.codigoEdital,
    required this.codigoAta,
    required this.retificacao,
    required this.status,
    required this.documentoJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['edital_id'] = Variable<int>(editalId);
    map['municipio'] = Variable<String>(municipio);
    map['entidade'] = Variable<String>(entidade);
    map['codigo_edital'] = Variable<String>(codigoEdital);
    map['codigo_ata'] = Variable<String>(codigoAta);
    map['retificacao'] = Variable<bool>(retificacao);
    map['status'] = Variable<String>(status);
    map['documento_json'] = Variable<String>(documentoJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AtasCompanion toCompanion(bool nullToAbsent) {
    return AtasCompanion(
      id: Value(id),
      editalId: Value(editalId),
      municipio: Value(municipio),
      entidade: Value(entidade),
      codigoEdital: Value(codigoEdital),
      codigoAta: Value(codigoAta),
      retificacao: Value(retificacao),
      status: Value(status),
      documentoJson: Value(documentoJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Ata.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ata(
      id: serializer.fromJson<int>(json['id']),
      editalId: serializer.fromJson<int>(json['editalId']),
      municipio: serializer.fromJson<String>(json['municipio']),
      entidade: serializer.fromJson<String>(json['entidade']),
      codigoEdital: serializer.fromJson<String>(json['codigoEdital']),
      codigoAta: serializer.fromJson<String>(json['codigoAta']),
      retificacao: serializer.fromJson<bool>(json['retificacao']),
      status: serializer.fromJson<String>(json['status']),
      documentoJson: serializer.fromJson<String>(json['documentoJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'editalId': serializer.toJson<int>(editalId),
      'municipio': serializer.toJson<String>(municipio),
      'entidade': serializer.toJson<String>(entidade),
      'codigoEdital': serializer.toJson<String>(codigoEdital),
      'codigoAta': serializer.toJson<String>(codigoAta),
      'retificacao': serializer.toJson<bool>(retificacao),
      'status': serializer.toJson<String>(status),
      'documentoJson': serializer.toJson<String>(documentoJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Ata copyWith({
    int? id,
    int? editalId,
    String? municipio,
    String? entidade,
    String? codigoEdital,
    String? codigoAta,
    bool? retificacao,
    String? status,
    String? documentoJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Ata(
    id: id ?? this.id,
    editalId: editalId ?? this.editalId,
    municipio: municipio ?? this.municipio,
    entidade: entidade ?? this.entidade,
    codigoEdital: codigoEdital ?? this.codigoEdital,
    codigoAta: codigoAta ?? this.codigoAta,
    retificacao: retificacao ?? this.retificacao,
    status: status ?? this.status,
    documentoJson: documentoJson ?? this.documentoJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Ata copyWithCompanion(AtasCompanion data) {
    return Ata(
      id: data.id.present ? data.id.value : this.id,
      editalId: data.editalId.present ? data.editalId.value : this.editalId,
      municipio: data.municipio.present ? data.municipio.value : this.municipio,
      entidade: data.entidade.present ? data.entidade.value : this.entidade,
      codigoEdital: data.codigoEdital.present
          ? data.codigoEdital.value
          : this.codigoEdital,
      codigoAta: data.codigoAta.present ? data.codigoAta.value : this.codigoAta,
      retificacao: data.retificacao.present
          ? data.retificacao.value
          : this.retificacao,
      status: data.status.present ? data.status.value : this.status,
      documentoJson: data.documentoJson.present
          ? data.documentoJson.value
          : this.documentoJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ata(')
          ..write('id: $id, ')
          ..write('editalId: $editalId, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('codigoEdital: $codigoEdital, ')
          ..write('codigoAta: $codigoAta, ')
          ..write('retificacao: $retificacao, ')
          ..write('status: $status, ')
          ..write('documentoJson: $documentoJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    editalId,
    municipio,
    entidade,
    codigoEdital,
    codigoAta,
    retificacao,
    status,
    documentoJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ata &&
          other.id == this.id &&
          other.editalId == this.editalId &&
          other.municipio == this.municipio &&
          other.entidade == this.entidade &&
          other.codigoEdital == this.codigoEdital &&
          other.codigoAta == this.codigoAta &&
          other.retificacao == this.retificacao &&
          other.status == this.status &&
          other.documentoJson == this.documentoJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AtasCompanion extends UpdateCompanion<Ata> {
  final Value<int> id;
  final Value<int> editalId;
  final Value<String> municipio;
  final Value<String> entidade;
  final Value<String> codigoEdital;
  final Value<String> codigoAta;
  final Value<bool> retificacao;
  final Value<String> status;
  final Value<String> documentoJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AtasCompanion({
    this.id = const Value.absent(),
    this.editalId = const Value.absent(),
    this.municipio = const Value.absent(),
    this.entidade = const Value.absent(),
    this.codigoEdital = const Value.absent(),
    this.codigoAta = const Value.absent(),
    this.retificacao = const Value.absent(),
    this.status = const Value.absent(),
    this.documentoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AtasCompanion.insert({
    this.id = const Value.absent(),
    required int editalId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required String codigoAta,
    this.retificacao = const Value.absent(),
    this.status = const Value.absent(),
    this.documentoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : editalId = Value(editalId),
       municipio = Value(municipio),
       entidade = Value(entidade),
       codigoEdital = Value(codigoEdital),
       codigoAta = Value(codigoAta);
  static Insertable<Ata> custom({
    Expression<int>? id,
    Expression<int>? editalId,
    Expression<String>? municipio,
    Expression<String>? entidade,
    Expression<String>? codigoEdital,
    Expression<String>? codigoAta,
    Expression<bool>? retificacao,
    Expression<String>? status,
    Expression<String>? documentoJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (editalId != null) 'edital_id': editalId,
      if (municipio != null) 'municipio': municipio,
      if (entidade != null) 'entidade': entidade,
      if (codigoEdital != null) 'codigo_edital': codigoEdital,
      if (codigoAta != null) 'codigo_ata': codigoAta,
      if (retificacao != null) 'retificacao': retificacao,
      if (status != null) 'status': status,
      if (documentoJson != null) 'documento_json': documentoJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AtasCompanion copyWith({
    Value<int>? id,
    Value<int>? editalId,
    Value<String>? municipio,
    Value<String>? entidade,
    Value<String>? codigoEdital,
    Value<String>? codigoAta,
    Value<bool>? retificacao,
    Value<String>? status,
    Value<String>? documentoJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AtasCompanion(
      id: id ?? this.id,
      editalId: editalId ?? this.editalId,
      municipio: municipio ?? this.municipio,
      entidade: entidade ?? this.entidade,
      codigoEdital: codigoEdital ?? this.codigoEdital,
      codigoAta: codigoAta ?? this.codigoAta,
      retificacao: retificacao ?? this.retificacao,
      status: status ?? this.status,
      documentoJson: documentoJson ?? this.documentoJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (editalId.present) {
      map['edital_id'] = Variable<int>(editalId.value);
    }
    if (municipio.present) {
      map['municipio'] = Variable<String>(municipio.value);
    }
    if (entidade.present) {
      map['entidade'] = Variable<String>(entidade.value);
    }
    if (codigoEdital.present) {
      map['codigo_edital'] = Variable<String>(codigoEdital.value);
    }
    if (codigoAta.present) {
      map['codigo_ata'] = Variable<String>(codigoAta.value);
    }
    if (retificacao.present) {
      map['retificacao'] = Variable<bool>(retificacao.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (documentoJson.present) {
      map['documento_json'] = Variable<String>(documentoJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AtasCompanion(')
          ..write('id: $id, ')
          ..write('editalId: $editalId, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('codigoEdital: $codigoEdital, ')
          ..write('codigoAta: $codigoAta, ')
          ..write('retificacao: $retificacao, ')
          ..write('status: $status, ')
          ..write('documentoJson: $documentoJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AjustesTable extends Ajustes with TableInfo<$AjustesTable, Ajuste> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AjustesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _editalIdMeta = const VerificationMeta(
    'editalId',
  );
  @override
  late final GeneratedColumn<int> editalId = GeneratedColumn<int>(
    'edital_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES editais (id)',
    ),
  );
  static const VerificationMeta _ataIdMeta = const VerificationMeta('ataId');
  @override
  late final GeneratedColumn<int> ataId = GeneratedColumn<int>(
    'ata_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES atas (id)',
    ),
  );
  static const VerificationMeta _municipioMeta = const VerificationMeta(
    'municipio',
  );
  @override
  late final GeneratedColumn<String> municipio = GeneratedColumn<String>(
    'municipio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadeMeta = const VerificationMeta(
    'entidade',
  );
  @override
  late final GeneratedColumn<String> entidade = GeneratedColumn<String>(
    'entidade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoEditalMeta = const VerificationMeta(
    'codigoEdital',
  );
  @override
  late final GeneratedColumn<String> codigoEdital = GeneratedColumn<String>(
    'codigo_edital',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoAtaMeta = const VerificationMeta(
    'codigoAta',
  );
  @override
  late final GeneratedColumn<String> codigoAta = GeneratedColumn<String>(
    'codigo_ata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codigoContratoMeta = const VerificationMeta(
    'codigoContrato',
  );
  @override
  late final GeneratedColumn<String> codigoContrato = GeneratedColumn<String>(
    'codigo_contrato',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retificacaoMeta = const VerificationMeta(
    'retificacao',
  );
  @override
  late final GeneratedColumn<bool> retificacao = GeneratedColumn<bool>(
    'retificacao',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retificacao" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _documentoJsonMeta = const VerificationMeta(
    'documentoJson',
  );
  @override
  late final GeneratedColumn<String> documentoJson = GeneratedColumn<String>(
    'documento_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    editalId,
    ataId,
    municipio,
    entidade,
    codigoEdital,
    codigoAta,
    codigoContrato,
    retificacao,
    status,
    documentoJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ajustes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ajuste> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('edital_id')) {
      context.handle(
        _editalIdMeta,
        editalId.isAcceptableOrUnknown(data['edital_id']!, _editalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_editalIdMeta);
    }
    if (data.containsKey('ata_id')) {
      context.handle(
        _ataIdMeta,
        ataId.isAcceptableOrUnknown(data['ata_id']!, _ataIdMeta),
      );
    }
    if (data.containsKey('municipio')) {
      context.handle(
        _municipioMeta,
        municipio.isAcceptableOrUnknown(data['municipio']!, _municipioMeta),
      );
    } else if (isInserting) {
      context.missing(_municipioMeta);
    }
    if (data.containsKey('entidade')) {
      context.handle(
        _entidadeMeta,
        entidade.isAcceptableOrUnknown(data['entidade']!, _entidadeMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadeMeta);
    }
    if (data.containsKey('codigo_edital')) {
      context.handle(
        _codigoEditalMeta,
        codigoEdital.isAcceptableOrUnknown(
          data['codigo_edital']!,
          _codigoEditalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codigoEditalMeta);
    }
    if (data.containsKey('codigo_ata')) {
      context.handle(
        _codigoAtaMeta,
        codigoAta.isAcceptableOrUnknown(data['codigo_ata']!, _codigoAtaMeta),
      );
    }
    if (data.containsKey('codigo_contrato')) {
      context.handle(
        _codigoContratoMeta,
        codigoContrato.isAcceptableOrUnknown(
          data['codigo_contrato']!,
          _codigoContratoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codigoContratoMeta);
    }
    if (data.containsKey('retificacao')) {
      context.handle(
        _retificacaoMeta,
        retificacao.isAcceptableOrUnknown(
          data['retificacao']!,
          _retificacaoMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('documento_json')) {
      context.handle(
        _documentoJsonMeta,
        documentoJson.isAcceptableOrUnknown(
          data['documento_json']!,
          _documentoJsonMeta,
        ),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ajuste map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ajuste(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      editalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edital_id'],
      )!,
      ataId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ata_id'],
      ),
      municipio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipio'],
      )!,
      entidade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidade'],
      )!,
      codigoEdital: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_edital'],
      )!,
      codigoAta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_ata'],
      ),
      codigoContrato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_contrato'],
      )!,
      retificacao: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retificacao'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      documentoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}documento_json'],
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
  $AjustesTable createAlias(String alias) {
    return $AjustesTable(attachedDatabase, alias);
  }
}

class Ajuste extends DataClass implements Insertable<Ajuste> {
  final int id;
  final int editalId;
  final int? ataId;
  final String municipio;
  final String entidade;
  final String codigoEdital;
  final String? codigoAta;
  final String codigoContrato;
  final bool retificacao;
  final String status;
  final String documentoJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Ajuste({
    required this.id,
    required this.editalId,
    this.ataId,
    required this.municipio,
    required this.entidade,
    required this.codigoEdital,
    this.codigoAta,
    required this.codigoContrato,
    required this.retificacao,
    required this.status,
    required this.documentoJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['edital_id'] = Variable<int>(editalId);
    if (!nullToAbsent || ataId != null) {
      map['ata_id'] = Variable<int>(ataId);
    }
    map['municipio'] = Variable<String>(municipio);
    map['entidade'] = Variable<String>(entidade);
    map['codigo_edital'] = Variable<String>(codigoEdital);
    if (!nullToAbsent || codigoAta != null) {
      map['codigo_ata'] = Variable<String>(codigoAta);
    }
    map['codigo_contrato'] = Variable<String>(codigoContrato);
    map['retificacao'] = Variable<bool>(retificacao);
    map['status'] = Variable<String>(status);
    map['documento_json'] = Variable<String>(documentoJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AjustesCompanion toCompanion(bool nullToAbsent) {
    return AjustesCompanion(
      id: Value(id),
      editalId: Value(editalId),
      ataId: ataId == null && nullToAbsent
          ? const Value.absent()
          : Value(ataId),
      municipio: Value(municipio),
      entidade: Value(entidade),
      codigoEdital: Value(codigoEdital),
      codigoAta: codigoAta == null && nullToAbsent
          ? const Value.absent()
          : Value(codigoAta),
      codigoContrato: Value(codigoContrato),
      retificacao: Value(retificacao),
      status: Value(status),
      documentoJson: Value(documentoJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Ajuste.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ajuste(
      id: serializer.fromJson<int>(json['id']),
      editalId: serializer.fromJson<int>(json['editalId']),
      ataId: serializer.fromJson<int?>(json['ataId']),
      municipio: serializer.fromJson<String>(json['municipio']),
      entidade: serializer.fromJson<String>(json['entidade']),
      codigoEdital: serializer.fromJson<String>(json['codigoEdital']),
      codigoAta: serializer.fromJson<String?>(json['codigoAta']),
      codigoContrato: serializer.fromJson<String>(json['codigoContrato']),
      retificacao: serializer.fromJson<bool>(json['retificacao']),
      status: serializer.fromJson<String>(json['status']),
      documentoJson: serializer.fromJson<String>(json['documentoJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'editalId': serializer.toJson<int>(editalId),
      'ataId': serializer.toJson<int?>(ataId),
      'municipio': serializer.toJson<String>(municipio),
      'entidade': serializer.toJson<String>(entidade),
      'codigoEdital': serializer.toJson<String>(codigoEdital),
      'codigoAta': serializer.toJson<String?>(codigoAta),
      'codigoContrato': serializer.toJson<String>(codigoContrato),
      'retificacao': serializer.toJson<bool>(retificacao),
      'status': serializer.toJson<String>(status),
      'documentoJson': serializer.toJson<String>(documentoJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Ajuste copyWith({
    int? id,
    int? editalId,
    Value<int?> ataId = const Value.absent(),
    String? municipio,
    String? entidade,
    String? codigoEdital,
    Value<String?> codigoAta = const Value.absent(),
    String? codigoContrato,
    bool? retificacao,
    String? status,
    String? documentoJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Ajuste(
    id: id ?? this.id,
    editalId: editalId ?? this.editalId,
    ataId: ataId.present ? ataId.value : this.ataId,
    municipio: municipio ?? this.municipio,
    entidade: entidade ?? this.entidade,
    codigoEdital: codigoEdital ?? this.codigoEdital,
    codigoAta: codigoAta.present ? codigoAta.value : this.codigoAta,
    codigoContrato: codigoContrato ?? this.codigoContrato,
    retificacao: retificacao ?? this.retificacao,
    status: status ?? this.status,
    documentoJson: documentoJson ?? this.documentoJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Ajuste copyWithCompanion(AjustesCompanion data) {
    return Ajuste(
      id: data.id.present ? data.id.value : this.id,
      editalId: data.editalId.present ? data.editalId.value : this.editalId,
      ataId: data.ataId.present ? data.ataId.value : this.ataId,
      municipio: data.municipio.present ? data.municipio.value : this.municipio,
      entidade: data.entidade.present ? data.entidade.value : this.entidade,
      codigoEdital: data.codigoEdital.present
          ? data.codigoEdital.value
          : this.codigoEdital,
      codigoAta: data.codigoAta.present ? data.codigoAta.value : this.codigoAta,
      codigoContrato: data.codigoContrato.present
          ? data.codigoContrato.value
          : this.codigoContrato,
      retificacao: data.retificacao.present
          ? data.retificacao.value
          : this.retificacao,
      status: data.status.present ? data.status.value : this.status,
      documentoJson: data.documentoJson.present
          ? data.documentoJson.value
          : this.documentoJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ajuste(')
          ..write('id: $id, ')
          ..write('editalId: $editalId, ')
          ..write('ataId: $ataId, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('codigoEdital: $codigoEdital, ')
          ..write('codigoAta: $codigoAta, ')
          ..write('codigoContrato: $codigoContrato, ')
          ..write('retificacao: $retificacao, ')
          ..write('status: $status, ')
          ..write('documentoJson: $documentoJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    editalId,
    ataId,
    municipio,
    entidade,
    codigoEdital,
    codigoAta,
    codigoContrato,
    retificacao,
    status,
    documentoJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ajuste &&
          other.id == this.id &&
          other.editalId == this.editalId &&
          other.ataId == this.ataId &&
          other.municipio == this.municipio &&
          other.entidade == this.entidade &&
          other.codigoEdital == this.codigoEdital &&
          other.codigoAta == this.codigoAta &&
          other.codigoContrato == this.codigoContrato &&
          other.retificacao == this.retificacao &&
          other.status == this.status &&
          other.documentoJson == this.documentoJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AjustesCompanion extends UpdateCompanion<Ajuste> {
  final Value<int> id;
  final Value<int> editalId;
  final Value<int?> ataId;
  final Value<String> municipio;
  final Value<String> entidade;
  final Value<String> codigoEdital;
  final Value<String?> codigoAta;
  final Value<String> codigoContrato;
  final Value<bool> retificacao;
  final Value<String> status;
  final Value<String> documentoJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AjustesCompanion({
    this.id = const Value.absent(),
    this.editalId = const Value.absent(),
    this.ataId = const Value.absent(),
    this.municipio = const Value.absent(),
    this.entidade = const Value.absent(),
    this.codigoEdital = const Value.absent(),
    this.codigoAta = const Value.absent(),
    this.codigoContrato = const Value.absent(),
    this.retificacao = const Value.absent(),
    this.status = const Value.absent(),
    this.documentoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AjustesCompanion.insert({
    this.id = const Value.absent(),
    required int editalId,
    this.ataId = const Value.absent(),
    required String municipio,
    required String entidade,
    required String codigoEdital,
    this.codigoAta = const Value.absent(),
    required String codigoContrato,
    this.retificacao = const Value.absent(),
    this.status = const Value.absent(),
    this.documentoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : editalId = Value(editalId),
       municipio = Value(municipio),
       entidade = Value(entidade),
       codigoEdital = Value(codigoEdital),
       codigoContrato = Value(codigoContrato);
  static Insertable<Ajuste> custom({
    Expression<int>? id,
    Expression<int>? editalId,
    Expression<int>? ataId,
    Expression<String>? municipio,
    Expression<String>? entidade,
    Expression<String>? codigoEdital,
    Expression<String>? codigoAta,
    Expression<String>? codigoContrato,
    Expression<bool>? retificacao,
    Expression<String>? status,
    Expression<String>? documentoJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (editalId != null) 'edital_id': editalId,
      if (ataId != null) 'ata_id': ataId,
      if (municipio != null) 'municipio': municipio,
      if (entidade != null) 'entidade': entidade,
      if (codigoEdital != null) 'codigo_edital': codigoEdital,
      if (codigoAta != null) 'codigo_ata': codigoAta,
      if (codigoContrato != null) 'codigo_contrato': codigoContrato,
      if (retificacao != null) 'retificacao': retificacao,
      if (status != null) 'status': status,
      if (documentoJson != null) 'documento_json': documentoJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AjustesCompanion copyWith({
    Value<int>? id,
    Value<int>? editalId,
    Value<int?>? ataId,
    Value<String>? municipio,
    Value<String>? entidade,
    Value<String>? codigoEdital,
    Value<String?>? codigoAta,
    Value<String>? codigoContrato,
    Value<bool>? retificacao,
    Value<String>? status,
    Value<String>? documentoJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AjustesCompanion(
      id: id ?? this.id,
      editalId: editalId ?? this.editalId,
      ataId: ataId ?? this.ataId,
      municipio: municipio ?? this.municipio,
      entidade: entidade ?? this.entidade,
      codigoEdital: codigoEdital ?? this.codigoEdital,
      codigoAta: codigoAta ?? this.codigoAta,
      codigoContrato: codigoContrato ?? this.codigoContrato,
      retificacao: retificacao ?? this.retificacao,
      status: status ?? this.status,
      documentoJson: documentoJson ?? this.documentoJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (editalId.present) {
      map['edital_id'] = Variable<int>(editalId.value);
    }
    if (ataId.present) {
      map['ata_id'] = Variable<int>(ataId.value);
    }
    if (municipio.present) {
      map['municipio'] = Variable<String>(municipio.value);
    }
    if (entidade.present) {
      map['entidade'] = Variable<String>(entidade.value);
    }
    if (codigoEdital.present) {
      map['codigo_edital'] = Variable<String>(codigoEdital.value);
    }
    if (codigoAta.present) {
      map['codigo_ata'] = Variable<String>(codigoAta.value);
    }
    if (codigoContrato.present) {
      map['codigo_contrato'] = Variable<String>(codigoContrato.value);
    }
    if (retificacao.present) {
      map['retificacao'] = Variable<bool>(retificacao.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (documentoJson.present) {
      map['documento_json'] = Variable<String>(documentoJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AjustesCompanion(')
          ..write('id: $id, ')
          ..write('editalId: $editalId, ')
          ..write('ataId: $ataId, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('codigoEdital: $codigoEdital, ')
          ..write('codigoAta: $codigoAta, ')
          ..write('codigoContrato: $codigoContrato, ')
          ..write('retificacao: $retificacao, ')
          ..write('status: $status, ')
          ..write('documentoJson: $documentoJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EmpenhosTable extends Empenhos with TableInfo<$EmpenhosTable, Empenho> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmpenhosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ajusteIdMeta = const VerificationMeta(
    'ajusteId',
  );
  @override
  late final GeneratedColumn<int> ajusteId = GeneratedColumn<int>(
    'ajuste_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ajustes (id)',
    ),
  );
  static const VerificationMeta _municipioMeta = const VerificationMeta(
    'municipio',
  );
  @override
  late final GeneratedColumn<String> municipio = GeneratedColumn<String>(
    'municipio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadeMeta = const VerificationMeta(
    'entidade',
  );
  @override
  late final GeneratedColumn<String> entidade = GeneratedColumn<String>(
    'entidade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoContratoMeta = const VerificationMeta(
    'codigoContrato',
  );
  @override
  late final GeneratedColumn<String> codigoContrato = GeneratedColumn<String>(
    'codigo_contrato',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numeroEmpenhoMeta = const VerificationMeta(
    'numeroEmpenho',
  );
  @override
  late final GeneratedColumn<String> numeroEmpenho = GeneratedColumn<String>(
    'numero_empenho',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anoEmpenhoMeta = const VerificationMeta(
    'anoEmpenho',
  );
  @override
  late final GeneratedColumn<int> anoEmpenho = GeneratedColumn<int>(
    'ano_empenho',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retificacaoMeta = const VerificationMeta(
    'retificacao',
  );
  @override
  late final GeneratedColumn<bool> retificacao = GeneratedColumn<bool>(
    'retificacao',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retificacao" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _documentoJsonMeta = const VerificationMeta(
    'documentoJson',
  );
  @override
  late final GeneratedColumn<String> documentoJson = GeneratedColumn<String>(
    'documento_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ajusteId,
    municipio,
    entidade,
    codigoContrato,
    numeroEmpenho,
    anoEmpenho,
    retificacao,
    status,
    documentoJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'empenhos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Empenho> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ajuste_id')) {
      context.handle(
        _ajusteIdMeta,
        ajusteId.isAcceptableOrUnknown(data['ajuste_id']!, _ajusteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ajusteIdMeta);
    }
    if (data.containsKey('municipio')) {
      context.handle(
        _municipioMeta,
        municipio.isAcceptableOrUnknown(data['municipio']!, _municipioMeta),
      );
    } else if (isInserting) {
      context.missing(_municipioMeta);
    }
    if (data.containsKey('entidade')) {
      context.handle(
        _entidadeMeta,
        entidade.isAcceptableOrUnknown(data['entidade']!, _entidadeMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadeMeta);
    }
    if (data.containsKey('codigo_contrato')) {
      context.handle(
        _codigoContratoMeta,
        codigoContrato.isAcceptableOrUnknown(
          data['codigo_contrato']!,
          _codigoContratoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codigoContratoMeta);
    }
    if (data.containsKey('numero_empenho')) {
      context.handle(
        _numeroEmpenhoMeta,
        numeroEmpenho.isAcceptableOrUnknown(
          data['numero_empenho']!,
          _numeroEmpenhoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_numeroEmpenhoMeta);
    }
    if (data.containsKey('ano_empenho')) {
      context.handle(
        _anoEmpenhoMeta,
        anoEmpenho.isAcceptableOrUnknown(data['ano_empenho']!, _anoEmpenhoMeta),
      );
    } else if (isInserting) {
      context.missing(_anoEmpenhoMeta);
    }
    if (data.containsKey('retificacao')) {
      context.handle(
        _retificacaoMeta,
        retificacao.isAcceptableOrUnknown(
          data['retificacao']!,
          _retificacaoMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('documento_json')) {
      context.handle(
        _documentoJsonMeta,
        documentoJson.isAcceptableOrUnknown(
          data['documento_json']!,
          _documentoJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Empenho map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Empenho(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ajusteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ajuste_id'],
      )!,
      municipio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipio'],
      )!,
      entidade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidade'],
      )!,
      codigoContrato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_contrato'],
      )!,
      numeroEmpenho: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero_empenho'],
      )!,
      anoEmpenho: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ano_empenho'],
      )!,
      retificacao: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retificacao'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      documentoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}documento_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EmpenhosTable createAlias(String alias) {
    return $EmpenhosTable(attachedDatabase, alias);
  }
}

class Empenho extends DataClass implements Insertable<Empenho> {
  final int id;
  final int ajusteId;
  final String municipio;
  final String entidade;
  final String codigoContrato;
  final String numeroEmpenho;
  final int anoEmpenho;
  final bool retificacao;
  final String status;
  final String documentoJson;
  final DateTime createdAt;
  const Empenho({
    required this.id,
    required this.ajusteId,
    required this.municipio,
    required this.entidade,
    required this.codigoContrato,
    required this.numeroEmpenho,
    required this.anoEmpenho,
    required this.retificacao,
    required this.status,
    required this.documentoJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ajuste_id'] = Variable<int>(ajusteId);
    map['municipio'] = Variable<String>(municipio);
    map['entidade'] = Variable<String>(entidade);
    map['codigo_contrato'] = Variable<String>(codigoContrato);
    map['numero_empenho'] = Variable<String>(numeroEmpenho);
    map['ano_empenho'] = Variable<int>(anoEmpenho);
    map['retificacao'] = Variable<bool>(retificacao);
    map['status'] = Variable<String>(status);
    map['documento_json'] = Variable<String>(documentoJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EmpenhosCompanion toCompanion(bool nullToAbsent) {
    return EmpenhosCompanion(
      id: Value(id),
      ajusteId: Value(ajusteId),
      municipio: Value(municipio),
      entidade: Value(entidade),
      codigoContrato: Value(codigoContrato),
      numeroEmpenho: Value(numeroEmpenho),
      anoEmpenho: Value(anoEmpenho),
      retificacao: Value(retificacao),
      status: Value(status),
      documentoJson: Value(documentoJson),
      createdAt: Value(createdAt),
    );
  }

  factory Empenho.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Empenho(
      id: serializer.fromJson<int>(json['id']),
      ajusteId: serializer.fromJson<int>(json['ajusteId']),
      municipio: serializer.fromJson<String>(json['municipio']),
      entidade: serializer.fromJson<String>(json['entidade']),
      codigoContrato: serializer.fromJson<String>(json['codigoContrato']),
      numeroEmpenho: serializer.fromJson<String>(json['numeroEmpenho']),
      anoEmpenho: serializer.fromJson<int>(json['anoEmpenho']),
      retificacao: serializer.fromJson<bool>(json['retificacao']),
      status: serializer.fromJson<String>(json['status']),
      documentoJson: serializer.fromJson<String>(json['documentoJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ajusteId': serializer.toJson<int>(ajusteId),
      'municipio': serializer.toJson<String>(municipio),
      'entidade': serializer.toJson<String>(entidade),
      'codigoContrato': serializer.toJson<String>(codigoContrato),
      'numeroEmpenho': serializer.toJson<String>(numeroEmpenho),
      'anoEmpenho': serializer.toJson<int>(anoEmpenho),
      'retificacao': serializer.toJson<bool>(retificacao),
      'status': serializer.toJson<String>(status),
      'documentoJson': serializer.toJson<String>(documentoJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Empenho copyWith({
    int? id,
    int? ajusteId,
    String? municipio,
    String? entidade,
    String? codigoContrato,
    String? numeroEmpenho,
    int? anoEmpenho,
    bool? retificacao,
    String? status,
    String? documentoJson,
    DateTime? createdAt,
  }) => Empenho(
    id: id ?? this.id,
    ajusteId: ajusteId ?? this.ajusteId,
    municipio: municipio ?? this.municipio,
    entidade: entidade ?? this.entidade,
    codigoContrato: codigoContrato ?? this.codigoContrato,
    numeroEmpenho: numeroEmpenho ?? this.numeroEmpenho,
    anoEmpenho: anoEmpenho ?? this.anoEmpenho,
    retificacao: retificacao ?? this.retificacao,
    status: status ?? this.status,
    documentoJson: documentoJson ?? this.documentoJson,
    createdAt: createdAt ?? this.createdAt,
  );
  Empenho copyWithCompanion(EmpenhosCompanion data) {
    return Empenho(
      id: data.id.present ? data.id.value : this.id,
      ajusteId: data.ajusteId.present ? data.ajusteId.value : this.ajusteId,
      municipio: data.municipio.present ? data.municipio.value : this.municipio,
      entidade: data.entidade.present ? data.entidade.value : this.entidade,
      codigoContrato: data.codigoContrato.present
          ? data.codigoContrato.value
          : this.codigoContrato,
      numeroEmpenho: data.numeroEmpenho.present
          ? data.numeroEmpenho.value
          : this.numeroEmpenho,
      anoEmpenho: data.anoEmpenho.present
          ? data.anoEmpenho.value
          : this.anoEmpenho,
      retificacao: data.retificacao.present
          ? data.retificacao.value
          : this.retificacao,
      status: data.status.present ? data.status.value : this.status,
      documentoJson: data.documentoJson.present
          ? data.documentoJson.value
          : this.documentoJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Empenho(')
          ..write('id: $id, ')
          ..write('ajusteId: $ajusteId, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('codigoContrato: $codigoContrato, ')
          ..write('numeroEmpenho: $numeroEmpenho, ')
          ..write('anoEmpenho: $anoEmpenho, ')
          ..write('retificacao: $retificacao, ')
          ..write('status: $status, ')
          ..write('documentoJson: $documentoJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ajusteId,
    municipio,
    entidade,
    codigoContrato,
    numeroEmpenho,
    anoEmpenho,
    retificacao,
    status,
    documentoJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Empenho &&
          other.id == this.id &&
          other.ajusteId == this.ajusteId &&
          other.municipio == this.municipio &&
          other.entidade == this.entidade &&
          other.codigoContrato == this.codigoContrato &&
          other.numeroEmpenho == this.numeroEmpenho &&
          other.anoEmpenho == this.anoEmpenho &&
          other.retificacao == this.retificacao &&
          other.status == this.status &&
          other.documentoJson == this.documentoJson &&
          other.createdAt == this.createdAt);
}

class EmpenhosCompanion extends UpdateCompanion<Empenho> {
  final Value<int> id;
  final Value<int> ajusteId;
  final Value<String> municipio;
  final Value<String> entidade;
  final Value<String> codigoContrato;
  final Value<String> numeroEmpenho;
  final Value<int> anoEmpenho;
  final Value<bool> retificacao;
  final Value<String> status;
  final Value<String> documentoJson;
  final Value<DateTime> createdAt;
  const EmpenhosCompanion({
    this.id = const Value.absent(),
    this.ajusteId = const Value.absent(),
    this.municipio = const Value.absent(),
    this.entidade = const Value.absent(),
    this.codigoContrato = const Value.absent(),
    this.numeroEmpenho = const Value.absent(),
    this.anoEmpenho = const Value.absent(),
    this.retificacao = const Value.absent(),
    this.status = const Value.absent(),
    this.documentoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EmpenhosCompanion.insert({
    this.id = const Value.absent(),
    required int ajusteId,
    required String municipio,
    required String entidade,
    required String codigoContrato,
    required String numeroEmpenho,
    required int anoEmpenho,
    this.retificacao = const Value.absent(),
    this.status = const Value.absent(),
    this.documentoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : ajusteId = Value(ajusteId),
       municipio = Value(municipio),
       entidade = Value(entidade),
       codigoContrato = Value(codigoContrato),
       numeroEmpenho = Value(numeroEmpenho),
       anoEmpenho = Value(anoEmpenho);
  static Insertable<Empenho> custom({
    Expression<int>? id,
    Expression<int>? ajusteId,
    Expression<String>? municipio,
    Expression<String>? entidade,
    Expression<String>? codigoContrato,
    Expression<String>? numeroEmpenho,
    Expression<int>? anoEmpenho,
    Expression<bool>? retificacao,
    Expression<String>? status,
    Expression<String>? documentoJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ajusteId != null) 'ajuste_id': ajusteId,
      if (municipio != null) 'municipio': municipio,
      if (entidade != null) 'entidade': entidade,
      if (codigoContrato != null) 'codigo_contrato': codigoContrato,
      if (numeroEmpenho != null) 'numero_empenho': numeroEmpenho,
      if (anoEmpenho != null) 'ano_empenho': anoEmpenho,
      if (retificacao != null) 'retificacao': retificacao,
      if (status != null) 'status': status,
      if (documentoJson != null) 'documento_json': documentoJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EmpenhosCompanion copyWith({
    Value<int>? id,
    Value<int>? ajusteId,
    Value<String>? municipio,
    Value<String>? entidade,
    Value<String>? codigoContrato,
    Value<String>? numeroEmpenho,
    Value<int>? anoEmpenho,
    Value<bool>? retificacao,
    Value<String>? status,
    Value<String>? documentoJson,
    Value<DateTime>? createdAt,
  }) {
    return EmpenhosCompanion(
      id: id ?? this.id,
      ajusteId: ajusteId ?? this.ajusteId,
      municipio: municipio ?? this.municipio,
      entidade: entidade ?? this.entidade,
      codigoContrato: codigoContrato ?? this.codigoContrato,
      numeroEmpenho: numeroEmpenho ?? this.numeroEmpenho,
      anoEmpenho: anoEmpenho ?? this.anoEmpenho,
      retificacao: retificacao ?? this.retificacao,
      status: status ?? this.status,
      documentoJson: documentoJson ?? this.documentoJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ajusteId.present) {
      map['ajuste_id'] = Variable<int>(ajusteId.value);
    }
    if (municipio.present) {
      map['municipio'] = Variable<String>(municipio.value);
    }
    if (entidade.present) {
      map['entidade'] = Variable<String>(entidade.value);
    }
    if (codigoContrato.present) {
      map['codigo_contrato'] = Variable<String>(codigoContrato.value);
    }
    if (numeroEmpenho.present) {
      map['numero_empenho'] = Variable<String>(numeroEmpenho.value);
    }
    if (anoEmpenho.present) {
      map['ano_empenho'] = Variable<int>(anoEmpenho.value);
    }
    if (retificacao.present) {
      map['retificacao'] = Variable<bool>(retificacao.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (documentoJson.present) {
      map['documento_json'] = Variable<String>(documentoJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmpenhosCompanion(')
          ..write('id: $id, ')
          ..write('ajusteId: $ajusteId, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('codigoContrato: $codigoContrato, ')
          ..write('numeroEmpenho: $numeroEmpenho, ')
          ..write('anoEmpenho: $anoEmpenho, ')
          ..write('retificacao: $retificacao, ')
          ..write('status: $status, ')
          ..write('documentoJson: $documentoJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TermosContratoTable extends TermosContrato
    with TableInfo<$TermosContratoTable, TermosContratoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TermosContratoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ajusteIdMeta = const VerificationMeta(
    'ajusteId',
  );
  @override
  late final GeneratedColumn<int> ajusteId = GeneratedColumn<int>(
    'ajuste_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ajustes (id)',
    ),
  );
  static const VerificationMeta _municipioMeta = const VerificationMeta(
    'municipio',
  );
  @override
  late final GeneratedColumn<String> municipio = GeneratedColumn<String>(
    'municipio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadeMeta = const VerificationMeta(
    'entidade',
  );
  @override
  late final GeneratedColumn<String> entidade = GeneratedColumn<String>(
    'entidade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoContratoMeta = const VerificationMeta(
    'codigoContrato',
  );
  @override
  late final GeneratedColumn<String> codigoContrato = GeneratedColumn<String>(
    'codigo_contrato',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoTermoContratoMeta =
      const VerificationMeta('codigoTermoContrato');
  @override
  late final GeneratedColumn<String> codigoTermoContrato =
      GeneratedColumn<String>(
        'codigo_termo_contrato',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _retificacaoMeta = const VerificationMeta(
    'retificacao',
  );
  @override
  late final GeneratedColumn<bool> retificacao = GeneratedColumn<bool>(
    'retificacao',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retificacao" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _documentoJsonMeta = const VerificationMeta(
    'documentoJson',
  );
  @override
  late final GeneratedColumn<String> documentoJson = GeneratedColumn<String>(
    'documento_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ajusteId,
    municipio,
    entidade,
    codigoContrato,
    codigoTermoContrato,
    retificacao,
    status,
    documentoJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'termos_contrato';
  @override
  VerificationContext validateIntegrity(
    Insertable<TermosContratoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ajuste_id')) {
      context.handle(
        _ajusteIdMeta,
        ajusteId.isAcceptableOrUnknown(data['ajuste_id']!, _ajusteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ajusteIdMeta);
    }
    if (data.containsKey('municipio')) {
      context.handle(
        _municipioMeta,
        municipio.isAcceptableOrUnknown(data['municipio']!, _municipioMeta),
      );
    } else if (isInserting) {
      context.missing(_municipioMeta);
    }
    if (data.containsKey('entidade')) {
      context.handle(
        _entidadeMeta,
        entidade.isAcceptableOrUnknown(data['entidade']!, _entidadeMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadeMeta);
    }
    if (data.containsKey('codigo_contrato')) {
      context.handle(
        _codigoContratoMeta,
        codigoContrato.isAcceptableOrUnknown(
          data['codigo_contrato']!,
          _codigoContratoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codigoContratoMeta);
    }
    if (data.containsKey('codigo_termo_contrato')) {
      context.handle(
        _codigoTermoContratoMeta,
        codigoTermoContrato.isAcceptableOrUnknown(
          data['codigo_termo_contrato']!,
          _codigoTermoContratoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codigoTermoContratoMeta);
    }
    if (data.containsKey('retificacao')) {
      context.handle(
        _retificacaoMeta,
        retificacao.isAcceptableOrUnknown(
          data['retificacao']!,
          _retificacaoMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('documento_json')) {
      context.handle(
        _documentoJsonMeta,
        documentoJson.isAcceptableOrUnknown(
          data['documento_json']!,
          _documentoJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TermosContratoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TermosContratoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ajusteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ajuste_id'],
      )!,
      municipio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipio'],
      )!,
      entidade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidade'],
      )!,
      codigoContrato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_contrato'],
      )!,
      codigoTermoContrato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_termo_contrato'],
      )!,
      retificacao: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retificacao'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      documentoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}documento_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TermosContratoTable createAlias(String alias) {
    return $TermosContratoTable(attachedDatabase, alias);
  }
}

class TermosContratoData extends DataClass
    implements Insertable<TermosContratoData> {
  final int id;
  final int ajusteId;
  final String municipio;
  final String entidade;
  final String codigoContrato;
  final String codigoTermoContrato;
  final bool retificacao;
  final String status;
  final String documentoJson;
  final DateTime createdAt;
  const TermosContratoData({
    required this.id,
    required this.ajusteId,
    required this.municipio,
    required this.entidade,
    required this.codigoContrato,
    required this.codigoTermoContrato,
    required this.retificacao,
    required this.status,
    required this.documentoJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ajuste_id'] = Variable<int>(ajusteId);
    map['municipio'] = Variable<String>(municipio);
    map['entidade'] = Variable<String>(entidade);
    map['codigo_contrato'] = Variable<String>(codigoContrato);
    map['codigo_termo_contrato'] = Variable<String>(codigoTermoContrato);
    map['retificacao'] = Variable<bool>(retificacao);
    map['status'] = Variable<String>(status);
    map['documento_json'] = Variable<String>(documentoJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TermosContratoCompanion toCompanion(bool nullToAbsent) {
    return TermosContratoCompanion(
      id: Value(id),
      ajusteId: Value(ajusteId),
      municipio: Value(municipio),
      entidade: Value(entidade),
      codigoContrato: Value(codigoContrato),
      codigoTermoContrato: Value(codigoTermoContrato),
      retificacao: Value(retificacao),
      status: Value(status),
      documentoJson: Value(documentoJson),
      createdAt: Value(createdAt),
    );
  }

  factory TermosContratoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TermosContratoData(
      id: serializer.fromJson<int>(json['id']),
      ajusteId: serializer.fromJson<int>(json['ajusteId']),
      municipio: serializer.fromJson<String>(json['municipio']),
      entidade: serializer.fromJson<String>(json['entidade']),
      codigoContrato: serializer.fromJson<String>(json['codigoContrato']),
      codigoTermoContrato: serializer.fromJson<String>(
        json['codigoTermoContrato'],
      ),
      retificacao: serializer.fromJson<bool>(json['retificacao']),
      status: serializer.fromJson<String>(json['status']),
      documentoJson: serializer.fromJson<String>(json['documentoJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ajusteId': serializer.toJson<int>(ajusteId),
      'municipio': serializer.toJson<String>(municipio),
      'entidade': serializer.toJson<String>(entidade),
      'codigoContrato': serializer.toJson<String>(codigoContrato),
      'codigoTermoContrato': serializer.toJson<String>(codigoTermoContrato),
      'retificacao': serializer.toJson<bool>(retificacao),
      'status': serializer.toJson<String>(status),
      'documentoJson': serializer.toJson<String>(documentoJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TermosContratoData copyWith({
    int? id,
    int? ajusteId,
    String? municipio,
    String? entidade,
    String? codigoContrato,
    String? codigoTermoContrato,
    bool? retificacao,
    String? status,
    String? documentoJson,
    DateTime? createdAt,
  }) => TermosContratoData(
    id: id ?? this.id,
    ajusteId: ajusteId ?? this.ajusteId,
    municipio: municipio ?? this.municipio,
    entidade: entidade ?? this.entidade,
    codigoContrato: codigoContrato ?? this.codigoContrato,
    codigoTermoContrato: codigoTermoContrato ?? this.codigoTermoContrato,
    retificacao: retificacao ?? this.retificacao,
    status: status ?? this.status,
    documentoJson: documentoJson ?? this.documentoJson,
    createdAt: createdAt ?? this.createdAt,
  );
  TermosContratoData copyWithCompanion(TermosContratoCompanion data) {
    return TermosContratoData(
      id: data.id.present ? data.id.value : this.id,
      ajusteId: data.ajusteId.present ? data.ajusteId.value : this.ajusteId,
      municipio: data.municipio.present ? data.municipio.value : this.municipio,
      entidade: data.entidade.present ? data.entidade.value : this.entidade,
      codigoContrato: data.codigoContrato.present
          ? data.codigoContrato.value
          : this.codigoContrato,
      codigoTermoContrato: data.codigoTermoContrato.present
          ? data.codigoTermoContrato.value
          : this.codigoTermoContrato,
      retificacao: data.retificacao.present
          ? data.retificacao.value
          : this.retificacao,
      status: data.status.present ? data.status.value : this.status,
      documentoJson: data.documentoJson.present
          ? data.documentoJson.value
          : this.documentoJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TermosContratoData(')
          ..write('id: $id, ')
          ..write('ajusteId: $ajusteId, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('codigoContrato: $codigoContrato, ')
          ..write('codigoTermoContrato: $codigoTermoContrato, ')
          ..write('retificacao: $retificacao, ')
          ..write('status: $status, ')
          ..write('documentoJson: $documentoJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ajusteId,
    municipio,
    entidade,
    codigoContrato,
    codigoTermoContrato,
    retificacao,
    status,
    documentoJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TermosContratoData &&
          other.id == this.id &&
          other.ajusteId == this.ajusteId &&
          other.municipio == this.municipio &&
          other.entidade == this.entidade &&
          other.codigoContrato == this.codigoContrato &&
          other.codigoTermoContrato == this.codigoTermoContrato &&
          other.retificacao == this.retificacao &&
          other.status == this.status &&
          other.documentoJson == this.documentoJson &&
          other.createdAt == this.createdAt);
}

class TermosContratoCompanion extends UpdateCompanion<TermosContratoData> {
  final Value<int> id;
  final Value<int> ajusteId;
  final Value<String> municipio;
  final Value<String> entidade;
  final Value<String> codigoContrato;
  final Value<String> codigoTermoContrato;
  final Value<bool> retificacao;
  final Value<String> status;
  final Value<String> documentoJson;
  final Value<DateTime> createdAt;
  const TermosContratoCompanion({
    this.id = const Value.absent(),
    this.ajusteId = const Value.absent(),
    this.municipio = const Value.absent(),
    this.entidade = const Value.absent(),
    this.codigoContrato = const Value.absent(),
    this.codigoTermoContrato = const Value.absent(),
    this.retificacao = const Value.absent(),
    this.status = const Value.absent(),
    this.documentoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TermosContratoCompanion.insert({
    this.id = const Value.absent(),
    required int ajusteId,
    required String municipio,
    required String entidade,
    required String codigoContrato,
    required String codigoTermoContrato,
    this.retificacao = const Value.absent(),
    this.status = const Value.absent(),
    this.documentoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : ajusteId = Value(ajusteId),
       municipio = Value(municipio),
       entidade = Value(entidade),
       codigoContrato = Value(codigoContrato),
       codigoTermoContrato = Value(codigoTermoContrato);
  static Insertable<TermosContratoData> custom({
    Expression<int>? id,
    Expression<int>? ajusteId,
    Expression<String>? municipio,
    Expression<String>? entidade,
    Expression<String>? codigoContrato,
    Expression<String>? codigoTermoContrato,
    Expression<bool>? retificacao,
    Expression<String>? status,
    Expression<String>? documentoJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ajusteId != null) 'ajuste_id': ajusteId,
      if (municipio != null) 'municipio': municipio,
      if (entidade != null) 'entidade': entidade,
      if (codigoContrato != null) 'codigo_contrato': codigoContrato,
      if (codigoTermoContrato != null)
        'codigo_termo_contrato': codigoTermoContrato,
      if (retificacao != null) 'retificacao': retificacao,
      if (status != null) 'status': status,
      if (documentoJson != null) 'documento_json': documentoJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TermosContratoCompanion copyWith({
    Value<int>? id,
    Value<int>? ajusteId,
    Value<String>? municipio,
    Value<String>? entidade,
    Value<String>? codigoContrato,
    Value<String>? codigoTermoContrato,
    Value<bool>? retificacao,
    Value<String>? status,
    Value<String>? documentoJson,
    Value<DateTime>? createdAt,
  }) {
    return TermosContratoCompanion(
      id: id ?? this.id,
      ajusteId: ajusteId ?? this.ajusteId,
      municipio: municipio ?? this.municipio,
      entidade: entidade ?? this.entidade,
      codigoContrato: codigoContrato ?? this.codigoContrato,
      codigoTermoContrato: codigoTermoContrato ?? this.codigoTermoContrato,
      retificacao: retificacao ?? this.retificacao,
      status: status ?? this.status,
      documentoJson: documentoJson ?? this.documentoJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ajusteId.present) {
      map['ajuste_id'] = Variable<int>(ajusteId.value);
    }
    if (municipio.present) {
      map['municipio'] = Variable<String>(municipio.value);
    }
    if (entidade.present) {
      map['entidade'] = Variable<String>(entidade.value);
    }
    if (codigoContrato.present) {
      map['codigo_contrato'] = Variable<String>(codigoContrato.value);
    }
    if (codigoTermoContrato.present) {
      map['codigo_termo_contrato'] = Variable<String>(
        codigoTermoContrato.value,
      );
    }
    if (retificacao.present) {
      map['retificacao'] = Variable<bool>(retificacao.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (documentoJson.present) {
      map['documento_json'] = Variable<String>(documentoJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TermosContratoCompanion(')
          ..write('id: $id, ')
          ..write('ajusteId: $ajusteId, ')
          ..write('municipio: $municipio, ')
          ..write('entidade: $entidade, ')
          ..write('codigoContrato: $codigoContrato, ')
          ..write('codigoTermoContrato: $codigoTermoContrato, ')
          ..write('retificacao: $retificacao, ')
          ..write('status: $status, ')
          ..write('documentoJson: $documentoJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ApiLogsTable extends ApiLogs with TableInfo<$ApiLogsTable, ApiLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestMeta = const VerificationMeta(
    'request',
  );
  @override
  late final GeneratedColumn<String> request = GeneratedColumn<String>(
    'request',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseMeta = const VerificationMeta(
    'response',
  );
  @override
  late final GeneratedColumn<String> response = GeneratedColumn<String>(
    'response',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusCodeMeta = const VerificationMeta(
    'statusCode',
  );
  @override
  late final GeneratedColumn<int> statusCode = GeneratedColumn<int>(
    'status_code',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    endpoint,
    request,
    response,
    statusCode,
    userId,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('request')) {
      context.handle(
        _requestMeta,
        request.isAcceptableOrUnknown(data['request']!, _requestMeta),
      );
    } else if (isInserting) {
      context.missing(_requestMeta);
    }
    if (data.containsKey('response')) {
      context.handle(
        _responseMeta,
        response.isAcceptableOrUnknown(data['response']!, _responseMeta),
      );
    }
    if (data.containsKey('status_code')) {
      context.handle(
        _statusCodeMeta,
        statusCode.isAcceptableOrUnknown(data['status_code']!, _statusCodeMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ApiLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      request: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request'],
      )!,
      response: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response'],
      ),
      statusCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status_code'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $ApiLogsTable createAlias(String alias) {
    return $ApiLogsTable(attachedDatabase, alias);
  }
}

class ApiLog extends DataClass implements Insertable<ApiLog> {
  final int id;
  final String endpoint;
  final String request;
  final String? response;
  final int? statusCode;
  final int? userId;
  final DateTime timestamp;
  const ApiLog({
    required this.id,
    required this.endpoint,
    required this.request,
    this.response,
    this.statusCode,
    this.userId,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['endpoint'] = Variable<String>(endpoint);
    map['request'] = Variable<String>(request);
    if (!nullToAbsent || response != null) {
      map['response'] = Variable<String>(response);
    }
    if (!nullToAbsent || statusCode != null) {
      map['status_code'] = Variable<int>(statusCode);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  ApiLogsCompanion toCompanion(bool nullToAbsent) {
    return ApiLogsCompanion(
      id: Value(id),
      endpoint: Value(endpoint),
      request: Value(request),
      response: response == null && nullToAbsent
          ? const Value.absent()
          : Value(response),
      statusCode: statusCode == null && nullToAbsent
          ? const Value.absent()
          : Value(statusCode),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      timestamp: Value(timestamp),
    );
  }

  factory ApiLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiLog(
      id: serializer.fromJson<int>(json['id']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      request: serializer.fromJson<String>(json['request']),
      response: serializer.fromJson<String?>(json['response']),
      statusCode: serializer.fromJson<int?>(json['statusCode']),
      userId: serializer.fromJson<int?>(json['userId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'endpoint': serializer.toJson<String>(endpoint),
      'request': serializer.toJson<String>(request),
      'response': serializer.toJson<String?>(response),
      'statusCode': serializer.toJson<int?>(statusCode),
      'userId': serializer.toJson<int?>(userId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  ApiLog copyWith({
    int? id,
    String? endpoint,
    String? request,
    Value<String?> response = const Value.absent(),
    Value<int?> statusCode = const Value.absent(),
    Value<int?> userId = const Value.absent(),
    DateTime? timestamp,
  }) => ApiLog(
    id: id ?? this.id,
    endpoint: endpoint ?? this.endpoint,
    request: request ?? this.request,
    response: response.present ? response.value : this.response,
    statusCode: statusCode.present ? statusCode.value : this.statusCode,
    userId: userId.present ? userId.value : this.userId,
    timestamp: timestamp ?? this.timestamp,
  );
  ApiLog copyWithCompanion(ApiLogsCompanion data) {
    return ApiLog(
      id: data.id.present ? data.id.value : this.id,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      request: data.request.present ? data.request.value : this.request,
      response: data.response.present ? data.response.value : this.response,
      statusCode: data.statusCode.present
          ? data.statusCode.value
          : this.statusCode,
      userId: data.userId.present ? data.userId.value : this.userId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiLog(')
          ..write('id: $id, ')
          ..write('endpoint: $endpoint, ')
          ..write('request: $request, ')
          ..write('response: $response, ')
          ..write('statusCode: $statusCode, ')
          ..write('userId: $userId, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    endpoint,
    request,
    response,
    statusCode,
    userId,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiLog &&
          other.id == this.id &&
          other.endpoint == this.endpoint &&
          other.request == this.request &&
          other.response == this.response &&
          other.statusCode == this.statusCode &&
          other.userId == this.userId &&
          other.timestamp == this.timestamp);
}

class ApiLogsCompanion extends UpdateCompanion<ApiLog> {
  final Value<int> id;
  final Value<String> endpoint;
  final Value<String> request;
  final Value<String?> response;
  final Value<int?> statusCode;
  final Value<int?> userId;
  final Value<DateTime> timestamp;
  const ApiLogsCompanion({
    this.id = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.request = const Value.absent(),
    this.response = const Value.absent(),
    this.statusCode = const Value.absent(),
    this.userId = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  ApiLogsCompanion.insert({
    this.id = const Value.absent(),
    required String endpoint,
    required String request,
    this.response = const Value.absent(),
    this.statusCode = const Value.absent(),
    this.userId = const Value.absent(),
    this.timestamp = const Value.absent(),
  }) : endpoint = Value(endpoint),
       request = Value(request);
  static Insertable<ApiLog> custom({
    Expression<int>? id,
    Expression<String>? endpoint,
    Expression<String>? request,
    Expression<String>? response,
    Expression<int>? statusCode,
    Expression<int>? userId,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (endpoint != null) 'endpoint': endpoint,
      if (request != null) 'request': request,
      if (response != null) 'response': response,
      if (statusCode != null) 'status_code': statusCode,
      if (userId != null) 'user_id': userId,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  ApiLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? endpoint,
    Value<String>? request,
    Value<String?>? response,
    Value<int?>? statusCode,
    Value<int?>? userId,
    Value<DateTime>? timestamp,
  }) {
    return ApiLogsCompanion(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      request: request ?? this.request,
      response: response ?? this.response,
      statusCode: statusCode ?? this.statusCode,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (request.present) {
      map['request'] = Variable<String>(request.value);
    }
    if (response.present) {
      map['response'] = Variable<String>(response.value);
    }
    if (statusCode.present) {
      map['status_code'] = Variable<int>(statusCode.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiLogsCompanion(')
          ..write('id: $id, ')
          ..write('endpoint: $endpoint, ')
          ..write('request: $request, ')
          ..write('response: $response, ')
          ..write('statusCode: $statusCode, ')
          ..write('userId: $userId, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $EditaisTable editais = $EditaisTable(this);
  late final $LicitacoesTable licitacoes = $LicitacoesTable(this);
  late final $AtasTable atas = $AtasTable(this);
  late final $AjustesTable ajustes = $AjustesTable(this);
  late final $EmpenhosTable empenhos = $EmpenhosTable(this);
  late final $TermosContratoTable termosContrato = $TermosContratoTable(this);
  late final $ApiLogsTable apiLogs = $ApiLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    editais,
    licitacoes,
    atas,
    ajustes,
    empenhos,
    termosContrato,
    apiLogs,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String nome,
      required String email,
      required String municipio,
      required String entidade,
      Value<bool> isAdmin,
      Value<String?> passwordHash,
      Value<DateTime> createdAt,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> nome,
      Value<String> email,
      Value<String> municipio,
      Value<String> entidade,
      Value<bool> isAdmin,
      Value<String?> passwordHash,
      Value<DateTime> createdAt,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdmin => $composableBuilder(
    column: $table.isAdmin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdmin => $composableBuilder(
    column: $table.isAdmin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get municipio =>
      $composableBuilder(column: $table.municipio, builder: (column) => column);

  GeneratedColumn<String> get entidade =>
      $composableBuilder(column: $table.entidade, builder: (column) => column);

  GeneratedColumn<bool> get isAdmin =>
      $composableBuilder(column: $table.isAdmin, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> municipio = const Value.absent(),
                Value<String> entidade = const Value.absent(),
                Value<bool> isAdmin = const Value.absent(),
                Value<String?> passwordHash = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                nome: nome,
                email: email,
                municipio: municipio,
                entidade: entidade,
                isAdmin: isAdmin,
                passwordHash: passwordHash,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nome,
                required String email,
                required String municipio,
                required String entidade,
                Value<bool> isAdmin = const Value.absent(),
                Value<String?> passwordHash = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                nome: nome,
                email: email,
                municipio: municipio,
                entidade: entidade,
                isAdmin: isAdmin,
                passwordHash: passwordHash,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$EditaisTableCreateCompanionBuilder =
    EditaisCompanion Function({
      Value<int> id,
      required String municipio,
      required String entidade,
      required String codigoEdital,
      Value<bool> retificacao,
      Value<String> status,
      Value<String?> pdfPath,
      Value<String> documentoJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$EditaisTableUpdateCompanionBuilder =
    EditaisCompanion Function({
      Value<int> id,
      Value<String> municipio,
      Value<String> entidade,
      Value<String> codigoEdital,
      Value<bool> retificacao,
      Value<String> status,
      Value<String?> pdfPath,
      Value<String> documentoJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$EditaisTableReferences
    extends BaseReferences<_$AppDatabase, $EditaisTable, Editai> {
  $$EditaisTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LicitacoesTable, List<Licitacoe>>
  _licitacoesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.licitacoes,
    aliasName: $_aliasNameGenerator(db.editais.id, db.licitacoes.editalId),
  );

  $$LicitacoesTableProcessedTableManager get licitacoesRefs {
    final manager = $$LicitacoesTableTableManager(
      $_db,
      $_db.licitacoes,
    ).filter((f) => f.editalId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_licitacoesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AtasTable, List<Ata>> _atasRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.atas,
    aliasName: $_aliasNameGenerator(db.editais.id, db.atas.editalId),
  );

  $$AtasTableProcessedTableManager get atasRefs {
    final manager = $$AtasTableTableManager(
      $_db,
      $_db.atas,
    ).filter((f) => f.editalId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_atasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AjustesTable, List<Ajuste>> _ajustesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ajustes,
    aliasName: $_aliasNameGenerator(db.editais.id, db.ajustes.editalId),
  );

  $$AjustesTableProcessedTableManager get ajustesRefs {
    final manager = $$AjustesTableTableManager(
      $_db,
      $_db.ajustes,
    ).filter((f) => f.editalId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ajustesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EditaisTableFilterComposer
    extends Composer<_$AppDatabase, $EditaisTable> {
  $$EditaisTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoEdital => $composableBuilder(
    column: $table.codigoEdital,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
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

  Expression<bool> licitacoesRefs(
    Expression<bool> Function($$LicitacoesTableFilterComposer f) f,
  ) {
    final $$LicitacoesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.licitacoes,
      getReferencedColumn: (t) => t.editalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LicitacoesTableFilterComposer(
            $db: $db,
            $table: $db.licitacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> atasRefs(
    Expression<bool> Function($$AtasTableFilterComposer f) f,
  ) {
    final $$AtasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.atas,
      getReferencedColumn: (t) => t.editalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtasTableFilterComposer(
            $db: $db,
            $table: $db.atas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ajustesRefs(
    Expression<bool> Function($$AjustesTableFilterComposer f) f,
  ) {
    final $$AjustesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ajustes,
      getReferencedColumn: (t) => t.editalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AjustesTableFilterComposer(
            $db: $db,
            $table: $db.ajustes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EditaisTableOrderingComposer
    extends Composer<_$AppDatabase, $EditaisTable> {
  $$EditaisTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoEdital => $composableBuilder(
    column: $table.codigoEdital,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
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

class $$EditaisTableAnnotationComposer
    extends Composer<_$AppDatabase, $EditaisTable> {
  $$EditaisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get municipio =>
      $composableBuilder(column: $table.municipio, builder: (column) => column);

  GeneratedColumn<String> get entidade =>
      $composableBuilder(column: $table.entidade, builder: (column) => column);

  GeneratedColumn<String> get codigoEdital => $composableBuilder(
    column: $table.codigoEdital,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get pdfPath =>
      $composableBuilder(column: $table.pdfPath, builder: (column) => column);

  GeneratedColumn<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> licitacoesRefs<T extends Object>(
    Expression<T> Function($$LicitacoesTableAnnotationComposer a) f,
  ) {
    final $$LicitacoesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.licitacoes,
      getReferencedColumn: (t) => t.editalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LicitacoesTableAnnotationComposer(
            $db: $db,
            $table: $db.licitacoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> atasRefs<T extends Object>(
    Expression<T> Function($$AtasTableAnnotationComposer a) f,
  ) {
    final $$AtasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.atas,
      getReferencedColumn: (t) => t.editalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtasTableAnnotationComposer(
            $db: $db,
            $table: $db.atas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ajustesRefs<T extends Object>(
    Expression<T> Function($$AjustesTableAnnotationComposer a) f,
  ) {
    final $$AjustesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ajustes,
      getReferencedColumn: (t) => t.editalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AjustesTableAnnotationComposer(
            $db: $db,
            $table: $db.ajustes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EditaisTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EditaisTable,
          Editai,
          $$EditaisTableFilterComposer,
          $$EditaisTableOrderingComposer,
          $$EditaisTableAnnotationComposer,
          $$EditaisTableCreateCompanionBuilder,
          $$EditaisTableUpdateCompanionBuilder,
          (Editai, $$EditaisTableReferences),
          Editai,
          PrefetchHooks Function({
            bool licitacoesRefs,
            bool atasRefs,
            bool ajustesRefs,
          })
        > {
  $$EditaisTableTableManager(_$AppDatabase db, $EditaisTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EditaisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EditaisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EditaisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> municipio = const Value.absent(),
                Value<String> entidade = const Value.absent(),
                Value<String> codigoEdital = const Value.absent(),
                Value<bool> retificacao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<String> documentoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => EditaisCompanion(
                id: id,
                municipio: municipio,
                entidade: entidade,
                codigoEdital: codigoEdital,
                retificacao: retificacao,
                status: status,
                pdfPath: pdfPath,
                documentoJson: documentoJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String municipio,
                required String entidade,
                required String codigoEdital,
                Value<bool> retificacao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<String> documentoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => EditaisCompanion.insert(
                id: id,
                municipio: municipio,
                entidade: entidade,
                codigoEdital: codigoEdital,
                retificacao: retificacao,
                status: status,
                pdfPath: pdfPath,
                documentoJson: documentoJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EditaisTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                licitacoesRefs = false,
                atasRefs = false,
                ajustesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (licitacoesRefs) db.licitacoes,
                    if (atasRefs) db.atas,
                    if (ajustesRefs) db.ajustes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (licitacoesRefs)
                        await $_getPrefetchedData<
                          Editai,
                          $EditaisTable,
                          Licitacoe
                        >(
                          currentTable: table,
                          referencedTable: $$EditaisTableReferences
                              ._licitacoesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EditaisTableReferences(
                                db,
                                table,
                                p0,
                              ).licitacoesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.editalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (atasRefs)
                        await $_getPrefetchedData<Editai, $EditaisTable, Ata>(
                          currentTable: table,
                          referencedTable: $$EditaisTableReferences
                              ._atasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EditaisTableReferences(db, table, p0).atasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.editalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ajustesRefs)
                        await $_getPrefetchedData<
                          Editai,
                          $EditaisTable,
                          Ajuste
                        >(
                          currentTable: table,
                          referencedTable: $$EditaisTableReferences
                              ._ajustesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EditaisTableReferences(
                                db,
                                table,
                                p0,
                              ).ajustesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.editalId == item.id,
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

typedef $$EditaisTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EditaisTable,
      Editai,
      $$EditaisTableFilterComposer,
      $$EditaisTableOrderingComposer,
      $$EditaisTableAnnotationComposer,
      $$EditaisTableCreateCompanionBuilder,
      $$EditaisTableUpdateCompanionBuilder,
      (Editai, $$EditaisTableReferences),
      Editai,
      PrefetchHooks Function({
        bool licitacoesRefs,
        bool atasRefs,
        bool ajustesRefs,
      })
    >;
typedef $$LicitacoesTableCreateCompanionBuilder =
    LicitacoesCompanion Function({
      Value<int> id,
      required int editalId,
      required String municipio,
      required String entidade,
      required String codigoEdital,
      Value<bool> retificacao,
      Value<String> status,
      Value<String> documentoJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$LicitacoesTableUpdateCompanionBuilder =
    LicitacoesCompanion Function({
      Value<int> id,
      Value<int> editalId,
      Value<String> municipio,
      Value<String> entidade,
      Value<String> codigoEdital,
      Value<bool> retificacao,
      Value<String> status,
      Value<String> documentoJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$LicitacoesTableReferences
    extends BaseReferences<_$AppDatabase, $LicitacoesTable, Licitacoe> {
  $$LicitacoesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EditaisTable _editalIdTable(_$AppDatabase db) => db.editais
      .createAlias($_aliasNameGenerator(db.licitacoes.editalId, db.editais.id));

  $$EditaisTableProcessedTableManager get editalId {
    final $_column = $_itemColumn<int>('edital_id')!;

    final manager = $$EditaisTableTableManager(
      $_db,
      $_db.editais,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_editalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LicitacoesTableFilterComposer
    extends Composer<_$AppDatabase, $LicitacoesTable> {
  $$LicitacoesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoEdital => $composableBuilder(
    column: $table.codigoEdital,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
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

  $$EditaisTableFilterComposer get editalId {
    final $$EditaisTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.editalId,
      referencedTable: $db.editais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditaisTableFilterComposer(
            $db: $db,
            $table: $db.editais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LicitacoesTableOrderingComposer
    extends Composer<_$AppDatabase, $LicitacoesTable> {
  $$LicitacoesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoEdital => $composableBuilder(
    column: $table.codigoEdital,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
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

  $$EditaisTableOrderingComposer get editalId {
    final $$EditaisTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.editalId,
      referencedTable: $db.editais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditaisTableOrderingComposer(
            $db: $db,
            $table: $db.editais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LicitacoesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LicitacoesTable> {
  $$LicitacoesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get municipio =>
      $composableBuilder(column: $table.municipio, builder: (column) => column);

  GeneratedColumn<String> get entidade =>
      $composableBuilder(column: $table.entidade, builder: (column) => column);

  GeneratedColumn<String> get codigoEdital => $composableBuilder(
    column: $table.codigoEdital,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$EditaisTableAnnotationComposer get editalId {
    final $$EditaisTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.editalId,
      referencedTable: $db.editais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditaisTableAnnotationComposer(
            $db: $db,
            $table: $db.editais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LicitacoesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LicitacoesTable,
          Licitacoe,
          $$LicitacoesTableFilterComposer,
          $$LicitacoesTableOrderingComposer,
          $$LicitacoesTableAnnotationComposer,
          $$LicitacoesTableCreateCompanionBuilder,
          $$LicitacoesTableUpdateCompanionBuilder,
          (Licitacoe, $$LicitacoesTableReferences),
          Licitacoe,
          PrefetchHooks Function({bool editalId})
        > {
  $$LicitacoesTableTableManager(_$AppDatabase db, $LicitacoesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LicitacoesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LicitacoesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LicitacoesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> editalId = const Value.absent(),
                Value<String> municipio = const Value.absent(),
                Value<String> entidade = const Value.absent(),
                Value<String> codigoEdital = const Value.absent(),
                Value<bool> retificacao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> documentoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LicitacoesCompanion(
                id: id,
                editalId: editalId,
                municipio: municipio,
                entidade: entidade,
                codigoEdital: codigoEdital,
                retificacao: retificacao,
                status: status,
                documentoJson: documentoJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int editalId,
                required String municipio,
                required String entidade,
                required String codigoEdital,
                Value<bool> retificacao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> documentoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LicitacoesCompanion.insert(
                id: id,
                editalId: editalId,
                municipio: municipio,
                entidade: entidade,
                codigoEdital: codigoEdital,
                retificacao: retificacao,
                status: status,
                documentoJson: documentoJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LicitacoesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({editalId = false}) {
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
                    if (editalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.editalId,
                                referencedTable: $$LicitacoesTableReferences
                                    ._editalIdTable(db),
                                referencedColumn: $$LicitacoesTableReferences
                                    ._editalIdTable(db)
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

typedef $$LicitacoesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LicitacoesTable,
      Licitacoe,
      $$LicitacoesTableFilterComposer,
      $$LicitacoesTableOrderingComposer,
      $$LicitacoesTableAnnotationComposer,
      $$LicitacoesTableCreateCompanionBuilder,
      $$LicitacoesTableUpdateCompanionBuilder,
      (Licitacoe, $$LicitacoesTableReferences),
      Licitacoe,
      PrefetchHooks Function({bool editalId})
    >;
typedef $$AtasTableCreateCompanionBuilder =
    AtasCompanion Function({
      Value<int> id,
      required int editalId,
      required String municipio,
      required String entidade,
      required String codigoEdital,
      required String codigoAta,
      Value<bool> retificacao,
      Value<String> status,
      Value<String> documentoJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$AtasTableUpdateCompanionBuilder =
    AtasCompanion Function({
      Value<int> id,
      Value<int> editalId,
      Value<String> municipio,
      Value<String> entidade,
      Value<String> codigoEdital,
      Value<String> codigoAta,
      Value<bool> retificacao,
      Value<String> status,
      Value<String> documentoJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$AtasTableReferences
    extends BaseReferences<_$AppDatabase, $AtasTable, Ata> {
  $$AtasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EditaisTable _editalIdTable(_$AppDatabase db) => db.editais
      .createAlias($_aliasNameGenerator(db.atas.editalId, db.editais.id));

  $$EditaisTableProcessedTableManager get editalId {
    final $_column = $_itemColumn<int>('edital_id')!;

    final manager = $$EditaisTableTableManager(
      $_db,
      $_db.editais,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_editalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AjustesTable, List<Ajuste>> _ajustesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ajustes,
    aliasName: $_aliasNameGenerator(db.atas.id, db.ajustes.ataId),
  );

  $$AjustesTableProcessedTableManager get ajustesRefs {
    final manager = $$AjustesTableTableManager(
      $_db,
      $_db.ajustes,
    ).filter((f) => f.ataId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ajustesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AtasTableFilterComposer extends Composer<_$AppDatabase, $AtasTable> {
  $$AtasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoEdital => $composableBuilder(
    column: $table.codigoEdital,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoAta => $composableBuilder(
    column: $table.codigoAta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
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

  $$EditaisTableFilterComposer get editalId {
    final $$EditaisTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.editalId,
      referencedTable: $db.editais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditaisTableFilterComposer(
            $db: $db,
            $table: $db.editais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ajustesRefs(
    Expression<bool> Function($$AjustesTableFilterComposer f) f,
  ) {
    final $$AjustesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ajustes,
      getReferencedColumn: (t) => t.ataId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AjustesTableFilterComposer(
            $db: $db,
            $table: $db.ajustes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AtasTableOrderingComposer extends Composer<_$AppDatabase, $AtasTable> {
  $$AtasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoEdital => $composableBuilder(
    column: $table.codigoEdital,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoAta => $composableBuilder(
    column: $table.codigoAta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
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

  $$EditaisTableOrderingComposer get editalId {
    final $$EditaisTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.editalId,
      referencedTable: $db.editais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditaisTableOrderingComposer(
            $db: $db,
            $table: $db.editais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AtasTableAnnotationComposer
    extends Composer<_$AppDatabase, $AtasTable> {
  $$AtasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get municipio =>
      $composableBuilder(column: $table.municipio, builder: (column) => column);

  GeneratedColumn<String> get entidade =>
      $composableBuilder(column: $table.entidade, builder: (column) => column);

  GeneratedColumn<String> get codigoEdital => $composableBuilder(
    column: $table.codigoEdital,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codigoAta =>
      $composableBuilder(column: $table.codigoAta, builder: (column) => column);

  GeneratedColumn<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$EditaisTableAnnotationComposer get editalId {
    final $$EditaisTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.editalId,
      referencedTable: $db.editais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditaisTableAnnotationComposer(
            $db: $db,
            $table: $db.editais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ajustesRefs<T extends Object>(
    Expression<T> Function($$AjustesTableAnnotationComposer a) f,
  ) {
    final $$AjustesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ajustes,
      getReferencedColumn: (t) => t.ataId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AjustesTableAnnotationComposer(
            $db: $db,
            $table: $db.ajustes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AtasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AtasTable,
          Ata,
          $$AtasTableFilterComposer,
          $$AtasTableOrderingComposer,
          $$AtasTableAnnotationComposer,
          $$AtasTableCreateCompanionBuilder,
          $$AtasTableUpdateCompanionBuilder,
          (Ata, $$AtasTableReferences),
          Ata,
          PrefetchHooks Function({bool editalId, bool ajustesRefs})
        > {
  $$AtasTableTableManager(_$AppDatabase db, $AtasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AtasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AtasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AtasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> editalId = const Value.absent(),
                Value<String> municipio = const Value.absent(),
                Value<String> entidade = const Value.absent(),
                Value<String> codigoEdital = const Value.absent(),
                Value<String> codigoAta = const Value.absent(),
                Value<bool> retificacao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> documentoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AtasCompanion(
                id: id,
                editalId: editalId,
                municipio: municipio,
                entidade: entidade,
                codigoEdital: codigoEdital,
                codigoAta: codigoAta,
                retificacao: retificacao,
                status: status,
                documentoJson: documentoJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int editalId,
                required String municipio,
                required String entidade,
                required String codigoEdital,
                required String codigoAta,
                Value<bool> retificacao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> documentoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AtasCompanion.insert(
                id: id,
                editalId: editalId,
                municipio: municipio,
                entidade: entidade,
                codigoEdital: codigoEdital,
                codigoAta: codigoAta,
                retificacao: retificacao,
                status: status,
                documentoJson: documentoJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AtasTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({editalId = false, ajustesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ajustesRefs) db.ajustes],
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
                    if (editalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.editalId,
                                referencedTable: $$AtasTableReferences
                                    ._editalIdTable(db),
                                referencedColumn: $$AtasTableReferences
                                    ._editalIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ajustesRefs)
                    await $_getPrefetchedData<Ata, $AtasTable, Ajuste>(
                      currentTable: table,
                      referencedTable: $$AtasTableReferences._ajustesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$AtasTableReferences(db, table, p0).ajustesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.ataId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AtasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AtasTable,
      Ata,
      $$AtasTableFilterComposer,
      $$AtasTableOrderingComposer,
      $$AtasTableAnnotationComposer,
      $$AtasTableCreateCompanionBuilder,
      $$AtasTableUpdateCompanionBuilder,
      (Ata, $$AtasTableReferences),
      Ata,
      PrefetchHooks Function({bool editalId, bool ajustesRefs})
    >;
typedef $$AjustesTableCreateCompanionBuilder =
    AjustesCompanion Function({
      Value<int> id,
      required int editalId,
      Value<int?> ataId,
      required String municipio,
      required String entidade,
      required String codigoEdital,
      Value<String?> codigoAta,
      required String codigoContrato,
      Value<bool> retificacao,
      Value<String> status,
      Value<String> documentoJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$AjustesTableUpdateCompanionBuilder =
    AjustesCompanion Function({
      Value<int> id,
      Value<int> editalId,
      Value<int?> ataId,
      Value<String> municipio,
      Value<String> entidade,
      Value<String> codigoEdital,
      Value<String?> codigoAta,
      Value<String> codigoContrato,
      Value<bool> retificacao,
      Value<String> status,
      Value<String> documentoJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$AjustesTableReferences
    extends BaseReferences<_$AppDatabase, $AjustesTable, Ajuste> {
  $$AjustesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EditaisTable _editalIdTable(_$AppDatabase db) => db.editais
      .createAlias($_aliasNameGenerator(db.ajustes.editalId, db.editais.id));

  $$EditaisTableProcessedTableManager get editalId {
    final $_column = $_itemColumn<int>('edital_id')!;

    final manager = $$EditaisTableTableManager(
      $_db,
      $_db.editais,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_editalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AtasTable _ataIdTable(_$AppDatabase db) =>
      db.atas.createAlias($_aliasNameGenerator(db.ajustes.ataId, db.atas.id));

  $$AtasTableProcessedTableManager? get ataId {
    final $_column = $_itemColumn<int>('ata_id');
    if ($_column == null) return null;
    final manager = $$AtasTableTableManager(
      $_db,
      $_db.atas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ataIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EmpenhosTable, List<Empenho>> _empenhosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.empenhos,
    aliasName: $_aliasNameGenerator(db.ajustes.id, db.empenhos.ajusteId),
  );

  $$EmpenhosTableProcessedTableManager get empenhosRefs {
    final manager = $$EmpenhosTableTableManager(
      $_db,
      $_db.empenhos,
    ).filter((f) => f.ajusteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_empenhosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TermosContratoTable, List<TermosContratoData>>
  _termosContratoRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.termosContrato,
    aliasName: $_aliasNameGenerator(db.ajustes.id, db.termosContrato.ajusteId),
  );

  $$TermosContratoTableProcessedTableManager get termosContratoRefs {
    final manager = $$TermosContratoTableTableManager(
      $_db,
      $_db.termosContrato,
    ).filter((f) => f.ajusteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_termosContratoRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AjustesTableFilterComposer
    extends Composer<_$AppDatabase, $AjustesTable> {
  $$AjustesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoEdital => $composableBuilder(
    column: $table.codigoEdital,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoAta => $composableBuilder(
    column: $table.codigoAta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoContrato => $composableBuilder(
    column: $table.codigoContrato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
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

  $$EditaisTableFilterComposer get editalId {
    final $$EditaisTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.editalId,
      referencedTable: $db.editais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditaisTableFilterComposer(
            $db: $db,
            $table: $db.editais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AtasTableFilterComposer get ataId {
    final $$AtasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ataId,
      referencedTable: $db.atas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtasTableFilterComposer(
            $db: $db,
            $table: $db.atas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> empenhosRefs(
    Expression<bool> Function($$EmpenhosTableFilterComposer f) f,
  ) {
    final $$EmpenhosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.empenhos,
      getReferencedColumn: (t) => t.ajusteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpenhosTableFilterComposer(
            $db: $db,
            $table: $db.empenhos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> termosContratoRefs(
    Expression<bool> Function($$TermosContratoTableFilterComposer f) f,
  ) {
    final $$TermosContratoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.termosContrato,
      getReferencedColumn: (t) => t.ajusteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TermosContratoTableFilterComposer(
            $db: $db,
            $table: $db.termosContrato,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AjustesTableOrderingComposer
    extends Composer<_$AppDatabase, $AjustesTable> {
  $$AjustesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoEdital => $composableBuilder(
    column: $table.codigoEdital,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoAta => $composableBuilder(
    column: $table.codigoAta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoContrato => $composableBuilder(
    column: $table.codigoContrato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
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

  $$EditaisTableOrderingComposer get editalId {
    final $$EditaisTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.editalId,
      referencedTable: $db.editais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditaisTableOrderingComposer(
            $db: $db,
            $table: $db.editais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AtasTableOrderingComposer get ataId {
    final $$AtasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ataId,
      referencedTable: $db.atas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtasTableOrderingComposer(
            $db: $db,
            $table: $db.atas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AjustesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AjustesTable> {
  $$AjustesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get municipio =>
      $composableBuilder(column: $table.municipio, builder: (column) => column);

  GeneratedColumn<String> get entidade =>
      $composableBuilder(column: $table.entidade, builder: (column) => column);

  GeneratedColumn<String> get codigoEdital => $composableBuilder(
    column: $table.codigoEdital,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codigoAta =>
      $composableBuilder(column: $table.codigoAta, builder: (column) => column);

  GeneratedColumn<String> get codigoContrato => $composableBuilder(
    column: $table.codigoContrato,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$EditaisTableAnnotationComposer get editalId {
    final $$EditaisTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.editalId,
      referencedTable: $db.editais,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditaisTableAnnotationComposer(
            $db: $db,
            $table: $db.editais,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AtasTableAnnotationComposer get ataId {
    final $$AtasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ataId,
      referencedTable: $db.atas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtasTableAnnotationComposer(
            $db: $db,
            $table: $db.atas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> empenhosRefs<T extends Object>(
    Expression<T> Function($$EmpenhosTableAnnotationComposer a) f,
  ) {
    final $$EmpenhosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.empenhos,
      getReferencedColumn: (t) => t.ajusteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmpenhosTableAnnotationComposer(
            $db: $db,
            $table: $db.empenhos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> termosContratoRefs<T extends Object>(
    Expression<T> Function($$TermosContratoTableAnnotationComposer a) f,
  ) {
    final $$TermosContratoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.termosContrato,
      getReferencedColumn: (t) => t.ajusteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TermosContratoTableAnnotationComposer(
            $db: $db,
            $table: $db.termosContrato,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AjustesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AjustesTable,
          Ajuste,
          $$AjustesTableFilterComposer,
          $$AjustesTableOrderingComposer,
          $$AjustesTableAnnotationComposer,
          $$AjustesTableCreateCompanionBuilder,
          $$AjustesTableUpdateCompanionBuilder,
          (Ajuste, $$AjustesTableReferences),
          Ajuste,
          PrefetchHooks Function({
            bool editalId,
            bool ataId,
            bool empenhosRefs,
            bool termosContratoRefs,
          })
        > {
  $$AjustesTableTableManager(_$AppDatabase db, $AjustesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AjustesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AjustesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AjustesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> editalId = const Value.absent(),
                Value<int?> ataId = const Value.absent(),
                Value<String> municipio = const Value.absent(),
                Value<String> entidade = const Value.absent(),
                Value<String> codigoEdital = const Value.absent(),
                Value<String?> codigoAta = const Value.absent(),
                Value<String> codigoContrato = const Value.absent(),
                Value<bool> retificacao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> documentoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AjustesCompanion(
                id: id,
                editalId: editalId,
                ataId: ataId,
                municipio: municipio,
                entidade: entidade,
                codigoEdital: codigoEdital,
                codigoAta: codigoAta,
                codigoContrato: codigoContrato,
                retificacao: retificacao,
                status: status,
                documentoJson: documentoJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int editalId,
                Value<int?> ataId = const Value.absent(),
                required String municipio,
                required String entidade,
                required String codigoEdital,
                Value<String?> codigoAta = const Value.absent(),
                required String codigoContrato,
                Value<bool> retificacao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> documentoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AjustesCompanion.insert(
                id: id,
                editalId: editalId,
                ataId: ataId,
                municipio: municipio,
                entidade: entidade,
                codigoEdital: codigoEdital,
                codigoAta: codigoAta,
                codigoContrato: codigoContrato,
                retificacao: retificacao,
                status: status,
                documentoJson: documentoJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AjustesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                editalId = false,
                ataId = false,
                empenhosRefs = false,
                termosContratoRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (empenhosRefs) db.empenhos,
                    if (termosContratoRefs) db.termosContrato,
                  ],
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
                        if (editalId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.editalId,
                                    referencedTable: $$AjustesTableReferences
                                        ._editalIdTable(db),
                                    referencedColumn: $$AjustesTableReferences
                                        ._editalIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (ataId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ataId,
                                    referencedTable: $$AjustesTableReferences
                                        ._ataIdTable(db),
                                    referencedColumn: $$AjustesTableReferences
                                        ._ataIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (empenhosRefs)
                        await $_getPrefetchedData<
                          Ajuste,
                          $AjustesTable,
                          Empenho
                        >(
                          currentTable: table,
                          referencedTable: $$AjustesTableReferences
                              ._empenhosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AjustesTableReferences(
                                db,
                                table,
                                p0,
                              ).empenhosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ajusteId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (termosContratoRefs)
                        await $_getPrefetchedData<
                          Ajuste,
                          $AjustesTable,
                          TermosContratoData
                        >(
                          currentTable: table,
                          referencedTable: $$AjustesTableReferences
                              ._termosContratoRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AjustesTableReferences(
                                db,
                                table,
                                p0,
                              ).termosContratoRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ajusteId == item.id,
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

typedef $$AjustesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AjustesTable,
      Ajuste,
      $$AjustesTableFilterComposer,
      $$AjustesTableOrderingComposer,
      $$AjustesTableAnnotationComposer,
      $$AjustesTableCreateCompanionBuilder,
      $$AjustesTableUpdateCompanionBuilder,
      (Ajuste, $$AjustesTableReferences),
      Ajuste,
      PrefetchHooks Function({
        bool editalId,
        bool ataId,
        bool empenhosRefs,
        bool termosContratoRefs,
      })
    >;
typedef $$EmpenhosTableCreateCompanionBuilder =
    EmpenhosCompanion Function({
      Value<int> id,
      required int ajusteId,
      required String municipio,
      required String entidade,
      required String codigoContrato,
      required String numeroEmpenho,
      required int anoEmpenho,
      Value<bool> retificacao,
      Value<String> status,
      Value<String> documentoJson,
      Value<DateTime> createdAt,
    });
typedef $$EmpenhosTableUpdateCompanionBuilder =
    EmpenhosCompanion Function({
      Value<int> id,
      Value<int> ajusteId,
      Value<String> municipio,
      Value<String> entidade,
      Value<String> codigoContrato,
      Value<String> numeroEmpenho,
      Value<int> anoEmpenho,
      Value<bool> retificacao,
      Value<String> status,
      Value<String> documentoJson,
      Value<DateTime> createdAt,
    });

final class $$EmpenhosTableReferences
    extends BaseReferences<_$AppDatabase, $EmpenhosTable, Empenho> {
  $$EmpenhosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AjustesTable _ajusteIdTable(_$AppDatabase db) => db.ajustes
      .createAlias($_aliasNameGenerator(db.empenhos.ajusteId, db.ajustes.id));

  $$AjustesTableProcessedTableManager get ajusteId {
    final $_column = $_itemColumn<int>('ajuste_id')!;

    final manager = $$AjustesTableTableManager(
      $_db,
      $_db.ajustes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ajusteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EmpenhosTableFilterComposer
    extends Composer<_$AppDatabase, $EmpenhosTable> {
  $$EmpenhosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoContrato => $composableBuilder(
    column: $table.codigoContrato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numeroEmpenho => $composableBuilder(
    column: $table.numeroEmpenho,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anoEmpenho => $composableBuilder(
    column: $table.anoEmpenho,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AjustesTableFilterComposer get ajusteId {
    final $$AjustesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ajusteId,
      referencedTable: $db.ajustes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AjustesTableFilterComposer(
            $db: $db,
            $table: $db.ajustes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmpenhosTableOrderingComposer
    extends Composer<_$AppDatabase, $EmpenhosTable> {
  $$EmpenhosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoContrato => $composableBuilder(
    column: $table.codigoContrato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numeroEmpenho => $composableBuilder(
    column: $table.numeroEmpenho,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anoEmpenho => $composableBuilder(
    column: $table.anoEmpenho,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AjustesTableOrderingComposer get ajusteId {
    final $$AjustesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ajusteId,
      referencedTable: $db.ajustes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AjustesTableOrderingComposer(
            $db: $db,
            $table: $db.ajustes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmpenhosTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmpenhosTable> {
  $$EmpenhosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get municipio =>
      $composableBuilder(column: $table.municipio, builder: (column) => column);

  GeneratedColumn<String> get entidade =>
      $composableBuilder(column: $table.entidade, builder: (column) => column);

  GeneratedColumn<String> get codigoContrato => $composableBuilder(
    column: $table.codigoContrato,
    builder: (column) => column,
  );

  GeneratedColumn<String> get numeroEmpenho => $composableBuilder(
    column: $table.numeroEmpenho,
    builder: (column) => column,
  );

  GeneratedColumn<int> get anoEmpenho => $composableBuilder(
    column: $table.anoEmpenho,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AjustesTableAnnotationComposer get ajusteId {
    final $$AjustesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ajusteId,
      referencedTable: $db.ajustes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AjustesTableAnnotationComposer(
            $db: $db,
            $table: $db.ajustes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmpenhosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmpenhosTable,
          Empenho,
          $$EmpenhosTableFilterComposer,
          $$EmpenhosTableOrderingComposer,
          $$EmpenhosTableAnnotationComposer,
          $$EmpenhosTableCreateCompanionBuilder,
          $$EmpenhosTableUpdateCompanionBuilder,
          (Empenho, $$EmpenhosTableReferences),
          Empenho,
          PrefetchHooks Function({bool ajusteId})
        > {
  $$EmpenhosTableTableManager(_$AppDatabase db, $EmpenhosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmpenhosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmpenhosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmpenhosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ajusteId = const Value.absent(),
                Value<String> municipio = const Value.absent(),
                Value<String> entidade = const Value.absent(),
                Value<String> codigoContrato = const Value.absent(),
                Value<String> numeroEmpenho = const Value.absent(),
                Value<int> anoEmpenho = const Value.absent(),
                Value<bool> retificacao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> documentoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EmpenhosCompanion(
                id: id,
                ajusteId: ajusteId,
                municipio: municipio,
                entidade: entidade,
                codigoContrato: codigoContrato,
                numeroEmpenho: numeroEmpenho,
                anoEmpenho: anoEmpenho,
                retificacao: retificacao,
                status: status,
                documentoJson: documentoJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ajusteId,
                required String municipio,
                required String entidade,
                required String codigoContrato,
                required String numeroEmpenho,
                required int anoEmpenho,
                Value<bool> retificacao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> documentoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EmpenhosCompanion.insert(
                id: id,
                ajusteId: ajusteId,
                municipio: municipio,
                entidade: entidade,
                codigoContrato: codigoContrato,
                numeroEmpenho: numeroEmpenho,
                anoEmpenho: anoEmpenho,
                retificacao: retificacao,
                status: status,
                documentoJson: documentoJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EmpenhosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ajusteId = false}) {
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
                    if (ajusteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ajusteId,
                                referencedTable: $$EmpenhosTableReferences
                                    ._ajusteIdTable(db),
                                referencedColumn: $$EmpenhosTableReferences
                                    ._ajusteIdTable(db)
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

typedef $$EmpenhosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmpenhosTable,
      Empenho,
      $$EmpenhosTableFilterComposer,
      $$EmpenhosTableOrderingComposer,
      $$EmpenhosTableAnnotationComposer,
      $$EmpenhosTableCreateCompanionBuilder,
      $$EmpenhosTableUpdateCompanionBuilder,
      (Empenho, $$EmpenhosTableReferences),
      Empenho,
      PrefetchHooks Function({bool ajusteId})
    >;
typedef $$TermosContratoTableCreateCompanionBuilder =
    TermosContratoCompanion Function({
      Value<int> id,
      required int ajusteId,
      required String municipio,
      required String entidade,
      required String codigoContrato,
      required String codigoTermoContrato,
      Value<bool> retificacao,
      Value<String> status,
      Value<String> documentoJson,
      Value<DateTime> createdAt,
    });
typedef $$TermosContratoTableUpdateCompanionBuilder =
    TermosContratoCompanion Function({
      Value<int> id,
      Value<int> ajusteId,
      Value<String> municipio,
      Value<String> entidade,
      Value<String> codigoContrato,
      Value<String> codigoTermoContrato,
      Value<bool> retificacao,
      Value<String> status,
      Value<String> documentoJson,
      Value<DateTime> createdAt,
    });

final class $$TermosContratoTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TermosContratoTable,
          TermosContratoData
        > {
  $$TermosContratoTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AjustesTable _ajusteIdTable(_$AppDatabase db) =>
      db.ajustes.createAlias(
        $_aliasNameGenerator(db.termosContrato.ajusteId, db.ajustes.id),
      );

  $$AjustesTableProcessedTableManager get ajusteId {
    final $_column = $_itemColumn<int>('ajuste_id')!;

    final manager = $$AjustesTableTableManager(
      $_db,
      $_db.ajustes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ajusteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TermosContratoTableFilterComposer
    extends Composer<_$AppDatabase, $TermosContratoTable> {
  $$TermosContratoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoContrato => $composableBuilder(
    column: $table.codigoContrato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoTermoContrato => $composableBuilder(
    column: $table.codigoTermoContrato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AjustesTableFilterComposer get ajusteId {
    final $$AjustesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ajusteId,
      referencedTable: $db.ajustes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AjustesTableFilterComposer(
            $db: $db,
            $table: $db.ajustes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TermosContratoTableOrderingComposer
    extends Composer<_$AppDatabase, $TermosContratoTable> {
  $$TermosContratoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidade => $composableBuilder(
    column: $table.entidade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoContrato => $composableBuilder(
    column: $table.codigoContrato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoTermoContrato => $composableBuilder(
    column: $table.codigoTermoContrato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AjustesTableOrderingComposer get ajusteId {
    final $$AjustesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ajusteId,
      referencedTable: $db.ajustes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AjustesTableOrderingComposer(
            $db: $db,
            $table: $db.ajustes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TermosContratoTableAnnotationComposer
    extends Composer<_$AppDatabase, $TermosContratoTable> {
  $$TermosContratoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get municipio =>
      $composableBuilder(column: $table.municipio, builder: (column) => column);

  GeneratedColumn<String> get entidade =>
      $composableBuilder(column: $table.entidade, builder: (column) => column);

  GeneratedColumn<String> get codigoContrato => $composableBuilder(
    column: $table.codigoContrato,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codigoTermoContrato => $composableBuilder(
    column: $table.codigoTermoContrato,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get retificacao => $composableBuilder(
    column: $table.retificacao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get documentoJson => $composableBuilder(
    column: $table.documentoJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AjustesTableAnnotationComposer get ajusteId {
    final $$AjustesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ajusteId,
      referencedTable: $db.ajustes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AjustesTableAnnotationComposer(
            $db: $db,
            $table: $db.ajustes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TermosContratoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TermosContratoTable,
          TermosContratoData,
          $$TermosContratoTableFilterComposer,
          $$TermosContratoTableOrderingComposer,
          $$TermosContratoTableAnnotationComposer,
          $$TermosContratoTableCreateCompanionBuilder,
          $$TermosContratoTableUpdateCompanionBuilder,
          (TermosContratoData, $$TermosContratoTableReferences),
          TermosContratoData,
          PrefetchHooks Function({bool ajusteId})
        > {
  $$TermosContratoTableTableManager(
    _$AppDatabase db,
    $TermosContratoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TermosContratoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TermosContratoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TermosContratoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ajusteId = const Value.absent(),
                Value<String> municipio = const Value.absent(),
                Value<String> entidade = const Value.absent(),
                Value<String> codigoContrato = const Value.absent(),
                Value<String> codigoTermoContrato = const Value.absent(),
                Value<bool> retificacao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> documentoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TermosContratoCompanion(
                id: id,
                ajusteId: ajusteId,
                municipio: municipio,
                entidade: entidade,
                codigoContrato: codigoContrato,
                codigoTermoContrato: codigoTermoContrato,
                retificacao: retificacao,
                status: status,
                documentoJson: documentoJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ajusteId,
                required String municipio,
                required String entidade,
                required String codigoContrato,
                required String codigoTermoContrato,
                Value<bool> retificacao = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> documentoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TermosContratoCompanion.insert(
                id: id,
                ajusteId: ajusteId,
                municipio: municipio,
                entidade: entidade,
                codigoContrato: codigoContrato,
                codigoTermoContrato: codigoTermoContrato,
                retificacao: retificacao,
                status: status,
                documentoJson: documentoJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TermosContratoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ajusteId = false}) {
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
                    if (ajusteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ajusteId,
                                referencedTable: $$TermosContratoTableReferences
                                    ._ajusteIdTable(db),
                                referencedColumn:
                                    $$TermosContratoTableReferences
                                        ._ajusteIdTable(db)
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

typedef $$TermosContratoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TermosContratoTable,
      TermosContratoData,
      $$TermosContratoTableFilterComposer,
      $$TermosContratoTableOrderingComposer,
      $$TermosContratoTableAnnotationComposer,
      $$TermosContratoTableCreateCompanionBuilder,
      $$TermosContratoTableUpdateCompanionBuilder,
      (TermosContratoData, $$TermosContratoTableReferences),
      TermosContratoData,
      PrefetchHooks Function({bool ajusteId})
    >;
typedef $$ApiLogsTableCreateCompanionBuilder =
    ApiLogsCompanion Function({
      Value<int> id,
      required String endpoint,
      required String request,
      Value<String?> response,
      Value<int?> statusCode,
      Value<int?> userId,
      Value<DateTime> timestamp,
    });
typedef $$ApiLogsTableUpdateCompanionBuilder =
    ApiLogsCompanion Function({
      Value<int> id,
      Value<String> endpoint,
      Value<String> request,
      Value<String?> response,
      Value<int?> statusCode,
      Value<int?> userId,
      Value<DateTime> timestamp,
    });

class $$ApiLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ApiLogsTable> {
  $$ApiLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get request => $composableBuilder(
    column: $table.request,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get response => $composableBuilder(
    column: $table.response,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statusCode => $composableBuilder(
    column: $table.statusCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApiLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiLogsTable> {
  $$ApiLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get request => $composableBuilder(
    column: $table.request,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get response => $composableBuilder(
    column: $table.response,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statusCode => $composableBuilder(
    column: $table.statusCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApiLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiLogsTable> {
  $$ApiLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get request =>
      $composableBuilder(column: $table.request, builder: (column) => column);

  GeneratedColumn<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => column);

  GeneratedColumn<int> get statusCode => $composableBuilder(
    column: $table.statusCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$ApiLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiLogsTable,
          ApiLog,
          $$ApiLogsTableFilterComposer,
          $$ApiLogsTableOrderingComposer,
          $$ApiLogsTableAnnotationComposer,
          $$ApiLogsTableCreateCompanionBuilder,
          $$ApiLogsTableUpdateCompanionBuilder,
          (ApiLog, BaseReferences<_$AppDatabase, $ApiLogsTable, ApiLog>),
          ApiLog,
          PrefetchHooks Function()
        > {
  $$ApiLogsTableTableManager(_$AppDatabase db, $ApiLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> request = const Value.absent(),
                Value<String?> response = const Value.absent(),
                Value<int?> statusCode = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => ApiLogsCompanion(
                id: id,
                endpoint: endpoint,
                request: request,
                response: response,
                statusCode: statusCode,
                userId: userId,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String endpoint,
                required String request,
                Value<String?> response = const Value.absent(),
                Value<int?> statusCode = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => ApiLogsCompanion.insert(
                id: id,
                endpoint: endpoint,
                request: request,
                response: response,
                statusCode: statusCode,
                userId: userId,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApiLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiLogsTable,
      ApiLog,
      $$ApiLogsTableFilterComposer,
      $$ApiLogsTableOrderingComposer,
      $$ApiLogsTableAnnotationComposer,
      $$ApiLogsTableCreateCompanionBuilder,
      $$ApiLogsTableUpdateCompanionBuilder,
      (ApiLog, BaseReferences<_$AppDatabase, $ApiLogsTable, ApiLog>),
      ApiLog,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$EditaisTableTableManager get editais =>
      $$EditaisTableTableManager(_db, _db.editais);
  $$LicitacoesTableTableManager get licitacoes =>
      $$LicitacoesTableTableManager(_db, _db.licitacoes);
  $$AtasTableTableManager get atas => $$AtasTableTableManager(_db, _db.atas);
  $$AjustesTableTableManager get ajustes =>
      $$AjustesTableTableManager(_db, _db.ajustes);
  $$EmpenhosTableTableManager get empenhos =>
      $$EmpenhosTableTableManager(_db, _db.empenhos);
  $$TermosContratoTableTableManager get termosContrato =>
      $$TermosContratoTableTableManager(_db, _db.termosContrato);
  $$ApiLogsTableTableManager get apiLogs =>
      $$ApiLogsTableTableManager(_db, _db.apiLogs);
}
