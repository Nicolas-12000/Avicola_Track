/// Parsea una respuesta paginada o lista plana de la API.
/// Soporta tanto respuestas DRF con `{results: [...]}` como listas directas.
List<dynamic> parsePaginatedResponse(dynamic responseData) {
  if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
    return responseData['results'] as List<dynamic>;
  }
  return responseData as List<dynamic>;
}
