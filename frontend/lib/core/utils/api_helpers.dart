/// Parsea una respuesta paginada o lista plana de la API.
/// Soporta tanto respuestas DRF con `{results: [...]}` como listas directas.
List<dynamic> parsePaginatedResponse(dynamic responseData) {
  if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
    return responseData['results'] as List<dynamic>;
  }
  return responseData as List<dynamic>;
}

/// Resultado de una respuesta paginada con metadata.
class PaginatedResult {
  final List<dynamic> results;
  final int? count;
  final String? next;
  final String? previous;

  PaginatedResult({
    required this.results,
    this.count,
    this.next,
    this.previous,
  });

  bool get hasNext => next != null;
}

/// Parsea una respuesta paginada conservando metadata de paginación.
PaginatedResult parsePaginatedResponseFull(dynamic responseData) {
  if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
    return PaginatedResult(
      results: responseData['results'] as List<dynamic>,
      count: responseData['count'] as int?,
      next: responseData['next'] as String?,
      previous: responseData['previous'] as String?,
    );
  }
  // Plain list — no pagination metadata
  return PaginatedResult(results: responseData as List<dynamic>);
}
