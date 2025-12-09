import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/services/storage_service_factory.dart';
import '../data/services/storage_interface.dart';
import '../data/services/ai_service.dart';
import '../presentation/providers/chat_provider.dart';
import '../presentation/providers/notes_provider.dart';
import '../presentation/pages/home_page.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final IStorageService _storageService = StorageServiceFactory.getInstance();
  final AiService _aiService = AiService();
  bool _isInitialized = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // 初始化存储服务
      await _storageService.initialize();

      // 检查是否有保存的API密钥（这里可以扩展为从安全存储读取）
      // 暂时留空，需要用户手动配置

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _initializationError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ze Memo',
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Center(
            child: _initializationError != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '初始化失败',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _initializationError!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _initializeServices,
                        child: const Text('重试'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '正在初始化...',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            aiService: _aiService,
            storageService: _storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotesProvider(
            storageService: _storageService,
          )..initialize(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ze Memo - 智能笔记',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // 暂时使用浅色主题
        home: const HomePage(),
      ),
    );
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}