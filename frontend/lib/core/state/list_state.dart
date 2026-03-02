/// Generic list state for collections with loading/error/pagination tracking.
/// Eliminates duplicated state classes across features.
class ListState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMoreData;

  static const int defaultPageSize = 20;

  const ListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMoreData = true,
  });

  ListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMoreData,
  }) {
    return ListState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }

  /// Convenience: set loading state
  ListState<T> loading() => copyWith(
    isLoading: true,
    error: null,
    currentPage: 1,
    hasMoreData: true,
  );

  /// Convenience: set loaded state with items (first page)
  ListState<T> loaded(List<T> items) => copyWith(
    isLoading: false,
    items: items,
    currentPage: 1,
    hasMoreData: items.length >= defaultPageSize,
  );

  /// Convenience: set error state
  ListState<T> failed(String message) => copyWith(isLoading: false, isLoadingMore: false, error: message);

  /// Convenience: add a single item to the list
  ListState<T> addItem(T item) => copyWith(items: [...items, item]);

  /// Convenience: update an item in the list by predicate
  ListState<T> updateItem(bool Function(T) test, T newItem) {
    return copyWith(items: items.map((e) => test(e) ? newItem : e).toList());
  }

  /// Convenience: append more items from next page
  ListState<T> appendPage(List<T> newItems, int page) => copyWith(
    items: [...items, ...newItems],
    isLoadingMore: false,
    currentPage: page,
    hasMoreData: newItems.length >= defaultPageSize,
  );
}
