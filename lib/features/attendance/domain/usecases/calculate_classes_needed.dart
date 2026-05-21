class CalculateClassesNeeded {
  /// Returns classes needed, or -1 if θ=100% and absences exist (impossible)
  int call({required int attended, required int total, required double threshold}) {
    if (total == 0) return 0;
    if (attended / total >= threshold) return 0;
    if (threshold >= 1.0) return attended < total ? -1 : 0;
    final x = ((threshold * total - attended) / (1 - threshold)).ceil();
    return x < 0 ? 0 : x;
  }
}