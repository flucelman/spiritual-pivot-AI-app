import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class UserMsg extends StatelessWidget {
  final String message;
  final bool isFile;
  final bool isImage;
  const UserMsg({
    super.key, 
    required this.message,
    this.isFile = false,
    this.isImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 300,
        ),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 240, 240, 240),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFile)
              SvgPicture.asset("assets/icons/chat/file.svg", width: 30)
            else if (isImage)
              SvgPicture.asset("assets/icons/chat/image.svg", width: 30)
            else
              Flexible(
                child: SelectableText(
                  message,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
