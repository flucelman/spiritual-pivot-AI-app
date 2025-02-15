import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../viewModel/handle_files.dart';

class ShowFiles extends StatelessWidget {
  const ShowFiles({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Files>(
      builder: (context, files, child) {
        // 合并所有需要显示的文件：已上传的和待上传的
        final allFiles = [
          ...files.pendingFiles,
          ...files.imagePaths, 
          ...files.filePaths,
        ].toList(); // 直接使用列表字面量
        
        return Container(
          width: double.infinity,
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: allFiles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final path = allFiles[index];
              final isImage = path.toLowerCase().endsWith('.jpg') || 
                            path.toLowerCase().endsWith('.jpeg') || 
                            path.toLowerCase().endsWith('.png') ||
                            path.toLowerCase().endsWith('.gif');
              final isPending = files.pendingFiles.contains(path);
              
              return Content(
                imagePath: path,
                isImage: isImage,
                onDelete: isPending ? null : () {
                  if (files.imagePaths.contains(path)) {
                    files.removeImage(files.imagePaths.indexOf(path));
                    files.removeFileFromDialogueAndList(path,isImage:true);
                  } else if (files.filePaths.contains(path)) {
                    files.removeFile(files.filePaths.indexOf(path));
                    files.removeFileFromDialogueAndList(path,isImage:false);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

// 内容
class Content extends StatelessWidget {
  final String? imagePath;
  final bool isImage;
  final VoidCallback? onDelete;
  
  const Content({
    super.key, 
    this.imagePath, 
    this.isImage = true,
    this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<Files>(
      builder: (context, files, child) {
        final isUploading = files.pendingFiles.contains(imagePath ?? '');

        return Container(
          width: 150,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color.fromARGB(255, 226, 226, 226)),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      FileImage(imagePath: imagePath, isImage: isImage),
                      if (isUploading)
                        const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  FileItem(
                    imagePath: imagePath, 
                    isImage: isImage,
                    uploading: isUploading,
                  ),
                ],
              ),
              if (!isUploading)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: SvgPicture.asset(
                      'assets/icons/chat/cancel.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// 图片
class FileImage extends StatelessWidget {
  final String? imagePath;
  final bool isImage;
  
  const FileImage({
    super.key, 
    this.imagePath,
    this.isImage = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.file(
          File(imagePath!),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      );
    }
    return SvgPicture.asset(
      'assets/icons/chat/file.svg',
      width: 30,
      height: 30,
    );
  }
}

// 名字和大小
class FileItem extends StatelessWidget {
  final String? imagePath;
  final bool isImage;
  final bool uploading;
  
  const FileItem({
    super.key, 
    this.imagePath,
    this.isImage = true,
    this.uploading = false,
  });

  String _getFileName() {
    if (imagePath == null) return '';
    return isImage ? "图片" : File(imagePath!).uri.pathSegments.last;
  }

  String _getFileSize() {
    if (imagePath == null) return '';
    final file = File(imagePath!);
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            uploading ? '解析中...' : _getFileName(),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            uploading ? '仅识别文字' : _getFileSize(),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}