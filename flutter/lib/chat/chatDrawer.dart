import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../util/create_historty.dart';
import 'package:provider/provider.dart';
import '../viewModel/dialogue.dart';
import '../util/SharedService.dart';
import '../viewModel/chat_config.dart';

class ChatDrawer extends StatelessWidget {
  const ChatDrawer({super.key});

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除所有聊天记录吗？此操作不可恢复。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                List<String> historyTimes = CreateHistory.getHistoryTimes();
                for (var time in historyTimes) {
                  await SharedService.remove(time);
                }
                await SharedService.remove('historyTime');
                if (context.mounted) {
                  Provider.of<Dialogue>(context, listen: false).clearDialogue();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final chatConfig = Provider.of<ChatConfig>(context, listen: false);
    String tempPrompt = chatConfig.prompt;
    String tempModel = chatConfig.modelName;
    int tempMaxTokens = chatConfig.maxTokens;
    double tempTemperature = chatConfig.temperature;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            chatConfig.prompt = tempPrompt;
            if (tempModel != chatConfig.modelName) {
              chatConfig.updateModel(
                tempModel,
                chatConfig.models[tempModel]?['logo'] ?? '',
              );
            }
            chatConfig.updateMaxTokens(tempMaxTokens);
            chatConfig.updateTemperature(tempTemperature);
            return true;
          },
          child: AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('设置中心'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '系统提示语（system prompt）',
                      hintText: '请输入默认的提示语',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 4,
                    controller: TextEditingController(text: chatConfig.prompt),
                    onChanged: (value) {
                      tempPrompt = value;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '默认模型',
                      border: OutlineInputBorder(),
                    ),
                    value: SharedService.get("modelName")??chatConfig.modelName,
                    items: chatConfig.models.keys.map((String model) {
                      return DropdownMenuItem(
                        value: model,
                        child: Text(model),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        tempModel = value;
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('最大回复数: ${tempMaxTokens.toString()}',
                      style: TextStyle(color: Colors.grey[700])),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3.6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6.0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14.0,
                      ),
                    ),
                    child: Slider(
                      value: tempMaxTokens.toDouble(),
                      min: 10,
                      max: 8192,
                      divisions: 819,
                      label: tempMaxTokens.toString(),
                      onChanged: (value) {
                        tempMaxTokens = value.round();
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('温度: ${tempTemperature.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[700])),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3.6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6.0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14.0,
                      ),
                    ),
                    child: Slider(
                      value: tempTemperature,
                      min: 0.0,
                      max: 1.0,
                      divisions: 40,
                      label: tempTemperature.toStringAsFixed(2),
                      onChanged: (value) {
                        tempTemperature = value;
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  chatConfig.prompt = tempPrompt;
                  if (tempModel != chatConfig.modelName) {
                    chatConfig.updateModel(
                      tempModel,
                      chatConfig.models[tempModel]?['logo'] ?? '',
                    );
                  }
                  chatConfig.updateMaxTokens(tempMaxTokens);
                  chatConfig.updateTemperature(tempTemperature);
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // 添加顶部栏，包含标题和删除按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '聊天记录',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _showDeleteConfirmDialog(context),
                    color: Colors.grey[600],
                  ),
                ],
              ),
              // 历史记录
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    HistoryItem(),
                  ],
                ),
              ),
              // 底部用户信息
              SizedBox(
                height: 60,
                child: GestureDetector(
                  onTap: () => _showSettingsDialog(context),
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/icons/chat/userAvatar.svg', width: 30),
                      const SizedBox(width: 10),
                      const Text('设置中心'),
                      const SizedBox(width: 10),
                      Icon(Icons.arrow_forward_ios, size: 10),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryItem extends StatefulWidget {
  const HistoryItem({super.key});

  @override
  State<HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<HistoryItem> {
  @override
  Widget build(BuildContext context) {
    final historyTimes = CreateHistory.getHistoryTimes();
    final categorizedTimes = _categorizeHistoryTimes(historyTimes);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var category in ['今天', '昨天', '更早'])
          if (categorizedTimes[category]!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            for (var time in categorizedTimes[category]!)
              Builder(
                builder: (context) {
                  List<Map<String, String>> dialogue = CreateHistory.getDialogue(time);
                  var title = dialogue[0]["content"] ?? "新对话";
                  return ChatHistoryListItem(
                    title: title,
                    time: time,
                    onTap: () {
                      final dialogueProvider = Provider.of<Dialogue>(context, listen: false);
                      dialogueProvider.setCurrentDialogueTime(time);
                      dialogueProvider.setDialogue(dialogue);
                      Navigator.pop(context);
                    },
                  );
                }
              )
          ],
      ],
    );
  }

  Map<String, List<String>> _categorizeHistoryTimes(List<String> historyTimes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    Map<String, List<String>> categorized = {
      '今天': [],
      '昨天': [],
      '更早': [],
    };
    
    for (var time in historyTimes) {
      DateTime historyDate = DateTime.parse(time.split(' ')[0]);
      if (historyDate.isAtSameMomentAs(today)) {
        categorized['今天']!.add(time);
      } else if (historyDate.isAtSameMomentAs(yesterday)) {
        categorized['昨天']!.add(time);
      } else {
        categorized['更早']!.add(time);
      }
    }
    
    // 对每个类别的列表进行倒序排序
    categorized['今天']!.sort((a, b) => b.compareTo(a));
    categorized['昨天']!.sort((a, b) => b.compareTo(a));
    categorized['更早']!.sort((a, b) => b.compareTo(a));
    
    return categorized;
  }
}

class ChatHistoryListItem extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final String time;

  const ChatHistoryListItem({
    super.key,
    required this.title,
    required this.onTap,
    required this.time,
  });

  @override
  State<ChatHistoryListItem> createState() => _ChatHistoryListItemState();
}

class _ChatHistoryListItemState extends State<ChatHistoryListItem> {
  bool _showDelete = false;

  void _deleteHistory() async {
    List<String> historyTimes = CreateHistory.getHistoryTimes();
    historyTimes.remove(widget.time);
    await SharedService.set('historyTime', historyTimes);
    await SharedService.remove(widget.time);
    
    if (context.mounted) {
      final dialogueProvider = Provider.of<Dialogue>(context, listen: false);
      if (dialogueProvider.currentDialogueTime == widget.time) {
        dialogueProvider.clearDialogue();
      }
      final state = context.findAncestorStateOfType<_HistoryItemState>();
      state?.setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () {
        setState(() {
          _showDelete = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 248, 248, 248),
          borderRadius: BorderRadius.circular(50.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[300]!,
              offset: const Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, 
              size: 20, 
              color: Colors.grey[600]
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_showDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _deleteHistory,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              Icon(Icons.arrow_forward_ios, 
                size: 16, 
                color: Colors.grey[400]
              ),
          ],
        ),
      ),
    );
  }
}