# App Store Connect: what to fill in (copy-paste ready)

Build: `.github/workflows/ios.yml` (TestFlight, no Mac needed). Needs the
four secrets listed there; then push a tag `ios-<n>` to build and upload.

## App record (Apps → ➕ → New App)

| Field | Value |
|---|---|
| Platform | iOS |
| Name (≤30) | `Pantomime Party: Charades` |
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
Game night in your pocket: act it out in teams or put the phone on your forehead. Works offline, no sign-up.

**Description:**
```
Turn any get-together into a laugh-out-loud game night with Pantomime Party!

TEAM GAME
2–4 teams, pick the turn length and number of rounds. One player acts out the word without speaking while teammates shout their guesses.

FOREHEAD MODE
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
- iPad 13" display: `store/appstore/ipad-en/` (2048×2732; `05_forehead.png` is landscape).
  The app runs natively on iPad (full screen; the UI is scaled up 1.2–1.4× on tablets,
  `lib/core/widgets/tablet_scale.dart`).

**App Review Information:** no sign-in required. Notes:
`No account needed. Tap "Team game" or "Forehead mode", then "Let's go!". Forehead mode uses the motion sensor; on the simulator use "Start with buttons".`

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
