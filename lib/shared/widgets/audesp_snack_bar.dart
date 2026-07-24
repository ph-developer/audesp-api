import 'dart:async';

import 'package:flutter/material.dart';

class AudespSnackBar {
  const AudespSnackBar._();

  static OverlayEntry? _activeError;
  static Timer? _errorTimer;

  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message);
  }

  static void error(BuildContext context, String message) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      show(context, message: message, backgroundColor: Colors.red);
      return;
    }

    _dismissActiveError();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        final colors = Theme.of(overlayContext).colorScheme;
        return Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  child: Material(
                    elevation: 12,
                    color: colors.error,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colors.onError),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                message,
                                style: TextStyle(color: colors.onError),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Fechar mensagem',
                            onPressed: () => _dismissError(entry),
                            icon: Icon(Icons.close, color: colors.onError),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    _activeError = entry;
    overlay.insert(entry);
    _errorTimer = Timer(const Duration(seconds: 4), () => _dismissError(entry));
  }

  static void _dismissActiveError() {
    final current = _activeError;
    if (current != null) _dismissError(current);
  }

  static void _dismissError(OverlayEntry entry) {
    if (_activeError != entry) return;
    _errorTimer?.cancel();
    _errorTimer = null;
    _activeError = null;
    entry.remove();
  }
}
