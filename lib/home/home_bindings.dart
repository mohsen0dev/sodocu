import 'package:get/get.dart';
import 'package:sodocu/home/home_controller.dart';
// import './home_controller.dart';

class HomeBindings implements Bindings {
  @override
  void dependencies() {
    // Get.put(HomeController());
    Get.put(HomeController());
  }
}
