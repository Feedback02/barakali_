import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Longest-edge cap (px) for stored offer photos.
const int kOfferImageMaxEdge = 1280;

/// Size ceiling for the encoded JPEG (~1 MB).
const int kOfferImageMaxBytes = 1024 * 1024;

/// Normalizes a picked photo for upload: bakes EXIF orientation (so rotation
/// survives), then re-encodes as JPEG which drops all metadata — including GPS
/// (mandatory EXIF strip, per Security Rules) — downscales to
/// [kOfferImageMaxEdge], and steps quality down until under [kOfferImageMaxBytes].
///
/// Pure + synchronous so it is unit-testable and cross-platform (no native
/// plugin); callers should run it off the UI thread for large inputs.
/// Returns null if [input] is not a decodable image.
Uint8List? processOfferImage(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) return null;

  var image = img.bakeOrientation(decoded);

  final longestEdge = image.width > image.height ? image.width : image.height;
  if (longestEdge > kOfferImageMaxEdge) {
    image = image.width >= image.height
        ? img.copyResize(image, width: kOfferImageMaxEdge)
        : img.copyResize(image, height: kOfferImageMaxEdge);
  }

  var out = img.encodeJpg(image, quality: 82);
  for (final quality in const [70, 55, 40]) {
    if (out.length <= kOfferImageMaxBytes) break;
    out = img.encodeJpg(image, quality: quality);
  }
  return out;
}
