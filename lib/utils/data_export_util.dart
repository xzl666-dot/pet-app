import 'dart:convert' show JsonEncoder, utf8;
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

// 为web平台条件导入
import 'data_export_web.dart' if (dart.library.html) 'data_export_web.dart';

class DataExportUtil {
  static final DataExportUtil instance = DataExportUtil._init();

  DataExportUtil._init();

  // 将数据导出为CSV格式
  Future<String> exportToCSV(List<Map<String, dynamic>> data, String filenamePrefix) async {
    if (data.isEmpty) {
      throw Exception('没有数据可以导出');
    }

    // 获取CSV文件头
    final headers = data.first.keys.toList();
    final csvContent = StringBuffer();

    // 写入CSV头
    csvContent.writeln(headers.join(','));

    // 写入数据行
    for (final row in data) {
      final csvRow = headers.map((header) {
        final value = row[header];
        // 如果值包含逗号或引号，需要用引号包裹
        if (value.toString().contains(',') || value.toString().contains('"')) {
          return '"${value.toString().replaceAll('"', '""')}"';
        }
        return value.toString();
      }).join(',');
      csvContent.writeln(csvRow);
    }

    // 创建文件路径
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final filename = '$filenamePrefix$timestamp.csv';

    // 根据平台选择不同的下载方式
    if (kIsWeb) {
      // Web平台：使用浏览器下载API
      downloadFile(csvContent.toString(), filename, 'text/csv;charset=utf-8');
      return filename;
    } else {
      // 其他平台：使用文件系统
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('无法获取存储目录');
      }
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsString(csvContent.toString());
      return filePath;
    }
  }

  // 将数据导出为JSON格式
  Future<String> exportToJSON(List<Map<String, dynamic>> data, String filenamePrefix) async {
    if (data.isEmpty) {
      throw Exception('没有数据可以导出');
    }

    // 将数据转换为JSON字符串
    final jsonString = JsonEncoder.withIndent('  ').convert(data);

    // 创建文件路径
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final filename = '$filenamePrefix$timestamp.json';

    // 根据平台选择不同的下载方式
    if (kIsWeb) {
      // Web平台：使用浏览器下载API
      downloadFile(jsonString, filename, 'application/json;charset=utf-8');
      return filename;
    } else {
      // 其他平台：使用文件系统
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('无法获取存储目录');
      }
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsString(jsonString);
      return filePath;
    }
  }
}