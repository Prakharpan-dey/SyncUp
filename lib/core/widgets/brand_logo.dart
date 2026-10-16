import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The SyncUp symbol: the cobalt-and-lime S with its sparks.
///
/// Vector, so it stays sharp at any size. The artwork and its source live in
/// the brand kit (syncup-brand/final); this is the light symbol from it.
class SyncUpSymbol extends StatelessWidget {
  final double height;

  const SyncUpSymbol({super.key, this.height = 72});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/syncup_symbol.svg',
      height: height,
      semanticsLabel: 'SyncUp',
    );
  }
}

/// The brand's own grounds. The native splash is painted in these, so the
/// in-app splash uses them too: otherwise the background would change colour
/// the moment Flutter draws its first frame.
abstract final class BrandColors {
  static const paper = Color(0xFFF7F6F0);
  static const ink = Color(0xFF171717);
}
