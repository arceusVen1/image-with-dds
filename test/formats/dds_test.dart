import 'dart:io';
import 'package:image/image.dart';
import 'package:image/src/formats/dds_decoder.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    final dir = Directory('test/_data/dds');
    if (!dir.existsSync()) {
      return;
    }
    final files = dir.listSync();

    group('dds', () {
      for (final f in files.whereType<File>()) {
        if (!f.path.endsWith('.dds')) {
          continue;
        }

        final name = f.uri.pathSegments.last;
        test(name, () {
          final bytes = f.readAsBytesSync();
          final image = DdsDecoder().decode(bytes);
          expect(image, isNotNull);

          encodePngFile(
              'test/_data/dds/${name.replaceAll(".dds", "")}.png', image!);
        });
      }
    });
  });
}
