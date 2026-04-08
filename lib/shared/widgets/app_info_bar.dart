import 'package:fluent_ui/fluent_ui.dart';

/// Severidade do InfoBar exibido.
enum AppInfoBarSeverity { success, warning, error, info }

/// Exibe um [InfoBar] flutuante via [displayInfoBar].
///
/// Uso:
/// ```dart
/// showAppInfoBar(context, 'Registro salvo.', severity: AppInfoBarSeverity.success);
/// ```
void showAppInfoBar(
  BuildContext context,
  String message, {
  AppInfoBarSeverity severity = AppInfoBarSeverity.info,
  bool isLong = false,
}) {
  displayInfoBar(
    context,
    duration: isLong ? const Duration(seconds: 5) : const Duration(seconds: 3),
    builder: (ctx, close) => InfoBar(
      title: Text(message),
      severity: _toInfoBarSeverity(severity),
      onClose: close,
    ),
  );
}

InfoBarSeverity _toInfoBarSeverity(AppInfoBarSeverity s) {
  switch (s) {
    case AppInfoBarSeverity.success:
      return InfoBarSeverity.success;
    case AppInfoBarSeverity.warning:
      return InfoBarSeverity.warning;
    case AppInfoBarSeverity.error:
      return InfoBarSeverity.error;
    case AppInfoBarSeverity.info:
      return InfoBarSeverity.info;
  }
}
