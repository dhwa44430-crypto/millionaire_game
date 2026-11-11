import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'ad_service.dart';
import 'app_theme.dart';
import 'game_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _isBannerLoaded = false;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _showAudienceDialog(BuildContext context, Map<int, int> votes) {
    final letters = ['أ', 'ب', 'ج', 'د'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlue,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.metallicGold),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('تصويت الجمهور', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.metallicGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            final percent = votes[i] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Text('${letters[i]}: ', style: const TextStyle(color: AppTheme.metallicGold, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      color: AppTheme.metallicGold,
                      backgroundColor: Colors.white24,
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$percent%', style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تم', style: TextStyle(color: AppTheme.metallicGold)),
          )
        ],
      ),
    );
  }

  void _showLadderSheet(BuildContext context, GameProvider game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceBlue,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            reverse: true,
            shrinkWrap: true,
            itemCount: game.prizeLadder.length,
            itemBuilder: (context, idx) {
              final isCurrent = idx == game.currentIndex;
              final isMilestone = idx == 4 || idx == 9 || idx == 14;
              final isPassed = idx < game.currentIndex;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent ? AppTheme.metallicGold.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isCurrent ? Border.all(color: AppTheme.metallicGold) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('السؤال ${idx + 1}', style: TextStyle(color: isPassed ? Colors.grey : Colors.white)),
                    Text(
                      '${game.prizeLadder[idx]} \$',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMilestone ? AppTheme.metallicGold : (isPassed ? Colors.grey : Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    if (game.isGameOver || game.isGameWon) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AdService().showInterstitialAd(
          onAdClosed: () => _showGameOverDialog(context, game),
        );
      });
    }

    final question = game.currentQuestion;
    if (question == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: AppTheme.metallicGold),
            onPressed: () => _showLadderSheet(context, game),
          ),
        ],
        title: Text(
          'الجائزة: ${game.currentPrize} \$',
          style: const TextStyle(color: AppTheme.metallicGold, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Lifelines Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LifelineButton(
                    label: '50:50',
                    isUsed: game.fiftyFiftyUsed,
                    onTap: () => game.useFiftyFifty(),
                  ),
                  _LifelineButton(
                    label: 'الجمهور',
                    isUsed: game.audiencePollUsed,
                    onTap: () {
                      final results = game.getAudiencePollResults();
                      _showAudienceDialog(context, results);
                    },
                  ),
                  _LifelineButton(
                    label: 'تغيير',
                    isUsed: game.switchQuestionUsed,
                    onTap: () => game.useSwitchQuestion(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Circular Countdown Timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 55,
                  height: 55,
                  child: CircularProgressIndicator(
                    value: game.remainingSeconds / 45,
                    strokeWidth: 4,
                    color: game.remainingSeconds < 10 ? Colors.red : AppTheme.metallicGold,
                    backgroundColor: Colors.white12,
                  ),
                ),
                Text(
                  '${game.remainingSeconds}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                )
              ],
            ),
            const SizedBox(height: 20),
            // Question Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.metallicGold.withOpacity(0.7), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Text(
                  question.questionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 4 Options Grid/List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                itemBuilder: (ctx, idx) {
                  final isHidden = game.hiddenOptionIndices.contains(idx);
                  if (isHidden) return const SizedBox(height: 60);

                  final isSelected = game.selectedAnswerIndex == idx;
                  Color borderColor = AppTheme.metallicGold.withOpacity(0.5);
                  Color bgColor = AppTheme.surfaceBlue;

                  if (game.isAnswerConfirmed) {
                    if (idx == question.correctIndex) {
                      bgColor = AppTheme.correctGreen;
                      borderColor = Colors.white;
                    } else if (isSelected) {
                      bgColor = AppTheme.wrongRed;
                      borderColor = Colors.white;
                    }
                  } else if (isSelected) {
                    bgColor = AppTheme.deepGold;
                    borderColor = Colors.white;
                  }

                  final letters = ['أ', 'ب', 'ج', 'د'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => game.selectOption(idx),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${letters[idx]}: ',
                              style: const TextStyle(color: AppTheme.metallicGold, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Expanded(
                              child: Text(
                                question.options[idx],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Confirm Button
            if (game.selectedAnswerIndex != null && !game.isAnswerConfirmed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.metallicGold,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => game.confirmAnswer(),
                  child: const Text('تأكيد الإجابة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            // Bottom Google AdMob Banner
            if (_isBannerLoaded && _bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.metallicGold)),
        title: Text(
          game.isGameWon ? 'مبروك! لقد ربحت المليون' : 'للأسف انتهت اللعبة',
          textAlign: TextAlign.center,
          style: TextStyle(color: game.isGameWon ? AppTheme.metallicGold : AppTheme.wrongRed),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الرصيد المكتسب: ${game.isGameWon ? 1000000 : game.guaranteedPrize} \$', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.metallicGold, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(ctx);
                game.startNewGame();
              },
              child: const Text('العب مجدداً'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('العودة للقائمة الرئيسية', style: TextStyle(color: Colors.white70)),
            )
          ],
        ),
      ),
    );
  }
}

class _LifelineButton extends StatelessWidget {
  final String label;
  final bool isUsed;
  final VoidCallback onTap;

  const _LifelineButton({required this.label, required this.isUsed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUsed ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isUsed ? Colors.black38 : AppTheme.lightBlueCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isUsed ? Colors.white24 : AppTheme.metallicGold),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isUsed ? Colors.white30 : AppTheme.metallicGold,
            fontWeight: FontWeight.bold,
            decoration: isUsed ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
