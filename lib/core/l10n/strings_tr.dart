import '../../features/words/domain/word_models.dart';
import 'app_strings.dart';

class TrStrings extends AppStrings {
  const TrStrings();

  @override
  String get languageCode => 'tr';
  @override
  bool get isRtl => false;
  @override
  String n(int value) => '$value';

  @override
  String get appName => 'Pantomim Partisi';
  @override
  String get tagline => 'Sessizce anlat, kahkahayla gül!';
  @override
  String get teamGame => 'Hızlı Pantomim';
  @override
  String get teamGameHint => 'Bir dakikada en çok kelime';
  @override
  String get foreheadMode => 'Telefon Alnında';
  @override
  String get foreheadModeHint => 'Telefonu alnına koy!';
  @override
  String get comingSoon => 'Çok yakında!';
  @override
  String get settings => 'Ayarlar';

  @override
  String get setupTitle => 'Oyun Ayarları';
  @override
  String get teams => 'Takımlar';
  @override
  String defaultTeamName(int index) => '${index + 1}. Takım';
  @override
  String get addTeam => 'Takım Ekle';
  @override
  String get roundDuration => 'Tur Süresi';
  @override
  String seconds(int s) => '$s sn';
  @override
  String get roundsPerTeam => 'Takım Başına Tur';
  @override
  String get difficulty => 'Zorluk';
  @override
  String difficultyName(DifficultyChoice d) => switch (d) {
    DifficultyChoice.easy => 'Kolay',
    DifficultyChoice.medium => 'Orta',
    DifficultyChoice.hard => 'Zor',
    DifficultyChoice.mixed => 'Karışık',
  };
  @override
  String get categories => 'Kategoriler';
  @override
  String get selectAll => 'Tümü';
  @override
  String get clearAll => 'Hiçbiri';
  @override
  String get passLimit => 'Tur Başına Pas';
  @override
  String get unlimited => 'Sınırsız';
  @override
  String get startGame => 'Hadi başlayalım!';
  @override
  String get pickCategory => 'En az bir kategori seç';
  @override
  String wordsCount(int count) => '$count kelime';

  @override
  String turnOf(String team) => 'Sıra: $team';
  @override
  String roundOf(int round, int total) => 'Tur $round / $total';
  @override
  String get suddenDeath => 'Altın Tur!';
  @override
  String get suddenDeathHint => 'Berabere kaldınız, bir tur daha!';
  @override
  String get howToPlay =>
      'Bir oyuncu kelimeyi konuşmadan canlandırır, takım arkadaşları tahmin eder.\n'
      'Rakip takımdan biri telefonu tutar ve Doğru ya da Pas’a basar.';
  @override
  String get start => 'Başla';
  @override
  String get go => 'Hadi!';
  @override
  String get correct => 'Doğru';
  @override
  String get pass => 'Pas';
  @override
  String passesLeft(int? left) =>
      left == null ? 'Pas: sınırsız' : 'Kalan pas: $left';
  @override
  String get noPassLeft => 'Pas hakkı kalmadı';
  @override
  String get giveUp => 'Vazgeç';
  @override
  String get leaderboards => 'Sıralamalar ve Başarımlar';
  @override
  String get filmThisTurn => 'Bu Turu Kaydet';
  @override
  String get filmOn => 'Kayıt açık: arka kamerayı anlatan kişiye çevir';
  @override
  String get classicGame => 'Pantomim';
  @override
  String get classicGameHint => 'Her turda tek kelime';
  @override
  String get classicHowTo =>
      'Bir oyuncu kelimeyi görür ve konuşmadan canlandırır.\n'
      'Takım bilince "Bildiler!" düğmesine bas; her kelime bir puan.';
  @override
  String get guessedIt => 'Bildiler!';
  @override
  String get changeWord => 'Kelimeyi Değiştir';
  @override
  String changesLeft(int left) => 'Kalan değişiklik: $left';
  @override
  String get wordChangesTitle => 'Kelime Değiştirme (Takım Başına, Tüm Oyun)';
  @override
  String get off => 'Kapalı';
  @override
  String get customWordButton => 'Kelimeyi Rakip Takım Seçsin';
  @override
  String get customWordTitle => 'Rakip Takımın Kelimesi';
  @override
  String get customWordHint =>
      'Kelimeyi yaz, sonra telefonu anlatacak kişiye ver';
  @override
  String get customWordReady => 'Rakip Takımın Kelimesi Hazır';
  @override
  String get confirmWord => 'Bu Kelimeyi Kullan';
  @override
  String get installApp => 'Uygulamayı İndir (Android ve iPhone)';
  @override
  String get giveUpTitle => 'Bu kelimeden vazgeçilsin mi?';
  @override
  String get giveUpBody => 'Kelime bilinmemiş sayılır ve tur hemen sona erer.';
  @override
  String get timeUp => 'Süre Doldu!';
  @override
  String get paused => 'Duraklatıldı';
  @override
  String get resume => 'Devam Et';

  @override
  String get players => 'Oyuncular';
  @override
  String defaultPlayerName(int index) => '${index + 1}. Oyuncu';
  @override
  String get addPlayer => 'Oyuncu Ekle';
  @override
  String get turnsPerPlayer => 'Oyuncu Başına Tur';
  @override
  String get foreheadHowTo =>
      'Telefonu yatay olarak alnına koy, ekran gruba baksın.\n'
      'Arkadaşların kelimeyi sessizce canlandırır, sen tahmin edersin.\n'
      'Aşağı eğ = doğru  •  Yukarı eğ = pas';
  @override
  String get putOnForehead => 'Telefonu alnına koy';
  @override
  String get holdStill => 'Ekran gruba dönük, sabit tut…';
  @override
  String get tiltDownCorrect => 'Aşağı eğ = doğru';
  @override
  String get tiltUpPass => 'Yukarı eğ = pas';
  @override
  String get sensorUnavailable =>
      'Hareket sensörü bulunamadı; düğmelere başka biri bassın.';
  @override
  String get startWithButtons => 'Düğmelerle Başla';

  @override
  String get bonusBadge => '🎁 Bonus';
  @override
  String get unlockTitle => 'Bonus Kategorinin Kilidini Aç';
  @override
  String get unlockBody =>
      'Bu kategoriyi açmak için oyunu arkadaşlarına gönder. Biri bağlantıyı açtığında tüm bonus kategoriler sonsuza dek açık kalır.';
  @override
  String get inviteUnlockedForever =>
      '🎉 Bir arkadaşın bağlantını açtı: bonus kategoriler artık hep açık!';
  @override
  String get watchAd => 'Reklam İzle';
  @override
  String get cancel => 'İptal';
  @override
  String get unlockSkipped => 'Kilidi açmak için reklamı sonuna kadar izle.';
  @override
  String get shareToUnlock => 'Arkadaşlara Gönder';
  @override
  String get inviteText =>
      'Hadi birlikte Pantomim Partisi oynayalım! 🎭 Oyun geceleri için pantomim oyunu:';
  @override
  String get updateAvailable => 'Mağazada yeni bir sürüm var!';

  @override
  String get recordingExplainTitle => 'Eğlenceyi Kaydet 🎥';
  @override
  String get recordingExplainBody =>
      'Telefon Alnında modunda ön kamera arkadaşlarının canlandırmalarını '
      'kaydeder, sonra birlikte izleyip gülersiniz.\n\n'
      'Bunun için kamera ve mikrofon gerekir. Videolar telefonunda kalır ve '
      'asla yüklenmez; yalnızca sen istersen kaydedilir ya da paylaşılır.';
  @override
  String get allow => 'Tamam, Aç';
  @override
  String get notNow => 'Şimdi Değil';
  @override
  String get recordingDenied =>
      'Kamera veya mikrofon izni verilmedi; kayıt kapalı kalacak. '
      'İzni telefon ayarlarından verebilirsin.';
  @override
  String get rec => 'KAYIT';
  @override
  String get saveVideo => 'Videoyu Kaydet';
  @override
  String get videoSaved => 'Video galeriye kaydedildi ✅';
  @override
  String get videoSaveFailed => 'Kaydedilemedi; galeri iznini kontrol et.';
  @override
  String get preparingVideo => 'Video hazırlanıyor…';
  @override
  String get shareVideo => 'Videoyu Paylaş';
  @override
  String get shareCard => 'Skor Kartı';
  @override
  String get shareResult => 'Sonucu Paylaş';
  @override
  String get share => 'Paylaş';
  @override
  String shareCaption(int points) =>
      'Pantomim Partisi’nde $points puan topladık! 🎭 Bizi geçebilir misin?';
  @override
  String get shareResultCaption =>
      'Pantomim Partisi sonuçlarımız 🎭🏆 Gel sen de oyna!';
  @override
  String get cardCorrectWords => 'Bildiğimiz Kelimeler';
  @override
  String get downloadCta => 'Pantomim Partisi’ni indir, arkadaşlarınla oyna!';

  @override
  String get roundSummary => 'Tur Özeti';
  @override
  String get tapToFix =>
      'Yanlış düğmeye mi bastın? Düzeltmek için kelimeye dokun.';
  @override
  String score(int points) => '$points puan';
  @override
  String get timedOutWord => 'Süre bitti';
  @override
  String get noWordsPlayed => 'Hiç kelime oynanmadı!';
  @override
  String get continueLabel => 'Devam';
  @override
  String get scoreboard => 'Skor Tablosu';
  @override
  String nextTurn(String team) => 'Sıradaki: $team';
  @override
  String get seeResults => 'Sonuçları Gör';
  @override
  String get finalResults => 'Final Sonuçları';
  @override
  String winnerIs(String team) => 'Kazanan: $team!';
  @override
  String get itsATie => 'Berabere!';
  @override
  String get playAgain => 'Tekrar Oyna';
  @override
  String get backHome => 'Ana Sayfa';

  @override
  String get exitGameTitle => 'Oyundan çıkılsın mı?';
  @override
  String get exitGameBody => 'Bu oyunun puanları kaybolacak.';
  @override
  String get exit => 'Çık';
  @override
  String get stay => 'Oynamaya Devam';

  @override
  String get sound => 'Ses';
  @override
  String get vibration => 'Titreşim';
  @override
  String get recording => 'Telefon Alnında Modunda Video Kaydı';
  @override
  String get recordingHint => 'Yalnızca Telefon Alnında modunda, ön kamera';
  @override
  String get language => 'Dil';
  @override
  String get about => 'Hakkında';
  @override
  String get aboutBody =>
      'Pantomim Partisi: aile ve arkadaşlar için bir pantomim oyunu.\n'
      'Tamamen çevrimdışı, üyelik gerekmez.';
  @override
  String get privacyPolicy => 'Gizlilik Politikası';
  @override
  String get privacyBody =>
      'Bu oyunda hesap yoktur ve hiçbir kişisel veri toplanmaz.\n'
      'Ayarlar ve kelime geçmişi yalnızca cihazında saklanır.\n'
      'Kaydedilen videolar (açıksa) cihazında kalır ve asla yüklenmez.\n'
      'Oyun reklam gösterir; reklam ağları (Adivery, Tapsell veya AdMob) '
      'reklam sunmak için cihazın reklam kimliğini ve teknik cihaz verilerini '
      'toplayabilir. Açılışta oyun küçük bir ayar dosyası indirir ve senin '
      'hakkında hiçbir şey göndermez.';
  @override
  String get rateApp => 'Uygulamayı Puanla';
  @override
  String get close => 'Kapat';
}
