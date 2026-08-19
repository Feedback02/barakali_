import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:barakali/features/consumer/presentation/widgets/price_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'buildPriceMarker renders a non-empty PNG bitmap at the given ratio',
    () async {
      final descriptor = await buildPriceMarker(
        label: '16 000',
        icon: Icons.bakery_dining_rounded,
        background: const Color(0xFF2D7D46),
        foreground: Colors.white,
        scale: 3,
      );

      expect(descriptor, isA<BytesMapBitmap>());
      final bytes = (descriptor as BytesMapBitmap).byteData;
      // A PNG starts with the 8-byte signature; a non-trivial pin is well over it.
      expect(bytes.length, greaterThan(100));
      expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]); // \x89PNG
      expect(descriptor.imagePixelRatio, 3);
    },
  );

  test(
    'buildPriceMarker scales the bitmap with the device pixel ratio',
    () async {
      final at1 = await buildPriceMarker(
        label: '16 000',
        icon: Icons.bakery_dining_rounded,
        background: const Color(0xFF2D7D46),
        foreground: Colors.white,
        scale: 1,
      );
      final at3 = await buildPriceMarker(
        label: '16 000',
        icon: Icons.bakery_dining_rounded,
        background: const Color(0xFF2D7D46),
        foreground: Colors.white,
        scale: 3,
      );

      // A higher pixel ratio renders more pixels, so a larger PNG payload.
      expect(
        (at3 as BytesMapBitmap).byteData.length,
        greaterThan((at1 as BytesMapBitmap).byteData.length),
      );
    },
  );
}
