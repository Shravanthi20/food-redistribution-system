/// Stub for web platform - File operations not supported
/// This should never be called on web (kIsWeb guard in auth_provider.dart)
dynamic platformFile(String path) {
  throw UnsupportedError('File operations not supported on web');
}
