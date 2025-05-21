import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:epubx/epubx.dart';
import 'package:html_unescape/html_unescape.dart';

class EpubUtils {
  /// Trả về một Map: tiêu đề chương → danh sách đoạn plain-text
  static Future<Map<String, List<String>>> getParagraphsByChapterFromAsset(
      String assetPath) async {
    // 1) Load bytes từ asset
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    // 2) Parse EPUB
    final book = await EpubReader.readBook(bytes);

    // 3) Chuẩn bị unescaper và container kết quả
    final unescaper = HtmlUnescape();
    final Map<String, List<String>> result = {};

    if (book.Chapters != null) {
      for (final chap in book.Chapters!) {
        // Lấy tiêu đề chương, nếu null thì đặt “Không tiêu đề”
        final title = chap.Title?.trim().isNotEmpty == true
            ? chap.Title!
            : 'Chương không tên';

        // Loại bỏ tag HTML và unescape
        final html = chap.HtmlContent ?? '';
        final plain =
            unescaper.convert(html.replaceAll(RegExp(r'<[^>]+>'), '').trim());

        // Tách thành đoạn theo blank-line
        final paras = plain
            .split(RegExp(r'\r?\n\s*\r?\n'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        result[title] = paras;
      }
    }

    return result;
  }

  /// Tương tự cho EPUB đã tải xuống
  static Future<Map<String, List<String>>> getParagraphsByChapterFromFile(
      String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final book = await EpubReader.readBook(bytes);
    final unescaper = HtmlUnescape();
    final Map<String, List<String>> result = {};

    if (book.Chapters != null) {
      for (final chap in book.Chapters!) {
        final title = chap.Title?.trim().isNotEmpty == true
            ? chap.Title!
            : 'Chương không tên';
        final html = chap.HtmlContent ?? '';
        final plain =
            unescaper.convert(html.replaceAll(RegExp(r'<[^>]+>'), '').trim());
        final paras = plain
            .split(RegExp(r'\r?\n\s*\r?\n'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
        result[title] = paras;
      }
    }

    return result;
  }
}
