// Regenerates the favicon + PWA icons from the master source
// (design/barakali_logo_source.png): mattes the cream background out, crops the
// crescent mark, and writes the transparent favicon/icons (+ maskable on cream).
// The in-app logo is a vector (assets/images/barakali_logo.svg, see
// tool/trace_logo.py). Re-run with: dart run tool/process_logo.dart
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

// Source background (sampled corner): cream #FAF5E2.
const _bgR = 250.0, _bgG = 245.0, _bgB = 226.0;
// Feather threshold: pixels this far (max-channel) from the bg are fully opaque;
// closer ones are feathered + decontaminated. The artwork (green/gold) is well
// beyond this, so only the cream and its anti-aliased edges are affected.
const _t = 80.0;

/// Replaces the cream background with a proper alpha matte: feathered edges +
/// colour decontamination (un-mix the cream out of edge pixels) so there's no
/// light halo on any surface. Mutates [image].
void matte(img.Image image) {
  for (final p in image) {
    final diff = [
      (p.r - _bgR).abs(),
      (p.g - _bgG).abs(),
      (p.b - _bgB).abs(),
    ].reduce(max);
    final a = (diff / _t).clamp(0.0, 1.0);
    if (a <= 0.004) {
      p.setRgba(0, 0, 0, 0);
    } else if (a >= 0.996) {
      p.setRgba(p.r, p.g, p.b, 255);
    } else {
      // F = (P - (1-a)*B) / a
      double f(num c, double b) => (((c - (1 - a) * b) / a)).clamp(0.0, 255.0);
      p.setRgba(f(p.r, _bgR), f(p.g, _bgG), f(p.b, _bgB), (a * 255).round());
    }
  }
}

bool _opaque(img.Image im, int x, int y) => im.getPixel(x, y).a > 40;

void main() {
  final src = img.decodeImage(
    File('design/barakali_logo_source.png').readAsBytesSync(),
  )!;
  matte(src);

  // Find the gap between the crescent (top) and the wordmark (bottom): the row
  // with the fewest opaque pixels in the middle band.
  int rowCount(int y) {
    var n = 0;
    for (var x = 0; x < src.width; x++) {
      if (_opaque(src, x, y)) n++;
    }
    return n;
  }

  var splitY = (src.height * 0.62).round();
  var minCount = 1 << 30;
  for (
    var y = (src.height * 0.42).round();
    y < (src.height * 0.78).round();
    y++
  ) {
    final c = rowCount(y);
    if (c < minCount) {
      minCount = c;
      splitY = y;
    }
  }

  // Bounding box of the crescent (opaque pixels above the gap).
  var minX = src.width, minY = src.height, maxX = 0, maxY = 0;
  for (var y = 0; y < splitY; y++) {
    for (var x = 0; x < src.width; x++) {
      if (_opaque(src, x, y)) {
        minX = min(minX, x);
        minY = min(minY, y);
        maxX = max(maxX, x);
        maxY = max(maxY, y);
      }
    }
  }
  stdout.writeln('split=$splitY crescent bbox=($minX,$minY)-($maxX,$maxY)');

  // Square crop centred on the crescent with ~12% padding (clamped to bounds).
  final side = ((max(maxX - minX, maxY - minY)) * 1.12).round();
  final cx = (minX + maxX) ~/ 2, cy = (minY + maxY) ~/ 2;
  final x0 = (cx - side ~/ 2).clamp(0, src.width - 1);
  final y0 = (cy - side ~/ 2).clamp(0, src.height - 1);
  final mark = img.copyCrop(
    src,
    x: x0,
    y: y0,
    width: min(side, src.width - x0),
    height: min(side, src.height - y0),
  );

  // Transparent icons (favicon + PWA regular).
  void writePng(img.Image im, String path) =>
      File(path).writeAsBytesSync(img.encodePng(im));
  writePng(img.copyResize(mark, width: 256), 'web/favicon.png');
  writePng(img.copyResize(mark, width: 192), 'web/icons/Icon-192.png');
  writePng(img.copyResize(mark, width: 512), 'web/icons/Icon-512.png');

  // Maskable icons: crescent at ~62% inside a cream square (safe zone).
  img.Image maskable(int size) {
    final canvas = img.Image(width: size, height: size, numChannels: 4);
    img.fill(canvas, color: img.ColorRgb8(250, 245, 226));
    final inner = (size * 0.62).round();
    final scaled = img.copyResize(mark, width: inner, height: inner);
    img.compositeImage(
      canvas,
      scaled,
      dstX: (size - inner) ~/ 2,
      dstY: (size - inner) ~/ 2,
    );
    return canvas;
  }

  writePng(maskable(192), 'web/icons/Icon-maskable-192.png');
  writePng(maskable(512), 'web/icons/Icon-maskable-512.png');
  stdout.writeln('mark ${side}x$side → favicon + PWA icons written');
}
