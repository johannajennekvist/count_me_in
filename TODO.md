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

**Group tasks**
- [x] Design the data model (group, members, each member's personal tally, group total)
- [x] Build "create group task" flow
- [x] Build "join group task" flow (invite code)
- [x] Build group detail screen showing group total + per-member breakdown
- [x] Wire up realtime updates so group totals update live across members
- [x] Let the group creator edit name/goal, including converting to/from having a goal

**Leaderboards**
- [x] Build a leaderboard view ranking members within a group task by tally
- [ ] Decide tie-breaking and time-window rules (all-time vs. reset periodically)

**Achievements / badges**
- [ ] Award a badge when a counter or group goal is reached (target hit)
- [ ] Save the date a goal was reached
- [ ] Design what a badge actually looks like / where it's shown (not scoped yet — no implementation until this is fleshed out)

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
