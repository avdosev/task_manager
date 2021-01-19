extension IteratorHelper<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension BoolHelper on bool {
  int toInt() => this ? 1 : 0;
}
