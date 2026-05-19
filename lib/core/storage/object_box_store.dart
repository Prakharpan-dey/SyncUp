import 'package:path_provider/path_provider.dart';
import '../../objectbox.g.dart';

class ObjectBoxStore {
  late final Store store;
  ObjectBoxStore._create(this.store);

  static Future<ObjectBoxStore> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: '${dir.path}/syncup-db');
    return ObjectBoxStore._create(store);
  }

  Box<T> box<T>() => store.box<T>();
  void close() => store.close();
}
