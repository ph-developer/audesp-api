import 'package:drift/drift.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Users — usuários locais do app (credenciais AUDESP ficam no secure storage)
// ─────────────────────────────────────────────────────────────────────────────
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text()();
  TextColumn get email => text().unique()();
  TextColumn get municipio => text()();
  TextColumn get entidade => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────────────────────────────────────
// Editais — Módulo 1
// ─────────────────────────────────────────────────────────────────────────────
class Editais extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get municipio => text()();
  TextColumn get entidade => text()();
  TextColumn get codigoEdital => text()();
  BoolColumn get retificacao =>
      boolean().withDefault(const Constant(false))();
  // 'draft' | 'sent'
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get pdfPath => text().nullable()();
  TextColumn get documentoJson =>
      text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────────────────────────────────────
// Licitacoes — Módulo 2, vinculado a um Edital
// ─────────────────────────────────────────────────────────────────────────────
class Licitacoes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get editalId => integer().references(Editais, #id)();
  TextColumn get municipio => text()();
  TextColumn get entidade => text()();
  TextColumn get codigoEdital => text()();
  BoolColumn get retificacao =>
      boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get documentoJson =>
      text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────────────────────────────────────
// Atas — Módulo 3, vinculado a Edital com srp=true
// ─────────────────────────────────────────────────────────────────────────────
class Atas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get editalId => integer().references(Editais, #id)();
  TextColumn get municipio => text()();
  TextColumn get entidade => text()();
  TextColumn get codigoEdital => text()();
  TextColumn get codigoAta => text()();
  BoolColumn get retificacao =>
      boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get documentoJson =>
      text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────────────────────────────────────
// Ajustes — Módulo 4, vinculado a Edital + Ata (opcional)
// ─────────────────────────────────────────────────────────────────────────────
class Ajustes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get editalId => integer().references(Editais, #id)();
  IntColumn get ataId => integer().references(Atas, #id).nullable()();
  TextColumn get municipio => text()();
  TextColumn get entidade => text()();
  TextColumn get codigoEdital => text()();
  TextColumn get codigoAta => text().nullable()();
  TextColumn get codigoContrato => text()();
  BoolColumn get retificacao =>
      boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get documentoJson =>
      text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────────────────────────────────────
// Empenhos — sub-módulo do Ajuste
// ─────────────────────────────────────────────────────────────────────────────
class Empenhos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ajusteId => integer().references(Ajustes, #id)();
  TextColumn get municipio => text()();
  TextColumn get entidade => text()();
  TextColumn get codigoContrato => text()();
  TextColumn get numeroEmpenho => text()();
  IntColumn get anoEmpenho => integer()();
  BoolColumn get retificacao =>
      boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get documentoJson =>
      text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────────────────────────────────────
// TermosContrato — sub-módulo do Ajuste
// ─────────────────────────────────────────────────────────────────────────────
class TermosContrato extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ajusteId => integer().references(Ajustes, #id)();
  TextColumn get municipio => text()();
  TextColumn get entidade => text()();
  TextColumn get codigoContrato => text()();
  TextColumn get codigoTermoContrato => text()();
  BoolColumn get retificacao =>
      boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get documentoJson =>
      text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────────────────────────────────────
// ApiLogs — histórico de todas as chamadas à API AUDESP
// ─────────────────────────────────────────────────────────────────────────────
class ApiLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get endpoint => text()();
  TextColumn get request => text()();
  TextColumn get response => text().nullable()();
  IntColumn get statusCode => integer().nullable()();
  IntColumn get userId => integer().nullable()();
  DateTimeColumn get timestamp =>
      dateTime().withDefault(currentDateAndTime)();
}
