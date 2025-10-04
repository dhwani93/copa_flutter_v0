import 'dart:io';
import 'package:image/image.dart';

void main() {
  final srcDir = Directory('assets/figma/pins/png');
  final outDir = Directory('assets/figma/pins/resized');
  if (!srcDir.existsSync()) {
    print('source dir does not exist: ${srcDir.path}');
    return;
  }
  outDir.createSync(recursive: true);

  final sizes = [24, 32, 36, 48];
  final files = srcDir.listSync().whereType<File>().where((f) => f.path.endsWith('.png'));
  for (final file in files) {
    final bytes = file.readAsBytesSync();
    final img = decodeImage(bytes);
    if (img == null) continue;
    for (final size in sizes) {
      final resized = copyResize(img, width: size, height: (img.height * size / img.width).round(), interpolation: Interpolation.cubic);
      final outName = '${outDir.path}/${file.uri.pathSegments.last.replaceAll('.png', '')}_${size}w.png';
      File(outName).writeAsBytesSync(encodePng(resized));
      print('wrote $outName');
    }
  }
}
