class AppSetting {
  final String key;
  final String value;

  const AppSetting({required this.key, required this.value});

  factory AppSetting.fromMap(Map<String, dynamic> row) =>
      AppSetting(key: row['key'] as String, value: row['value'] as String);

  Map<String, dynamic> toMap() => {'key': key, 'value': value};
}
