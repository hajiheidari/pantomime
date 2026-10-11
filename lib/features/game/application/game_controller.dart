import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../words/domain/word_models.dart';
import '../../words/domain/word_picker.dart';
import '../../words/words_providers.dart';
import '../domain/game_config.dart';
import '../domain/game_state.dart';
import 'feedback_service.dart';

enum GamePhase {
  ready,

  /// Forehead mode only: waiting for the phone to be held still on the
  /// forehead to record the neutral tilt.
  calibrating,
  countdown,
  playing,
  summary,
  scoreboard,
  finished,
}

/// Everything the game screens render: the pure [GameState] plus the live
/// state of the turn being played.
class GameSession {
  const GameSession({
    required this.game,
    required this.phase,
    this.countdown = 3,
    this.remainingSeconds = 0,
    this.currentWord,
    this.results = const [],
    this.passesUsed = 0,
    this.paused = false,
    this.tiltBaseline = 0,
    this.changesUsed = const [],
    this.customWord,
  });

  final GameState game;
  final GamePhase phase;
  final int countdown;
  final int remainingSeconds;
  final WordEntry? currentWord;
  final List<WordResult> results;
  final int passesUsed;
  final bool paused;

  /// Forehead mode: calibrated neutral pitch (degrees).
  final double tiltBaseline;

  /// Classic mode: word swaps used by each team so far in this game.
  final List<int> changesUsed;

  /// Classic mode: a word the other team typed for the next turn.
  final WordEntry? customWord;

  GameConfig get config => game.config;
  bool get isForehead => config.mode == GameMode.forehead;
  bool get isClassic => config.mode == GameMode.classic;

  /// Classic mode: word swaps the current team has left.
  int get changesLeft {
    final team = game.currentTeamIndex;
    final used = team < changesUsed.length ? changesUsed[team] : 0;
    return (config.wordChanges - used).clamp(0, config.wordChanges);
  }

  /// Passes left this turn, `null` = unlimited.
  int? get passesLeft {
    final limit = config.passLimit;
    return limit == null ? null : (limit - passesUsed).clamp(0, limit);
  }

  bool get canPass => passesLeft == null || passesLeft! > 0;

  int get correctCount => results.where((r) => r.isCorrect).length;

  /// Results of the last completed turn (for the summary screen).
  TurnRecord? get lastTurn => game.turns.isEmpty ? null : game.turns.last;

  GameSession copyWith({
    GameState? game,
    GamePhase? phase,
    int? countdown,
    int? remainingSeconds,
    WordEntry? Function()? currentWord,
    List<WordResult>? results,
    int? passesUsed,
    bool? paused,
    double? tiltBaseline,
    List<int>? changesUsed,
    WordEntry? Function()? customWord,
  }) => GameSession(
    game: game ?? this.game,
    phase: phase ?? this.phase,
    countdown: countdown ?? this.countdown,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    currentWord: currentWord != null ? currentWord() : this.currentWord,
    results: results ?? this.results,
    passesUsed: passesUsed ?? this.passesUsed,
    paused: paused ?? this.paused,
    tiltBaseline: tiltBaseline ?? this.tiltBaseline,
    changesUsed: changesUsed ?? this.changesUsed,
    customWord: customWord != null ? customWord() : this.customWord,
  );
}

final gameControllerProvider = NotifierProvider<GameController, GameSession?>(
  GameController.new,
);

/// Drives a game: countdown, turn timer, word picking, scoring, turn order.
/// `state == null` means no game is running.
class GameController extends Notifier<GameSession?> {
  static const warningSeconds = 10;

  Timer? _timer;
  WordPicker? _picker;
  List<WordCategory> _categories = const [];

  FeedbackService get _feedback => ref.read(feedbackProvider);

  @override
  GameSession? build() {
    ref.onDispose(_cancelTimer);
    return null;
  }

  /// Starts a new game with [config] using the words of [categories].
  void startGame(GameConfig config, List<WordCategory> categories) {
    _cancelTimer();
    _categories = categories;
    final selected = config.categoryIds.isEmpty
        ? categories
        : categories.where((c) => config.categoryIds.contains(c.id));
    final pool = [
      for (final c in selected) ...c.wordsFor(config.difficulty.levels),
    ];

    final lang = ref.read(languageCodeProvider);
    final store = ref.read(seenWordsStoreProvider);
    _picker = WordPicker(
      pool: pool,
      seen: store.load(lang),
      onSeenChanged: (seen) => store.save(lang, seen),
    );
    state = GameSession(
      game: GameState.start(config),
      phase: GamePhase.ready,
      changesUsed: List.filled(config.teamCount, 0),
    );
  }

  /// Same settings, fresh scores.
  void restart() {
    final s = state;
    if (s != null) startGame(s.config, _categories);
  }

  void quit() {
    _cancelTimer();
    _picker = null;
    state = null;
  }

  // ---- Turn flow -----------------------------------------------------------

  /// Classic mode, ready screen: the other team gives the next word
  /// (empty text clears it, so the app picks one again).
  void setCustomWord(String text) {
    final s = state;
    if (s == null || !s.isClassic || s.phase != GamePhase.ready) return;
    final t = text.trim();
    state = s.copyWith(customWord: () => t.isEmpty ? null : _custom(t));
  }

  static WordEntry _custom(String text) => WordEntry(
    text: text.trim(),
    categoryId: customCategoryId,
    difficulty: Difficulty.medium,
  );

  static const customCategoryId = 'custom';

  /// "Start" on the ready screen: forehead mode calibrates first.
  void startTurn() {
    final s = state;
    if (s == null || s.phase != GamePhase.ready) return;
    if (s.isForehead) {
      state = s.copyWith(phase: GamePhase.calibrating);
    } else {
      beginCountdown();
    }
  }

  /// Forehead mode: the phone is on the forehead; remember the neutral tilt
  /// and start the countdown.
  void calibrated(double baseline) {
    final s = state;
    if (s == null || s.phase != GamePhase.calibrating) return;
    state = s.copyWith(tiltBaseline: baseline);
    beginCountdown();
  }

  /// 3-2-1 countdown, from the ready screen or after calibration.
  void beginCountdown() {
    final s = state;
    if (s == null ||
        (s.phase != GamePhase.ready && s.phase != GamePhase.calibrating)) {
      return;
    }
    state = s.copyWith(phase: GamePhase.countdown, countdown: 3);
    _feedback.countdown();
    _cancelTimer();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _countdownTick(),
    );
  }

  void _countdownTick() {
    final s = state;
    if (s == null || s.phase != GamePhase.countdown) return _cancelTimer();
    if (s.countdown > 1) {
      state = s.copyWith(countdown: s.countdown - 1);
      _feedback.countdown();
    } else {
      _feedback.go();
      _startTurn();
    }
  }

  void _startTurn() {
    _cancelTimer();
    final s = state!;
    state = s.copyWith(
      phase: GamePhase.playing,
      remainingSeconds: s.config.roundSeconds,
      currentWord: () => s.customWord ?? _picker?.next(),
      customWord: () => null,
      results: const [],
      passesUsed: 0,
      paused: false,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _turnTick());
  }

  void _turnTick() {
    final s = state;
    if (s == null || s.phase != GamePhase.playing) return _cancelTimer();
    if (s.paused) return;
    final left = s.remainingSeconds - 1;
    if (left <= 0) {
      state = s.copyWith(remainingSeconds: 0);
      _endTurn();
      return;
    }
    state = s.copyWith(remainingSeconds: left);
    if (left <= warningSeconds) _feedback.tick();
  }

  /// Speed mode: next word. Classic mode: the team guessed it, turn over.
  void markCorrect() {
    final s = state;
    if (s != null && s.isClassic) return _finishClassic(WordOutcome.correct);
    _answer(WordOutcome.correct);
  }

  /// Classic mode: swap the word (limited per team for the whole game).
  /// [typed]: the other team's new word (when they gave the first one).
  void changeWord([String? typed]) {
    final s = state;
    if (s == null ||
        !s.isClassic ||
        s.phase != GamePhase.playing ||
        s.paused ||
        s.changesLeft <= 0) {
      return;
    }
    final team = s.game.currentTeamIndex;
    final used = [...s.changesUsed];
    while (used.length <= team) {
      used.add(0);
    }
    used[team]++;
    _feedback.pass();
    state = s.copyWith(
      changesUsed: used,
      currentWord: () => typed != null && typed.trim().isNotEmpty
          ? _custom(typed)
          : _picker?.next() ?? s.currentWord,
    );
  }

  void markPass() {
    final s = state;
    if (s == null || !s.canPass) return;
    _answer(WordOutcome.passed);
  }

  /// Classic mode: the team gives up on the word; the turn ends now
  /// instead of waiting for the clock.
  void giveUp() {
    final s = state;
    if (s != null && s.isClassic) _finishClassic(WordOutcome.passed);
  }

  void _finishClassic(WordOutcome outcome) {
    final s = state;
    if (s == null || s.phase != GamePhase.playing || s.paused) return;
    final word = s.currentWord;
    if (outcome == WordOutcome.correct) _feedback.correct();
    state = s.copyWith(
      results: [if (word != null) WordResult(word, outcome)],
      currentWord: () => null,
    );
    _endTurn();
  }

  void _answer(WordOutcome outcome) {
    final s = state;
    final word = s?.currentWord;
    if (s == null || s.phase != GamePhase.playing || s.paused || word == null) {
      return;
    }
    outcome == WordOutcome.correct ? _feedback.correct() : _feedback.pass();
    state = s.copyWith(
      results: [...s.results, WordResult(word, outcome)],
      passesUsed: s.passesUsed + (outcome == WordOutcome.passed ? 1 : 0),
      currentWord: () => _picker?.next(),
    );
  }

  /// Pauses the running turn. During the 3-2-1 countdown (e.g. the app goes
  /// to the background) the countdown is cancelled and the team is back on
  /// the ready screen, so a turn never starts unseen.
  void setPaused(bool paused) {
    final s = state;
    if (s == null) return;
    if (paused && s.phase == GamePhase.countdown) {
      _cancelTimer();
      state = s.copyWith(phase: GamePhase.ready);
      return;
    }
    if (s.phase != GamePhase.playing || s.paused == paused) return;
    state = s.copyWith(paused: paused);
  }

  void _endTurn() {
    _cancelTimer();
    final s = state!;
    final results = [
      ...s.results,
      if (s.currentWord != null)
        WordResult(s.currentWord!, WordOutcome.timeout),
    ];
    _feedback.roundEnd();
    state = s.copyWith(
      game: s.game.completeTurn(results),
      phase: GamePhase.summary,
      currentWord: () => null,
      results: const [],
    );
  }

  // ---- Between turns -------------------------------------------------------

  /// Fixes a mistake in the just-finished turn.
  void toggleSummaryWord(int wordIndex) {
    final s = state;
    if (s == null || s.phase != GamePhase.summary) return;
    state = s.copyWith(
      game: s.game.toggleResult(s.game.turns.length - 1, wordIndex),
    );
  }

  void confirmSummary() {
    final s = state;
    if (s == null || s.phase != GamePhase.summary) return;
    state = s.copyWith(phase: GamePhase.scoreboard);
  }

  /// Goes to the next team's turn or to the final result.
  ///
  /// This is the (only) safe point for interstitial ads, added in M3.
  void nextTurn() {
    final s = state;
    if (s == null || s.phase != GamePhase.scoreboard) return;
    final game = s.game.advance();
    if (game.finished) _feedback.win();
    state = s.copyWith(
      game: game,
      phase: game.finished ? GamePhase.finished : GamePhase.ready,
    );
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
