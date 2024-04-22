import '../../../image.dart';

class DdsInfo extends DecodeInfo {
  @override
  int get numFrames => 1;

  @override
  Color? get backgroundColor => null;

  // dwSize is ignored, must match 124
  List<DdsHeaderFlags> flags = [];
  @override
  int width = 0;
  @override
  int height = 0;

  int pitchOrLinearSize = 0;
  int depth = 0;
  int mipmapCount = 0;
  // dwReserved*11 is ignored

  // ----------------- pixelFormat strcture ------------------------------------
  int pixelFormatSize = 0;
  DdsPixelFormatFlags pixelFormatFlags = DdsPixelFormatFlags.ddpfRGB;
  DDSFourCCFormat pixelFormatFourCC = DDSFourCCFormat.DXT1;
  int pixelFormatRGBBitCount = 0;
  int pixelFormatRBitMask = 0;
  int pixelFormatGBitMask = 0;
  int pixelFormatBBitMask = 0;
  int pixelFormatABitMask = 0;
  // ---------------------------------------------------------------------------

  int caps1 = 0;
  int caps2 = 0;
  int caps3 = 0;
  int caps4 = 0;
  // dwReserved2 is ignored

  // int pixelFormatRBitCount = 0;
  // int pixelFormatGBitCount = 0;
  // int pixelFormatBBitCount = 0;
  // int pixelFormatABitCount = 0;
  // int pixelFormatRBitShift = 0;
  // int pixelFormatGBitShift = 0;
  // int pixelFormatBBitShift = 0;
  // int pixelFormatABitShift = 0;

  void read(InputBuffer header) {
    if (header.length < 128) {
      return;
    }

    final magic = header.readUint32();
    if (magic != 0x20534444) {
      return;
    }

    header.skip(4); // size
    final flagsValue = header.readUint32();
    flags = DDSHeaderFlagsExtension.listOfFlagsFromInt(flagsValue);
    height = header.readUint32();
    width = header.readUint32();
    pitchOrLinearSize = header.readUint32();
    depth = header.readUint32();
    mipmapCount = header.readUint32();
    header.skip(44); // reserved

    pixelFormatSize = header.readUint32();
    final pixelFormatFlagsValue = header.readUint32();
    pixelFormatFlags = DDSdwFlagsExtension.fromInt(pixelFormatFlagsValue);

    pixelFormatFourCC = DDSFourCCFormatExtension.fromInt(header.readUint32());
    pixelFormatRGBBitCount = header.readUint32();
    pixelFormatRBitMask = header.readUint32();
    pixelFormatGBitMask = header.readUint32();
    pixelFormatBBitMask = header.readUint32();
    pixelFormatABitMask = header.readUint32();

    caps1 = header.readUint32();
    caps2 = header.readUint32();
    caps3 = header.readUint32();
    caps4 = header.readUint32();
  }

  bool isValid() {
    if (width <= 0 || height <= 0) {
      return false;
    }

    if (depth != 0 && depth != 1 && depth != 2 && depth != 3 && depth != 4) {
      return false;
    }

    // if (mipmapCount < 1) {
    //   return false;
    // }

    if (pixelFormatFlags != DdsPixelFormatFlags.ddpfFourCC) {
      if (pixelFormatRGBBitCount <= 0) {
        return false;
      }

      if (pixelFormatRBitMask <= 0) {
        return false;
      }

      if (pixelFormatGBitMask <= 0) {
        return false;
      }

      if (pixelFormatBBitMask <= 0) {
        return false;
      }

      if (pixelFormatABitMask <= 0) {
        return false;
      }
    }

    if (caps1 < 0x1000) {
      return false;
    }

    return true;
  }
}

enum DdsHeaderFlags {
  ddsCaps,
  ddsHeight,
  ddsWidth,
  ddsPitch,
  ddsPixelFormat,
  ddsMipMapCount,
  ddsLinearSize,
  ddsDepth,
}

extension DDSHeaderFlagsExtension on DdsHeaderFlags {
  static List<DdsHeaderFlags> listOfFlagsFromInt(int value) {
    final List<DdsHeaderFlags> flags = [];
    if (value & 7 != 0) {
      flags.addAll([
        DdsHeaderFlags.ddsCaps,
        DdsHeaderFlags.ddsHeight,
        DdsHeaderFlags.ddsWidth,
      ]);
    } else {
      throw ImageException(
        'Invalid DDSHeaderFlags value, should contain required flags: $value',
      );
    }

    if (value & 0x00000008 != 0) {
      flags.add(DdsHeaderFlags.ddsPitch);
    }

    if (value & 0x00001000 != 0) {
      flags.add(DdsHeaderFlags.ddsPixelFormat);
    }

    if (value & 0x00020000 != 0) {
      flags.add(DdsHeaderFlags.ddsMipMapCount);
    }

    if (value & 0x00080000 != 0) {
      flags.add(DdsHeaderFlags.ddsLinearSize);
    }

    if (value & 0x00800000 != 0) {
      flags.add(DdsHeaderFlags.ddsDepth);
    }
    return flags;
  }
}

enum DdsPixelFormatFlags {
  ddpfAlpgaPixels,
  ddpfAlpha,
  ddpfFourCC,
  ddpfRGB,
  ddpfYUV,
  ddpfLuminance,
}

extension DDSdwFlagsExtension on DdsPixelFormatFlags {
  static DdsPixelFormatFlags fromInt(int value) {
    switch (value) {
      case 0x00000001:
        return DdsPixelFormatFlags.ddpfAlpgaPixels;
      case 0x00000002:
        return DdsPixelFormatFlags.ddpfAlpha;
      case 0x00000004:
        return DdsPixelFormatFlags.ddpfFourCC;
      case 0x00000040:
        return DdsPixelFormatFlags.ddpfRGB;
      case 0x00000200:
        return DdsPixelFormatFlags.ddpfYUV;
      case 0x00020000:
        return DdsPixelFormatFlags.ddpfLuminance;
      default:
        throw ImageException('Invalid DDSdwFlags value: $value');
    }
  }
}

enum DDSFourCCFormat {
  DXT1,
  DXT2,
  DXT3,
  DXT4,
  DXT5,
  DX10, // unhandled case
}

extension DDSFourCCFormatExtension on DDSFourCCFormat {
  static DDSFourCCFormat fromInt(int value) {
    switch (value) {
      case 0x31545844:
        return DDSFourCCFormat.DXT1;
      case 0x32545844:
        return DDSFourCCFormat.DXT2;
      case 0x33545844:
        return DDSFourCCFormat.DXT3;
      case 0x34545844:
        return DDSFourCCFormat.DXT4;
      case 0x35545844:
        return DDSFourCCFormat.DXT5;
      default:
        throw ImageException('Invalid DDSFourCCFormat value: $value');
    }
  }

  int get channelsCount {
    switch (this) {
      case DDSFourCCFormat.DXT1:
        return 3;
      case DDSFourCCFormat.DXT2: // ignored
        return 4;
      case DDSFourCCFormat.DXT3: // ignored
        return 4;
      case DDSFourCCFormat.DXT4:
        return 4;
      case DDSFourCCFormat.DXT5:
        return 4;
      default:
        throw ImageException('Invalid DDSFourCCFormat value: $this');
    }
  }

  ({int r, int g, int b, int a}) get masks {
    switch (this) {
      case DDSFourCCFormat.DXT1:
        return (r: 0xF800, g: 0x7E0, b: 0x001F, a: 0);
      case DDSFourCCFormat.DXT2:
        return (r: 0xF800, g: 0x7E0, b: 0x001F, a: 0x0F);
      case DDSFourCCFormat.DXT3:
        return (r: 0xF800, g: 0x7E0, b: 0x001F, a: 0x0F);
      case DDSFourCCFormat.DXT4:
        return (r: 0xF800, g: 0x7E0, b: 0x001F, a: 0xFF);
      case DDSFourCCFormat.DXT5:
        return (r: 0xF800, g: 0x7E0, b: 0x001F, a: 0xFF);
      default:
        throw ImageException('Invalid DDSFourCCFormat value: $this');
    }
  }

  List<({int r, int g, int b})> generateColorsFromInitialColors(
      int color0Data, int color1Data) {
    final colors = [
      (
        r: ((color0Data & masks.r) / masks.r  * 255).ceil(),
        g: ((color0Data & masks.g) / masks.g * 255).ceil(),
        b: ((color0Data & masks.b) / masks.b * 255).ceil(),
      ),
      (
        r: ((color1Data & masks.r) / masks.r * 255).ceil() ,
        g: ((color1Data & masks.g) / masks.g * 255).ceil(),
        b: ((color1Data & masks.b) / masks.b * 255).ceil(),
      ),
    ];
    // colors.addAll([
    //   (
    //     r: (1 / 2 * colors[0].r + 1 / 2 * colors[1].r).ceil(),
    //     g: (1 / 2 * colors[0].g + 1 / 2 * colors[1].g).ceil(),
    //     b: (1 / 2 * colors[0].b + 1 / 2 * colors[1].b).ceil(),
    //   ),
    //   (
    //     r: 0,
    //     g: 0,
    //     b: 0,
    //   )
    // ]);
    colors.addAll([
      (
        r: (2 / 3 * colors[0].r + 1 / 3 * colors[1].r).ceil(),
        g: (2 / 3 * colors[0].g + 1 / 3 * colors[1].g).ceil(),
        b: (2 / 3 * colors[0].b + 1 / 3 * colors[1].b).ceil(),
      ),
      (
        r: (1 / 3 * colors[0].r + 2 / 3 * colors[1].r).ceil(),
        g: (1 / 3 * colors[0].g + 2 / 3 * colors[1].g).ceil(),
        b: (1 / 3 * colors[0].b + 2 / 3 * colors[1].b).ceil(),
      )
    ]);
    return colors;
  }

  List<int> generateAlphasFromInitialAlphas(int alpha0, int alpha1) {
    final alphas = [
      alpha0,
      alpha1,
    ];
    if (alpha0 > alpha1) {
      alphas.addAll([
        (6 / 7 * alpha0 + 1 / 7 * alpha1).ceil(),
        (5 / 7 * alpha0 + 2 / 7 * alpha1).ceil(),
        (4 / 7 * alpha0 + 3 / 7 * alpha1).ceil(),
        (3 / 7 * alpha0 + 4 / 7 * alpha1).ceil(),
        (2 / 7 * alpha0 + 5 / 7 * alpha1).ceil(),
        (1 / 7 * alpha0 + 6 / 7 * alpha1).ceil(),
      ]);
    } else {
      alphas.addAll([
        (4 / 5 * alpha0 + 1 / 5 * alpha1).ceil(),
        (3 / 5 * alpha0 + 2 / 5 * alpha1).ceil(),
        (2 / 5 * alpha0 + 3 / 5 * alpha1).ceil(),
        (1 / 5 * alpha0 + 4 / 5 * alpha1).ceil(),
        0,
        255,
      ]);
    }
    return alphas;
  }

  int get getBytesPer4x4Block {
    switch (this) {
      case DDSFourCCFormat.DXT1:
        return 8;
      case DDSFourCCFormat.DXT2:
        return 16;
      case DDSFourCCFormat.DXT3:
        return 16;
      case DDSFourCCFormat.DXT4:
        return 16;
      case DDSFourCCFormat.DXT5:
        return 16;
      default:
        throw ImageException('Invalid DDSFourCCFormat value: $this');
    }
  }
}
