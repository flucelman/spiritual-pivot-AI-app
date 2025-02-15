import 'package:flutter/material.dart';
import '../util/upLoad/file_text_extractor.dart';
import '../viewModel/dialogue.dart';
import 'package:provider/provider.dart';

class Files extends ChangeNotifier {
  final BuildContext context;
  
  Files(this.context);
// ==================================属性=========================================
  // 存储图片路径列表
  final List<String> _imagePaths = [];
  // 存储文件路径列表
  final List<String> _filePaths = [];

  // 存储待上传的文件路径
  final List<String> _pendingFiles = [];

  // 存储path和text的映射
  final Map<String, String> _pathTextMap = {};

// ==================================getter方法=========================================
  // getter方法
  List<String> get imagePaths => _imagePaths;
  List<String> get filePaths => _filePaths;

  List<String> get pendingFiles => _pendingFiles;

// ==================================setter方法=========================================
  // 添加图片路径
  void addImage(String path) {
    _imagePaths.add(path);
    notifyListeners();
  }

  // 移除指定索引的图片
  void removeImage(int index) {
    if (index >= 0 && index < _imagePaths.length) {
      _imagePaths.removeAt(index);
      notifyListeners();
    }
  }

  // 清空所有文件
  void clearAll() {
    _imagePaths.clear();
    _filePaths.clear();
    _pendingFiles.clear();
    _pathTextMap.clear();
    notifyListeners();
  }

  // 添加文件路径
  void addFile(String path) {
    _filePaths.add(path);
    notifyListeners();
  }

  // 移除指定索引的文件
  void removeFile(int index) {
    if (index >= 0 && index < _filePaths.length) {
      _filePaths.removeAt(index);
      notifyListeners();
    }
  }


  // 添加待上传文件
  void addPendingFile(String path) {
    _pendingFiles.add(path);
    notifyListeners();
  }

  // 移除待上传文件
  void removePendingFile(String path) {
    _pendingFiles.remove(path);
    notifyListeners();
  }

  // 添加path和text的映射
  void addPathText(String path, String text) {
    _pathTextMap[path] = text;
    notifyListeners();
  }

// ==================================删除相关方法=========================================
  /// 根据图片路径删除记录（图片路径、映射）
  void removeImageByPath(String path) {
    _imagePaths.remove(path);
    _pathTextMap.remove(path);
    notifyListeners();
  }

  /// 根据文件路径删除记录（文件路径、映射）
  void removeFileByPath(String path) {
    _filePaths.remove(path);
    _pathTextMap.remove(path);
    notifyListeners();
  }

// ==================================方法=========================================

  // 上传图片方法
  Future<String> uploadImage(String path) async {
    addPendingFile(path);
    final result = await FileTextExtractor.extractText(path);
    removePendingFile(path);
    addImage(path);

    if (context.mounted) {
      context.read<Dialogue>().addFile(result, isImage: true);
    }

    addPathText(path, result);

    return result;
  }

  // 上传文件方法
  Future<String> uploadFile(String path) async {
    addPendingFile(path);
    try {
      final result = await FileTextExtractor.extractText(path);
      addFile(path);

      if (context.mounted) {
        context.read<Dialogue>().addFile(result, isImage: false);
      }

      addPathText(path, result);
      return result;
    } catch (e) {
      // 如果需要在这里做特殊处理，可在此捕获异常
      rethrow;
    } finally {
      // 无论上传成功与否，都清理_pendingFiles中的对应记录
      removePendingFile(path);
    }
  }


  // 删除文件
  void removeFileFromDialogueAndList(String path, {bool isImage = false}) {
    final text = _pathTextMap[path];
    if (text != null && context.mounted) {
      context.read<Dialogue>().removeFile(text, isImage: isImage);
    }
    
    if (isImage) {
      removeImageByPath(path);
    } else {
      removeFileByPath(path);
    }
  }
}