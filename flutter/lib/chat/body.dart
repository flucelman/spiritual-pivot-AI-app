import 'package:flutter/material.dart';
import 'dialogue/user.dart';
import 'dialogue/assistant.dart';
import 'package:provider/provider.dart';
import '../../viewModel/dialogue.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

class ChatBody extends StatefulWidget {
  const ChatBody({super.key});

  @override
  State<ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<ChatBody> {
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;
  int _previousLength = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // 检测用户是否手动滚动
    if (!_scrollController.position.isScrollingNotifier.value) {
      return;
    }

    // 如果用户正在滚动，且不在底部，则禁用自动滚动
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent) {
      setState(() => _shouldAutoScroll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Consumer<Dialogue>(
        builder: (context, dialogue, child) {
          // 检查是否有新消息
          if (dialogue.dialogueList.length > _previousLength) {
            _shouldAutoScroll = true;
            _previousLength = dialogue.dialogueList.length;
          }

          // 只在需要自动滚动时执行
          if (_shouldAutoScroll) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController
                    .jumpTo(_scrollController.position.maxScrollExtent);
              }
            });
          }

          return dialogue.dialogueList.isEmpty 
              ? Center(
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeIn,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const TypewriterText(
                          text: "有什么能帮您的",
                          style: TextStyle(
                            fontSize: 35,
                            color: Color.fromARGB(255, 149, 149, 149),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Lottie.asset(
                            'assets/icons/chat/loading.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: dialogue.dialogueList.length,
                  itemBuilder: (context, index) {
                    final msg = dialogue.dialogueList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: msg['role'] == 'user'
                          ? UserMsg(
                              message: msg['content'] ?? '',
                              isFile: msg['content']?.toString().startsWith('文件内容: ') ?? false,
                              isImage: msg['content']?.toString().startsWith('图片内容: ') ?? false,
                            )
                          : AssistantMsg(message: msg),
                    );
                  },
                );
        },
      ),
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayText = '';
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    while (_charIndex < widget.text.length) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _charIndex++;
          _displayText = widget.text.substring(0, _charIndex);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style,
    );
  }
}
