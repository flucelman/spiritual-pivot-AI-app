import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedService {
  //单例生命
  factory SharedService() => _instance;
  SharedService._internal();
  static final SharedService _instance = SharedService._internal();
  //保持一个SharedPreferences的引用
  static late final SharedPreferences _sp;
  //初始化方法，只需要调用一次。
  static Future<SharedService> getInstance() async {
    _sp = await SharedPreferences.getInstance();
    return _instance;
  }


  // 设置值
  static Future<void> set<T>(String key, T value) async {
    Type type = value.runtimeType;
    
    // 处理List类型
    if (value is List) {
      await _sp.setString(key, json.encode(value));
      return;
    }
    
    // 处理Map类型
    if (value is Map) {
      await _sp.setString(key, json.encode(value));
      return;
    }
    
    // 处理基本类型
    switch (type) {
      case String:
        await _sp.setString(key, value as String);
        return;
      case int:
        await _sp.setInt(key, value as int);
        return;
      case bool:
        await _sp.setBool(key, value as bool);
        return;
      case double:
        await _sp.setDouble(key, value as double);
        return;
    }
  }

  // 获取值
  static dynamic get<T>(String key) {
    var value = _sp.get(key);
    if (value is String) {
      try {
        return json.decode(value);
      } on FormatException {
        return value;
      }
    }
    return value;
  }

    /// 获取数据中所有的key
  static Set<String> getKeys() {
    return _sp.getKeys();
  }

  /// 判断数据中是否包含某个key
  static bool containsKey(String key) {
    return _sp.containsKey(key);
  }

  /// 删除数据中某个key
  static Future<bool> remove(String key) async {
    return await _sp.remove(key);
  }

  /// 清除所有数据
  static Future<bool> clear() async {
    return await _sp.clear();
  }

  /// 重新加载
  static Future<void> reload() async {
    return await _sp.reload();
  }
}