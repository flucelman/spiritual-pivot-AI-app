import 'dart:io';
import 'dart:typed_data';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';

/// 文件文字提取类，根据传入的文件路径自动判断文件类型并提取文字
class FileTextExtractor {
  static final _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.chinese,
  );

  /// 根据文件路径提取文字
  static Future<String> extractText(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception("文件不存在: $filePath");
    }

    // 根据文件扩展名判断文件类型
    final extension = file.path.split('.').last.toLowerCase();

    try {
      if (['jpg', 'jpeg', 'png', 'bmp', 'gif'].contains(extension)) {
        // 图片文件采用 OCR 识别，支持中文和英文
        print("执行图片OCR文字识别...");
        final inputImage = InputImage.fromFilePath(filePath);
        final recognizedText = await _textRecognizer.processImage(inputImage);
        return recognizedText.text;
      } else if (extension == 'txt') {
        // 直接读取txt文件内容
        print("读取TXT文件内容...");
        return await file.readAsString();
      } else if (extension == 'pdf') {
        // 直接使用pdf_render渲染页面为图片，再通过OCR提取文字
        print("直接使用pdf_render进行PDF文字提取...");
        return await _extractTextFromScannedPdf(filePath);
      } else if (extension == 'docx' || extension == 'doc') {
        // 使用docx_to_text包提取Word文件文字
        print("提取Word文件文字...");
        final fileBytes = await file.readAsBytes();
        return await docxToText(fileBytes);
      } else if (extension == 'ppt' || extension == 'pptx') {
        // PPT文件暂时不支持提取
        throw UnsupportedError('暂不支持PPT文件的文字提取');
      } else {
        throw UnsupportedError('不支持的文件格式: $extension');
      }
    } catch (e) {
      print('文字提取错误: $e');
      rethrow;
    }
  }

  /// 当PDF文件无法直接提取文字时（如扫描版PDF），通过pdf_render将每一页转换为图片，再使用OCR提取文字
  static Future<String> _extractTextFromScannedPdf(String filePath) async {
    final doc = await PdfDocument.openFile(filePath);
    final List<Future<String>> ocrTasks = List.generate(doc.pageCount, (index) async {
      final page = await doc.getPage(index + 1);
      
      final pageImage = await page.render(
        width: page.width.toInt(),
        height: page.height.toInt(),
      );
      
      // 利用 compute 将图像处理任务放入后台 isolate
      final tempFilePath = await compute(_processImageToTempFile, {
        'width': page.width.toInt(),
        'height': page.height.toInt(),
        'pixels': pageImage.pixels,
        'pageIndex': index + 1,
      });
      
      // 在主 isolate 中同时发起 OCR 识别任务
      print("对PDF第 ${index + 1} 页使用OCR识别...");
      final inputImage = InputImage.fromFilePath(tempFilePath);
      final recognizer = TextRecognizer(script: TextRecognitionScript.chinese);
      final recognizedText = await recognizer.processImage(inputImage);
      await recognizer.close();
      
      // 删除临时文件
      final tempFile = File(tempFilePath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      return recognizedText.text;
    });
    
    // 并行等待所有 OCR 任务完成
    final List<String> results = await Future.wait(ocrTasks);
    await doc.dispose();
    return results.join("\n");
  }
}

// 在后台 isolate 中执行图像处理，转换为 png 图片，并保存临时文件，返回临时文件路径
Future<String> _processImageToTempFile(Map<String, dynamic> params) async {
  final int width = params['width'];
  final int height = params['height'];
  final Uint8List pixels = params['pixels'];
  final int pageIndex = params['pageIndex'];

  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: pixels.buffer,
    numChannels: 4,  // RGBA格式
  );
  final pngData = img.encodePng(image);
  final tempDir = Directory.systemTemp;
  final tempFile = await File('${tempDir.path}/pdf_page_$pageIndex.png').create();
  await tempFile.writeAsBytes(pngData);
  return tempFile.path;
}
