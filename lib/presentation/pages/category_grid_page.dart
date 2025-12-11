import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/category_card_widget.dart';
import '../widgets/empty_state_widget.dart';
import 'category_detail_page.dart';

class CategoryGridPage extends StatelessWidget {
  const CategoryGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactMode = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // 浅灰色背景
      body: Consumer<NotesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.noteFiles.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.folder_outlined,
              title: '暂无笔记类别',
              subtitle: '在AI对话中输入内容，会自动创建新的笔记类别',
            );
          }

          return CustomScrollView(
            slivers: [
              // 顶部标题
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(isCompactMode ? 16.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '我的笔记',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '共 ${provider.noteFiles.length} 个类别',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 布局选择
              if (isCompactMode)
                // 列表布局（窄屏）
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final noteFile = provider.noteFiles[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CategoryCard(
                            noteFile: noteFile,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryDetailPage(
                                    noteFile: noteFile,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: provider.noteFiles.length,
                    ),
                  ),
                )
              else
                // 网格布局（宽屏）
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisExtent: 180,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final noteFile = provider.noteFiles[index];
                        return CategoryCard(
                          noteFile: noteFile,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryDetailPage(
                                  noteFile: noteFile,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: provider.noteFiles.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}