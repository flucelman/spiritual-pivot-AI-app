import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// 初始化相机并返回控制器
Future<CameraController?> initCamera() async {
  try {
    // 确保Flutter绑定初始化
    WidgetsFlutterBinding.ensureInitialized();
    
    // 获取可用的相机列表
    final cameras = await availableCameras();
    
    // 如果没有可用的相机，返回null
    if (cameras.isEmpty) {
      debugPrint('没有可用的相机');
      return null;
    }
    
    // 创建相机控制器，使用第一个相机（通常是后置相机）
    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    
    // 等待控制器初始化完成
    await controller.initialize();
    
    return controller;
  } catch (e) {
    debugPrint('相机初始化错误: $e');
    return null;
  }
}

// 相机预览页面
Future<XFile?> openCameraPreview(BuildContext context, CameraController controller) async {
  // 通过 Navigator.push 打开全屏相机预览页面
  final imageFile = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CameraPreviewScreen(controller: controller),
      fullscreenDialog: true,
    ),
  );
  return imageFile;
}

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({Key? key, required this.controller}) : super(key: key);

  final CameraController controller;

  @override
  _CameraPreviewScreenState createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  bool isTakingPicture = false;

  @override
  Widget build(BuildContext context) {
    // 根据摄像头的宽高比计算预览区域的高度，
    // 保证旋转后预览宽度填满屏幕，同时保持正常比例
    final previewHeight =
        MediaQuery.of(context).size.width * widget.controller.value.aspectRatio;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context, null);
          },
        ),
      ),
      body: Column(
        children: [
          // 预览区域：固定高度，显示完整的相机预览（旋转后保持正常比例）
          SizedBox(
            height: previewHeight,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: RotatedBox(
                quarterTurns: 1, // 旋转90°使预览方向正确
                child: SizedBox(
                  // 预览区域旋转前的尺寸：
                  // 宽度 = 屏幕宽度 * 摄像头宽高比，height = 屏幕宽度
                  // 经 RotatedBox 旋转后得到：宽度=屏幕宽度，保持正常比例
                  width: MediaQuery.of(context).size.width * widget.controller.value.aspectRatio,
                  height: MediaQuery.of(context).size.width,
                  child: CameraPreview(widget.controller),
                ),
              ),
            ),
          ),
          // 占位区域：填充剩余空间（背景为黑色）
          Expanded(
            child: Container(
              color: Colors.black,
            ),
          ),
          // 拍照按钮区域：下方居中显示
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  if (isTakingPicture) return;
                  setState(() {
                    isTakingPicture = true;
                  });
                  try {
                    final image = await widget.controller.takePicture();
                    Navigator.pop(context, image);
                  } catch (e) {
                    debugPrint('拍照失败: $e');
                  } finally {
                    setState(() {
                      isTakingPicture = false;
                    });
                  }
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }
}
