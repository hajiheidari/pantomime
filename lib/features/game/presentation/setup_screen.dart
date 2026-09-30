import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cartoon.dart';
import '../../words/domain/word_models.dart';
import '../../words/words_providers.dart';
import '../application/game_controller.dart';
import '../domain/game_config.dart';
import 'game_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  String get _prefsKey => 'last_setup_${widget.mode.name}';
  bool get _forehead => widget.mode == GameMode.forehead;
  int get _min => GameConfig.minTeams(widget.mode);
  int get _max => GameConfig.maxTeams(widget.mode);

  late GameConfig _config;
  final List<TextEditingController> _names = [];

  /// `null` until categories load; then the explicit selection.
  Set<String>? _selected;
  Set<String> _savedCategoryIds = {};

  AppStrings get _s => ref.read(stringsProvider);

  @override
  void initState() {
    super.initState();
    // Empty name = "use the default name in the current language" (hint).
    _config = GameConfig.defaults(widget.mode);
    final raw = ref.read(sharedPreferencesProvider).getString(_prefsKey);
    if (raw != null) {
      try {
        _config = GameConfig.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
          mode: widget.mode,
        );
        _savedCategoryIds = _config.categoryIds;
      } catch (_) {}
    }
    for (final name in _config.teamNames) {
      _names.add(TextEditingController(text: name));
    }
  }

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  String _defaultName(AppStrings s, int i) =>
      _forehead ? s.defaultPlayerName(i) : s.defaultTeamName(i);

  List<String> _teamNames() => [
    for (var i = 0; i < _names.length; i++)
      _names[i].text.trim().isEmpty
          ? _defaultName(_s, i)
          : _names[i].text.trim(),
  ];

  void _addTeam() {
    if (_names.length >= _max) return;
    setState(() => _names.add(TextEditingController()));
  }

  void _removeTeam(int i) {
    if (_names.length <= _min) return;
    setState(() => _names.removeAt(i).dispose());
  }

  void _start(List<WordCategory> categories) {
    final selected = _selected ?? {};
    if (selected.isEmpty) return;
    final config = _config.copyWith(
      teamNames: _teamNames(),
      categoryIds: selected,
    );
    // Remember setup; names equal to a default are stored empty so they
    // follow the UI language.
    final defaults = {
      for (var i = 0; i < _max; i++)
        for (final lang in ['fa', 'en'])
          _defaultName(AppStrings.forLanguage(lang), i),
    };
    final toSave = config.copyWith(
      teamNames: [
        for (final n in config.teamNames) defaults.contains(n) ? '' : n,
      ],
    );
    ref
        .read(sharedPreferencesProvider)
        .setString(_prefsKey, jsonEncode(toSave.toJson()));

    ref.read(gameControllerProvider.notifier).startGame(config, categories);
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final categoriesAsync = ref.watch(wordCategoriesProvider);
    final categories = categoriesAsync.value ?? const <WordCategory>[];
    if (_selected == null && categoriesAsync.hasValue) {
      final ids = categories.map((c) => c.id).toSet();
      final saved = _savedCategoryIds.intersection(ids);
      _selected = saved.isEmpty ? ids : saved;
    }
    final selected = _selected ?? const <String>{};

    return Scaffold(
      appBar: AppBar(title: Text(s.setupTitle)),
      body: DecoratedBox(
        decoration: appBackground,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    SectionTitle(_forehead ? s.players : s.teams),
                    for (var i = 0; i < _names.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TeamField(
                          index: i,
                          controller: _names[i],
                          hint: _defaultName(s, i),
                          onRemove: _names.length > _min
                              ? () => _removeTeam(i)
                              : null,
                        ),
                      ),
                    if (_names.length < _max)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: CartoonChip(
                          label: '+ ${_forehead ? s.addPlayer : s.addTeam}',
                          selected: false,
                          onTap: _addTeam,
                        ),
                      ),
                    SectionTitle(s.roundDuration),
                    _Options<int>(
                      values: GameConfig.roundSecondsOptions,
                      selected: _config.roundSeconds,
                      label: s.seconds,
                      onSelect: (v) => setState(
                        () => _config = _config.copyWith(roundSeconds: v),
                      ),
                    ),
                    SectionTitle(
                      _forehead ? s.turnsPerPlayer : s.roundsPerTeam,
                    ),
                    _Options<int>(
                      values: GameConfig.roundsOptions(widget.mode),
                      selected: _config.roundsPerTeam,
                      label: s.n,
                      onSelect: (v) => setState(
                        () => _config = _config.copyWith(roundsPerTeam: v),
                      ),
                    ),
                    SectionTitle(s.difficulty),
                    _Options<DifficultyChoice>(
                      values: DifficultyChoice.values,
                      selected: _config.difficulty,
                      label: s.difficultyName,
                      onSelect: (v) => setState(
                        () => _config = _config.copyWith(difficulty: v),
                      ),
                    ),
                    // Forehead mode: passing (tilt up) is always allowed.
                    if (!_forehead) ...[
                      SectionTitle(s.passLimit),
                      _Options<int?>(
                        values: GameConfig.passLimitOptions,
                        selected: _config.passLimit,
                        label: (v) => v == null ? s.unlimited : s.n(v),
                        onSelect: (v) => setState(
                          () => _config = _config.copyWith(passLimit: () => v),
                        ),
                      ),
                    ],
                    SectionTitle(
                      s.categories,
                      trailing: categories.isEmpty
                          ? null
                          : CartoonChip(
                              label: selected.length == categories.length
                                  ? s.clearAll
                                  : s.selectAll,
                              selected: false,
                              onTap: () => setState(
                                () => _selected =
                                    selected.length == categories.length
                                    ? {}
                                    : categories.map((c) => c.id).toSet(),
                              ),
                            ),
                    ),
                    if (categoriesAsync.isLoading)
                      const Center(child: CircularProgressIndicator()),
                    for (final c in categories)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CategoryTile(
                          category: c,
                          count: c.wordsFor(_config.difficulty.levels).length,
                          selected: selected.contains(c.id),
                          countLabel: s.wordsCount,
                          onTap: () => setState(() {
                            final next = {...selected};
                            next.contains(c.id)
                                ? next.remove(c.id)
                                : next.add(c.id);
                            _selected = next;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: CartoonButton(
                  label: selected.isEmpty ? s.pickCategory : s.startGame,
                  icon: selected.isEmpty ? null : '🚀',
                  fontSize: selected.isEmpty ? 20 : 26,
                  color: AppColors.green,
                  onPressed: selected.isEmpty ? null : () => _start(categories),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamField extends StatelessWidget {
  const _TeamField({
    required this.index,
    required this.controller,
    required this.hint,
    this.onRemove,
  });

  final int index;
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final style = TeamStyle.of(index);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline, width: 3),
        boxShadow: [BoxShadow(color: style.color, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          TeamAvatar(teamIndex: index),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: 16,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.ink.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, color: AppColors.ink),
            ),
        ],
      ),
    );
  }
}

class _Options<T> extends StatelessWidget {
  const _Options({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final v in values)
        CartoonChip(
          label: label(v),
          selected: v == selected,
          onTap: () => onSelect(v),
        ),
    ],
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.count,
    required this.selected,
    required this.countLabel,
    required this.onTap,
  });

  final WordCategory category;
  final int count;
  final bool selected;
  final String Function(int) countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.card : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outline, width: 3),
        ),
        child: Row(
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.ink : AppColors.text,
                    ),
                  ),
                  Text(
                    countLabel(count),
                    style: TextStyle(
                      fontSize: 13,
                      color: selected
                          ? AppColors.ink.withValues(alpha: 0.6)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? AppColors.green : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outline, width: 2.5),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: AppColors.ink)
                  : null,
            ),
          ],
        ),
      ),
    ),
  );
}
