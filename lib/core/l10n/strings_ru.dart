import '../../features/words/domain/word_models.dart';
import 'app_strings.dart';

/// Russian plural form: [one] for 1, 21, 31…; [few] for 2–4, 22–24…;
/// [many] for 0, 5–20, 25–30…
String _ruPlural(int value, String one, String few, String many) {
  final abs = value.abs();
  final mod10 = abs % 10;
  final mod100 = abs % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

class RuStrings extends AppStrings {
  const RuStrings();

  @override
  String get languageCode => 'ru';
  @override
  bool get isRtl => false;
  @override
  String n(int value) => '$value';

  @override
  String get appName => 'Весёлая пантомима';
  @override
  String get tagline => 'Показывай молча, смейся громко!';
  @override
  String get teamGame => 'Быстрая пантомима';
  @override
  String get teamGameHint => 'Максимум слов за минуту';
  @override
  String get foreheadMode => 'Телефон на лоб';
  @override
  String get foreheadModeHint => 'Приложи телефон ко лбу!';
  @override
  String get comingSoon => 'Скоро!';
  @override
  String get settings => 'Настройки';

  @override
  String get setupTitle => 'Настройка игры';
  @override
  String get teams => 'Команды';
  @override
  String defaultTeamName(int index) => 'Команда ${index + 1}';
  @override
  String get addTeam => 'Добавить команду';
  @override
  String get roundDuration => 'Длительность хода';
  @override
  String seconds(int s) => '$s сек';
  @override
  String get roundsPerTeam => 'Ходов на команду';
  @override
  String get difficulty => 'Сложность';
  @override
  String difficultyName(DifficultyChoice d) => switch (d) {
    DifficultyChoice.easy => 'Легко',
    DifficultyChoice.medium => 'Средне',
    DifficultyChoice.hard => 'Сложно',
    DifficultyChoice.mixed => 'Вперемешку',
  };
  @override
  String get categories => 'Категории';
  @override
  String get selectAll => 'Все';
  @override
  String get clearAll => 'Ни одной';
  @override
  String get passLimit => 'Пропусков за ход';
  @override
  String get unlimited => 'Без ограничений';
  @override
  String get startGame => 'Поехали!';
  @override
  String get pickCategory => 'Выбери хотя бы одну категорию';
  @override
  String wordsCount(int count) =>
      '$count ${_ruPlural(count, 'слово', 'слова', 'слов')}';

  @override
  String turnOf(String team) => 'Ходит: $team';
  @override
  String roundOf(int round, int total) => 'Раунд $round из $total';
  @override
  String get suddenDeath => 'Решающий раунд!';
  @override
  String get suddenDeathHint => 'Ничья — играем ещё один раунд!';
  @override
  String get howToPlay =>
      'Один игрок молча показывает слово, его команда угадывает.\n'
      'Кто-то из соперников держит телефон и нажимает «Угадали» или «Пропуск».';
  @override
  String get start => 'Начать';
  @override
  String get go => 'Вперёд!';
  @override
  String get correct => 'Угадали';
  @override
  String get pass => 'Пропуск';
  @override
  String passesLeft(int? left) =>
      left == null ? 'Пропуски: без ограничений' : 'Осталось пропусков: $left';
  @override
  String get noPassLeft => 'Пропуски закончились';
  @override
  String get giveUp => 'Сдаться';
  @override
  String get leaderboards => 'Рейтинги и достижения';
  @override
  String get filmThisTurn => 'Снять этот ход на видео';
  @override
  String get filmOn =>
      'Идёт запись: наведи заднюю камеру на того, кто показывает';
  @override
  String get classicGame => 'Пантомима';
  @override
  String get classicGameHint => 'Одно слово за ход';
  @override
  String get classicHowTo =>
      'Один игрок смотрит слово и молча его показывает.\n'
      'Когда команда угадает, нажми «Угадали!»; каждое слово — одно очко.';
  @override
  String get guessedIt => 'Угадали!';
  @override
  String get changeWord => 'Сменить слово';
  @override
  String changesLeft(int left) => 'Осталось замен: $left';
  @override
  String get wordChangesTitle => 'Замены слова (на команду за всю игру)';
  @override
  String get off => 'Выкл.';
  @override
  String get customWordButton => 'Слово загадывают соперники';
  @override
  String get customWordTitle => 'Слово от соперников';
  @override
  String get customWordHint =>
      'Введите слово и передайте телефон тому, кто показывает';
  @override
  String get customWordReady => 'Слово от соперников готово';
  @override
  String get confirmWord => 'Загадать это слово';
  @override
  String get installApp => 'Скачать приложение (Android и iPhone)';
  @override
  String get giveUpTitle => 'Сдаться на этом слове?';
  @override
  String get giveUpBody =>
      'Слово засчитается как неугаданное, и ход закончится прямо сейчас.';
  @override
  String get timeUp => 'Время вышло!';
  @override
  String get paused => 'Пауза';
  @override
  String get resume => 'Продолжить';

  @override
  String get players => 'Игроки';
  @override
  String defaultPlayerName(int index) => 'Игрок ${index + 1}';
  @override
  String get addPlayer => 'Добавить игрока';
  @override
  String get turnsPerPlayer => 'Ходов на игрока';
  @override
  String get foreheadHowTo =>
      'Приложи телефон ко лбу горизонтально, экраном к друзьям.\n'
      'Друзья молча показывают слово, а ты угадываешь.\n'
      'Наклон вниз = угадал  •  Наклон вверх = пропуск';
  @override
  String get putOnForehead => 'Приложи телефон ко лбу';
  @override
  String get holdStill => 'Экраном к друзьям, держи ровно…';
  @override
  String get tiltDownCorrect => 'Наклон вниз = угадал';
  @override
  String get tiltUpPass => 'Наклон вверх = пропуск';
  @override
  String get sensorUnavailable =>
      'Датчик движения не найден; пусть кто-то другой нажимает кнопки.';
  @override
  String get startWithButtons => 'Играть с кнопками';

  @override
  String get bonusBadge => '🎁 Бонус';
  @override
  String get unlockTitle => 'Открыть бонусную категорию';
  @override
  String get unlockBody =>
      'Отправь игру друзьям, чтобы открыть эту категорию. Как только кто-то из них откроет ссылку, все бонусные категории откроются навсегда.';
  @override
  String get inviteUnlockedForever =>
      '🎉 Друг открыл твою ссылку: бонусные категории открыты навсегда!';
  @override
  String get watchAd => 'Смотреть рекламу';
  @override
  String get cancel => 'Отмена';
  @override
  String get unlockSkipped => 'Досмотри рекламу до конца, чтобы открыть.';
  @override
  String get shareToUnlock => 'Отправить друзьям';
  @override
  String get inviteText =>
      'Давай сыграем в «Весёлую пантомиму»! 🎭 Игра в крокодила для весёлой компании:';
  @override
  String get updateAvailable => 'В магазине доступна новая версия!';

  @override
  String get recordingExplainTitle => 'Сними самое смешное 🎥';
  @override
  String get recordingExplainBody =>
      'В режиме «Телефон на лоб» фронтальная камера снимает, как друзья '
      'показывают слова, чтобы потом вместе посмотреть и посмеяться.\n\n'
      'Для этого нужны камера и микрофон. Видео остаются на твоём телефоне и '
      'никуда не загружаются — сохранить или отправить их можешь только ты сам.';
  @override
  String get allow => 'Хорошо, включить';
  @override
  String get notNow => 'Не сейчас';
  @override
  String get recordingDenied =>
      'Доступ к камере или микрофону не получен, поэтому запись выключена. '
      'Его можно разрешить в настройках телефона.';
  @override
  String get rec => 'ЗАПИСЬ';
  @override
  String get saveVideo => 'Сохранить видео';
  @override
  String get videoSaved => 'Видео сохранено в галерею ✅';
  @override
  String get videoSaveFailed =>
      'Не удалось сохранить; проверь доступ к галерее.';
  @override
  String get preparingVideo => 'Готовим видео…';
  @override
  String get shareVideo => 'Поделиться видео';
  @override
  String get shareCard => 'Карточка счёта';
  @override
  String get shareResult => 'Поделиться результатом';
  @override
  String get share => 'Поделиться';
  @override
  String shareCaption(int points) =>
      'Мы набрали ${score(points)} в «Весёлой пантомиме»! 🎭 Сможете обыграть нас?';
  @override
  String get shareResultCaption =>
      'Наши результаты в «Весёлой пантомиме» 🎭🏆 Давай сыграем вместе!';
  @override
  String get cardCorrectWords => 'Угаданные слова';
  @override
  String get downloadCta => 'Скачай «Весёлую пантомиму» и играй с друзьями!';

  @override
  String get roundSummary => 'Итоги хода';
  @override
  String get tapToFix =>
      'Нажали не ту кнопку? Нажми на слово, чтобы исправить.';
  @override
  String score(int points) =>
      '$points ${_ruPlural(points, 'очко', 'очка', 'очков')}';
  @override
  String get timedOutWord => 'Время вышло';
  @override
  String get noWordsPlayed => 'Ни одного слова!';
  @override
  String get continueLabel => 'Продолжить';
  @override
  String get scoreboard => 'Таблица счёта';
  @override
  String nextTurn(String team) => 'Следующий ход: $team';
  @override
  String get seeResults => 'Посмотреть итоги';
  @override
  String get finalResults => 'Итоги игры';
  @override
  String winnerIs(String team) => 'Побеждает $team!';
  @override
  String get itsATie => 'Ничья!';
  @override
  String get playAgain => 'Сыграть ещё';
  @override
  String get backHome => 'На главную';

  @override
  String get exitGameTitle => 'Выйти из игры?';
  @override
  String get exitGameBody => 'Счёт этой игры не сохранится.';
  @override
  String get exit => 'Выйти';
  @override
  String get stay => 'Играть дальше';

  @override
  String get sound => 'Звук';
  @override
  String get vibration => 'Вибрация';
  @override
  String get recording => 'Запись видео в режиме «Телефон на лоб»';
  @override
  String get recordingHint =>
      'Только в режиме «Телефон на лоб», фронтальная камера';
  @override
  String get language => 'Язык';
  @override
  String get about => 'Об игре';
  @override
  String get aboutBody =>
      '«Весёлая пантомима» — игра в крокодила для семьи и друзей.\n'
      'Работает без интернета и без регистрации.';
  @override
  String get privacyPolicy => 'Политика конфиденциальности';
  @override
  String get privacyBody =>
      'В игре нет аккаунтов, и она не собирает персональные данные.\n'
      'Настройки и история слов хранятся только на твоём устройстве.\n'
      'Записанные видео (если запись включена) остаются на устройстве и '
      'никуда не загружаются.\n'
      'В игре показывается реклама; рекламные сети (Adivery, Tapsell или AdMob) '
      'могут собирать рекламный идентификатор и технические данные устройства '
      'для показа рекламы. При запуске игра скачивает небольшой файл настроек '
      'и ничего не отправляет о тебе.';
  @override
  String get rateApp => 'Оценить игру';
  @override
  String get close => 'Закрыть';
}
