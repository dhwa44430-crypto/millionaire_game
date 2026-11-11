import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';

class GameProvider extends ChangeNotifier {
  final List<int> prizeLadder = [
    100, 200, 300, 500, 1000,       // المرحلة الأولى (المحطة الآمنة: 1,000)
    2000, 4000, 8000, 16000, 32000, // المرحلة الثانية (المحطة الآمنة: 32,000)
    64000, 125000, 250000, 500000, 1000000 // المرحلة الحاسمة: المليون
  ];

  List<Question> _questions = [];
  int _currentIndex = 0;
  bool _isGameOver = false;
  bool _isGameWon = false;
  int? _selectedAnswerIndex;
  bool _isAnswerConfirmed = false;

  // Lifelines
  bool fiftyFiftyUsed = false;
  bool audiencePollUsed = false;
  bool switchQuestionUsed = false;
  List<int> hiddenOptionIndices = [];

  // Countdown Timer
  Timer? _timer;
  int _remainingSeconds = 45;
  static const int questionTimeoutSeconds = 45;

  // Getters
  List<Question> get questions => _questions;
  int get currentIndex => _currentIndex;
  Question? get currentQuestion => _questions.isNotEmpty ? _questions[_currentIndex] : null;
  bool get isGameOver => _isGameOver;
  bool get isGameWon => _isGameWon;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get isAnswerConfirmed => _isAnswerConfirmed;
  int get currentPrize => _currentIndex > 0 ? prizeLadder[_currentIndex - 1] : 0;
  int get remainingSeconds => _remainingSeconds;

  int get guaranteedPrize {
    if (_currentIndex >= 10) return prizeLadder[9]; // 32,000
    if (_currentIndex >= 5) return prizeLadder[4];   // 1,000
    return 0;
  }

  Future<void> startNewGame() async {
    _currentIndex = 0;
    _isGameOver = false;
    _isGameWon = false;
    _selectedAnswerIndex = null;
    _isAnswerConfirmed = false;
    fiftyFiftyUsed = false;
    audiencePollUsed = false;
    switchQuestionUsed = false;
    hiddenOptionIndices.clear();

    final db = DatabaseHelper.instance;
    final easy = await db.getQuestionsByDifficulty(Difficulty.easy, 5);
    final medium = await db.getQuestionsByDifficulty(Difficulty.medium, 5);
    final hard = await db.getQuestionsByDifficulty(Difficulty.hard, 5);

    _questions = [...easy, ...medium, ...hard];
    resetTimer();
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _remainingSeconds = questionTimeoutSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _isGameOver = true;
        notifyListeners();
      }
    });
  }

  void selectOption(int index) {
    if (_isAnswerConfirmed || hiddenOptionIndices.contains(index)) return;
    _selectedAnswerIndex = index;
    notifyListeners();
  }

  Future<void> confirmAnswer() async {
    if (_selectedAnswerIndex == null || _isAnswerConfirmed) return;
    _isAnswerConfirmed = true;
    _timer?.cancel();
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));

    if (_selectedAnswerIndex == currentQuestion!.correctIndex) {
      if (_currentIndex == prizeLadder.length - 1) {
        _isGameWon = true;
      } else {
        _currentIndex++;
        _selectedAnswerIndex = null;
        _isAnswerConfirmed = false;
        hiddenOptionIndices.clear();
        resetTimer();
      }
    } else {
      _isGameOver = true;
    }
    notifyListeners();
  }

  // Lifeline 1: Fifty-Fifty (حذف إجابتين)
  void useFiftyFifty() {
    if (fiftyFiftyUsed || _isAnswerConfirmed || currentQuestion == null) return;
    fiftyFiftyUsed = true;
    final correct = currentQuestion!.correctIndex;
    final random = Random();
    List<int> incorrect = [];

    for (int i = 0; i < 4; i++) {
      if (i != correct) incorrect.add(i);
    }
    incorrect.shuffle(random);
    hiddenOptionIndices = [incorrect[0], incorrect[1]];
    notifyListeners();
  }

  // Lifeline 2: Switch Question (تغيير السؤال)
  Future<void> useSwitchQuestion() async {
    if (switchQuestionUsed || _isAnswerConfirmed || currentQuestion == null) return;
    switchQuestionUsed = true;
    final diff = currentQuestion!.difficulty;
    final alternate = await DatabaseHelper.instance.getQuestionsByDifficulty(diff, 1);
    if (alternate.isNotEmpty) {
      _questions[_currentIndex] = alternate.first;
      hiddenOptionIndices.clear();
      _selectedAnswerIndex = null;
      resetTimer();
      notifyListeners();
    }
  }

  // Lifeline 3: Audience Poll percentages (رأي الجمهور)
  Map<int, int> getAudiencePollResults() {
    audiencePollUsed = true;
    notifyListeners();
    final correct = currentQuestion!.correctIndex;
    final random = Random();
    Map<int, int> distribution = {};

    int highPercent = 50 + random.nextInt(35); // 50% - 85% for correct option
    int remaining = 100 - highPercent;

    distribution[correct] = highPercent;

    List<int> otherIndices = [0, 1, 2, 3]..remove(correct);
    int p1 = random.nextInt(remaining);
    int p2 = random.nextInt(remaining - p1);
    int p3 = remaining - p1 - p2;

    distribution[otherIndices[0]] = p1;
    distribution[otherIndices[1]] = p2;
    distribution[otherIndices[2]] = p3;

    return distribution;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
