class FeatureFlags {
  final Map<String, dynamic> raw;
  const FeatureFlags(this.raw);

  T flag<T>(String key, T fallback) {
    final v = raw[key];
    if (v is T) return v;
    return fallback;
  }
}
