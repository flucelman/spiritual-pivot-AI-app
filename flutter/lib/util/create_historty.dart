import './SharedService.dart';
import '../viewModel/dialogue.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';


class CreateHistory {
  /*
  保存对话时间、对话记录
  1. 先获取现有的时间记录数组并进行类型转换
  2. 添加新的时间记录
  3. 保存更新后的时间记录数组
  4. 将对话记录转换为JSON字符串前确保是正确的格式
  5. 保存对应时间点的对话记录
   */

  static Future<void> setHistoryDirect(String currentDialogueTime, List<Map<String, String>> dialogueList) async {
    List<String> historyTimes = ((SharedService.get('historyTime') ?? []) as List)
        .map((item) => item.toString())
        .toList();
    
    try {
      await SharedService.remove(currentDialogueTime);
      historyTimes.remove(currentDialogueTime);
    } catch (e) {
      // 静默处理异常
    }

    historyTimes.add(currentDialogueTime);
    await SharedService.set('historyTime', historyTimes);
    await SharedService.set(currentDialogueTime, dialogueList);
  }

  // 返回所有历史记录的时间点，确保类型转换
  static List<String> getHistoryTimes() {
    return ((SharedService.get('historyTime') ?? []) as List)
        .map((item) => item.toString())
        .toList();
  }

  // 根据时间获取对话记录
  static List<Map<String, String>> getDialogue(String timeNow) {
    var data = SharedService.get(timeNow);
    if (data == null) return [];
    
    return (data as List).map((item) => 
      Map<String, String>.from(item as Map<String, dynamic>)
    ).toList();
  }

  // 点击设置dialogue.dialogueList
  static void setDialogue(BuildContext context, List<Map<String, String>> dialogue) {
    Provider.of<Dialogue>(context, listen: false).setDialogue(dialogue);
  }
}