import 'package:flutter/foundation.dart';

final inventoryChangeNotifier = ValueNotifier<int>(0);

void notifyInventoryChanged() {
  inventoryChangeNotifier.value++;
}
