import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/notes_provider.dart';
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