import 'dart:typed_data';

import '../../image.dart';

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

    if (info!.pixelFormat.isCompressed) {
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
      numChannels: 4,
    );
    final size = width * height;
    final compressionAlgorithm =
        info!.pixelFormat.compressionAlgorithm;
    final bytesPer4x4Block =
        compressionAlgorithm.getBytesPer4x4Block;
    final data = input.readBytes(
      size ~/ _pixelsPerBlock * bytesPer4x4Block,
    );

    final List<Pixel> pixelsBuffer =
        List.filled(_pixelsPerBlock, Pixel.undefined);
    int row = 0;
    int col = 0;
    for (var block = 0; block < size / _pixelsPerBlock; block++) {
      for (var p = 0; p < _pixelsPerBlock; p++) {
        final x = col + p % 4;
        final y = row + p ~/ 4;
        final pixel = image.getPixel(x, y);
        pixelsBuffer[p] = pixel;
      }
      col = (col + 4) % width;
      row += col == 0 ? 4 : 0;
      final blockData = data.readBytes(bytesPer4x4Block);

      if (compressionAlgorithm == CompressionAlgorithm.BC3) {
        // use BC3 alpha block
        final alpha0 = blockData.readByte();
        final alpha1 = blockData.readByte();
        final alphas = info!.pixelFormat.generateAlphasFromInitialAlphas(
          alpha0,
          alpha1,
        );
        for (var i = 0; i < 2; i++) {
          final alphaData = blockData.readBytes(3).readUint24();
          for (var j = 0; j < 8; j++) {
            final alpha = alphas[(alphaData >> j * 3) & 0x7];
            pixelsBuffer[i * 8 + j].a = alpha;
          }
        }
      } else if (compressionAlgorithm ==
          CompressionAlgorithm.BC2) {
        // use BC2 alpha block
        for (var i = 0; i < 4; i++) {
          final alphaData = blockData.readUint16();
          for (var j = 0; j < 4; j++) {
            final alpha = ((alphaData >> j * 4) & 0xF) / 0xF;
            pixelsBuffer[i * 4 + j].aNormalized = alpha;
          }
        }
      }

      final color0Data = blockData.readUint16();
      final color1Data = blockData.readUint16();

      final colors = info!.pixelFormat.generateColorsFromInitialColors(
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
          if (compressionAlgorithm == CompressionAlgorithm.BC1) {
            if (color.r + color.g + color.b == 0) {
              pixelsBuffer[i * 4 + j].a = 0;
            } else {
              pixelsBuffer[i * 4 + j].a = 255;
            }
          }
        }
      }
    }

    return image;
  }

  Image? _decodeRgb() {
    final int pixelBytesCount = info!.pixelFormat.rgbBitCount ~/ 8;
    final width = info!.width;
    final height = info!.height;
    final image = Image(
      width: width,
      height: height,
      numChannels: 4,
    );

    final size = width * height;
    final data = input.readBytes(size);

    for (final pixel in image) {
      final pixelData = data.readBytes(pixelBytesCount).readUint32();
      pixel
        ..r = pixelData & info!.pixelFormat.rBitMask
        ..g = pixelData & info!.pixelFormat.gBitMask
        ..b = pixelData & info!.pixelFormat.bBitMask;
      if (pixelBytesCount == 4) {
        pixel.a = pixelData & info!.pixelFormat.aBitMask;
      } else {
        pixel.a = 255;
      }
    }

    return image;
  }
}
