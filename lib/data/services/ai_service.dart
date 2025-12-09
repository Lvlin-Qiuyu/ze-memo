import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/classification_result.dart';
import '../../core/constants/api_constants.dart';

class AiService {
  late final Dio _dio;
  String? _apiKey;

  // 初始化AI服务
  AiService({String? apiKey}) {
    _apiKey = apiKey;
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 添加请求拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_apiKey != null) {
          options.headers['Authorization'] = 'Bearer $_apiKey';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        print('AI API 请求错误: ${error.message}');
        handler.next(error);
      },
    ));
  }

  // 设置API密钥
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  // 检查是否已配置API密钥
  bool get isApiKeyConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  // 对笔记内容进行分类
  Future<ClassificationResult> classifyNote(String content) async {
    if (!isApiKeyConfigured) {
      throw Exception('API密钥未配置');
    }

    try {
      final prompt = ApiConstants.classificationPrompt
          .replaceAll('{userInput}', content);

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': ApiConstants.model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.1,
          'max_tokens': 200,
        },
      );

      final responseData = response.data;
      final messageContent = responseData['choices'][0]['message']['content'];

      // 提取JSON内容
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(messageContent);
      if (jsonMatch == null) {
        throw Exception('无法解析AI响应中的JSON内容');
      }

      final jsonStr = jsonMatch.group(0)!;
      final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;

      return ClassificationResult.fromAiResponse(jsonData);
    } on DioException catch (e) {
      String errorMessage = 'AI分类失败';

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = '连接超时，请检查网络连接';
          break;
        case DioExceptionType.connectionError:
          errorMessage = '网络连接错误，请检查网络设置';
          break;
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 401) {
            errorMessage = 'API密钥无效，请检查配置';
          } else if (e.response?.statusCode == 429) {
            errorMessage = '请求过于频繁，请稍后再试';
          } else if (e.response?.statusCode == 500) {
            errorMessage = '服务器内部错误，请稍后再试';
          } else {
            errorMessage = 'API请求失败: ${e.response?.statusCode}';
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = '请求已取消';
          break;
        case DioExceptionType.unknown:
          errorMessage = '未知错误: ${e.message}';
          break;
        default:
          errorMessage = '网络请求错误';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('分类笔记失败: $e');
      throw Exception('分类失败: ${e.toString()}');
    }
  }

  // 生成笔记摘要（可选功能）
  Future<String> generateSummary(String content) async {
    if (!isApiKeyConfigured) {
      throw Exception('API密钥未配置');
    }

    try {
      final prompt = '''
请为以下笔记内容生成一个简洁的摘要（不超过50字）：

$content
      ''';

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': ApiConstants.model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.3,
          'max_tokens': 100,
        },
      );

      return response.data['choices'][0]['message']['content'].trim();
    } catch (e) {
      print('生成摘要失败: $e');
      throw Exception('生成摘要失败: ${e.toString()}');
    }
  }

  // 提取关键词（可选功能）
  Future<List<String>> extractKeywords(String content) async {
    if (!isApiKeyConfigured) {
      throw Exception('API密钥未配置');
    }

    try {
      final prompt = '''
从以下笔记内容中提取5-8个关键词，用逗号分隔：

$content

请直接返回关键词，不要添加其他解释。
      ''';

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': ApiConstants.model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.1,
          'max_tokens': 50,
        },
      );

      final keywordsStr = response.data['choices'][0]['message']['content'].trim();
      return keywordsStr.split(',').map((kw) => kw.trim()).where((kw) => kw.isNotEmpty).toList();
    } catch (e) {
      print('提取关键词失败: $e');
      return [];
    }
  }

  // 智能建议相关笔记（可选功能）
  Future<List<String>> suggestRelatedNotes(String content, List<String> existingNotes) async {
    if (!isApiKeyConfigured || existingNotes.isEmpty) {
      return [];
    }

    try {
      final prompt = '''
根据当前笔记内容，从已有笔记中找出最相关的3条笔记：

当前笔记：$content

已有笔记：
${existingNotes.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}').join('\n')}

请返回相关笔记的编号，用逗号分隔，例如：1,3,5
      ''';

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': ApiConstants.model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.1,
          'max_tokens': 30,
        },
      );

      final indicesStr = response.data['choices'][0]['message']['content'].trim();
      final indices = indicesStr.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((i) => i > 0 && i <= existingNotes.length).toList();

      return indices.map((index) => existingNotes[index - 1]).toList();
    } catch (e) {
      print('建议相关笔记失败: $e');
      return [];
    }
  }

  // 测试API连接
  Future<bool> testConnection() async {
    if (!isApiKeyConfigured) {
      return false;
    }

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': ApiConstants.model,
          'messages': [
            {
              'role': 'user',
              'content': '测试连接',
            }
          ],
          'temperature': 0.1,
          'max_tokens': 10,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('测试API连接失败: $e');
      return false;
    }
  }

  // 释放资源
  void dispose() {
    _dio.close();
  }
}