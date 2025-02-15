import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'chat/headbar.dart';
import 'chat/body.dart';
import 'chat/footer.dart';
import 'chat/chatDrawer.dart';
import 'chat/upFiles/add_files.dart';
import 'chat/upFiles/show_files.dart';

import 'viewModel/chat_config.dart';
import 'viewModel/dialogue.dart';
import 'util/SharedService.dart';
import 'viewModel/handle_files.dart';
import 'util/update_service.dart';


void main() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // 状态栏背景色设置为透明
    statusBarIconBrightness: Brightness.dark, // 状态栏图标颜色设置为深色
  ));
    // 初始化插件前需调用初始化代码 runApp()函数之前
  WidgetsFlutterBinding.ensureInitialized();
  //初始化SharedPreferences
  await SharedService.getInstance();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => ChatConfig()),
        ChangeNotifierProvider(create: (ctx) => Dialogue(ctx)),
        ChangeNotifierProvider(create: (ctx) => Files(ctx)),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const MainScreen(), // 将 Scaffold 移到单独的 StatefulWidget
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    // 在页面加载完成后检查更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ChatDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            const Headbar(),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: ChatBody(),
              ),
            ),
            Consumer<Files>(
              builder: (context, files, child) {
                if (files.imagePaths.isEmpty && 
                    files.filePaths.isEmpty && 
                    files.pendingFiles.isEmpty) {
                  return const SizedBox.shrink();
                }
                return const ShowFiles();
              },
            ),
            Padding(
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ChatFooter(),
              ),
            ),
            AddFiles(),
          ],
        ),
      ),
    );
  }
}
