# App Store Connect: what to fill in (copy-paste ready)

Filled in through the App Store Connect API (Oct 2026): name, subtitle,
privacy URL, categories (Games › Word + Family, secondary Entertainment), age
rating answers, content rights, price (free), availability (all territories),
English + Arabic texts, iPhone 6.9" and iPad 13" screenshots, build attached.
Left for the owner in the web UI: App Review contact (name, phone), App Privacy
answers, EU Digital Services Act status, and pressing Submit.

Build: `.github/workflows/ios.yml` (TestFlight, no Mac needed). Needs the
four secrets listed there; then push a tag `ios-<n>` to build and upload.

## Version 1.1.0 (submitted 2026-10-14, build 22)

Name, subtitle, ru/tr listings, language line, posters (`store/appstore/posters`), Game Center and review notes were all set through the API. The items below are done.


- The English name of forehead mode is now **Heads Up** (in the app since
  build 17+). Update the description, review notes and screenshots with the
  next version.
- First line of every description lists the languages, so Iranian users see
  the app is in Persian: `🌍 English · فارسی · العربية · Русский · Türkçe`.
- A more distinctive store name (several apps are already called "Pantomime
  Party"): waiting on the owner's choice.
- Designed (poster-style) screenshots instead of raw screen captures: people
  playing with the phone on the forehead, big headline, device mockup.
- Attach Game Center to the version; add ru / tr listings.

## App record (Apps → ➕ → New App)

| Field | Value |
|---|---|
| Platform | iOS |
| Name (≤30) | `Dorehami: Pantomime & Heads Up` (1.1; was `Pantomime Party: Charades`) |
| Primary language | English (U.S.) |
| Bundle ID | `com.espadna.pantomime` |
| SKU | `pantomime` |

## App Information

| Field | Value |
|---|---|
| Subtitle (≤30) | `Act it out with your friends` |
| Category | Games → primary **Word**, secondary **Family** |
| Content rights | No third-party content |
| Age rating | answer **None** to everything; "Mild cartoon or comedic humor" may be answered **Infrequent/Mild** → result **4+** |
| Privacy Policy URL | `https://espadna.com/pantomime-app/privacy` |
| Copyright | `2026 Espadna` |

## Version page (1.0)

**Promotional text (≤170):**
Game night in your pocket: classic charades, a speed round, or the phone on your forehead. Works offline, no sign-up.

**Description:**
```
Turn any get-together into a laugh-out-loud game night with Pantomime Party!

PANTOMIME (CLASSIC)
The traditional game: one word per turn. One player acts it out without speaking; if the team guesses it before time runs out, one point. 1–10 words per team, 30 s / 1 min / 2 min, optional word changes, or let the other team pick the word. Most words wins.

SPEED PANTOMIME
2–4 teams race the clock: act out and guess as many words as you can in one turn.

HEADS UP
Put the phone on your forehead while your friends act it out. Tilt down = correct, tilt up = pass.

800+ WORDS
Movies, food, animals, jobs, idioms, sports, places, actions, throwback 80s & 90s, funny situations and more.

MORE FUN
• Optional video of the fun (kept on your phone only)
• Shareable score cards
• Works fully offline, no sign-up, family-friendly
• No ads ever interrupt a round
• Also in Persian (فارسی) and Arabic (العربية)
```

**Keywords (≤100):**
`charades,party,game,heads up,forehead,act,guess,word,team,family,friends,mime,group,fun`

**Support URL:** `https://espadna.com/pantomime-app/`
**Marketing URL:** `https://espadna.com/pantomime-app/`

**Screenshots:**
- iPhone 6.9" display: `store/appstore/en/` (1290×2796; `05_forehead.png` is landscape).
  Made from the web build with `?lang=en&screenshot=1` (hides the web install bar).
- iPad 13" display: `store/appstore/ipad-en/` (2048×2732; `05_forehead.png` is landscape).
  The app runs natively on iPad (full screen; the UI is scaled up 1.2–1.4× on tablets,
  `lib/core/widgets/tablet_scale.dart`).

**App Review Information:** no sign-in required. Notes:
`No account needed. Tap "Pantomime", "Speed Pantomime" or "Heads Up", then "Let's go!". Heads Up uses the motion sensor; on the simulator use "Start with Buttons".`

## App Privacy

- Privacy policy URL as above.
- Data collection: **Yes** (the ad SDK is included):
  - Identifiers → Device ID: *Third-party advertising*, not linked to the user, **not** used for tracking.
  - Usage data → Advertising data: same answers.
  - Diagnostics → Crash data: *App functionality*, not linked, not tracking.
  - Location → Coarse location: *Third-party advertising*, not linked, not tracking.
- Camera, microphone and photos are used on the device only: not collected.

## Pricing and availability

- Price: **Free**. Availability: all countries (the App Store does not operate in Iran).
- EU Digital Services Act: answer the question, or the app is not shown in the
  EU. For now **Not a trader** (the iOS build shows no ads yet). **When iOS ads
  are turned on, switch to Trader** (App Information → Digital Services Act) and
  give a work e-mail and phone number; they are shown on the EU product page.

## Agreements

Free apps need no paid-apps agreement, tax or bank forms.

## Export compliance

`ITSAppUsesNonExemptEncryption = NO` is already in Info.plist, so uploads skip
the encryption question.
