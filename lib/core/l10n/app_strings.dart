import '../../features/words/domain/word_models.dart';
import '../utils/persian_text.dart';

/// All user-visible strings: Persian (primary), English and Arabic.
///
/// Plain Dart instead of ARB/codegen: few languages, easy to review.
abstract class AppStrings {
  const AppStrings();

  static AppStrings forLanguage(String code) => switch (code) {
    'en' => const EnStrings(),
    'ar' => const ArStrings(),
    _ => const FaStrings(),
  };

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

  /// Button when no passes are left: give up the word and end the turn.
  String get giveUp;

  /// Web only: bar on the home screen leading to the app page.
  String get installApp;
  String get giveUpTitle;
  String get giveUpBody;
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

  /// Snackbar when a friend opened the invite link.
  String get inviteUnlockedForever;
  String get watchAd;
  String get cancel;
  String get unlockSkipped;
  String get shareToUnlock;
  String get inviteText;
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
  String get preparingVideo;
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
  String get giveUp => 'انصراف';
  @override
  String get installApp => 'نصب اپ روی گوشی (اندروید و آیفون)';
  @override
  String get giveUpTitle => 'انصراف از این کلمه؟';
  @override
  String get giveUpBody =>
      'این کلمه حدس‌زده‌نشده حساب می‌شود و نوبت همین حالا تمام می‌شود.';
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
      'بازی را برای دوستانت بفرست تا این دسته باز شود. هر وقت یکی از آن‌ها لینک را باز کند، همه‌ی دسته‌های ویژه برای همیشه باز می‌شوند.';
  @override
  String get inviteUnlockedForever =>
      '🎉 یکی از دوستانت لینک را باز کرد؛ دسته‌های ویژه برای همیشه باز شد!';
  @override
  String get watchAd => 'دیدن تبلیغ';
  @override
  String get cancel => 'بی‌خیال';
  @override
  String get unlockSkipped => 'برای باز شدن دسته، تبلیغ باید تا آخر دیده شود.';
  @override
  String get shareToUnlock => 'فرستادن برای دوستان';
  @override
  String get inviteText =>
      'بیا با هم «پانتومیم دورهمی» بازی کنیم! 🎭 بازی ادا و حدس کلمه برای دورهمی‌ها:';
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
  String get preparingVideo => 'در حال آماده‌سازی ویدیو…';
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
  String get about => 'درباره بازی';
  @override
  String get aboutBody =>
      'پانتومیم دورهمی؛ بازی ادا و حدس کلمه برای جمع‌های خانوادگی و دوستانه.\n'
      'کاملاً آفلاین، بدون ثبت‌نام.';
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
  String get giveUp => 'Give up';
  @override
  String get installApp => 'Get the app (Android & iPhone)';
  @override
  String get giveUpTitle => 'Give up this word?';
  @override
  String get giveUpBody =>
      'The word counts as not guessed and the turn ends right now.';
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
      'Send the game to your friends to unlock this category. Once one of them opens the link, all bonus categories stay unlocked for good.';
  @override
  String get inviteUnlockedForever =>
      '🎉 A friend opened your link: bonus categories are unlocked for good!';
  @override
  String get watchAd => 'Watch ad';
  @override
  String get cancel => 'Cancel';
  @override
  String get unlockSkipped => 'Watch the ad to the end to unlock.';
  @override
  String get shareToUnlock => 'Send to friends';
  @override
  String get inviteText =>
      "Let's play Pantomime Party together! 🎭 The charades game for game night:";
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
  String get preparingVideo => 'Preparing the video…';
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
  String get about => 'About';
  @override
  String get aboutBody =>
      'Pantomime Party — a charades game for family and friends.\n'
      'Fully offline, no sign-up.';
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

const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

class ArStrings extends AppStrings {
  const ArStrings();

  @override
  String get languageCode => 'ar';
  @override
  bool get isRtl => true;
  @override
  String n(int value) => '$value'.split('').map((c) {
    final d = c.codeUnitAt(0) - 0x30;
    return d >= 0 && d < 10 ? _arabicDigits[d] : c;
  }).join();

  @override
  String get appName => 'بانتومايم الحفلات';
  @override
  String get tagline => 'مثّل بصمت، واضحك بصوت عالٍ!';
  @override
  String get teamGame => 'لعب جماعي';
  @override
  String get teamGameHint => 'الفرق تمثّل بالتناوب';
  @override
  String get foreheadMode => 'الهاتف على الجبين';
  @override
  String get foreheadModeHint => 'ضع الهاتف على جبينك!';
  @override
  String get comingSoon => 'قريبًا!';
  @override
  String get settings => 'الإعدادات';

  @override
  String get setupTitle => 'إعداد اللعبة';
  @override
  String get teams => 'الفرق';
  @override
  String defaultTeamName(int index) => 'الفريق ${n(index + 1)}';
  @override
  String get addTeam => 'فريق جديد';
  @override
  String get roundDuration => 'مدة الدور';
  @override
  String seconds(int s) => '${n(s)} ثانية';
  @override
  String get roundsPerTeam => 'عدد الأدوار لكل فريق';
  @override
  String get difficulty => 'الصعوبة';
  @override
  String difficultyName(DifficultyChoice d) => switch (d) {
    DifficultyChoice.easy => 'سهل',
    DifficultyChoice.medium => 'متوسط',
    DifficultyChoice.hard => 'صعب',
    DifficultyChoice.mixed => 'مختلط',
  };
  @override
  String get categories => 'الفئات';
  @override
  String get selectAll => 'الكل';
  @override
  String get clearAll => 'لا شيء';
  @override
  String get passLimit => 'عدد مرات التخطي في كل دور';
  @override
  String get unlimited => 'بلا حدود';
  @override
  String get startGame => 'هيا بنا!';
  @override
  String get pickCategory => 'اختر فئة واحدة على الأقل';
  @override
  String wordsCount(int count) => '${n(count)} كلمة';

  @override
  String turnOf(String team) => 'دور $team';
  @override
  String roundOf(int round, int total) => 'الجولة ${n(round)} من ${n(total)}';
  @override
  String get suddenDeath => 'جولة الحسم!';
  @override
  String get suddenDeathHint => 'تعادل، جولة إضافية!';
  @override
  String get howToPlay =>
      'يمثّل لاعب الكلمة دون أن يتكلم، ويخمّن زملاؤه.\n'
      'يمسك لاعب من الفريق الآخر الهاتف ويضغط «صحيح» أو «تخطٍّ».';
  @override
  String get start => 'ابدأ';
  @override
  String get go => 'انطلق!';
  @override
  String get correct => 'صحيح';
  @override
  String get pass => 'تخطٍّ';
  @override
  String passesLeft(int? left) =>
      left == null ? 'التخطي: بلا حدود' : 'مرات التخطي المتبقية: ${n(left)}';
  @override
  String get noPassLeft => 'لم يبقَ تخطٍّ';
  @override
  String get giveUp => 'استسلام';
  @override
  String get installApp => 'ثبّت التطبيق (أندرويد وآيفون)';
  @override
  String get giveUpTitle => 'الاستسلام في هذه الكلمة؟';
  @override
  String get giveUpBody => 'تُحسب الكلمة غير مخمَّنة وينتهي الدور الآن.';
  @override
  String get timeUp => 'انتهى الوقت!';
  @override
  String get paused => 'متوقف مؤقتًا';
  @override
  String get resume => 'متابعة';

  @override
  String get players => 'اللاعبون';
  @override
  String defaultPlayerName(int index) => 'اللاعب ${n(index + 1)}';
  @override
  String get addPlayer => 'لاعب جديد';
  @override
  String get turnsPerPlayer => 'عدد الأدوار لكل لاعب';
  @override
  String get foreheadHowTo =>
      'ضع الهاتف أفقيًا على جبينك والشاشة نحو الأصدقاء.\n'
      'يمثّل أصدقاؤك الكلمة بصمت، وأنت تخمّن.\n'
      'إمالة للأسفل = صحيح  •  إمالة للأعلى = تخطٍّ';
  @override
  String get putOnForehead => 'ضع الهاتف على جبينك';
  @override
  String get holdStill => 'الشاشة نحو الأصدقاء، ثبّت الهاتف…';
  @override
  String get tiltDownCorrect => 'إمالة للأسفل = صحيح';
  @override
  String get tiltUpPass => 'إمالة للأعلى = تخطٍّ';
  @override
  String get sensorUnavailable =>
      'لم يُعثر على مستشعر الحركة؛ ليضغط شخص آخر على الأزرار.';
  @override
  String get startWithButtons => 'ابدأ بالأزرار';

  @override
  String get bonusBadge => '🎁 مكافأة';
  @override
  String get unlockTitle => 'افتح الفئة الإضافية';
  @override
  String get unlockBody =>
      'أرسل اللعبة إلى أصدقائك لفتح هذه الفئة. عندما يفتح أحدهم الرابط، تبقى كل الفئات الإضافية مفتوحة دائمًا.';
  @override
  String get inviteUnlockedForever =>
      '🎉 فتح أحد أصدقائك رابطك: الفئات الإضافية مفتوحة دائمًا!';
  @override
  String get watchAd => 'شاهد الإعلان';
  @override
  String get cancel => 'إلغاء';
  @override
  String get unlockSkipped => 'شاهد الإعلان حتى النهاية لفتح الفئة.';
  @override
  String get shareToUnlock => 'أرسل إلى الأصدقاء';
  @override
  String get inviteText =>
      'تعال نلعب «بانتومايم الحفلات» معًا! 🎭 لعبة التمثيل وتخمين الكلمات:';
  @override
  String get updateAvailable => 'يتوفر إصدار جديد في المتجر!';

  @override
  String get recordingExplainTitle => 'سجّل اللحظات المضحكة 🎥';
  @override
  String get recordingExplainBody =>
      'في وضع الجبين تصوّر الكاميرا الأمامية أصدقاءك وهم يمثّلون، لتشاهدوا '
      'وتضحكوا بعد ذلك.\n\n'
      'يحتاج ذلك إلى الكاميرا والميكروفون. تبقى المقاطع على هاتفك ولا تُرفع '
      'أبدًا، ولا تُحفظ أو تُشارك إلا إذا اخترت ذلك.';
  @override
  String get allow => 'حسنًا، فعّله';
  @override
  String get recordingDenied =>
      'لم يُسمح بالوصول إلى الكاميرا أو الميكروفون، لذا يبقى التسجيل متوقفًا. '
      'يمكنك السماح بذلك من إعدادات الهاتف.';
  @override
  String get rec => 'تسجيل';
  @override
  String get saveVideo => 'حفظ الفيديو';
  @override
  String get videoSaved => 'حُفظ الفيديو في المعرض ✅';
  @override
  String get videoSaveFailed => 'تعذّر الحفظ؛ تحقق من إذن المعرض.';
  @override
  String get preparingVideo => 'جارٍ تجهيز الفيديو…';
  @override
  String get shareVideo => 'مشاركة الفيديو';
  @override
  String get shareCard => 'بطاقة النتيجة';
  @override
  String get shareResult => 'مشاركة النتيجة';
  @override
  String get share => 'مشاركة';
  @override
  String shareCaption(int points) =>
      'حصلنا على ${n(points)} نقطة في بانتومايم الحفلات! 🎭 هل تتفوقون علينا؟';
  @override
  String get shareResultCaption =>
      'نتيجتنا في بانتومايم الحفلات 🎭🏆 تعالوا العبوا معنا!';
  @override
  String get cardCorrectWords => 'الكلمات التي خمّناها';
  @override
  String get downloadCta => 'حمّل بانتومايم الحفلات والعب مع أصدقائك!';

  @override
  String get roundSummary => 'ملخص الدور';
  @override
  String get tapToFix => 'ضغطت الزر الخطأ؟ اضغط على الكلمة لتصحيحها.';
  @override
  String score(int points) => '${n(points)} نقطة';
  @override
  String get timedOutWord => 'انتهى الوقت';
  @override
  String get noWordsPlayed => 'لم تُلعب أي كلمة!';
  @override
  String get continueLabel => 'متابعة';
  @override
  String get scoreboard => 'لوحة النتائج';
  @override
  String nextTurn(String team) => 'الدور التالي: $team';
  @override
  String get seeResults => 'عرض النتيجة';
  @override
  String get finalResults => 'النتيجة النهائية';
  @override
  String winnerIs(String team) => 'فاز $team!';
  @override
  String get itsATie => 'تعادل!';
  @override
  String get playAgain => 'لنلعب مرة أخرى';
  @override
  String get backHome => 'الصفحة الرئيسية';

  @override
  String get exitGameTitle => 'الخروج من اللعبة؟';
  @override
  String get exitGameBody => 'ستضيع نتائج هذه اللعبة.';
  @override
  String get exit => 'خروج';
  @override
  String get stay => 'متابعة اللعب';

  @override
  String get sound => 'الصوت';
  @override
  String get vibration => 'الاهتزاز';
  @override
  String get recording => 'تسجيل فيديو في وضع الجبين';
  @override
  String get recordingHint => 'في وضع الجبين فقط، بالكاميرا الأمامية';
  @override
  String get language => 'اللغة';
  @override
  String get about => 'حول اللعبة';
  @override
  String get aboutBody =>
      'بانتومايم الحفلات: لعبة التمثيل الصامت للعائلة والأصدقاء.\n'
      'تعمل دون إنترنت ودون تسجيل.';
  @override
  String get privacyPolicy => 'سياسة الخصوصية';
  @override
  String get privacyBody =>
      'لا تحتوي هذه اللعبة على حسابات ولا تجمع بيانات شخصية.\n'
      'تُحفظ الإعدادات وسجل الكلمات على جهازك فقط.\n'
      'تبقى مقاطع الفيديو المسجلة (إن فُعّلت) على جهازك ولا تُرفع أبدًا.\n'
      'تعرض اللعبة إعلانات؛ وقد تجمع شبكات الإعلانات (Adivery أو Tapsell أو '
      'AdMob) معرّف الإعلانات وبيانات تقنية عن الجهاز لعرض الإعلانات. عند '
      'التشغيل تنزّل اللعبة ملف إعدادات صغيرًا ولا ترسل أي شيء عنك.';
  @override
  String get rateApp => 'قيّم التطبيق';
  @override
  String get close => 'إغلاق';
}
