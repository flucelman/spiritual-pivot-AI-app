import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../config/url.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final String baseUrl = Url.baseUrl; // 替换为服务器地址
  bool _isDownloading = false;
  
  // 保存下载进度
  Future<void> _saveDownloadProgress(String url, int received) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('download_progress_$url', received);
  }
  
  // 获取更新文件存储目录
  Future<String> _getUpdateDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final updateDir = Directory('${appDir.path}/updates');
    if (!await updateDir.exists()) {
      await updateDir.create();
    }
    return updateDir.path;
  }

  // 获取已下载的安装包路径
  Future<String?> _getDownloadedApk(String version) async {
    final updateDir = await _getUpdateDir();
    final apkFile = File('$updateDir/app_$version.apk');
    if (await apkFile.exists()) {
      return apkFile.path;
    }
    return null;
  }

  // 检查更新
  Future<void> checkUpdate(BuildContext context) async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      
      final response = await Dio().get(
        '$baseUrl/api/update/check',
        queryParameters: {'current_version': currentVersion}
      );
      
      if (response.data['need_update']) {
        try {
          final latestVersion = response.data['latest_version'];
          final downloadUrl = '$baseUrl${response.data['download_url']}';
          
          // 清理旧版本的安装包
          await _cleanOldApks(latestVersion);
          
          // 检查是否已下载最新版本
          String? existingApk = await _getDownloadedApk(latestVersion);
          String apkPath;
          
          if (existingApk != null) {
            apkPath = existingApk;
          } else {
            apkPath = await _downloadApkInBackground(downloadUrl, latestVersion);
          }
          
          if (context.mounted && apkPath.isNotEmpty) {
            _showInstallDialog(
              context,
              latestVersion,
              response.data['update_description'],
              response.data['force_update'],
              apkPath,
            );
          }
        } catch (e) {
          print('下载失败: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        }
      }
    } catch (e) {
      print('检查更新失败: $e');
    }
  }
  
  // 清理旧版本的安装包
  Future<void> _cleanOldApks(String latestVersion) async {
    try {
      final updateDir = await _getUpdateDir();
      final dir = Directory(updateDir);
      final List<FileSystemEntity> files = await dir.list().toList();
      
      for (var file in files) {
        if (file is File && file.path.endsWith('.apk')) {
          final fileName = file.path.split('/').last;
          // 如果不是最新版本的安装包，则删除
          if (!fileName.contains(latestVersion)) {
            await file.delete();
            print('删除旧版本安装包: ${file.path}');
          }
        }
      }
    } catch (e) {
      print('清理旧版本安装包失败: $e');
    }
  }

  // 后台下载APK
  Future<String> _downloadApkInBackground(String downloadUrl, String version) async {
    print('进入 _downloadApkInBackground 方法');
    if (_isDownloading) {
      print('已经在下载中，返回空字符串');
      return '';
    }
    _isDownloading = true;
    print('设置下载状态为 true');

    try {
      final updateDir = await _getUpdateDir();
      final savePath = '$updateDir/app_$version.apk';
      print('下载保存路径: $savePath');
      
      // 检查文件是否存在，如果存在则删除
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
        // 清除下载进度
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('download_progress_$downloadUrl');
      }
      
      // 添加下载选项和超时设置
      var dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.sendTimeout = const Duration(seconds: 30);
      
      // 打印下载地址以便调试
      print('开始下载，下载地址: $downloadUrl');
      print('保存路径: $savePath');
      
      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // 打印下载进度
            final progress = (received / total * 100).toStringAsFixed(1);
            print('下载进度: $progress%');
          }
          _saveDownloadProgress(downloadUrl, received);
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        )
      );
      
      // 验证文件是否下载成功
      final downloadedFile = File(savePath);
      if (!await downloadedFile.exists()) {
        throw '下载文件不存在';
      }
      
      final fileSize = await downloadedFile.length();
      if (fileSize == 0) {
        throw '下载文件大小为0';
      }
      
      print('下载完成，文件大小: ${fileSize}字节');
      
      _isDownloading = false;
      return savePath;
    } catch (e) {
      _isDownloading = false;
      print('下载过程发生异常: $e');
      throw '下载失败: $e';
    }
  }

  // 显示安装对话框
  void _showInstallDialog(
    BuildContext context,
    String newVersion,
    String updateDescription,
    bool forceUpdate,
    String apkPath,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => WillPopScope(
        onWillPop: () async => !forceUpdate,
        child: AlertDialog(
          title: Text('新版本 $newVersion 已准备就绪'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('更新内容：'),
              SizedBox(height: 2),
              Text(
                updateDescription,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                child: Text('稍后安装'),
                onPressed: () => Navigator.pop(context),
              ),
            TextButton(
              child: Text(forceUpdate ? '立即更新' : '立即安装'),
              onPressed: () async {
                try {
                  // 检查安装未知应用的权限
                  if (!await Permission.requestInstallPackages.isGranted) {
                    final status = await Permission.requestInstallPackages.request();
                    if (!status.isGranted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('需要授予安装权限才能更新应用')),
                      );
                      return;
                    }
                  }

                  final result = await OpenFile.open(apkPath);
                  
                  if (result.type != ResultType.done) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('安装失败: ${result.message}')),
                    );
                  }
                  
                  if (!forceUpdate) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  print('安装失败: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('安装失败: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}