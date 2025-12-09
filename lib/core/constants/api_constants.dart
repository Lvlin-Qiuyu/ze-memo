class ApiConstants {
  // DeepSeek API 配置
  static const String baseUrl = 'https://api.deepseek.com/v1';
  static const String chatEndpoint = '$baseUrl/chat/completions';
  static const String model = 'deepseek-chat';

  // API 超时设置
  static const int connectTimeout = 30000; // 30秒
  static const int receiveTimeout = 60000; // 60秒

  // 默认分类
  static const List<String> defaultCategories = [
    '工作',
    '学习',
    '生活',
  ];

  // 分类描述
  static const Map<String, String> categoryDescriptions = {
    '工作': '项目进度、会议记录、工作计划',
    '学习': '学习笔记、读书心得、知识整理',
    '生活': '日常记录、购物清单、旅行计划',
  };

  // AI分类提示词模板
  static const String classificationPrompt = '''
你是一个笔记分类助手。根据已有笔记类别和用户输入，返回最合适的分类。

已有笔记：
- 工作：项目进度、会议记录、工作计划
- 学习：学习笔记、读书心得、知识整理
- 生活：日常记录、购物清单、旅行计划

用户输入：{userInput}

请返回JSON格式，注意不要添加任何其他文字或解释：
{
  "categoryId": "work|study|life|new",
  "newCategory": {
    "name": "新类别名称",
    "description": "类别描述"
  }
}
  ''';
}