class CalculateSafeToSkip {
  int call({required int attended, required int total, required double threshold}) {
    if (total == 0) return 0;
    if (threshold <= 0) return 999;
    final y = ((attended - threshold * total) / threshold).floor();
    return y < 0 ? 0 : y;
  }
}