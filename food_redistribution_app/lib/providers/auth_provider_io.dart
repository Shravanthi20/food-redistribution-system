import 'dart:io';

/// Create a File from a path (only available on non-web platforms)
File platformFile(String path) => File(path);
