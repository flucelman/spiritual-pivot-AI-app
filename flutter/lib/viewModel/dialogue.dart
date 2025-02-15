import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../util/create_historty.dart';
import '../config/url.dart';

class Dialogue extends ChangeNotifier {
// ===============================定义变量================================================
  // 当前对话时间
  String _currentDialogueTime = "";
  final BuildContext context;
  // 当前对话列表
  final List<Map<String, String>> _dialogueList = [];
  // 是否正在生成
  bool isGenerating = false;
  // http客户端
  http.Client? _client;
  // 是否取消请求
  bool _isCancelled = false;

  Dialogue(this.context);

// ===============================定义get方法================================================
  // 获取当前对话时间
  String get currentDialogueTime => _currentDialogueTime;
  // 获取当前对话列表
  List<Map<String, String>> get dialogueList => _dialogueList;
// ===============================定义set方法================================================
  // 设置当前对话时间
  void setCurrentDialogueTime(String currentDialogueTime) {
    _currentDialogueTime = currentDialogueTime;
    notifyListeners();
  }

  // 设置当前对话列表
  void setDialogue(List<Map<String, String>> dialogue) {
    _dialogueList.clear();
    _dialogueList.addAll(dialogue);
    notifyListeners();
  }
  
  // 添加文件
  void addFile(String text, {bool isImage = false}) {
    // 将文件作为用户消息添加，使用统一的格式标记文件内容
    if (isImage) {
      _dialogueList.add({
        'role': 'user',
        'content': '图片内容: $text'
      });
    } else {
      _dialogueList.add({
        'role': 'user',
        'content': '文件内容: $text'
      });
    }
    notifyListeners();
  }

  // 删除文件
  void removeFile(String text, {bool isImage = false}) {
    // 根据文件类型构建要删除的内容格式
    final fileContent = isImage ? '图片内容: $text' : '文件内容: $text';
    _dialogueList.removeWhere((element) => 
      element['role'] == 'user' && element['content'] == fileContent
    );
    notifyListeners();
  }

// ===============================定义方法================================================


  // 清除当前对话列表
  Future<void> clearDialogue() async{
    await cancelRequest();
    _dialogueList.clear();
    notifyListeners();
  }
  // 对话过程添加消息
  Future<void> addMessage(String role, String content, String reasoningContent, String modelName) async {
    if (role == "user") {
      _dialogueList.add({'role': role, 'content': content});
      _dialogueList.add({
        'role': 'assistant', 
        'content': '', 
        'reasoning_content': '', 
        'model_name': modelName
      });
      notifyListeners();
      await _sendChatRequest();
    } else {
      // 给最后一个的assistant一个字一个字地添加
      if (reasoningContent.isNotEmpty) {
        _dialogueList.last['reasoning_content'] = (_dialogueList.last['reasoning_content'] ?? '') + reasoningContent;
      } else {
        _dialogueList.last['content'] = (_dialogueList.last['content'] ?? '') + content;
      }
      // 确保 model_name 被设置
      if (_dialogueList.last['model_name']?.isEmpty ?? true) {
        _dialogueList.last['model_name'] = modelName;
      }
      notifyListeners();
    }
  }

  Future<void> _sendChatRequest() async {
    _client = http.Client();
    _isCancelled = false;
    try {
      final chatConfig = Provider.of<ChatConfig>(context, listen: false);
      

      final url = Uri.parse(Url.chatApiEndpoint);
      final requestBody = {
        'model_name': chatConfig.modelName,
        'prompt': chatConfig.prompt,
        'messages': _dialogueList.sublist(0, _dialogueList.length - 1).map((msg) => {
          'role': msg['role'],
          'content': msg['content'],
        }).toList(), // 只包含 role 和 content 字段
        'max_tokens': chatConfig.maxTokens,
        'temperature': chatConfig.temperature,
      };

      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Accept'] = 'text/event-stream'
        ..body = jsonEncode(requestBody);

      final streamedResponse = await _client!.send(request);
      final stream = streamedResponse.stream.transform(utf8.decoder);

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 307) {
        if (streamedResponse.statusCode == 307) {
          final redirectUrl = streamedResponse.headers['location'];
          if (redirectUrl != null) {
            final redirectRequest = http.Request('POST', Uri.parse(redirectUrl))
              ..headers['Content-Type'] = 'application/json'
              ..headers['Accept'] = 'text/event-stream'
              ..body = jsonEncode(requestBody);

            final redirectResponse = await _client!.send(redirectRequest);
            final redirectStream =
                redirectResponse.stream.transform(utf8.decoder);

            await _processStream(redirectStream);
            return;
          }
        }

        await _processStream(stream);
      } else {
        throw Exception('请求失败: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      if (!_isCancelled) {
        // 只有在非用户主动取消的情况下才显示错误信息
        _dialogueList.last['content'] = '连接已断开，请重试';
        notifyListeners();
      }
    } finally {
      _client = null;
      // 停止生成
      stopGenerating();
      // 自动保存
      autoSave();
    }
  }

  Future<void> _processStream(Stream<String> stream) async {
    await for (var chunk in stream) {
      final lines = chunk.split('\n');
      for (var line in lines) {
        if (line.startsWith('data: ')) {
          try {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isNotEmpty) {
              final jsonData = jsonDecode(jsonStr);
              final content = jsonData['content'] as String;
              final reasoningContent = jsonData['reasoning_content'] as String;
              final modelName = Provider.of<ChatConfig>(context, listen: false).modelName;
              await addMessage('assistant', content, reasoningContent, modelName);
            }
          } catch (e) {
            print('解析数据出错: $e\n数据: $line');
            continue;
          }
        }
      }
    }
  }

  void startGenerating() {
    isGenerating = true;
    notifyListeners();
  }
  // 停止生成
  void stopGenerating() {
    isGenerating = false;
    notifyListeners();
  }

  Future<void> cancelRequest() async {
    if (_client != null) {
      _isCancelled = true;
      _client!.close();
      _client = null;
      stopGenerating();
    }
  }

  // 自动保存
  Future<void> autoSave() async {
      if (_currentDialogueTime.isEmpty) {
        _currentDialogueTime = DateTime.now().toString();
      }
      if (context.mounted) {
        try {
          await CreateHistory.setHistoryDirect(_currentDialogueTime, _dialogueList);
          print("已保存历史=================");
        } catch (e) {
          print("保存历史失败: $e");
        }
      }
  }
}
