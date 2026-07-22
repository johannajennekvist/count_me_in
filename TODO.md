# Count Me In — TODO

**Personal goals (polish current MVP)**
- [x] Fix keyboard not dismissing when tapping outside the step field
- [x] Fix delete confirmation dialog text overflow
- [ ] Handle edge cases (empty title, zero/negative targets, very large counts)

**Backend & auth**
- [x] Pick a backend — Firebase
- [x] Set up the Firebase project and configure it in the app
- [x] Add sign-up/login (email+password and Google Sign-In)
- [x] Migrate counter storage from local-only to Firestore
- [ ] Configure Firebase for the web platform — `firebase_options.dart` only has android/ios/macos (never ran `flutterfire configure` for web), so `flutter run -d chrome` throws immediately on `Firebase.initializeApp()` and can't be used for browser-based testing/dev right now

**Group tasks**
- [x] Design the data model (group, members, each member's personal tally, group total)
- [x] Build "create group task" flow
- [x] Build "join group task" flow (invite code)
- [x] Build group detail screen showing group total + per-member breakdown
- [x] Wire up realtime updates so group totals update live across members
- [x] Let the group creator edit name/goal, including converting to/from having a goal
- [x] Add copy-to-clipboard on the invite code popup, with visual feedback that it was copied
- [x] Add a "Share" button on the invite code popup using the native share sheet (`share_plus`), sharing the code as plain text
- [ ] Upgrade invite sharing to a tappable deep link that opens the app straight to "join this group" (skips manually typing the code). Needs Universal Links (iOS) / App Links (Android): a domain to host `apple-app-site-association` / `assetlinks.json` over HTTPS, Associated Domains + intent filter config in the native projects, and an `app_links`-based listener in Flutter to catch the incoming URL and route to the join flow. Bigger lift than the plain-text share — worth doing once there's real distribution (ties into the Distribution section below)
- [ ] Make invite codes actually unique — `_generateCode()` currently just picks 6 random chars with no check against existing codes in Firestore, so a collision (two groups sharing a code) is possible, just unlikely at small scale
- [ ] Send a notification to all other group members when the group's goal is reached (currently the celebration popup only shows to whoever has the group screen open at that moment)

**Accounts & profile**
- [x] Add a guest/offline mode — "Continue without an account" on the login page, personal counters stored on-device only (SharedPreferences), no cloud sync; Groups tab shows a sign-in prompt since group tasks are inherently multi-user
- [x] Let users set an optional username at sign-up (stored as the Firebase Auth display name), shown to other group members instead of their full name/email-derived name
- [x] Confirm password (twice) when creating an account
- [x] Let users change their password from Settings (current password, then new password twice) — only shown for email/password accounts, not Google sign-in
- [ ] Add "Forgot password" — send a password reset email link
- [ ] Improve the login flow further (revisit UX, consider additional sign-in options)
- [ ] Look into Apple Sign In (likely required by App Store review if Google Sign-In stays as an option)

**Friends & social**
- [ ] Look into a friends system — add/accept friends
- [ ] Let friends view each other's counters on a profile page
- [ ] Send a notification when a friend reaches a goal
- [ ] Invite friends directly to a group counter (instead of only sharing a code)

**Leaderboards**
- [x] Build a leaderboard view ranking members within a group task by tally
- [ ] Decide tie-breaking and time-window rules (all-time vs. reset periodically)

**Achievements / badges**
- [x] Award a badge when a personal counter's goal is reached (target hit), shown as a horizontal scrollable viewer under Notes, capped at the latest 15
- [x] Save the date a goal was reached
- [x] Award badges for group goals too, shown under the members list, attributed to whichever member's increment crossed the goal (initials shown on the badge)
- [ ] Look into time-targeted goals and streaks (e.g. daily/weekly goals, consecutive-day streak tracking)
- [x] Show a celebratory popup when a goal is reached (personal counters and group goals)
- [x] From that popup, offer an option to raise/update the goal right there instead of needing to go find the edit button
- [x] Show a number on each badge icon for the value it was reached at, formatted compactly for large numbers (999 as-is, then 1k, 1.4k, 1M, etc.)
- [x] Different colors of badge icons (5-color cycle by chronological order the goal was reached)

**Visuals & platform features**
- [ ] Add a light/dark mode switch in Settings (app currently follows system theme only — `ThemeMode.system` in `main.dart`)
- [ ] Investigate icon language/style options — look at swapping from Material Icons to a different consistent icon set (or a specific style variant, e.g. outlined vs. filled) to better match the app's look
- [ ] Look into localization (support languages beyond English)
- [ ] Investigate an iOS home screen widget (WidgetKit) for incrementing/decrementing a counter without opening the app

**Distribution**
- [ ] Enroll in the Apple Developer Program ($99/yr) when ready to share beyond your own device
- [ ] Set up App Store Connect record and app icon
- [ ] Run a TestFlight beta with a few real users (friends/family group is a natural first test)
- [ ] Write a privacy policy (required even for simple apps, more so once accounts/backend exist)
- [ ] Submit for App Store review

**Monetization (later, once group features exist)**
- [ ] Decide free-tier limits (e.g. capped number of personal counters)
- [ ] Scope what a paid tier unlocks (unlimited counters and/or group features)
- [ ] Implement in-app purchase or subscription via StoreKit
