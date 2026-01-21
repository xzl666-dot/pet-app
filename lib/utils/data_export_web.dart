// 仅用于web平台的导出功能
import 'dart:html' as html;
import 'dart:typed_data';

// 提供web平台的下载功能
bool downloadFile(String content, String filename, String mimeType) {
  try {
    final bytes = content.codeUnits;
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename);
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (e) {
    print('下载失败: $e');
    return false;
  }
}