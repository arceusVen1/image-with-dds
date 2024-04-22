import 'dart:typed_data';

import '../../image.dart';
import 'dds/dds_info.dart';

class DdsDecoder extends Decoder {
  DdsInfo? info;
  late InputBuffer input;

  static const _pixelsPerBlock = 16;

  @override
  ImageFormat get format => ImageFormat.dds;

  /// Is the given file a valid DDS image?
  @override
  bool isValidFile(Uint8List data) {
    final input = InputBuffer(data);

    info = DdsInfo();
    info!.read(input);
    return info!.isValid();
  }

  @override
  Image? decode(Uint8List bytes, {int? frame}) {
    if (startDecode(bytes) == null) {
      return null;
    }

    return decodeFrame(frame ?? 0);
  }

  @override
  DecodeInfo? startDecode(Uint8List bytes) {
    info = DdsInfo();
    input = InputBuffer(bytes);

    final header = input.readBytes(128);
    info!.read(header);
    if (!info!.isValid()) {
      return null;
    }

    return info;
  }

  @override
  int numFrames() => info != null ? 1 : 0;

  @override
  Image? decodeFrame(int frame) {
    if (info == null) {
      return null;
    }

    if (info!.pixelFormatFlags == DdsPixelFormatFlags.ddpfFourCC) {
      return _decodeDxt();
    }
    return _decodeRgb();
  }

  Image? _decodeDxt() {
    final width = info!.width;
    final height = info!.height;
    final image = Image(
      width: width,
      height: height,
      numChannels: info!.pixelFormatFourCC.channelsCount,
    );

    final size = width * height;
    final data = input.readBytes(size ~/ 16);

    final List<Pixel> pixelsBuffer =
        List.filled(_pixelsPerBlock, Pixel.undefined);
    int row = 0;
    int col = 0;
    for (var pCount = 0; pCount < size / _pixelsPerBlock; pCount++) {
      for (var p = 0; p < _pixelsPerBlock; p++) {
        final x = col + p % 4;
        final y = row + p ~/ 4;
        if (x >= width || y >= height) {
          continue;
        }
        final pixel = image.getPixel(x, y);
        pixelsBuffer[p] = pixel;
      }
      col = (col + 4) % width;
      row += col == 0 ? 4 : 0;
      final blockData = data.readBytes(
        info!.pixelFormatFourCC.getBytesPer4x4Block,
      );

      if (info!.pixelFormatFourCC == DDSFourCCFormat.DXT5 ||
          info!.pixelFormatFourCC == DDSFourCCFormat.DXT4) {
        // use BC3 alpha block
        final alpha0 = blockData.readByte();
        final alpha1 = blockData.readByte();
        final alphas = info!.pixelFormatFourCC.generateAlphasFromInitialAlphas(
          alpha0,
          alpha1,
        );
        final alphaData = blockData.readBytes(3).readUint32();
        for (var i = 0; i < 2; i++) {
          for (var j = 0; j < 8; j++) {
            final alpha = alphas[(alphaData >> j * 3) & 0x7];
            pixelsBuffer[i * 8 + j].a = alpha;
          }
        }
      }

      final color0Data = blockData.readUint16();
      final color1Data = blockData.readUint16();

      final colors = info!.pixelFormatFourCC.generateColorsFromInitialColors(
        color0Data,
        color1Data,
      );
      for (var i = 0; i < 4; i++) {
        final colorData = blockData.readByte();
        for (var j = 0; j < 4; j++) {
          final color = colors[(colorData >> j * 2) & 0x3];
          pixelsBuffer[i * 4 + j]
            ..r = color.r
            ..g = color.g
            ..b = color.b;
          if (info!.pixelFormatFourCC == DDSFourCCFormat.DXT1) {
            pixelsBuffer[i * 4 + j].a = 255;
          }
        }
      }
    }

    return image;
  }

  Image? _decodeRgb() {
    final int pixelBytesCount = info!.pixelFormatRGBBitCount ~/ 8;
    final width = info!.width;
    final height = info!.height;
    final image =
        Image(width: width, height: height, numChannels: pixelBytesCount);

    final size = width * height;
    final data = input.readBytes(size);

    for (final pixel in image) {
      final pixelData = data.readBytes(pixelBytesCount).readUint32();
      pixel
        ..r = pixelData & info!.pixelFormatRBitMask
        ..g = pixelData & info!.pixelFormatGBitMask
        ..b = pixelData & info!.pixelFormatBBitMask;
      if (pixelBytesCount == 4) {
        pixel.a = pixelData & info!.pixelFormatABitMask;
      }
    }

    return image;
  }
}
