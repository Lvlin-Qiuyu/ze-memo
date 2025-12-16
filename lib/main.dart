import 'package:flutter/material.dart';
import 'core/config/environment_manager.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化环境变量管理器
  await EnvironmentManager.instance.initialize();
  
  runApp(const App());
}
