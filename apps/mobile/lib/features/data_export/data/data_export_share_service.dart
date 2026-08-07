import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a completed data export to the native OS share sheet — Build
/// Session 8 Part 14. Same "write a temp file, hand it to Share"
/// pattern as [DefaultAscendShareService] (Marathon Part 4's achievement
/// sharing); kept as its own interface since it shares JSON text rather
/// than a rendered PNG.
abstract class DataExportShareService {
  Future<void> shareExport(Map<String, dynamic> export);
}

class DefaultDataExportShareService implements DataExportShareService {
  const DefaultDataExportShareService();

  @override
  Future<void> shareExport(Map<String, dynamic> export) async {
    final json = const JsonEncoder.withIndent('  ').convert(export);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/ascend-data-export-${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(json);

    await Share.shareXFiles([
      XFile(file.path, mimeType: 'application/json'),
    ], text: 'Your Ascend data export');
  }
}
