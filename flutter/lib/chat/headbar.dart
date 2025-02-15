import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../viewModel/chat_config.dart';
import '../viewModel/handle_files.dart';
import '../viewModel/dialogue.dart';

// 总组件
class Headbar extends StatefulWidget {
  const Headbar({super.key});

  @override
  State<Headbar> createState() => _HeadbarState();
}

class _HeadbarState extends State<Headbar> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 20,
          ),
          Builder(
            builder: (BuildContext context) => GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: SvgPicture.asset('assets/icons/chat/bar.svg', width: 30),
            ),
          ),
          SizedBox(
            width: 20,
          ),
          Expanded(
            flex: 1,
            child: GestureDetector(
              child: ModelSelect(),
            ),
          ),
          SizedBox(
            width: 20,
          ),
          Builder(
            builder: (BuildContext context) => GestureDetector(
              onTap: () {
                final dialogueProvider = Provider.of<Dialogue>(context, listen: false);
                final handleFilesProvider = Provider.of<Files>(context, listen: false);
                if (dialogueProvider.dialogueList.isNotEmpty) {
                  dialogueProvider.setCurrentDialogueTime(DateTime.now().toString());
                  dialogueProvider.clearDialogue();
                  handleFilesProvider.clearAll();
                }
              },
              child: SvgPicture.asset('assets/icons/chat/newChat.svg', width: 30),
            ),
          ),
          SizedBox(width: 20)
        ],
      ),
    );
  }
}

// 模型选择</edit>
class ModelSelect extends StatefulWidget {
  const ModelSelect({super.key});

  @override
  State<ModelSelect> createState() => _ModelSelectState();
}

class _ModelSelectState extends State<ModelSelect> {
  void _showModelSelector(BuildContext context, ChatConfig config) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Container(
            width: 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: config.models.entries.map((entry) {
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: SvgPicture.asset(
                    entry.value['logo']!,
                    width: 28,
                  ),
                  title: Text(
                    entry.key,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    config.updateModel(entry.key, entry.value['logo']!);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatConfig>(
      builder: (context, config, child) => GestureDetector(
        onTap: () => _showModelSelector(context, config),
        child: Container(
          width: 200,
          height: 40,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 241, 241, 251),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
              SvgPicture.asset(config.logo, width: 24),
              const SizedBox(width: 10),
              Text(
                config.modelName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              SvgPicture.asset('assets/icons/chat/down.svg', width: 24),
            ],
          ),
        ),
      ),
    );
  }
}
