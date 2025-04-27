// This file is kept as a placeholder for future core providers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/storage/storage_service.dart';

/// Core providers that are used across the app
/// These providers should be kept minimal and only include
/// services that are truly app-wide

// This provider is now defined in storage_service.dart
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
