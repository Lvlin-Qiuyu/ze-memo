import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/app_update_provider.dart';
import '../../core/utils/app_update_helper.dart';
import '../../core/config/update_config.dart';
import 'chat_page.dart';
import 'notes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ChatPage(),
      const NotesPage(),
    ];
  }

    // 延迟执行更新检查，确保UI已经渲染完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  /// 检查应用更新
  void _checkForUpdates() async {
    debugPrint('开始检查更新... Gitee: ${UpdateConfig.giteeOwner}/${UpdateConfig.giteeRepo}');

    try {
      await AppUpdateHelper.checkAndShowUpdate(
        context,
        owner: UpdateConfig.giteeOwner,
        repo: UpdateConfig.giteeRepo,
        showNoUpdateDialog: false, // 无更新时不显示提示
      );
      debugPrint('更新检查完成');
    } catch (e) {
      // 静默处理错误，不影响用户体验
      debugPrint('检查更新失败: $e');
    }
  }

  void _switchPage(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });

      // 切换到笔记页面时自动刷新
      if (index == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<NotesProvider>().refreshNotes();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: Consumer2<ChatProvider, NotesProvider>(
        builder: (context, chatProvider, notesProvider, child) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: FloatingActionButton(
              heroTag: "switchBtn",
              onPressed: () => _switchPage(_currentIndex == 0 ? 1 : 0),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  _currentIndex == 0 ? Icons.notes : Icons.chat,
                  key: ValueKey(_currentIndex),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}