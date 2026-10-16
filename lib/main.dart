import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapsell_plus/tapsell_plus.dart';
import 'package:uuid/uuid.dart';

// 🌐 آدرس Worker
const String API_URL = 'https://ai-assistant.amirali6281387.workers.dev';

// 🎯 Tapsell
const String TAPSELL_API_KEY = 'sdsdftnpetlllqqsogjrsfkpeokciqtbgkdisnlflekdmqoadhdojfnpsfjdssljnjhfba';
const String TAPSELL_BANNER_ZONE = '6ad24575949be22d4df3a662';
const String TAPSELL_INTERSTITIAL_ZONE = '6ad246e89140ba2215e772df';
const String TAPSELL_REWARDED_ZONE = '6ad247169140ba2215e772e0';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // راه‌اندازی Tapsell
  try {
    await TapsellPlus.instance.initialize(TAPSELL_API_KEY);
    if (kDebugMode) {
      TapsellPlus.instance.setDebugMode(LogLevel.Debug);
    }
  } catch (e) {
    if (kDebugMode) print('Tapsell init error: $e');
  }

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

    // نمایش Interstitial بعد از اسپلش
    _showInterstitial();

    if (!mounted) return;
    setState(() => stage = seen ? 2 : 1);
  }

  // 🎯 نمایش تبلیغ آنی (Interstitial) - API نسخه 2.x
  Future<void> _showInterstitial() async {
    try {
      final responseId = await TapsellPlus.instance
          .requestInterstitialAd(TAPSELL_INTERSTITIAL_ZONE);
      
      await TapsellPlus.instance.showInterstitialAd(
        responseId,
        onOpened: (map) {
          if (kDebugMode) print('Interstitial opened');
        },
        onClosed: (map) {
          if (kDebugMode) print('Interstitial closed');
        },
        onError: (map) {
          if (kDebugMode) print('Interstitial error: ${map['error_message']}');
        },
      );
    } catch (e) {
      if (kDebugMode) print('Interstitial exception: $e');
    }
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
// (کد SplashScreen بدون تغییر - از پیام قبلی کپی کن)
// ==================== ONBOARDING ====================
// (کد OnboardingScreen بدون تغییر - از پیام قبلی کپی کن)

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
  int _remaining = 25;
  int _currentLimit = 25;
  int _videosWatched = 0;
  int _maxVideos = 5;

  // 🎯 Banner responseId
  String? _bannerResponseId;

  @override
  void initState() {
    super.initState();
    _initDeviceId();
    _loadHistory();
    // پیش‌بارگذاری بنر
    _requestBannerAd();
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

  // 🎯 درخواست بنر تبلیغاتی - API نسخه 2.x
  Future<void> _requestBannerAd() async {
    try {
      final responseId = await TapsellPlus.instance.requestStandardBannerAd(
        TAPSELL_BANNER_ZONE,
        TapsellPlusBannerType.BANNER_320x50,
        onResponse: (map) {
          if (kDebugMode) print('Banner response: $map');
        },
        onError: (map) {
          if (kDebugMode) print('Banner error: $map');
        },
      );
      if (mounted) setState(() => _bannerResponseId = responseId);
    } catch (e) {
      if (kDebugMode) print('Banner exception: $e');
    }
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
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 40,
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

  // 🎯 نمایش تبلیغ ویدیویی جایزه‌ای - API نسخه 2.x
  Future<void> _showRewardedVideo() async {
    try {
      final responseId = await TapsellPlus.instance
          .requestRewardedVideoAd(TAPSELL_REWARDED_ZONE);

      await TapsellPlus.instance.showRewardedVideoAd(
        responseId,
        onOpened: (map) {
          if (kDebugMode) print('Rewarded video opened');
        },
        onRewarded: (map) {
          // کاربر ویدیو رو کامل دید
          _claimReward();
        },
        onClosed: (map) {
          if (kDebugMode) print('Rewarded video closed');
        },
        onError: (map) {
          _showToast('⚠️ خطا در نمایش ویدیو');
        },
      );
    } catch (e) {
      _showToast('⚠️ خطا در بارگذاری ویدیو');
    }
  }

  Future<void> _claimReward() async {
    try {
      final res = await http.post(
        Uri.parse(API_URL),
        headers: {
          'Content-Type': 'application/json',
          'X-Device-ID': _deviceId,
        },
        body: jsonEncode({'action': 'reward'}),
      );

      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        setState(() {
          _currentLimit = data['newLimit'];
          _remaining = data['newLimit'];
          _videosWatched = data['videosWatched'];
        });
        _showToast('🎉 ${data['message']}');
      } else {
        _showToast('⚠️ ${data['message']}');
      }
    } catch (e) {
      _showToast('❌ خطا در ارتباط با سرور');
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
          _currentLimit = data['currentLimit'] ?? _currentLimit;
          _videosWatched = data['videosWatched'] ?? _videosWatched;
          _maxVideos = data['maxVideos'] ?? 5;
        });

        if (data['canWatchAd'] == true) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _showRewardDialog();
          });
        }
      } else if (data['response'] != null &&
          data['response'].toString().isNotEmpty) {
        setState(() {
          _messages.add(Message(text: data['response'], isUser: false));
          _remaining = data['remaining'] ?? _remaining - 1;
          _currentLimit = data['currentLimit'] ?? _currentLimit;
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

  void _showRewardDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0A0E27),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: kBrand.withOpacity(0.5)),
          ),
          content: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5C8A), Color(0xFFFF8866)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kAccent2.withOpacity(0.5),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎬', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '🎁 ۱۰۰ پیام هدیه بگیر!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'یه ویدیو ۳۰ ثانیه‌ای ببین و ۱۰۰ پیام اضافی بگیر!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextDim, fontSize: 13, height: 1.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'ویدیوهای دیده‌شده: $_videosWatched / $_maxVideos',
                  style: const TextStyle(color: kMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('بعداً',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showRewardedVideo();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('تماشای ویدیو'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showToast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: kBrand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
              '$_remaining از $_currentLimit',
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

// ==================== AI THINKING + BANNER ====================
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
  String? _bannerResponseId;

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

    // 🎯 درخواست بنر
    _requestBannerAd();
  }

  // 🎯 API نسخه 2.x برای بنر
  Future<void> _requestBannerAd() async {
    try {
      await TapsellPlus.instance.requestStandardBannerAd(
        TAPSELL_BANNER_ZONE,
        TapsellPlusBannerType.BANNER_320x50,
        onResponse: (map) {
          if (mounted) {
            setState(() => _bannerResponseId = map['response_id']);
          }
        },
        onError: (map) {
          if (kDebugMode) print('Banner error: ${map['error_message']}');
        },
      );
    } catch (e) {
      if (kDebugMode) print('Banner exception: $e');
    }
  }

  // 🎯 نمایش بنر
  Future<void> _showBanner() async {
    if (_bannerResponseId == null) return;
    try {
      await TapsellPlus.instance.showStandardBannerAd(
        _bannerResponseId!,
        TapsellPlusHorizontalGravity.BOTTOM,
        TapsellPlusVerticalGravity.CENTER,
        margin: const EdgeInsets.only(bottom: 20),
        onOpened: (map) {},
        onError: (map) {},
      );
    } catch (e) {
      if (kDebugMode) print('Show banner error: $e');
    }
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    // 🎯 پاک کردن بنر
    if (_bannerResponseId != null) {
      TapsellPlus.instance.destroyStandardBanner(_bannerResponseId!);
    }
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
                  // ... انیمیشن مغز AI (بدون تغییر)
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
            // 🎯 بنر تبلیغاتی (جایگاه رزرو شده)
            Container(
              height: 60,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBrand.withOpacity(0.3)),
              ),
              child: _bannerResponseId != null
                  ? const Center(
                      child: Text(
                        'بنر در حال نمایش',
                        style: TextStyle(color: kTextDim, fontSize: 10),
                      ),
                    )
                  : const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kBrand2,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
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