import 'package:flutter/material.dart';
import 'package:muteng_app_ios/root_shell.dart';
import 'package:muteng_app_ios/storage/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 先初始化本地存储
  await LocalStorage.init();
  runApp(const MutengApp());
}

class MutengApp extends StatelessWidget {
  const MutengApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '木藤影视',
      debugShowCheckedModeBanner: false,
      // 启动时先展示 RootShell（首页 TabBar），登录页暂不强制拦截
      // 如需启用登录引导，可改为：home: const LoginPage()
      home: const RootShell(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F4FA),
      ),
    );
  }
}
