import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// 🌐 آدرس Worker خودت
const String API_URL = 'https://ai-assistant.amirali6281387.workers.dev';

// 🎨 رنگ‌ها
const Color kBg = Color(0xFF06070F);
const Color kSurface = Color(0xFF191C32);
const Color kBrand = Color(0xFF7C5CFF);
const Color kBrand2 = Color(0xFFA78BFA);
const Color kAccent = Color(0xFF00E5FF);
const Color kAccent2 = Color(0xFFFF5C8A);
const Color kTextDim = Color(0xFF8B8FAE);
const Color kMuted = Color(0xFF5A5F7E);
const LinearGradient kGradient = LinearGradient(
  colors: [Color(0xFF7C5CFF), Color(0xFFA78BFA), Color(0xFF00E5FF)],
);
const LinearGradient kUserGradient = LinearGradient(
  colors: [Color(0xFF7C5CFF), Color(0xFFA78BFA)],
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
        colorScheme: const ColorScheme.dark(
          primary: kBrand,
          secondary: kAccent,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AppFlow(),
      ),
    );
  }
}

// ==================== APP FLOW ====================
class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  int stage = 0;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 4000));
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    if (!mounted) return;
    setState(() => stage = seen ? 2 : 1);
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) setState(() => stage = 2);
  }

  @override
  Widget build(BuildContext context) {
    switch (stage) {
      case 0:
        return const SplashScreen();
      case 1:
        return OnboardingScreen(onFinish: _finishOnboarding);
      default:
        return const ChatScreen();
    }
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
  late AnimationController _orbitCtrl;

  int _progress = 0;
  String _status = 'راه‌اندازی سیستم...';
  Timer? _progressTimer;

  final List<Map<String, dynamic>> _steps = [
    {'progress': 10, 'status': 'راه‌اندازی سیستم...'},
    {'progress': 25, 'status': 'اتصال به هوش مصنوعی...'},
    {'progress': 45, 'status': 'بارگذاری مدل‌های زبانی...'},
    {'progress': 65, 'status': 'آماده‌سازی رابط کاربری...'},
    {'progress': 85, 'status': 'بهینه‌سازی تجربه کاربری...'},
    {'progress': 100, 'status': 'آماده! 🚀'},
  ];

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _runProgress();
  }

  void _runProgress() {
    int i = 0;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (i >= _steps.length) {
        t.cancel();
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

  @override
  void dispose() {
    _progressTimer?.cancel();
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
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
                          final dir = i.isEven ? 1 : -1;
                          return Transform.rotate(
                            angle: _rotateCtrl.value * 2 * math.pi * dir,
                            child: Container(
                              width: sizes[i],
                              height: sizes[i],
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    colors[i].withOpacity(0.9),
                                    colors[i].withOpacity(0.0),
                                  ],
                                  stops: const [0.0, 1.0],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    AnimatedBuilder(
                      animation: _orbitCtrl,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _orbitCtrl.value * 2 * math.pi,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _particle(75, kBrand, 0),
                              _particle(65, kAccent, 90),
                              _particle(85, kAccent2, 180),
                              _particle(70, kBrand2, 270),
                            ],
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseCtrl.value * 0.08);
                        return Transform.scale(
                          scale: scale,
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
                                ),
                              ],
                            ),
                            child: const Center(
                              child:
                                  Text('✨', style: TextStyle(fontSize: 32)),
                            ),
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
                child: const Text(
                  'هوشیار',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'دستیار هوشمند فارسی',
                style: TextStyle(
                  fontSize: 13,
                  color: kTextDim,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(flex: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'در حال بارگذاری',
                          style: TextStyle(fontSize: 11, color: kMuted),
                        ),
                        Text(
                          '${_toPersian(_progress)}٪',
                          style: const TextStyle(
                            fontSize: 11,
                            color: kBrand2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: kBrand.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: MediaQuery.of(context).size.width *
                              0.72 *
                              (_progress / 100),
                          decoration: BoxDecoration(
                            gradient: kGradient,
                            boxShadow: [
                              BoxShadow(
                                color: kBrand.withOpacity(0.8),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _status,
                        key: ValueKey(_status),
                        style: const TextStyle(fontSize: 12, color: kTextDim),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              const Text(
                'نسخه ۱.۰.۰ · ساخته شده با ❤️',
                style: TextStyle(fontSize: 10, color: kMuted),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _particle(double radius, Color color, double startAngle) {
    final angle = startAngle * math.pi / 180;
    return Transform.translate(
      offset: Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 12),
          ],
        ),
      ),
    );
  }

  String _toPersian(int n) {
    const digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return n.toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}

// ==================== ONBOARDING ====================
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': '✨',
      'title': 'به هوشیار\nخوش اومدی!',
      'desc': 'دستیار هوشمند فارسی‌زبان که همیشه آماده کمکه.',
      'illustrationColors': [kBrand, kBrand2],
    },
    {
      'icon': '🎯',
      'title': 'چیکار می‌تونم\nبکنم؟',
      'desc': '',
      'features': [
        {'icon': '💬', 'title': 'چت هوشمند', 'desc': 'پاسخ دقیق به هر سوالی'},
        {'icon': '📸', 'title': 'تحلیل عکس', 'desc': 'عکس بفرست، تحلیل بگیر'},
        {
          'icon': '🌍',
          'title': 'ترجمه و خلاصه',
          'desc': 'به ۱۰۰+ زبان زنده دنیا'
        },
      ],
      'illustrationColors': [Color(0xFF00E5FF), kBrand],
    },
    {
      'icon': '💡',
      'title': 'چطور استفاده\nکنم؟',
      'desc': '',
      'features': [
        {
          'icon': '✍️',
          'title': '۱. سوالت رو بنویس',
          'desc': 'توی باکس پایین صفحه'
        },
        {
          'icon': '📎',
          'title': '۲. عکس پیوست کن',
          'desc': 'اختیاری، برای تحلیل تصویر'
        },
        {
          'icon': '🚀',
          'title': '۳. ارسال کن',
          'desc': 'پاسخ هوشمند در چند ثانیه'
        },
      ],
      'illustrationColors': [kAccent2, kBrand2],
    },
    {
      'icon': '🚀',
      'title': 'همه چی\nآماده‌ست!',
      'desc':
          'حالا می‌تونی شروع کنی. هر سوالی داری بپرس.\n\nروزانه ۱۰۰ سوال رایگان داری! 🎁',
      'illustrationColors': [Color(0xFF00FF88), kAccent],
    },
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } else {
      widget.onFinish();
    }
  }

  void _prev() {
    if (_page > 0) {
      _ctrl.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
            colors: [Color(0xFF06070F), Color(0xFF0A0820)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (_page < _pages.length - 1)
                      TextButton(
                        onPressed: widget.onFinish,
                        child: const Text(
                          'رد کردن',
                          style: TextStyle(color: kTextDim),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _buildPage(_pages[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: _page == i ? kUserGradient : null,
                      color: _page == i ? null : kBrand.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: _page == i
                          ? [
                              BoxShadow(
                                color: kBrand.withOpacity(0.6),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                child: Row(
                  children: [
                    if (_page > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prev,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: BorderSide(color: kBrand.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'قبلی',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (_page > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _next,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: kUserGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kBrand.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _page == _pages.length - 1
                                    ? 'شروع کن 🚀'
                                    : 'بعدی',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_page < _pages.length - 1) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_back,
                                    color: Colors.white, size: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    final colors = page['illustrationColors'] as List<Color>;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FloatingBox(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(48),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(0.5),
                    blurRadius: 60,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  page['icon'],
                  style: const TextStyle(fontSize: 80),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ShaderMask(
            shaderCallback: (r) => kGradient.createShader(r),
            child: Text(
              page['title'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.3,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if ((page['desc'] as String).isNotEmpty)
            Text(
              page['desc'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: kTextDim,
                height: 1.9,
              ),
            ),
          if (page['features'] != null) ...[
            const SizedBox(height: 24),
            ...List.generate((page['features'] as List).length, (i) {
              final f = page['features'][i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: kSurface.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBrand.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kBrand.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kBrand.withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text(
                            f['icon'],
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f['title'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              f['desc'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: kTextDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// انیمیشن شناور
class _FloatingBox extends StatefulWidget {
  final Widget child;
  const _FloatingBox({required this.child});

  @override
  State<_FloatingBox> createState() => _FloatingBoxState();
}

class _FloatingBoxState extends State<_FloatingBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -10 * _ctrl.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ==================== CHAT SCREEN ====================
class Message {
  final String text;
  final bool isUser;
  final String? imageBase64;

  Message({required this.text, required this.isUser, this.imageBase64});

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'imageBase64': imageBase64,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        text: json['text'] ?? '',
        isUser: json['isUser'] ?? false,
        imageBase64: json['imageBase64'],
      );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

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
  int _remaining = 100;

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
    final saved = prefs.getString('chat_history');
    if (saved != null) {
      try {
        final list = jsonDecode(saved) as List;
        if (mounted) {
          setState(() {
            _messages.addAll(
              list.map((m) => Message.fromJson(m as Map<String, dynamic>)),
            );
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'chat_history',
      jsonEncode(_messages.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 60,
      );
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

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBase64 = null;
    });
  }

  void _showThinking() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const AIThinkingScreen(),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
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
        text: userText,
        isUser: true,
        imageBase64: _selectedImageBase64,
      ));
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
      };
      if (_selectedImageBase64 != null) {
        body['imageBase64'] = _selectedImageBase64;
      }

      final res = await http.post(
        Uri.parse(API_URL),
        headers: {
          'Content-Type': 'application/json',
          'X-Device-ID': _deviceId,
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (!mounted) return;
      _hideThinking();

      if (res.statusCode == 429) {
        setState(() {
          _messages.add(Message(
            text: data['message'] ?? 'محدودیت روزانه',
            isUser: false,
          ));
        });
      } else if (data['response'] != null &&
          data['response'].toString().isNotEmpty) {
        setState(() {
          _messages.add(Message(text: data['response'], isUser: false));
          _remaining = data['remaining'] ?? _remaining - 1;
        });
      } else {
        setState(() {
          _messages.add(Message(
            text: 'خطا: ${data['message'] ?? 'مشکل نامشخص'}',
            isUser: false,
          ));
        });
      }
      await _saveHistory();
      _clearImage();
    } catch (e) {
      if (!mounted) return;
      _hideThinking();
      setState(() {
        _messages.add(Message(
          text: '❌ خطا در ارتباط با سرور',
          isUser: false,
        ));
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _newChat() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0A0E27),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('گفتگوی جدید',
              style: TextStyle(color: kBrand2)),
          content: const Text('همه پیام‌ها پاک می‌شن. مطمئنی؟',
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('لغو',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _messages.clear());
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('chat_history');
              },
              style: ElevatedButton.styleFrom(backgroundColor: kBrand),
              child: const Text('پاک کن'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child:
                  _messages.isEmpty ? _buildWelcome() : _buildChatList(),
            ),
            if (_selectedImage != null) _buildImagePreview(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBrand.withOpacity(0.12), Colors.transparent],
        ),
        border: Border(
          bottom: BorderSide(color: kBrand.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: kUserGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: kBrand.withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      'هوشیار',
                      style: TextStyle(
                        color: kBrand2,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    PulseDot(),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'آماده کمک · آنلاین',
                  style: TextStyle(color: kTextDim, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kBrand.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBrand.withOpacity(0.3)),
            ),
            child: Text(
              '$_remaining باقی‌مونده',
              style: const TextStyle(
                color: kBrand2,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _newChat,
            icon: const Icon(Icons.add, color: kBrand2),
            tooltip: 'گفتگوی جدید',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _FloatingBox(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: kUserGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: kBrand.withOpacity(0.5),
                    blurRadius: 50,
                  ),
                ],
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 44)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (r) => kGradient.createShader(r),
            child: const Text(
              'سلام، من هوشیارم!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'متن می‌نویسم، عکس تحلیل می‌کنم\nو هر سوالی داری جواب می‌دم',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextDim,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _suggestion('✨', 'داستان بنویس',
                  'یه داستان کوتاه درباره یک ربات مهربون بنویس'),
              _suggestion('🌍', 'ترجمه کن',
                  'این متن رو به انگلیسی ترجمه کن: '),
              _suggestion('💡', 'مشاوره بده',
                  'چطور می‌تونم برنامه‌نویسی یاد بگیرم؟'),
              _suggestion('📧', 'ایمیل رسمی',
                  'یه ایمیل رسمی برای درخواست مرخصی بنویس'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _suggestion(String icon, String title, String prompt) {
    return InkWell(
      onTap: () {
        _controller.text = prompt;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kSurface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBrand.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
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
      itemBuilder: (context, i) => _buildMessage(_messages[i]),
    );
  }

  Widget _buildMessage(Message msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _avatar('✨', kSurface, true),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isUser ? kUserGradient : null,
                color: isUser ? null : kSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: kBrand.withOpacity(0.15)),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: kBrand.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.imageBase64 != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(msg.imageBase64!),
                        width: 180,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    msg.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) _avatar('👤', kBrand, false),
        ],
      ),
    );
  }

  Widget _avatar(String icon, Color bg, bool isBot) {
    return Container(
      width: 34,
      height: 34,
      margin: EdgeInsets.only(
        left: isBot ? 8 : 0,
        right: isBot ? 0 : 8,
      ),
      decoration: BoxDecoration(
        gradient: isBot ? null : kUserGradient,
        color: isBot ? kSurface : null,
        borderRadius: BorderRadius.circular(12),
        border: isBot ? Border.all(color: kBrand.withOpacity(0.3)) : null,
      ),
      child: Center(
        child: Text(icon, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBrand.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(_selectedImage!.path,
                    width: 50, height: 50, fit: BoxFit.cover)
                : Image.file(_selectedImage!,
                    width: 50, height: 50, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('عکس انتخاب شد',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text('آماده ارسال',
                    style: TextStyle(color: kTextDim, fontSize: 10.5)),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearImage,
            icon: const Icon(Icons.close, color: kAccent2),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBg.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: kBrand.withOpacity(0.15)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBrand.withOpacity(0.2)),
              ),
              child: const Icon(Icons.image_outlined,
                  color: kBrand2, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kBrand.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'پیامت رو بنویس...',
                  hintStyle: TextStyle(color: kMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _isLoading ? null : _send,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: kUserGradient,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: kBrand.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== AI THINKING SCREEN ====================
class AIThinkingScreen extends StatefulWidget {
  const AIThinkingScreen({super.key});

  @override
  State<AIThinkingScreen> createState() => _AIThinkingScreenState();
}

class _AIThinkingScreenState extends State<AIThinkingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _progressCtrl;

  int _msgIndex = 0;
  Timer? _msgTimer;

  final List<String> _messages = [
    'در حال پردازش درخواست شما...',
    'در حال جستجو در دانش...',
    'در حال ساخت پاسخ...',
    'تقریباً آماده‌ست...',
  ];

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _msgTimer = Timer.periodic(const Duration(milliseconds: 1200), (t) {
      if (!mounted) return;
      setState(() {
        _msgIndex = (_msgIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBg.withOpacity(0.97),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(4, (i) {
                          final sizes = [70.0, 90.0, 110.0, 130.0];
                          final colors = [kBrand, kAccent, kAccent2, kBrand2];
                          return AnimatedBuilder(
                            animation: _rotateCtrl,
                            builder: (_, __) {
                              final dir = i.isEven ? 1 : -1;
                              return Transform.rotate(
                                angle:
                                    _rotateCtrl.value * 2 * math.pi * dir,
                                child: Container(
                                  width: sizes[i],
                                  height: sizes[i],
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        colors[i].withOpacity(0.9),
                                        colors[i].withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) {
                            final scale = 1.0 + (_pulseCtrl.value * 0.1);
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: kGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: kBrand.withOpacity(
                                          0.7 + (_pulseCtrl.value * 0.3)),
                                      blurRadius:
                                          50 + (_pulseCtrl.value * 30),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        ...List.generate(6, (i) {
                          final angle = (i * 60) * math.pi / 180;
                          final colors = [
                            kAccent,
                            kBrand2,
                            kAccent2,
                            kAccent,
                            kBrand2,
                            kAccent2,
                          ];
                          return Transform.translate(
                            offset: Offset(
                              math.cos(angle) * 75,
                              math.sin(angle) * 75,
                            ),
                            child: AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (_, __) {
                                return Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colors[i],
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors[i],
                                        blurRadius:
                                            10 + (_pulseCtrl.value * 8),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ShaderMask(
                    shaderCallback: (r) => kGradient.createShader(r),
                    child: const Text(
                      'هوشیار در حال فکر کردن...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _messages[_msgIndex],
                      key: ValueKey(_msgIndex),
                      style: const TextStyle(
                        fontSize: 13,
                        color: kTextDim,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 240,
                    height: 3,
                    decoration: BoxDecoration(
                      color: kBrand.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (_, __) {
                          return Align(
                            alignment: Alignment(
                              -1.0 + (_progressCtrl.value * 2.5),
                              0,
                            ),
                            child: Container(
                              width: 60,
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: kGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: kBrand.withOpacity(0.8),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) {
                            final delay = i * 0.15;
                            final value = ((_pulseCtrl.value - delay) % 1.0)
                                .clamp(0.0, 1.0);
                            final translateY = value < 0.5
                                ? -8 * (value * 2)
                                : -8 * ((1 - value) * 2);
                            return Transform.translate(
                              offset: Offset(0, translateY),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: kBrand2,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: kBrand2.withOpacity(0.8),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: _buildAdBanner(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تبلیغات',
                style: TextStyle(
                  fontSize: 9,
                  color: kMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kBrand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: kBrand.withOpacity(0.15)),
                ),
                child: const Text(
                  'حمایت شده',
                  style: TextStyle(fontSize: 9, color: kMuted),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1A1F3A),
                Color(0xFF2A1F4A),
                Color(0xFF1A2A4A)
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBrand.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kAccent2, Color(0xFFFF8866)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kAccent2.withOpacity(0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎁', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'پیشنهاد ویژه امروز',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kAccent2, Color(0xFFFF8866)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '٪۵۰ تخفیف',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'با کلیک روی این بنر، از تخفیف‌های ویژه بهره‌مند شوید',
                      style: TextStyle(fontSize: 10.5, color: kTextDim),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kBrand.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBrand.withOpacity(0.4)),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: kBrand2,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== PULSE DOT ====================
class PulseDot extends StatefulWidget {
  const PulseDot({super.key});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFF00FF88),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF88).withOpacity(
                0.5 + (_ctrl.value * 0.5),
              ),
              blurRadius: 8 + (_ctrl.value * 8),
              spreadRadius: _ctrl.value * 3,
            ),
          ],
        ),
      ),
    );
  }
}