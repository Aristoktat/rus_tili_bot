// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found: $e");
  }
  runApp(const RusTiliApp());
}

class RusTiliApp extends StatelessWidget {
  const RusTiliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LessonController()),
      ],
      child: MaterialApp(
        title: 'Rus Tili AI Ustoz',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          fontFamily: 'Roboto',
        ),
        home: const LessonWrapper(),
      ),
    );
  }
}

// ------------------- LOGIKA (CONTROLLER) -------------------

enum LessonStep { vocabulary, writing, reading, grammar, aiChat, mistakes, roleplay, dailyChallenge }

class LessonController extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  GenerativeModel? _model;

  // State
  LessonStep _currentStep = LessonStep.vocabulary;
  int _currentStepIndex = 0;
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastRecognizedWords = "";
  String _feedbackMessage = "";
  final TextEditingController textInputController = TextEditingController();
  
  // Data Storage
  final List<Map<String, String>> _chatMessages = [];
  final List<String> _myMistakes = [];
  final List<String> _dailyTask = ["Bugun 3 ta yangi sifat o'rganing va ularni gapda ishlating."];
  
  // Getters
  LessonStep get currentStep => _currentStep;
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get recognizedWords => _lastRecognizedWords;
  String get feedbackMessage => _feedbackMessage;
  List<Map<String, String>> get chatMessages => _chatMessages;
  List<String> get myMistakes => _myMistakes;
  String get dailyChallenge => _dailyTask.first;

  // Dars Ma'lumotlari
  final String lessonTopic = "Tanishuv (Знакомство)";
  
  final Map<String, String> vocabulary = {
    "Привет": "Salom",
    "Как дела?": "Ishlaring qalay?",
    "Меня зовут...": "Mening ismim...",
    "Я из Узбекистана": "Men O'zbekistondanman",
    "Приятно познакомиться": "Tanishganimdan xursandman",
  };

  final String dictationSentence = "Меня зовут Анвар я из Ташкента"; 
  final String readingText = "Здравствуйте. Меня зовут Азиз. Я люблю изучать русский язык.";

  final List<String> grammarWords = ["Я", "студент", "хороший"];
  final String grammarCorrectAnswer = "Я хороший студент";
  
  // Roleplay Scenarios
  final List<String> roleplayScenarios = ["Do'konda", "Takside", "Restoranda", "Mehmonxonada"];
  // String _currentRoleplayScenario = "";

  LessonController() {
    _initTts();
    _initGemini();
  }

  Future<void> _initGemini() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null) {
      _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ru-RU");
  }

  void changeStep(int index) {
    if (index >= 0 && index < LessonStep.values.length) {
      _currentStepIndex = index;
      _currentStep = LessonStep.values[index];
      _feedbackMessage = "";
      _lastRecognizedWords = "";
      textInputController.clear();
      notifyListeners();
    }
  }

  void nextStep() {
    changeStep(_currentStepIndex + 1);
  }

  // --- TTS ---
  Future<void> speak(String text) async {
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.speak(text);
  }

  // --- STT (Eshitish) ---
  Future<void> startListening({String? expectedText}) async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    bool available = await _speech.initialize();
    if (available) {
      _isListening = true;
      _lastRecognizedWords = "";
      notifyListeners();

      _speech.listen(
        onResult: (result) {
          _lastRecognizedWords = result.recognizedWords;
          notifyListeners();
          
          if (result.finalResult) {
             _isListening = false;
             if (expectedText != null) {
               _checkPronunciation(expectedText, _lastRecognizedWords);
             }
             notifyListeners();
          }
        },
        localeId: 'ru_RU',
      );
    }
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  // --- 1. Yodlash Logikasi ---
  // UI da shunchaki speak() chaqiriladi.

  // --- 2. Yozish (Diktant) Logikasi ---
  void checkDictation() {
    String userInput = textInputController.text.trim().toLowerCase();
    String target = dictationSentence.toLowerCase();
    
    // Oddiy solishtirish algoritm (tinish belgilarni olib tashlaymiz)
    userInput = userInput.replaceAll(RegExp(r'[^\w\s]'), '');
    target = target.replaceAll(RegExp(r'[^\w\s]'), '');

    if (userInput == target) {
      _feedbackMessage = "✅ To'g'ri! Ofarin.";
    } else {
      _feedbackMessage = "❌ Xato. To'g'ri javob: $dictationSentence";
    }
    notifyListeners();
  }

  // --- 3. O'qish Logikasi ---
  void _checkPronunciation(String target, String actual) {
    // Bu yerda oddiy solishtirish yoki Levenshtein distance ishlatish mumkin.
    // Biz soddalashtirib, so'zlar sonini tekshiramiz.
    if (actual.toLowerCase().contains("меня зовут")) {
       _feedbackMessage = "✅ Yaxshi o'qidingiz! ($actual)";
    } else {
       _feedbackMessage = "⚠️ Biroz xato. Qayta urinib ko'ring.\nEshitildi: $actual";
    }
    notifyListeners();
  }

  // --- 4. Gap tuzish Logikasi ---
  void checkGrammar() {
     if (textInputController.text.trim() == grammarCorrectAnswer) {
       _feedbackMessage = "✅ Barakalla! Gap to'g'ri tuzildi.";
     } else {
       _feedbackMessage = "❌ Noto'g'ri.";
     }
     notifyListeners();
  }

  // --- 5. AI Chat Logikasi ---
  Future<void> sendMessageToAI(String message) async {
    if (message.isEmpty) return;
    
    _chatMessages.add({"role": "user", "text": message});
    _isProcessing = true;
    notifyListeners();
    textInputController.clear();

    try {
      if (_model == null) throw Exception("API Key not found");
      
      final prompt = "Sen rus tili o'qituvchisisan. Bugungi mavzu: Tanishtiruv. Foydalanuvchi bilan shu mavzuda suhbatlash. Xatolarini tuzat. Javobing rus tilida bo'lsin. Foydalanuvchi: $message";
      
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final aiResponse = response.text ?? "Tushunmadim...";

      _chatMessages.add({"role": "ai", "text": aiResponse});
      speak(aiResponse); // Javobni o'qib berish
    } catch (e) {
      _chatMessages.add({"role": "ai", "text": "Xatolik: $e"});
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}

// ------------------- UI (KORINISH) -------------------

class LessonWrapper extends StatelessWidget {
  const LessonWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = context.watch<LessonController>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Rus Tili: ${controller.lessonTopic}"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                _buildStepChip(context, 0, "1. Yodlash", Icons.book),
                _buildStepChip(context, 1, "2. Yozish", Icons.edit),
                _buildStepChip(context, 2, "3. O'qish", Icons.mic),
                _buildStepChip(context, 3, "4. Grammatika", Icons.extension),
                _buildStepChip(context, 4, "5. AI Suhbat", Icons.chat_bubble),
                _buildStepChip(context, 5, "Xtolar", Icons.error_outline),
                _buildStepChip(context, 6, "Rolli O'yin", Icons.theater_comedy),
                _buildStepChip(context, 7, "Kunlik", Icons.calendar_today),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCurrentStep(controller),
      ),
    );
  }

  Widget _buildStepChip(BuildContext context, int index, String label, IconData icon) {
    var controller = context.watch<LessonController>();
    bool isActive = controller._currentStepIndex == index;
    return GestureDetector(
      onTap: () => controller.changeStep(index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.teal : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : Colors.black54),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(LessonController controller) {
    switch (controller.currentStep) {
      case LessonStep.vocabulary: return VocabularyStep(controller);
      case LessonStep.writing:    return WritingStep(controller);
      case LessonStep.reading:    return ReadingStep(controller);
      case LessonStep.grammar:    return GrammarStep(controller);
      case LessonStep.aiChat:     return AIChatStep(controller);
      case LessonStep.mistakes:   return MistakesStep(controller);
      case LessonStep.roleplay:   return RoleplayStep(controller);
      case LessonStep.dailyChallenge: return DailyChallengeStep(controller);
    }
  }
}

// --- STEP 1: Yodlash ---
class VocabularyStep extends StatelessWidget {
  final LessonController controller;
  const VocabularyStep(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Yangi so'zlarni tinglang va takrorlang:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: controller.vocabulary.entries.map((entry) {
              return Card(
                child: ListTile(
                  title: Text(entry.key, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  subtitle: Text(entry.value, style: const TextStyle(fontSize: 16)),
                  trailing: IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.teal),
                    onPressed: () => controller.speak(entry.key),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        ElevatedButton(
          onPressed: controller.nextStep,
          child: const Text("Keyingi bosqich"),
        )
      ],
    );
  }
}

// --- STEP 2: Yozish (Diktant) ---
class WritingStep extends StatelessWidget {
  final LessonController controller;
  const WritingStep(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Diktant yozish vaqti!", style: TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        IconButton(
          icon: const Icon(Icons.play_circle_fill, size: 60, color: Colors.teal),
          onPressed: () => controller.speak(controller.dictationSentence),
        ),
        const Text("Tugmani bosib, eshitgan gapingizni yozing:"),
        const SizedBox(height: 20),
        TextField(
          controller: controller.textInputController,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Shu yerga yozing..."),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: controller.checkDictation,
          child: const Text("Tekshirish"),
        ),
        const SizedBox(height: 20),
        Text(controller.feedbackMessage, style: const TextStyle(fontSize: 18, color: Colors.blueAccent)),
      ],
    );
  }
}

// --- STEP 3: O'qish ---
class ReadingStep extends StatelessWidget {
  final LessonController controller;
  const ReadingStep(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Matnni ovoz chiqarib o'qing:", style: TextStyle(fontSize: 18)),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(10)),
          child: Text(controller.readingText, style: const TextStyle(fontSize: 22, color: Colors.black87)),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            if (controller.isListening) {
              controller.stopListening();
            } else {
              controller.startListening(expectedText: controller.readingText);
            }
          },
          child: CircleAvatar(
            radius: 40,
            backgroundColor: controller.isListening ? Colors.red : Colors.teal,
            child: Icon(controller.isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 20),
        Text("Eshitildi: ${controller.recognizedWords}", style: const TextStyle(fontStyle: FontStyle.italic)),
        const SizedBox(height: 10),
        Text(controller.feedbackMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// --- STEP 4: Grammatika ---
class GrammarStep extends StatelessWidget {
  final LessonController controller;
  const GrammarStep(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("So'zlardan to'g'ri gap tuzing:", style: TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          children: controller.grammarWords.map((word) => Chip(label: Text(word))).toList(),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller.textInputController,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Javobingiz..."),
        ),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: controller.checkGrammar, child: const Text("Tekshirish")),
        const SizedBox(height: 20),
        Text(controller.feedbackMessage, style: const TextStyle(fontSize: 18, color: Colors.green)),
      ],
    );
  }
}

// --- STEP 5: AI Suhbat ---
class AIChatStep extends StatelessWidget {
  final LessonController controller;
  const AIChatStep(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("AI bilan darsni mustahkamlang:", style: TextStyle(fontSize: 16)),
        Expanded(
          child: ListView.builder(
            itemCount: controller.chatMessages.length,
            itemBuilder: (ctx, i) {
              var msg = controller.chatMessages[i];
              bool isUser = msg['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(5),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.teal : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(msg['text']!, style: TextStyle(color: isUser ? Colors.white : Colors.black)),
                ),
              );
            },
          ),
        ),
        if (controller.isProcessing) const LinearProgressIndicator(),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.textInputController,
                decoration: const InputDecoration(hintText: "Xabar yozing...", border: OutlineInputBorder()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.teal),
              onPressed: () => controller.sendMessageToAI(controller.textInputController.text),
            ),
            IconButton(
              icon: const Icon(Icons.mic, color: Colors.teal),
              onPressed: () {
                // Bu yerda STT ni chat uchun ishlatish mumkin (kelajakda)
              },
            ),
          ],
        )
      ],
    );
  }
}

// --- STEP 6: Xatolar ---
class MistakesStep extends StatelessWidget {
  final LessonController controller;
  const MistakesStep(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Sizning Xatolaringiz:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        controller.myMistakes.isEmpty
            ? const Expanded(child: Center(child: Text("Hozircha xatolar yo'q! Ofarin! 🎉")))
            : Expanded(
                child: ListView.builder(
                  itemCount: controller.myMistakes.length,
                  itemBuilder: (ctx, i) {
                    return Card(
                      color: Colors.red[50],
                      child: ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text(controller.myMistakes[i]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () { 
                            controller.myMistakes.removeAt(i);
                            // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                            controller.notifyListeners(); 
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}

// --- STEP 7: Rolli O'yin ---
class RoleplayStep extends StatelessWidget {
  final LessonController controller;
  const RoleplayStep(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Rolli O'yin Tanlang:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: controller.roleplayScenarios.map((scenario) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ActionChip(
                  label: Text(scenario),
                  onPressed: () {
                    // controller._currentRoleplayScenario = scenario;
                    controller.changeStep(4); // Chatga o'tish
                    controller.sendMessageToAI("Biz hozir rolli o'yin o'ynaymiz. Vaziyat: $scenario. Sen sotuvchi/haydovchi/ofitsiant bo'l, men mijozman. O'yinni boshla.");
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(),
        const Expanded(child: Center(child: Text("O'yin tanlab, chatda davom eting!"))),
      ],
    );
  }
}

// --- STEP 8: Kunlik Chellenj ---
class DailyChallengeStep extends StatelessWidget {
  final LessonController controller;
  const DailyChallengeStep(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department, size: 60, color: Colors.orange),
              const SizedBox(height: 20),
              const Text("Bugungi Vazifa", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(controller.dailyChallenge, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  controller.changeStep(4); // Chatga o'tish
                  controller.sendMessageToAI("Men bugungi vazifani bajarmoqchiman: ${controller.dailyChallenge}");
                },
                child: const Text("Bajarish"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
