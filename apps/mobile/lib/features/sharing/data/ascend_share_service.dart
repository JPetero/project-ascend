import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders a widget (an [AchievementShareCard], wrapped in a
/// [RepaintBoundary]) to a PNG and hands it to the native OS share sheet.
///
/// Not implemented: automated posting directly to Instagram. Meta's
/// Content Publishing API requires a Business/Creator account and app
/// review — see packages/docs/roadmap.md for that future integration.
abstract class AscendShareService {
  Future<void> shareCard({
    required GlobalKey boundaryKey,
    required String shareText,
  });
}

class DefaultAscendShareService implements AscendShareService {
  const DefaultAscendShareService();

  @override
  Future<void> shareCard({
    required GlobalKey boundaryKey,
    required String shareText,
  }) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final pngBytes = byteData.buffer.asUint8List();
    final file = await _writeTempFile(pngBytes);

    await Share.shareXFiles([XFile(file.path)], text: shareText);
  }

  Future<File> _writeTempFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/ascend-achievement-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    return file.writeAsBytes(bytes);
  }
}
