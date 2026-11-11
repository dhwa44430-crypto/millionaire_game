import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

enum Difficulty { easy, medium, hard }

class Question {
  final int? id;
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final Difficulty difficulty;
  final String category;

  Question({
    this.id,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'optA': options[0],
      'optB': options[1],
      'optC': options[2],
      'optD': options[3],
      'correctIndex': correctIndex,
      'difficulty': difficulty.index,
      'category': category,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      questionText: map['questionText'],
      options: [map['optA'], map['optB'], map['optC'], map['optD']],
      correctIndex: map['correctIndex'],
      difficulty: Difficulty.values[map['difficulty']],
      category: map['category'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quiz_master.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        questionText TEXT NOT NULL,
        optA TEXT NOT NULL,
        optB TEXT NOT NULL,
        optC TEXT NOT NULL,
        optD TEXT NOT NULL,
        correctIndex INTEGER NOT NULL,
        difficulty INTEGER NOT NULL,
        category TEXT NOT NULL
      )
    ''');
    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    final List<Question> sampleBank = [
      // Easy (سهل)
      Question(
        questionText: "ما هي عاصمة المملكة العربية السعودية؟",
        options: ["جدة", "الرياض", "الدمام", "مكة المكرمة"],
        correctIndex: 1,
        difficulty: Difficulty.easy,
        category: "جغرافيا",
      ),
      Question(
        questionText: "كم عدد سور القرآن الكريم؟",
        options: ["112", "113", "114", "115"],
        correctIndex: 2,
        difficulty: Difficulty.easy,
        category: "إسلاميات",
      ),
      Question(
        questionText: "ما هو العنصر الأكثر وفرة في الغلاف الجوي للأرض؟",
        options: ["الأكسجين", "النيتروجين", "الهيدروجين", "ثاني أكسيد الكربون"],
        correctIndex: 1,
        difficulty: Difficulty.easy,
        category: "علوم",
      ),
      Question(
        questionText: "في أي قارة تقع دولة مصر؟",
        options: ["آسيا", "إفريقيا", "أوروبا", "أمريكا الجنوبية"],
        correctIndex: 1,
        difficulty: Difficulty.easy,
        category: "جغرافيا",
      ),
      Question(
        questionText: "ما هو الحيوان المعروف بـ 'سفينة الصحراء'؟",
        options: ["الحصان", "الجمل", "الفيل", "الوعل"],
        correctIndex: 1,
        difficulty: Difficulty.easy,
        category: "طبيعة",
      ),
      // Medium (متوسط)
      Question(
        questionText: "من هو الشاعر الملقب بـ 'أمير الشعراء'؟",
        options: ["أحمد شوقي", "حافظ إبراهيم", "المتنبي", "نزار قباني"],
        correctIndex: 0,
        difficulty: Difficulty.medium,
        category: "أدب",
      ),
      Question(
        questionText: "في أي عام وقعت معركة حطين الشهيرة؟",
        options: ["1187م", "1192م", "1258م", "1099م"],
        correctIndex: 0,
        difficulty: Difficulty.medium,
        category: "تاريخ",
      ),
      Question(
        questionText: "ما هو الكوكب الأقرب حجماً إلى كوكب الأرض؟",
        options: ["المريخ", "عطارد", "الزهرة", "نبتون"],
        correctIndex: 2,
        difficulty: Difficulty.medium,
        category: "فلك",
      ),
      Question(
        questionText: "ما هي العملة الرسمية لدولة اليابان؟",
        options: ["اليوان", "الوون", "الين", "الروبية"],
        correctIndex: 2,
        difficulty: Difficulty.medium,
        category: "اقتصاد",
      ),
      Question(
        questionText: "من هو العالم العربي مؤسس علم الجبر؟",
        options: ["ابن الهيثم", "الخوارزمي", "ابن سينا", "الفارابي"],
        correctIndex: 1,
        difficulty: Difficulty.medium,
        category: "علوم",
      ),
      // Hard (صعب)
      Question(
        questionText: "ما هو الاسم القديم لمدينة إسطنبول قبل الفتح الإسلامي؟",
        options: ["القسطنطينية", "أنطاكية", "طرابزون", "نيقية"],
        correctIndex: 0,
        difficulty: Difficulty.hard,
        category: "تاريخ",
      ),
      Question(
        questionText: "من هو صاحب كتاب 'حي بن يقظان' في الفلسفة العربية؟",
        options: ["ابن طفيل", "ابن رشد", "الكندي", "الغزالي"],
        correctIndex: 0,
        difficulty: Difficulty.hard,
        category: "فلسفة وأدب",
      ),
      Question(
        questionText: "ما هو أعمق خندق محيطي على وجه الأرض؟",
        options: ["خندق بورتوريكو", "خندق ماريانا", "خندق جاوة", "خندق تونغا"],
        correctIndex: 1,
        difficulty: Difficulty.hard,
        category: "جغرافيا",
      ),
      Question(
        questionText: "ما هو المعدن الوحيد الذي يتواجد في الحالة السائلة بحرارة الغرفة؟",
        options: ["البروم", "الزئبق", "الجاليوم", "السيزيوم"],
        correctIndex: 1,
        difficulty: Difficulty.hard,
        category: "كيمياء",
      ),
      Question(
        questionText: "في أي سنة نال الأديب نجيب محفوظ جائزة نوبل للآداب؟",
        options: ["1985م", "1988م", "1990م", "1992م"],
        correctIndex: 1,
        difficulty: Difficulty.hard,
        category: "ثقافة عامة",
      ),
    ];

    for (var q in sampleBank) {
      await db.insert('questions', q.toMap());
    }
  }

  Future<List<Question>> getQuestionsByDifficulty(Difficulty diff, int limit) async {
    final db = await instance.database;
    final result = await db.query(
      'questions',
      where: 'difficulty = ?',
      whereArgs: [diff.index],
      orderBy: 'RANDOM()',
      limit: limit,
    );
    return result.map((json) => Question.fromMap(json)).toList();
  }
}
