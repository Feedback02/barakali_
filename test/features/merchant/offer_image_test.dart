import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:barakali/features/merchant/presentation/utils/offer_image.dart';

void main() {
  group('processOfferImage', () {
    test('re-encodes a large image to a bounded, downscaled JPEG', () {
      final src = img.Image(width: 2000, height: 1500);
      img.fill(src, color: img.ColorRgb8(120, 180, 90));
      final png = img.encodePng(src);

      final out = processOfferImage(png);

      expect(out, isNotNull);
      // JPEG magic bytes.
      expect(out!.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
      expect(out.length, lessThanOrEqualTo(kOfferImageMaxBytes));

      final decoded = img.decodeJpg(out)!;
      expect(decoded.width, kOfferImageMaxEdge); // 2000 -> 1280
      expect(decoded.height, lessThanOrEqualTo(kOfferImageMaxEdge));
    });

    test('leaves a small image within the max edge', () {
      final src = img.Image(width: 400, height: 300);
      img.fill(src, color: img.ColorRgb8(10, 20, 30));
      final out = processOfferImage(img.encodePng(src));

      expect(out, isNotNull);
      final decoded = img.decodeJpg(out!)!;
      expect(decoded.width, 400);
      expect(decoded.height, 300);
    });

    test('returns null for non-image bytes', () {
      final garbage = Uint8List.fromList(List.filled(64, 7));
      expect(processOfferImage(garbage), isNull);
    });
  });
}
