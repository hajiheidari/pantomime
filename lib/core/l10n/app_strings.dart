import '../../features/words/domain/word_models.dart';
import '../utils/persian_text.dart';

/// All user-visible strings. Persian is primary; English exists so store
/// reviewers on English devices see a localized app.
///
/// Plain Dart instead of ARB/codegen: two languages, easy to review.
abstract class AppStrings {
  const AppStrings();

  static AppStrings forLanguage(String code) =>
      code == 'en' ? const EnStrings() : const FaStrings();

  String get languageCode;
  bool get isRtl;

  /// Formats a number with the language's digits.
  String n(int value);

  String get appName;
  String get tagline;
  String get teamGame;
  String get teamGameHint;
  String get foreheadMode;
  String get foreheadModeHint;
  String get comingSoon;
  String get settings;

  // Setup
  String get setupTitle;
  String get teams;
  String defaultTeamName(int index);
  String get addTeam;
  String get roundDuration;
  String seconds(int s);
  String get roundsPerTeam;
  String get difficulty;
  String difficultyName(DifficultyChoice d);
  String get categories;
  String get selectAll;
  String get clearAll;
  String get passLimit;
  String get unlimited;
  String get startGame;
  String get pickCategory;
  String wordsCount(int count);

  // Turn
  String turnOf(String team);
  String roundOf(int round, int total);
  String get suddenDeath;
  String get suddenDeathHint;
  String get howToPlay;
  String get start;
  String get go;
  String get correct;
  String get pass;
  String passesLeft(int? left);
  String get noPassLeft;
  String get timeUp;
  String get paused;
  String get resume;

  // Forehead mode
  String get players;
  String defaultPlayerName(int index);
  String get addPlayer;
  String get turnsPerPlayer;
  String get foreheadHowTo;
  String get putOnForehead;
  String get holdStill;
  String get tiltDownCorrect;
  String get tiltUpPass;
  String get sensorUnavailable;
  String get startWithButtons;

  // Bonus pack / notices
  String get bonusBadge;
  String get unlockTitle;
  String get unlockBody;
  String get watchAd;
  String get cancel;
  String get unlockSkipped;
  String get updateAvailable;

  // Recording & sharing
  String get recordingExplainTitle;
  String get recordingExplainBody;
  String get allow;
  String get recordingDenied;
  String get rec;
  String get saveVideo;
  String get videoSaved;
  String get videoSaveFailed;
  String get shareVideo;
  String get shareCard;
  String get shareResult;
  String get share;
  String shareCaption(int points);
  String get shareResultCaption;
  String get cardCorrectWords;
  String get downloadCta;

  // Summary / scores
  String get roundSummary;
  String get tapToFix;
  String score(int points);
  String get timedOutWord;
  String get noWordsPlayed;
  String get continueLabel;
  String get scoreboard;
  String nextTurn(String team);
  String get seeResults;
  String get finalResults;
  String winnerIs(String team);
  String get itsATie;
  String get playAgain;
  String get backHome;

  // Exit dialog
  String get exitGameTitle;
  String get exitGameBody;
  String get exit;
  String get stay;

  // Settings
  String get sound;
  String get vibration;
  String get recording;
  String get recordingHint;
  String get language;
  String get languageSystem;
  String get about;
  String get aboutBody;
  String get privacyPolicy;
  String get privacyBody;
  String get rateApp;
  String get close;
}

class FaStrings extends AppStrings {
  const FaStrings();

  @override
  String get languageCode => 'fa';
  @override
  bool get isRtl => true;
  @override
  String n(int value) => toPersianDigits('$value');

  @override
  String get appName => 'پانتومیم دورهمی';
  @override
  String get tagline => 'بی‌صدا بازی کن، بلند بخند!';
  @override
  String get teamGame => 'بازی تیمی';
  @override
  String get teamGameHint => 'تیم‌ها نوبتی ادا درمی‌آورند';
  @override
  String get foreheadMode => 'گوشی روی پیشونی';
  @override
  String get foreheadModeHint => 'گوشی رو بذار رو پیشونیت!';
  @override
  String get comingSoon => 'به‌زودی!';
  @override
  String get settings => 'تنظیمات';

  @override
  String get setupTitle => 'آماده‌سازی بازی';
  @override
  String get teams => 'تیم‌ها';
  @override
  String defaultTeamName(int index) => 'تیم ${n(index + 1)}';
  @override
  String get addTeam => 'تیم جدید';
  @override
  String get roundDuration => 'زمان هر نوبت';
  @override
  String seconds(int s) => '${n(s)} ثانیه';
  @override
  String get roundsPerTeam => 'تعداد نوبت هر تیم';
  @override
  String get difficulty => 'سختی';
  @override
  String difficultyName(DifficultyChoice d) => switch (d) {
    DifficultyChoice.easy => 'آسان',
    DifficultyChoice.medium => 'متوسط',
    DifficultyChoice.hard => 'سخت',
    DifficultyChoice.mixed => 'قاطی',
  };
  @override
  String get categories => 'دسته‌ها';
  @override
  String get selectAll => 'همه';
  @override
  String get clearAll => 'هیچ‌کدام';
  @override
  String get passLimit => 'تعداد پاس در هر نوبت';
  @override
  String get unlimited => 'نامحدود';
  @override
  String get startGame => 'بزن بریم!';
  @override
  String get pickCategory => 'حداقل یک دسته انتخاب کن';
  @override
  String wordsCount(int count) => '${n(count)} کلمه';

  @override
  String turnOf(String team) => 'نوبت $team';
  @override
  String roundOf(int round, int total) => 'دور ${n(round)} از ${n(total)}';
  @override
  String get suddenDeath => 'مرگ ناگهانی!';
  @override
  String get suddenDeathHint => 'امتیازها مساوی شد؛ یک دور دیگر!';
  @override
  String get howToPlay =>
      'یک نفر از تیم بدون حرف زدن ادا درمی‌آورد و هم‌تیمی‌ها حدس می‌زنند.\n'
      'یک نفر از تیم مقابل گوشی را نگه دارد و «درست» یا «پاس» را بزند.';
  @override
  String get start => 'شروع';
  @override
  String get go => 'برو!';
  @override
  String get correct => 'درست';
  @override
  String get pass => 'پاس';
  @override
  String passesLeft(int? left) =>
      left == null ? 'پاس: نامحدود' : 'پاس باقی‌مانده: ${n(left)}';
  @override
  String get noPassLeft => 'پاس تمام شد';
  @override
  String get timeUp => 'وقت تمام شد!';
  @override
  String get paused => 'مکث';
  @override
  String get resume => 'ادامه';

  @override
  String get players => 'بازیکن‌ها';
  @override
  String defaultPlayerName(int index) => 'بازیکن ${n(index + 1)}';
  @override
  String get addPlayer => 'بازیکن جدید';
  @override
  String get turnsPerPlayer => 'تعداد نوبت هر بازیکن';
  @override
  String get foreheadHowTo =>
      'گوشی را افقی روی پیشانی بگذار، صفحه رو به جمع.\n'
      'بقیه بدون حرف زدن ادا درمی‌آورند و تو حدس می‌زنی.\n'
      'سر پایین = درست  •  سر بالا = پاس';
  @override
  String get putOnForehead => 'گوشی را روی پیشانی بگذار';
  @override
  String get holdStill => 'صفحه رو به جمع، صاف و بی‌حرکت نگه دار…';
  @override
  String get tiltDownCorrect => 'سر پایین = درست';
  @override
  String get tiltUpPass => 'سر بالا = پاس';
  @override
  String get sensorUnavailable =>
      'حسگر حرکت پیدا نشد؛ یک نفر دیگر دکمه‌ها را بزند.';
  @override
  String get startWithButtons => 'شروع با دکمه‌ها';

  @override
  String get bonusBadge => '🎁 ویژه';
  @override
  String get unlockTitle => 'باز کردن دسته ویژه';
  @override
  String get unlockBody =>
      'با دیدن یک تبلیغ کوتاه، این دسته تا وقتی بازی باز است در دسترس می‌ماند.';
  @override
  String get watchAd => 'دیدن تبلیغ';
  @override
  String get cancel => 'بی‌خیال';
  @override
  String get unlockSkipped => 'برای باز شدن دسته، تبلیغ باید تا آخر دیده شود.';
  @override
  String get updateAvailable => 'نسخه جدید بازی آمده؛ از فروشگاه به‌روز کن!';

  @override
  String get recordingExplainTitle => 'ضبط ویدیوی خنده‌دار 🎥';
  @override
  String get recordingExplainBody =>
      'در حالت «گوشی روی پیشونی»، دوربین جلو از ادا درآوردن دوستانت فیلم '
      'می‌گیرد تا بعد ببینید و بخندید.\n\n'
      'برای این کار به دوربین و میکروفون نیاز داریم. ویدیوها فقط روی گوشی '
      'خودت می‌مانند و هرگز جایی آپلود نمی‌شوند؛ فقط اگر خودت بخواهی آن را '
      'ذخیره یا برای کسی بفرستی.';
  @override
  String get allow => 'باشه، فعال کن';
  @override
  String get recordingDenied =>
      'دسترسی به دوربین یا میکروفون داده نشد؛ ضبط خاموش ماند. '
      'می‌توانی از تنظیمات گوشی اجازه بدهی.';
  @override
  String get rec => 'ضبط';
  @override
  String get saveVideo => 'ذخیره ویدیو';
  @override
  String get videoSaved => 'ویدیو در گالری ذخیره شد ✅';
  @override
  String get videoSaveFailed => 'ذخیره نشد؛ اجازه دسترسی به گالری را بررسی کن.';
  @override
  String get shareVideo => 'ارسال ویدیو';
  @override
  String get shareCard => 'کارت امتیاز';
  @override
  String get shareResult => 'اشتراک نتیجه';
  @override
  String get share => 'اشتراک‌گذاری';
  @override
  String shareCaption(int points) =>
      'ما در «پانتومیم دورهمی» ${n(points)} امتیاز گرفتیم! 🎭 تو چند تا می‌گیری؟';
  @override
  String get shareResultCaption =>
      'نتیجه بازی ما در «پانتومیم دورهمی» 🎭🏆 بیا با هم بازی کنیم!';
  @override
  String get cardCorrectWords => 'کلمه‌هایی که درست گفتیم';
  @override
  String get downloadCta => 'پانتومیم دورهمی را نصب کن و با دوستانت بازی کن!';

  @override
  String get roundSummary => 'خلاصه نوبت';
  @override
  String get tapToFix => 'اگر اشتباه زدید، روی کلمه بزنید تا درست شود.';
  @override
  String score(int points) => '${n(points)} امتیاز';
  @override
  String get timedOutWord => 'وقت تمام شد';
  @override
  String get noWordsPlayed => 'هیچ کلمه‌ای بازی نشد!';
  @override
  String get continueLabel => 'ادامه';
  @override
  String get scoreboard => 'جدول امتیاز';
  @override
  String nextTurn(String team) => 'نوبت بعد: $team';
  @override
  String get seeResults => 'دیدن نتیجه';
  @override
  String get finalResults => 'نتیجه نهایی';
  @override
  String winnerIs(String team) => '$team برنده شد!';
  @override
  String get itsATie => 'مساوی شد!';
  @override
  String get playAgain => 'دوباره بازی کنیم';
  @override
  String get backHome => 'صفحه اصلی';

  @override
  String get exitGameTitle => 'خروج از بازی؟';
  @override
  String get exitGameBody => 'امتیازهای این بازی از بین می‌رود.';
  @override
  String get exit => 'خروج';
  @override
  String get stay => 'ادامه بازی';

  @override
  String get sound => 'صدا';
  @override
  String get vibration => 'لرزش';
  @override
  String get recording => 'ضبط ویدیو در حالت پیشونی';
  @override
  String get recordingHint => 'فقط در حالت پیشونی، دوربین جلو';
  @override
  String get language => 'زبان';
  @override
  String get languageSystem => 'زبان گوشی';
  @override
  String get about => 'درباره بازی';
  @override
  String get aboutBody =>
      'پانتومیم دورهمی؛ بازی ادا و حدس کلمه برای جمع‌های خانوادگی و دوستانه.\n'
      'کاملاً آفلاین، بدون ثبت‌نام.\n'
      'فونت: وزیرمتن (مجوز OFL).';
  @override
  String get privacyPolicy => 'حریم خصوصی';
  @override
  String get privacyBody =>
      'این بازی حساب کاربری ندارد و هیچ اطلاعات شخصی از شما جمع نمی‌کند.\n'
      'همه تنظیمات و سوابق کلمات فقط روی گوشی خودتان ذخیره می‌شود.\n'
      'ویدیوهای ضبط‌شده (در صورت فعال کردن) فقط روی گوشی شما ذخیره می‌شوند و '
      'هرگز جایی آپلود نمی‌شوند.\n'
      'این بازی تبلیغ نمایش می‌دهد؛ شبکه‌های تبلیغاتی (مثل عدیوری، تپسل یا '
      'ادموب) ممکن است شناسه تبلیغاتی دستگاه و اطلاعات فنی گوشی را برای '
      'نمایش تبلیغ جمع کنند. هنگام شروع، بازی فقط یک فایل تنظیمات کوچک '
      'دانلود می‌کند و هیچ اطلاعاتی از شما ارسال نمی‌کند.';
  @override
  String get rateApp => 'امتیاز به بازی';
  @override
  String get close => 'بستن';
}

class EnStrings extends AppStrings {
  const EnStrings();

  @override
  String get languageCode => 'en';
  @override
  bool get isRtl => false;
  @override
  String n(int value) => '$value';

  @override
  String get appName => 'Pantomime Party';
  @override
  String get tagline => 'Act it out, laugh out loud!';
  @override
  String get teamGame => 'Team game';
  @override
  String get teamGameHint => 'Teams take turns acting';
  @override
  String get foreheadMode => 'Forehead mode';
  @override
  String get foreheadModeHint => 'Hold the phone on your forehead!';
  @override
  String get comingSoon => 'Coming soon!';
  @override
  String get settings => 'Settings';

  @override
  String get setupTitle => 'Game setup';
  @override
  String get teams => 'Teams';
  @override
  String defaultTeamName(int index) => 'Team ${index + 1}';
  @override
  String get addTeam => 'Add team';
  @override
  String get roundDuration => 'Turn duration';
  @override
  String seconds(int s) => '$s sec';
  @override
  String get roundsPerTeam => 'Turns per team';
  @override
  String get difficulty => 'Difficulty';
  @override
  String difficultyName(DifficultyChoice d) => switch (d) {
    DifficultyChoice.easy => 'Easy',
    DifficultyChoice.medium => 'Medium',
    DifficultyChoice.hard => 'Hard',
    DifficultyChoice.mixed => 'Mixed',
  };
  @override
  String get categories => 'Categories';
  @override
  String get selectAll => 'All';
  @override
  String get clearAll => 'None';
  @override
  String get passLimit => 'Passes per turn';
  @override
  String get unlimited => 'Unlimited';
  @override
  String get startGame => "Let's go!";
  @override
  String get pickCategory => 'Pick at least one category';
  @override
  String wordsCount(int count) => '$count words';

  @override
  String turnOf(String team) => "$team's turn";
  @override
  String roundOf(int round, int total) => 'Round $round of $total';
  @override
  String get suddenDeath => 'Sudden death!';
  @override
  String get suddenDeathHint => "It's a tie — one more round!";
  @override
  String get howToPlay =>
      'One player acts the word without speaking; teammates guess.\n'
      'Someone from the other team holds the phone and taps Correct or Pass.';
  @override
  String get start => 'Start';
  @override
  String get go => 'Go!';
  @override
  String get correct => 'Correct';
  @override
  String get pass => 'Pass';
  @override
  String passesLeft(int? left) =>
      left == null ? 'Passes: unlimited' : 'Passes left: $left';
  @override
  String get noPassLeft => 'No passes left';
  @override
  String get timeUp => "Time's up!";
  @override
  String get paused => 'Paused';
  @override
  String get resume => 'Resume';

  @override
  String get players => 'Players';
  @override
  String defaultPlayerName(int index) => 'Player ${index + 1}';
  @override
  String get addPlayer => 'Add player';
  @override
  String get turnsPerPlayer => 'Turns per player';
  @override
  String get foreheadHowTo =>
      'Hold the phone sideways on your forehead, screen facing the group.\n'
      'Friends act the word out silently; you guess.\n'
      'Tilt down = correct  •  Tilt up = pass';
  @override
  String get putOnForehead => 'Put the phone on your forehead';
  @override
  String get holdStill => 'Screen facing the group, hold it still…';
  @override
  String get tiltDownCorrect => 'Tilt down = correct';
  @override
  String get tiltUpPass => 'Tilt up = pass';
  @override
  String get sensorUnavailable =>
      'No motion sensor found; someone else taps the buttons.';
  @override
  String get startWithButtons => 'Start with buttons';

  @override
  String get bonusBadge => '🎁 Bonus';
  @override
  String get unlockTitle => 'Unlock bonus category';
  @override
  String get unlockBody =>
      'Watch a short ad to unlock this category until you close the app.';
  @override
  String get watchAd => 'Watch ad';
  @override
  String get cancel => 'Cancel';
  @override
  String get unlockSkipped => 'Watch the ad to the end to unlock.';
  @override
  String get updateAvailable => 'A new version is available in the store!';

  @override
  String get recordingExplainTitle => 'Record the fun 🎥';
  @override
  String get recordingExplainBody =>
      'In forehead mode the front camera films your friends acting, so you '
      'can watch and laugh afterwards.\n\n'
      'This needs the camera and microphone. Videos stay on your phone and '
      'are never uploaded — only saved or shared if you choose to.';
  @override
  String get allow => 'OK, turn it on';
  @override
  String get recordingDenied =>
      'Camera or microphone access was not granted; recording stays off. '
      'You can allow it in the phone settings.';
  @override
  String get rec => 'REC';
  @override
  String get saveVideo => 'Save video';
  @override
  String get videoSaved => 'Video saved to gallery ✅';
  @override
  String get videoSaveFailed => 'Could not save; check gallery permission.';
  @override
  String get shareVideo => 'Share video';
  @override
  String get shareCard => 'Score card';
  @override
  String get shareResult => 'Share result';
  @override
  String get share => 'Share';
  @override
  String shareCaption(int points) =>
      'We scored $points in Pantomime Party! 🎭 Can you beat us?';
  @override
  String get shareResultCaption =>
      'Our Pantomime Party results 🎭🏆 Come play with us!';
  @override
  String get cardCorrectWords => 'Words we got';
  @override
  String get downloadCta => 'Get Pantomime Party and play with friends!';

  @override
  String get roundSummary => 'Turn summary';
  @override
  String get tapToFix => 'Tapped the wrong button? Tap a word to fix it.';
  @override
  String score(int points) => points == 1 ? '1 point' : '$points points';
  @override
  String get timedOutWord => 'Time ran out';
  @override
  String get noWordsPlayed => 'No words played!';
  @override
  String get continueLabel => 'Continue';
  @override
  String get scoreboard => 'Scoreboard';
  @override
  String nextTurn(String team) => 'Next: $team';
  @override
  String get seeResults => 'See results';
  @override
  String get finalResults => 'Final results';
  @override
  String winnerIs(String team) => '$team wins!';
  @override
  String get itsATie => "It's a tie!";
  @override
  String get playAgain => 'Play again';
  @override
  String get backHome => 'Home';

  @override
  String get exitGameTitle => 'Leave the game?';
  @override
  String get exitGameBody => 'Scores of this game will be lost.';
  @override
  String get exit => 'Leave';
  @override
  String get stay => 'Keep playing';

  @override
  String get sound => 'Sound';
  @override
  String get vibration => 'Vibration';
  @override
  String get recording => 'Record video in forehead mode';
  @override
  String get recordingHint => 'Forehead mode only, front camera';
  @override
  String get language => 'Language';
  @override
  String get languageSystem => 'Device language';
  @override
  String get about => 'About';
  @override
  String get aboutBody =>
      'Pantomime Party — a charades game for family and friends.\n'
      'Fully offline, no sign-up.\n'
      'Font: Vazirmatn (OFL license).';
  @override
  String get privacyPolicy => 'Privacy policy';
  @override
  String get privacyBody =>
      'This game has no accounts and collects no personal data.\n'
      'Settings and word history are stored only on your device.\n'
      'Recorded videos (if enabled) stay on your device and are never '
      'uploaded.\n'
      'The game shows ads; ad networks (Adivery, Tapsell or AdMob) may collect '
      'the device advertising ID and technical device data to serve ads. On '
      'start the game downloads a small settings file and sends nothing about '
      'you.';
  @override
  String get rateApp => 'Rate the app';
  @override
  String get close => 'Close';
}
