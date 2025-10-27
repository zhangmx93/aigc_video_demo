import 'package:aigc_video_demo/features/editor/pages/video_editor_basic_example_page.dart';
import 'package:aigc_video_demo/features/editor/pages/video_editor_grounded_example_page.dart';
import 'package:aigc_video_demo/features/audio_extraction/audio_extraction_example_page.dart';
import 'package:aigc_video_demo/features/audio_extraction/simple_audio_extractor_example.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pro_video_editor/pro_video_editor.dart';

import 'features/metadata/video_metadata_example_page.dart';
import 'features/render/video_renderer_page.dart';
import 'features/thumbnail/thumbnail_example_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  runApp(const MyApp());
}

/// The root widget of the application.
///
/// This widget sets up the app's state and initial configuration.
/// It is typically used to initialize themes, routes, and global settings.
class MyApp extends StatelessWidget {
  /// Creates the root [MyApp] widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade800,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// The main landing page of the application.
///
/// This widget serves as the entry point after launching the app,
/// typically containing the primary UI or navigation structure.
class HomePage extends StatefulWidget {
  /// Creates the [HomePage] widget.
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _platformVersion = 'Unknown';
  final List<_ExampleListItem> _exampleList = [
    _ExampleListItem(
      icon: Icons.info_outline,
      title: 'Video-Metadata',
      pageBuilder: () => const VideoMetadataExamplePage(),
    ),
    _ExampleListItem(
      icon: Icons.image_outlined,
      title: 'Thumbnails',
      pageBuilder: () => const ThumbnailExamplePage(),
    ),
    _ExampleListItem(
      icon: Icons.developer_board_outlined,
      title: 'Video-Renderer',
      pageBuilder: () => const VideoRendererPage(),
    ),
    _ExampleListItem(
      icon: Icons.edit,
      title: 'Video-Editor',
      pageBuilder: () => const VideoEditorBasicExamplePage(),
    ),
    _ExampleListItem(
      icon: Icons.grass_outlined,
      title: 'Video-Editor Grounded-Design',
      pageBuilder: () => const VideoEditorGroundedExamplePage(),
    ),
    _ExampleListItem(
      icon: Icons.audiotrack,
      title: 'Audio-Extraction',
      pageBuilder: () => const AudioExtractionExamplePage(),
    ),
    _ExampleListItem(
      icon: Icons.audio_file,
      title: 'Simple Audio Extractor',
      pageBuilder: () => const SimpleAudioExtractorExamplePage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await ProVideoEditor.instance.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pro Video Editor')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: _exampleList.map((item) {
                return ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => item.pageBuilder()),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 50),
          Center(child: Text('Running on: $_platformVersion\n')),
        ],
      ),
    );
  }
}

class _ExampleListItem {
  _ExampleListItem({
    required this.icon,
    required this.title,
    required this.pageBuilder,
  });
  final IconData icon;
  final String title;
  final Widget Function() pageBuilder;
}
