# Store notes: release checklists, privacy forms, listing text

Package / bundle id: `com.espadna.pantomime` (same in every store and on
iOS). Change it everywhere with `python3 tool/set_package.py <new id>`.
Everything only you can do is listed in [OWNER_TODO.md](OWNER_TODO.md).

## Build per store

```bash
cp ad_keys.example.json ad_keys.json        # fill in ids + CONFIG_URL(s); git-ignored
ADMOB_APP_ID=ca-app-pub-…~… tool/release.sh play     # → AAB (Google Play)
tool/release.sh bazaar                                # → APK (Cafe Bazaar)
tool/release.sh myket                                 # → APK (Myket)
tool/release.sh ios                                   # → IPA (on a Mac with Xcode)
```

`tool/release.sh` selects the store's ad-SDK profile (Bazaar/Myket: Adivery
only, no AdMob/Google Play Services), builds the matching flavor (obfuscated,
R8-shrunk) and restores the dev profile. Keep `build/symbols/<store>/`
for each release to read crash stack traces.

Verified in this repo (2026-10-01): all three Android release builds succeed.
Bazaar/Myket APKs contain **0** `com.google.android.gms` classes, no
`AD_ID` permission and no AdMob app id. (Bazaar/Myket universal APK ≈ 54 MB;
Play AAB → per-device downloads are much smaller. To shrink Bazaar/Myket,
upload per-ABI APKs if the store accepts several:
`flutter build apk --flavor bazaar --split-per-abi`.)

## Signing: one upload key per store

```bash
mkdir -p ~/pantomime-keys
for s in play bazaar myket; do
  keytool -genkeypair -v -keystore ~/pantomime-keys/$s-upload.jks \
    -keyalg RSA -keysize 4096 -validity 10000 -alias $s-upload
done
```

Then create `android/keys/<store>.properties` (the folder is git-ignored):

```properties
storeFile=/Users/you/pantomime-keys/bazaar-upload.jks
storePassword=…
keyAlias=bazaar-upload
keyPassword=…
```

Without that file a release build is signed with the debug key. That's fine
for testing, but **never upload** such a build. Back up the `.jks` files and
passwords somewhere safe (a password manager plus an offline copy). Losing a
Bazaar/Myket key means you can't update the app there.

- **Google Play**: use Play App Signing (default). Your key above is the
  *upload* key.
- **Cafe Bazaar / Myket**: they keep the key you sign with; the APK must be
  signed with the same key forever.

## Checklists

### Google Play
- [ ] Developer account (one-time USD 25 fee; identity verification).
- [ ] Create app → default language **Persian (fa)** + English (en-US)
      listing.
- [ ] Upload `app-play-release.aab` to *Internal testing* first.
- [ ] Store listing: icon `assets/branding/icon_512.png`, feature graphic
      `assets/branding/feature_graphic_1024x500.png`, 4–8 phone
      screenshots (see below).
- [ ] App content: privacy policy URL (`https://<worker>/privacy`), ads =
      **Yes**, Data safety (below), content rating questionnaire (below),
      target audience 13+ (avoid the Families policy because of ad SDKs),
      news app = no.
- [ ] AdMob: create the app in AdMob, link it to Play, put the real app id in
      `ADMOB_APP_ID` and the unit ids in `ad_keys.json` or the bot (`/keys`).
- [ ] `app-ads.txt` on your developer website, if you list one (AdMob
      requirement for full fill).

### Cafe Bazaar (کافه‌بازار)
- [ ] Developer account at <https://pishkhan.cafebazaar.ir> (Iranian
      identity verification; small one-time fee).
- [ ] New app → upload `app-bazaar-release.apk` (signed with the Bazaar key).
- [ ] Persian title «پانتومیم دورهمی», short + long description (below),
      icon 512×512, at least 2 screenshots, category: *Games → Casual/Party*.
- [ ] Age rating: 3+ / all ages; ads = yes; privacy policy URL.
- [ ] Adivery: register the app in the Adivery panel, create placements,
      enter ids through the bot (`/keys adivery …`).
- [ ] Test on a phone **without Google Play Services** before release.

### Myket (مایکت)
- [ ] Developer account at <https://developer.myket.ir> (identity
      verification).
- [ ] Upload `app-myket-release.apk` (signed with the Myket key), same
      listing assets as Bazaar.
- [ ] Ads = yes, privacy policy URL, age rating all ages.

### Apple App Store (iOS)
- [ ] Apple Developer Program (USD 99/year). Paying from Iran is often not
      possible; you may need a trusted person or company abroad.
- [ ] Set the bundle id and team in Xcode (`ios/Runner.xcodeproj`), create
      the app in App Store Connect.
- [ ] `ios/Flutter/AdKeys.xcconfig` with `ADMOB_APP_ID=…`; build with
      `IOS_APP_ID` in `ad_keys.json` (needed for the "Rate app" link).
- [ ] `tool/release.sh ios`, then upload with Xcode/Transporter.
- [ ] Privacy nutrition label (below); no ATT prompt (AdMob runs without
      IDFA).
- [ ] Note: Apple may reject apps whose store presence targets Iran under
      sanctions rules; list the app for Persian speakers worldwide.

## Privacy forms

### Google Play Data safety

| Data | Collected? | Notes |
|---|---|---|
| Device or other IDs (advertising ID) | **Yes**, by AdMob SDK (Play build) | Advertising; not linked to identity; shared with Google |
| App interactions / diagnostics | **Yes**, by the ad SDKs (Adivery includes Sentry crash reports) | Ads / analytics |
| Approximate location (IP) | Processed by ad SDKs | Ads |
| Photos/videos, audio | **No** | Recorded only on the device when the user enables it; never uploaded |
| Personal info, contacts, messages, financial | No | |

- Data encrypted in transit: Yes (HTTPS).
- Users can request deletion: no account and no server-side personal data;
  ad networks handle their own deletion.
- Our config server receives an HTTPS request with no identifiers (IP only,
  not stored).

### iOS privacy label (App Store Connect)
- **Data used to track you:** Device ID only if you later enable ATT +
  personalized ads; with the current setup choose "No".
- **Data not linked to you:** *Identifiers → Device ID* (AdMob),
  *Usage data → Advertising data*, *Diagnostics → Crash data* (ad SDK),
  *Location → Coarse location* (IP, by AdMob).
- Camera/microphone are used on-device only and nothing is collected.

### Bazaar / Myket
Answer "ads: yes", "collects personal info: no", and give the privacy URL.
Mention camera/microphone are optional and on-device only.

## Content rating notes (IARC questionnaire)

- Violence: none. Sexual content: none. Language: none. Drugs/alcohol/
  tobacco: none. Gambling: none (no real-money or simulated gambling).
- **Crude humor: mild** (category «خنده‌دار و خجالت‌آور»: hiccups, snoring,
  slipping on a banana peel).
- User-generated content / user interaction: **none**. Team names stay on the
  device; shared images and videos go through the OS share sheet only.
- Ads: yes. In-app purchases: no. Location sharing: no.
- Expected rating: PEGI 3 / ESRB Everyone / IARC 3+.

## Screenshots checklist (phone, 1080×1920 or larger)

Take them on a real phone in Persian, with real-looking team names:
1. Home (logo + two big buttons).
2. Setup with 3–4 teams and categories.
3. Play screen with a big word and the timer in the last 10 s (red).
4. Round summary with ✅/❌ words.
5. Forehead mode in landscape (word + "سر پایین = درست").
6. Final result with 🏆.
7. Optional: the 🖼️ share card.

Add a short Persian caption on top of each (for example «بی‌صدا بازی کن، بلند
بخند!»). Bazaar/Myket accept the same set. Use 1–2 landscape shots for
forehead mode.

## Listing text

**Title:** پانتومیم دورهمی · **Short name (under icon):** پانتومیم

**Short description (≤80):**
بازی پانتومیم و حدس کلمه برای دورهمی‌ها؛ تیمی یا گوشی روی پیشونی!

**Long description:**
> دورهمی‌تان را با «پانتومیم دورهمی» پر از خنده کنید! 🎭
>
> 👥 **بازی تیمی:** ۲ تا ۴ تیم، زمان و تعداد نوبت دلخواه، یک نفر بی‌صدا ادا
> درمی‌آورد و هم‌تیمی‌ها حدس می‌زنند.
> 🤳 **گوشی روی پیشونی:** گوشی را روی پیشانی بگذار؛ دوستانت ادا درمی‌آورند،
> سرت را پایین بیاور = درست، بالا = پاس.
> 📚 بیش از ۹۰۰ کلمه در ۱۳ دسته: فیلم و سریال، غذای ایرانی، حیوانات،
> ضرب‌المثل، خاطرات دهه ۶۰ و ۷۰ و …
> 🎥 ضبط ویدیوی خنده‌دار از بازی (اختیاری) و ارسال کارت امتیاز برای دوستان.
> ✅ کاملاً آفلاین، بدون ثبت‌نام، مناسب همه سنین. در حین بازی هیچ تبلیغی نمایش
> داده نمی‌شود.

**English (for reviewers / en-US listing):**
> Pantomime Party: a charades game for family and friends. Team mode
> (2–4 teams) and forehead mode (tilt down = correct, tilt up = pass).
> 900+ Persian words in 13 categories, optional video recording of the fun
> (kept on your device), shareable score cards. Fully offline, no sign-up,
> no ads during a round.
