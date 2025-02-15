// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import '../util/SharedService.dart';

class ChatConfig extends ChangeNotifier {
  String _prompt = SharedService.get("prompt")?.toString() ?? "帮助用户解决问题";
  String _logo = SharedService.get("modelLogo")?.toString() ?? "assets/icons/chat/deepseek.svg";
  String _modelName = SharedService.get("modelName")?.toString() ?? "DeepSeek-v3";
  int _maxTokens = SharedService.get("maxTokens") as int? ?? 4096;
  double _temperature = SharedService.get("temperature") as double? ?? 0.7;
  final Map<String, Map<String, String>> _models = {
    "DeepSeek-v3": {"logo": "assets/icons/chat/deepseek.svg"},
    "DeepSeek-R1": {"logo": "assets/icons/chat/deepseek.svg"},
    "ChatGPT-4o": {"logo": "assets/icons/chat/chatgpt.svg"},
    "Claude3.5": {"logo": "assets/icons/chat/claude.svg"}
  };

  // 上传文件是否显示
  bool _upLoadVisible = false;

  bool get upLoadVisible => _upLoadVisible;

  void toggleUpLoadVisible({bool? value}) {
    _upLoadVisible = value ?? !_upLoadVisible;
    notifyListeners();
  }
  
  String get prompt => _prompt;
  String get logo => _logo;
  String get modelName => _modelName;
  Map<String, Map<String, String>> get models => _models;
  int get maxTokens => _maxTokens;
  double get temperature => _temperature;

  void updateModel(String modelName, String logo) {
    _modelName = modelName;
    _logo = logo;
    SharedService.set("modelName", modelName);
    SharedService.set("modelLogo", logo);
    notifyListeners();
  }

  void updateMaxTokens(int tokens) {
    _maxTokens = tokens;
    SharedService.set("maxTokens", tokens);
    notifyListeners();
  }

  void updateTemperature(double temp) {
    _temperature = temp;
    SharedService.set("temperature", temp);
    notifyListeners();
  }

  set prompt(String prompt) {
    _prompt = prompt;
    SharedService.set("prompt", prompt);
    notifyListeners();
  }
}
