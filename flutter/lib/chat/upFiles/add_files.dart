import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewModel/chat_config.dart';
import '../../util/upLoad/take_photo.dart';
import '../../viewModel/handle_files.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';


class AddFiles extends StatelessWidget {
  const AddFiles({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatConfig>(
      builder: (context, state, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150), // 动画持续时间
          curve: Curves.easeInOut, // 动画曲线
          height: state.upLoadVisible ? 100 : 0, // 控制容器高度
          child: SingleChildScrollView( // 防止动画过程中出现溢出错误
            physics: const NeverScrollableScrollPhysics(), // 禁用滚动
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TakePhoto(),
                  const UpImage(),
                  const UpFile(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// 拍照
class TakePhoto extends StatelessWidget {
  const TakePhoto({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final controller = await initCamera();
        if (controller == null) {
          if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar(content: '相机初始化失败', backgroundColor: Colors.red),
                );
          }
          return;
        }
        
        if (context.mounted) {
          final imageFile = await openCameraPreview(context, controller);
          if (imageFile != null && context.mounted) {
            final result = await context.read<Files>().uploadImage(imageFile.path);
            if (context.mounted) {
              if (result != '') {
                print(result);
                ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar(content: '上传成功', backgroundColor: Colors.green),
                );
              } else {
                context.read<Files>().removeFileFromDialogueAndList(imageFile.path, isImage: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar(content: '未识别到文字', backgroundColor: Colors.red),
                );
              }
            }
          }
        }
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 236, 236, 236),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.camera, size: 30),
          ),
          const SizedBox(height: 8),
          const Text('拍照'),
        ],
      ),
    );
  }
}

// 上传图片
class UpImage extends StatelessWidget {
  const UpImage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ImagePicker picker = ImagePicker();
        final List<XFile> images = await picker.pickMultiImage();
        try {
          if (images.isNotEmpty && context.mounted) {
            final uploadTasks = images.map((image) async {
              if (context.mounted) {
                final result = await context.read<Files>().uploadImage(image.path);
                if (context.mounted) {
                  if (result == '') {
                    context.read<Files>().removeFileFromDialogueAndList(image.path, isImage: true);
                  }
                  return result;
                }
              }
              return '';
            }).toList();

            final results = await Future.wait(uploadTasks);
            if (context.mounted) {
              final successCount = results.where((result) => result != '').length;
              final failCount = results.length - successCount;
              
              if (successCount > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar(
                    content: '成功上传 $successCount 个文件${failCount > 0 ? '，$failCount 个文件未识别到文字' : ''}',
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (failCount > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar(
                    content: '$failCount 个文件未识别到文字',
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar(content: e.toString(), backgroundColor: Colors.red),
            );
          }
        }
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 236, 236, 236),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, size: 30),
          ),
          const SizedBox(height: 8),
          const Text('上传图片'),
        ],
      ),
    );
  }
}

// 上传文件
class UpFile extends StatelessWidget {
  const UpFile({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: true,
        );
        
        if (result != null && result.files.isNotEmpty && context.mounted) {
          try {
            final uploadTasks = result.files.where((file) => file.path != null).map((file) async {
              if (context.mounted) {
                final uploadResult = await context.read<Files>().uploadFile(file.path!);
                if (context.mounted) {
                  if (uploadResult == '') {
                    context.read<Files>().removeFileFromDialogueAndList(file.path!, isImage: false);
                  }
                  return uploadResult;
                }
              }
              return '';
            }).toList();

            final results = await Future.wait(uploadTasks);
            if (context.mounted) {
              final successCount = results.where((result) => result != '').length;
              final failCount = results.length - successCount;
              
              if (successCount > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar(
                    content: '成功上传 $successCount 个文件${failCount > 0 ? '，$failCount 个文件未识别到文字' : ''}',
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (failCount > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar(
                    content: '$failCount 个文件未识别到文字',
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                CustomSnackBar(content: e.toString(), backgroundColor: Colors.red),
              );
            }
          }
        }
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 236, 236, 236),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.file_present, size: 30),
          ),
          const SizedBox(height: 8),
          const Text('上传文件'),
        ],
      ),
    );
  }
}

class CustomSnackBar extends SnackBar {
  CustomSnackBar({
    super.key, 
    required String content,
    required Color backgroundColor,
  }) : super(
    content: Text(
      content,
      style: const TextStyle(color: Colors.white),
      textAlign: TextAlign.center,
    ),
    backgroundColor: backgroundColor,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.symmetric(horizontal: 140, vertical: 300),
    duration: const Duration(seconds: 1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
}
