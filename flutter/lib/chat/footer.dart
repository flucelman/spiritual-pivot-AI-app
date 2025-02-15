import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../viewModel/dialogue.dart';
import '../viewModel/chat_config.dart';
import '../viewModel/handle_files.dart';

class ChatFooter extends StatefulWidget {
  const ChatFooter({super.key});

  @override
  State<ChatFooter> createState() => _ChatFooterState();
}

class _ChatFooterState extends State<ChatFooter> {
  final TextEditingController _controller = TextEditingController();
  bool hasInput = false;

  void _handleSend() async {
    if (_controller.text.isEmpty) return;

    final dialogue = Provider.of<Dialogue>(context, listen: false);
    dialogue.addMessage('user', _controller.text, '', '');
    dialogue.startGenerating();
    _controller.clear();
  }

  void _handleCancel() {
    Provider.of<Dialogue>(context, listen: false).cancelRequest();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        if (_controller.text.isNotEmpty && Provider.of<Files>(context, listen: false).pendingFiles.isEmpty) {
          hasInput = true;
        } else {
          hasInput = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AddButton(),
            ChatInputField(controller: _controller),
            Consumer<Dialogue>(
              builder: (context, dialogue, child) {
                return SendButton(
                  hasInput: hasInput,
                  isGenerating: dialogue.isGenerating,
                  onPressed:
                      dialogue.isGenerating ? _handleCancel : _handleSend,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 打开文件按钮
class AddButton extends StatelessWidget {
  const AddButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Center(
        child: GestureDetector(
          onTap: () {
            Provider.of<ChatConfig>(context, listen: false).toggleUpLoadVisible();
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 10),
            child: SvgPicture.asset('assets/icons/chat/add.svg', width: 28),
          ),
        ),
      ),
    );
  }
}

// 输入框
class ChatInputField extends StatelessWidget {
  final TextEditingController controller;

  const ChatInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 240, 245, 255),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: false,
                maxLines: null,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: '给 AI 发送消息...',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(255, 199, 200, 203),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(
                    left: 16,
                    right: 0,
                    top: 10,
                    bottom: 10,
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                if (value.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () => controller.clear(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SvgPicture.asset(
                      'assets/icons/chat/cancel.svg',
                      width: 22,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 发送按钮
class SendButton extends StatelessWidget {
  final bool hasInput;
  final bool isGenerating;
  final VoidCallback onPressed;

  const SendButton({
    super.key,
    required this.hasInput,
    required this.isGenerating,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (hasInput || isGenerating) ? () {
        onPressed();
        Provider.of<ChatConfig>(context, listen: false).toggleUpLoadVisible(value: false);
        FocusScope.of(context).unfocus();
      } : null,
      child: SizedBox(
        height: 50,
        width: 50,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 10),
            child: SvgPicture.asset(
              isGenerating
                  ? 'assets/icons/chat/pause.svg'
                  : hasInput
                      ? 'assets/icons/chat/send-on.svg'
                      : 'assets/icons/chat/send-off.svg',
              width: 30,
            ),
          ),
        ),
      ),
    );
  }
}
