import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class HtmlClipboard {
  static void copyHtml(String htmlContent) {
    // Generate the CF_HTML format string
    final String cfHtml = _buildCfHtml(htmlContent);

    using((arena) {
      // Register the HTML Format with Windows
      final formatName = arena.pcwstr('HTML Format');
      final cfHtmlResult = RegisterClipboardFormat(formatName);
      final int cfHtmlId = cfHtmlResult.value;

      if (cfHtmlId == 0) return;

      final openResult = OpenClipboard(null);
      if (openResult.value) {
        EmptyClipboard();

        // Allocate global memory
        final dataBytes = utf8.encode(cfHtml);
        final allocResult = GlobalAlloc(GMEM_MOVEABLE, dataBytes.length + 1);
        final hMem = allocResult.value;

        final lockResult = GlobalLock(hMem);
        final pMem = lockResult.value;
        if (pMem != nullptr) {
          // Copy data to global memory
          final ptr = pMem.cast<Uint8>();
          for (var i = 0; i < dataBytes.length; i++) {
            ptr[i] = dataBytes[i];
          }
          ptr[dataBytes.length] = 0; // null terminator

          GlobalUnlock(hMem);
          SetClipboardData(cfHtmlId, HANDLE(Pointer.fromAddress(hMem.address)));
        }
        CloseClipboard();
      }
    });
  }

  static String _buildCfHtml(String html) {
    // The HTML Clipboard Format requires a specific header structure
    // We pad the byte offsets to 10 digits to keep the header size constant
    final header = '''Version:0.9\r
StartHTML:0000000000\r
EndHTML:0000000000\r
StartFragment:0000000000\r
EndFragment:0000000000\r
''';

    final fragmentStart = '<!--StartFragment-->';
    final fragmentEnd = '<!--EndFragment-->';

    final fullHtml = '$fragmentStart$html$fragmentEnd';

    // Calculate byte offsets
    final startHtml = utf8.encode(header).length;
    final startFragment = startHtml + utf8.encode(fragmentStart).length;
    final endFragment = startFragment + utf8.encode(html).length;
    final endHtml = endFragment + utf8.encode(fragmentEnd).length;

    // Replace the placeholders with actual offsets
    final result = header
        .replaceFirst(
          'StartHTML:0000000000',
          'StartHTML:${startHtml.toString().padLeft(10, '0')}',
        )
        .replaceFirst(
          'EndHTML:0000000000',
          'EndHTML:${endHtml.toString().padLeft(10, '0')}',
        )
        .replaceFirst(
          'StartFragment:0000000000',
          'StartFragment:${startFragment.toString().padLeft(10, '0')}',
        )
        .replaceFirst(
          'EndFragment:0000000000',
          'EndFragment:${endFragment.toString().padLeft(10, '0')}',
        );

    return result + fullHtml;
  }
}
