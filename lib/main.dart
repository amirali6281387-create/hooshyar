import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// 🌐 آدرس Worker
const String API_URL = 'https://ai-assistant.amirali6281387.workers.dev';

// 🎨 رنگ‌ها
const Color kBg = Color(0xFF06070F);
const Color kSurface = Color(0xFF191C32);
const Color kBrand = Color(0xFF7C5CFF);
const Color kBrand2 = Color(0xFFA78BFA);
const Color kAccent = Color(0xFF00E5FF);
const Color kAccent2 = Color(0xFFFF5C8A);
const Color kGold = Color(0xFFFFD700);
const Color kTextDim = Color(0xFF8B8FAE);
const Color kMuted = Color(0xFF5A5F7E);
const LinearGradient kGradient = LinearGradient(
    colors: [Color(0xFF7C5CFF), Color(0xFFA78BFA), Color(0xFF00E5FF)]);
const LinearGradient kUserGradient =
    LinearGradient(colors: [Color(0xFF7C5CFF), Color(0xFFA78BFA)]);
const LinearGradient kGoldGradient =
    LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]);

// ==================== MAIN ====================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const HooshyarApp());
}

class HooshyarApp extends StatelessWidget {
  const HooshyarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'هوشیار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(primary: kBrand, secondary: kAccent),
      ),
      home: const Directionality(
          textDirection: TextDirection.rtl, child: SplashScreen()),
    );
  }
}

// ==================== SPLASH ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  int _progress = 0;
  String _status = 'راه‌اندازی سیستم...';
  Timer? _progressTimer;

  final List<Map<String, dynamic>> _steps = [
    {'progress': 10, 'status': 'راه‌اندازی سیستم...'},
    {'progress': 25, 'status': 'اتصال به هوش مصنوعی...'},
    {'progress': 45, 'status': 'بارگذاری مدل‌های زبانی...'},
    {'progress': 65, 'status': 'آماده‌سازی رابط کاربری...'},
    {'progress': 100, 'status': 'آماده! 🚀'},
  ];

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _runProgress();
  }

  void _runProgress() {
    int i = 0;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (i >= _steps.length) {
        t.cancel();
        _goToApp();
        return;
      }
      if (!mounted) return;
      setState(() {
        _progress = _steps[i]['progress'];
        _status = _steps[i]['status'];
      });
      i++;
    });
  }

  void _goToApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AppFlow(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF06070F), Color(0xFF0A0820), Color(0xFF12082B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(4, (i) {
                      final sizes = [90.0, 110.0, 130.0, 150.0];
                      final colors = [kBrand, kAccent, kAccent2, kBrand2];
                      return AnimatedBuilder(
                        animation: _rotateCtrl,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateCtrl.value *
                                2 *
                                math.pi *
                                (i.isEven ? 1 : -1),
                            child: Container(
                              width: sizes[i],
                              height: sizes[i],
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(colors: [
                                  colors[i].withOpacity(0.9),
                                  colors[i].withOpacity(0.0),
                                ], stops: const [0.0, 1.0]),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseCtrl.value * 0.08),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: kGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: kBrand.withOpacity(
                                      0.7 + (_pulseCtrl.value * 0.3)),
                                  blurRadius: 60 + (_pulseCtrl.value * 40),
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            child: const Center(
                                child: Text('✨',
                                    style: TextStyle(fontSize: 32))),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ShaderMask(
                shaderCallback: (r) => kGradient.createShader(r),
                child: const Text('هوشیار',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const SizedBox(height: 8),
              const Text('دستیار هوشمند فارسی',
                  style: TextStyle(fontSize: 13, color: kTextDim)),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('در حال بارگذاری',
                            style:
                                TextStyle(fontSize: 11, color: kMuted)),
                        Text('$_progress٪',
                            style: const TextStyle(
                                fontSize: 11,
                                color: kBrand2,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                          color: kBrand.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(3)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: MediaQuery.of(context).size.width *
                              0.72 *
                              (_progress / 100),
                          decoration:
                              const BoxDecoration(gradient: kGradient),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(_status,
                          key: ValueKey(_status),
                          style: const TextStyle(
                              fontSize: 12, color: kTextDim)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text('نسخه ۱.۰.۰ · ساخته شده با ❤️',
                  style: TextStyle(fontSize: 10, color: kMuted)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== APP FLOW (Tabs & Pro State) ====================
class AppFlow extends StatefulWidget {
  const AppFlow({super.key});
  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  int _currentIndex = 0;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _isPremium = prefs.getBool('is_premium') ?? false);
    }
  }

  Future<void> _simulatePurchase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
    if (mounted) {
      setState(() => _isPremium = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 تبریک! به هوش برتر دسترسی پیدا کردید.'),
          backgroundColor: kGold,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const ChatScreen(isPremium: false),
          _isPremium
              ? const ChatScreen(isPremium: true)
              : ProLockScreen(onPurchase: _simulatePurchase),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0A0820),
        selectedItemColor: _currentIndex == 1 ? kGold : kBrand2,
        unselectedItemColor: kTextDim,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'هوشیار'),
          BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium), label: 'هوش برتر'),
        ],
      ),
    );
  }
}

// ==================== PRO LOCK SCREEN ====================
class ProLockScreen extends StatelessWidget {
  final VoidCallback onPurchase;
  const ProLockScreen({super.key, required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.workspace_premium, size: 80, color: kGold),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (r) => kGoldGradient.createShader(r),
                  child: const Text('هوش برتر (Pro)',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                const SizedBox(height: 15),
                const Text(
                  'تجربه گفتگو با پیشرفته‌ترین مدل هوش مصنوعی!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextDim, fontSize: 14),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kGold.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      _FeatureItem(text: 'هوش بسیار بالاتر (GPT-OSS-120B)'),
                      _FeatureItem(text: 'پاسخ‌های طولانی و دقیق'),
                      _FeatureItem(text: 'بدون محدودیت پیام'),
                      _FeatureItem(text: 'پشتیبانی از تحلیل عکس'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: onPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'ارتقا به نسخه Pro (۵۰,۰۰۰ تومان)',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        const Icon(Icons.check_circle, color: kGold, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white))),
      ]),
    );
  }
}

// ==================== CHAT SCREEN ====================
class Message {
  final String text;
  final bool isUser;
  final String? imageBase64;
  Message({required this.text, required this.isUser, this.imageBase64});

  Map<String, dynamic> toJson() =>
      {'text': text, 'isUser': isUser, 'imageBase64': imageBase64};

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        text: json['text'] ?? '',
        isUser: json['isUser'] ?? false,
        imageBase64: json['imageBase64'],
      );
}

class ChatScreen extends StatefulWidget {
  final bool isPremium;
  const ChatScreen({super.key, required this.isPremium});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final List<Message> _messages = [];
  File? _selectedImage;
  String? _selectedImageBase64;
  String _deviceId = '';
  bool _isLoading = false;
  int _remaining = 25;
  int _currentLimit = 25;

  @override
  void initState() {
    super.initState();
    _initDeviceId();
    _loadHistory();
  }

  Future<void> _initDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('device_id');
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('device_id', id);
    }
    if (mounted) setState(() => _deviceId = id!);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(
        widget.isPremium ? 'chat_history_pro' : 'chat_history_free');
    if (saved != null) {
      try {
        final list = jsonDecode(saved) as List;
        if (mounted) {
          setState(() => _messages.addAll(
              list.map((m) => Message.fromJson(m as Map<String, dynamic>))));
        }
      } catch (_) {}
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      widget.isPremium ? 'chat_history_pro' : 'chat_history_free',
      jsonEncode(_messages.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 400,
          maxHeight: 400,
          imageQuality: 40);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedImage = File(picked.path);
            _selectedImageBase64 = base64Encode(bytes);
          });
        }
      }
    } catch (_) {}
  }

  void _showThinking() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) =>
          AIThinkingScreen(isPremium: widget.isPremium),
      transitionBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  void _hideThinking() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImageBase64 == null) return;
    if (_isLoading) return;

    final userText = text.isEmpty ? '📸 عکس فرستادم' : text;
    setState(() {
      _messages.add(Message(
          text: userText, isUser: true, imageBase64: _selectedImageBase64));
      _isLoading = true;
    });
    _controller.clear();
    _showThinking();
    _scrollToBottom();

    try {
      final body = <String, dynamic>{
        'prompt': text.isEmpty ? 'این عکس را به فارسی توصیف کن' : text,
        'history': _messages
            .where((m) => !m.isUser)
            .map((m) => {'role': 'assistant', 'content': m.text})
            .toList(),
        'isPremium': widget.isPremium,
      };
      if (_selectedImageBase64 != null) {
        body['imageBase64'] = _selectedImageBase64;
      }

      final res = await http
          .post(
            Uri.parse(API_URL),
            headers: {
              'Content-Type': 'application/json',
              'X-Device-ID': _deviceId,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));

      if (!mounted) return;
      _hideThinking();

      final data = jsonDecode(res.body);

      if (res.statusCode == 429) {
        setState(() {
          _messages.add(Message(
              text: data['message'] ?? 'محدودیت', isUser: false));
          _currentLimit = data['currentLimit'] ?? _currentLimit;
        });
      } else if (data['response'] != null) {
        setState(() {
          _messages.add(Message(text: data['response'], isUser: false));
          _remaining = data['remaining'] ?? _remaining - 1;
        });
      } else {
        setState(() => _messages.add(Message(
            text: 'خطا: ${data['message'] ?? 'مشکل نامشخص'}',
            isUser: false)));
      }
      await _saveHistory();
      setState(() {
        _selectedImage = null;
        _selectedImageBase64 = null;
      });
    } catch (e) {
      if (!mounted) return;
      _hideThinking();
      if (kDebugMode) print('Send error: $e');
      setState(() => _messages
          .add(Message(text: '❌ خطا در ارتباط با سرور', isUser: false)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() => Future.delayed(
        const Duration(milliseconds: 100),
        () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(
                widget.isPremium
                    ? Icons.workspace_premium
                    : Icons.smart_toy,
                color: widget.isPremium ? kGold : kBrand2),
            const SizedBox(width: 8),
            Text(
              widget.isPremium ? 'هوش برتر' : 'هوشیار',
              style: TextStyle(
                  color: widget.isPremium ? kGold : kBrand2,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (!widget.isPremium)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: Text('$_remaining از $_currentLimit',
                    style: const TextStyle(
                        color: kTextDim, fontSize: 12)),
              ),
            )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                          'سلام! من ${widget.isPremium ? 'هوش برتر' : 'هوشیار'} هستم.',
                          style: const TextStyle(color: kTextDim)))
                  : _buildChatList(),
            ),
            if (_selectedImage != null) _buildImagePreview(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg = _messages[i];
        return Align(
          alignment:
              msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: msg.isUser ? kUserGradient : null,
              color: msg.isUser ? null : kSurface,
              borderRadius: BorderRadius.circular(16),
              border: msg.isUser
                  ? null
                  : Border.all(
                      color: widget.isPremium
                          ? kGold.withOpacity(0.3)
                          : kBrand.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.imageBase64 != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                        base64Decode(msg.imageBase64!),
                        width: 150),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(msg.text,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview() => Container(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Image.file(_selectedImage!, width: 50, height: 50),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() {
              _selectedImage = null;
              _selectedImageBase64 = null;
            }),
          )
        ]),
      );

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border(
          top: BorderSide(
            color: widget.isPremium
                ? kGold.withOpacity(0.2)
                : kBrand.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.image, color: kBrand2),
              onPressed: _pickImage),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: 'پیام...', border: InputBorder.none),
            ),
          ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.send,
                    color: widget.isPremium ? kGold : kBrand2),
            onPressed: _isLoading ? null : _send,
          ),
        ],
      ),
    );
  }
}

// ==================== AI THINKING ====================
class AIThinkingScreen extends StatefulWidget {
  final bool isPremium;
  const AIThinkingScreen({super.key, required this.isPremium});
  @override
  State<AIThinkingScreen> createState() => _AIThinkingScreenState();
}

class _AIThinkingScreenState extends State<AIThinkingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBg.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _ctrl,
              child: Icon(
                widget.isPremium
                    ? Icons.auto_awesome
                    : Icons.smart_toy,
                size: 60,
                color: widget.isPremium ? kGold : kBrand2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isPremium
                  ? 'هوش برتر در حال فکر کردن...'
                  : 'هوشیار در حال فکر کردن...',
              style: TextStyle(
                  color: widget.isPremium ? kGold : Colors.white,
                  fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}