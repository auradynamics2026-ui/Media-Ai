/// Replaceable AI layer. Swap [DemoFaceMatcher] for a real implementation
/// (e.g. a self-hosted open-source face-recognition endpoint).
abstract class FaceMatcher {
  Future<List<String>> matchPhotos(String referenceImagePath, List<String> photoIds);
}

class DemoFaceMatcher implements FaceMatcher {
  @override
  Future<List<String>> matchPhotos(String referenceImagePath, List<String> photoIds) async {
    await Future.delayed(const Duration(seconds: 1));
    return [for (var i = 0; i < photoIds.length; i += 3) photoIds[i]];
  }
}
