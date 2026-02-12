/// Generic list state for collections with loading/error tracking.
/// Eliminates duplicated state classes across features.
class ListState<T> {
  final List<T> items;
  final bool isLoading;
  final String? error;

  const ListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  ListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    String? error,
  }) {
    return ListState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Convenience: set loading state
  ListState<T> loading() => copyWith(isLoading: true, error: null);

  /// Convenience: set loaded state with items
  ListState<T> loaded(List<T> items) => copyWith(isLoading: false, items: items);

  /// Convenience: set error state
  ListState<T> failed(String message) => copyWith(isLoading: false, error: message);

  /// Convenience: add a single item to the list
  ListState<T> addItem(T item) => copyWith(items: [...items, item]);

  /// Convenience: update an item in the list by predicate
  ListState<T> updateItem(bool Function(T) test, T newItem) {
    return copyWith(items: items.map((e) => test(e) ? newItem : e).toList());
  }
}
