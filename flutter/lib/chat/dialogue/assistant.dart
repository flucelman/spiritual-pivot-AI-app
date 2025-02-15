import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import '../../viewModel/chat_config.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/vs2015.dart';
import 'package:markdown/markdown.dart' as md;

class AssistantMsg extends StatelessWidget {
  final Map<String, dynamic> message;

  const AssistantMsg({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Consumer<ChatConfig>(builder: (context, provider, child) {
            // 如果 model_name 为空，使用 provider 中的默认值
            String modelName = message['model_name']?.toString().isNotEmpty == true 
                ? message['model_name'].toString() 
                : provider.modelName;
            String logo = provider.models[modelName]?['logo'] ?? provider.logo;
            
            return Row(
              children: [
                SvgPicture.asset(logo, width: 24),
                SizedBox(width: 10),
                Text(modelName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 0, 0, 0))),
              ],
            );
          }),
          SizedBox(height: 6),
          // 加载消息
          message['content'].isEmpty && message['reasoning_content'].isEmpty
              ? Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 4),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message['reasoning_content'].isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 8),
                              Text(
                                '推理过程',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          initiallyExpanded: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Message(
                                message: message['reasoning_content'],
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (message['content'].isNotEmpty)
                      Message(message: message['content']),
                  ],
                ),
          SizedBox(height: 6),
          // 复制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message['content']));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        '已复制到剪贴板',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      backgroundColor: const Color(0xFF4CAF50),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height / 2,
                        left: MediaQuery.of(context).size.width / 2 - 75,
                        right: MediaQuery.of(context).size.width / 2 - 75,
                      ),
                      duration: const Duration(seconds: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                child:
                    SvgPicture.asset('assets/icons/chat/copy.svg', width: 20),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class Message extends StatelessWidget {
  final String message;
  final TextStyle? style;
  
  const Message({
    super.key, 
    required this.message,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MarkdownBody(
        data: message,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: style ?? const TextStyle(fontSize: 16),
        ),
        builders: {
          'code': CodeElementBuilder(),
        },
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';
    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      language = lg.substring(9); // 移除 'language-' 前缀
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: const Color(0xFF1E1E1E),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      child: HighlightView(
        element.textContent,
        language: language,
        theme: vs2015Theme,
        padding: EdgeInsets.zero,
        textStyle: const TextStyle(fontSize: 14),
      ),
    );
  }
}
