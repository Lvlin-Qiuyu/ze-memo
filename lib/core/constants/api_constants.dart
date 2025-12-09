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
你是一个智能笔记分类助手。请根据已有笔记类别和用户输入的内容，将笔记归入最合适的分类，或者创建新分类。

已有笔记类别：
{existingCategories}

用户输入：{userInput}

分类原则：
1. 优先归入已有分类，只要语义相关即可。
2. 如果已有分类都不合适，请创建新分类。
3. 避免使用过于宽泛的分类（如"生活"），应根据具体内容细分，例如："思考"、"经历"、"消费"等。
4. 对于工具类、辅助类内容，可以使用较宽泛的分类（如"工具"）。
5. 账号、密码、密钥等为了防止忘记的内容，应统一归类（如"账号密钥"）。
6. 新分类名称应简洁明了（2-4个字）。

请返回JSON格式，不要包含任何Markdown标记或额外解释：
{
  "categoryId": "已有分类ID或new",
  "newCategory": {
    "name": "新类别名称（仅当categoryId为new时必填）",
    "description": "类别描述（仅当categoryId为new时必填）"
  }
}
  ''';
}