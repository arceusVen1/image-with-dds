import 'dart:typed_data';

import 'channel_iterator.dart';
import 'color.dart';
import 'color_util.dart';
import 'format.dart';

class ColorFloat32 extends Iterable<num> implements Color {
  final Float32List data;

  ColorFloat32(int numChannels)
      : data = Float32List(numChannels);

  ColorFloat32.from(ColorFloat32 other)
      : data = Float32List.fromList(other.data);

  ColorFloat32.fromList(List<double> color)
      : data = Float32List.fromList(color);

  ColorFloat32.rgb(num r, num g, num b)
      : data = Float32List(3) {
    data[0] = r.toDouble();
    data[1] = g.toDouble();
    data[2] = b.toDouble();
  }

  ColorFloat32.rgba(num r, num g, num b, num a)
      : data = Float32List(4) {
    data[0] = r.toDouble();
    data[1] = g.toDouble();
    data[2] = b.toDouble();
    data[3] = a.toDouble();
  }

  ColorFloat32 clone() => ColorFloat32.from(this);

  Format get format => Format.float32;
  int get length => data.length;
  num get maxChannelValue => 1.0;
  bool get isLdrFormat => false;
  bool get isHdrFormat => true;

  num operator[](int index) => index < data.length ? data[index] : 0;
  void operator[]=(int index, num value) {
    if (index < data.length) {
      data[index] = value.toDouble();
    }
  }

  num get index => r;
  void set index(num i) => r = i;

  num get r => data.isNotEmpty ? data[0] : 0;
  void set r(num r) => data.isNotEmpty ? data[0] = r.toDouble() : 0;

  num get g => data.length > 1 ? data[1] : 0;
  void set g(num g) {
    if (data.length > 1) {
      data[1] = g.toDouble();
    }
  }

  num get b => data.length > 2 ? data[2] : 0;
  void set b(num b) {
    if (data.length > 2) {
      data[2] = b.toDouble();
    }
  }

  num get a => data.length > 3 ? data[3] : 1;
  void set a(num a) {
    if (data.length > 3) {
      data[3] = a.toDouble();
    }
  }

  num get rNormalized => r / maxChannelValue;
  void set rNormalized(num v) => r = v * maxChannelValue;

  num get gNormalized => g / maxChannelValue;
  void set gNormalized(num v) => g = v * maxChannelValue;

  num get bNormalized => b / maxChannelValue;
  void set bNormalized(num v) => b = v * maxChannelValue;

  num get aNormalized => a / maxChannelValue;
  void set aNormalized(num v) => a = v * maxChannelValue;

  void set(Color c) {
    r = c.r;
    g = c.g;
    b = c.b;
    a = c.a;
  }

  void setColor(num r, [num g = 0, num b = 0, num a = 0]) {
    data[0] = r.toDouble();
    final nc = data.length;
    if (nc > 1) {
      data[1] = g.toDouble();
      if (nc > 2) {
        data[2] = b.toDouble();
        if (nc > 3) {
          data[3] = a.toDouble();
        }
      }
    }
  }

  ChannelIterator get iterator => ChannelIterator(this);

  bool operator==(Object? other) =>
      other is Color &&
          other.length == length &&
          other.hashCode == hashCode;

  int get hashCode => Object.hashAll(toList());

  Color convert({ Format? format, int? numChannels, num? alpha }) =>
      convertColor(this, format: format, numChannels: numChannels,
          alpha: alpha);
}
