import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/services.dart' show rootBundle;

Future<bool> downloadAssetScript(String scriptName) async {
  try {
    final content = await rootBundle.loadString('scripts/$scriptName');
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/x-shellscript');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..download = scriptName
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (_) {
    return false;
  }
}
