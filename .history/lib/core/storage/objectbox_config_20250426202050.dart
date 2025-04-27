import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todoApp/core/globals.dart';
import 'package:path/path.dart' as p;

/// Global ObjectBox store instance for the application
/// This is initialized once at app startup and used throughout the app
class ObjectBox {
  /// The ObjectBox Store, the entry point to the ObjectBox API
  late final Store store;

  /// Private constructor to prevent multiple instances
  ObjectBox._create(this.store) {
    talker.info('ObjectBox store created successfully');
  }

  /// Create an instance of ObjectBox
  /// This is called once at app startup
  static Future<ObjectBox> create() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbDirectory = p.join(docsDir.path, "objectbox");

      // Create the store
      talker.info('Creating ObjectBox store at: $dbDirectory');
      final store = await openStore(directory: dbDirectory);

      return ObjectBox._create(store);
    } catch (e) {
      talker.error('Error creating ObjectBox store: $e');
      rethrow;
    }
  }
}

/// Global ObjectBox instance
/// This is initialized once at app startup and used throughout the app
late ObjectBox objectbox;

/// Initialize ObjectBox
/// This should be called once at app startup
Future<void> initObjectBox() async {
  try {
    objectbox = await ObjectBox.create();
    talker.info('ObjectBox initialized successfully');
  } catch (e) {
    talker.error('Failed to initialize ObjectBox: $e');
    // Re-throw to allow the app to handle the error
    rethrow;
  }
}
