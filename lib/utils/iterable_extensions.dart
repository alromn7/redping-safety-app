/// Compatibility Iterable extension for environments without Dart's built-in firstOrNull
extension IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
