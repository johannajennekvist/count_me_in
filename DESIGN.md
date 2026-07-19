# Count Me In — Design Doc

## Summary

Count Me In is a counter and goal-tracking app. At its core, it lets someone create counters they can increment or decrement by a custom amount, either for personal goals or for tasks shared with a group where each member contributes to a collective tally while also keeping their own personal count within it.

## Problem

Habit and tally tracking apps are usually either purely personal (a solo counter/habit tracker) or purely social (a shared leaderboard), rarely both at once in something lightweight. Count Me In aims to cover both: quick personal counters for individual goals, and shared group counters for things a group is doing together (e.g. a shared challenge where everyone's contributing to one number, but you can also see how you personally stack up).

## Core Features

- **Personal goals** — create a counter, optionally set a target, increment/decrement by a custom step amount, track progress toward the goal.
- **Group tasks** — a shared counter multiple people contribute to; each person's individual contribution is tracked alongside the group total.
- **Leaderboards** — rank members within a group task by their tally.
- **Auth** — account login so personal and group data sync across devices and group membership is possible at all.

## Current State

MVP is local-only: personal counters with create/edit/delete/increment/decrement, no accounts or backend yet. Group tasks, leaderboards, and auth are not built.

## What's Next

Group tasks, leaderboards, and auth all require a backend with real-time multi-user sync — this pushes the app from local-first to needing something like Firebase or Supabase rather than custom backend infra. Personal-goal features can keep working local-first in the meantime.

## TODO

**Personal goals (polish current MVP)**
- [ ] Fix any remaining rough edges in create/edit/delete/increment/decrement flows
- [ ] Handle edge cases (empty title, zero/negative targets, very large counts)

**Backend & auth**
- [ ] Pick a backend (Firebase or Supabase — either gives auth + realtime data with minimal custom infra)
- [ ] Set up the backend project and configure it in the app
- [ ] Add sign-up/login (email+password and/or Sign in with Apple, since this is iOS-first)
- [ ] Migrate counter storage from local-only to backend-synced, keeping local cache for offline use

**Group tasks**
- [ ] Design the data model (group, members, each member's personal tally, group total)
- [ ] Build "create group task" flow
- [ ] Build "join group task" flow (invite link or code)
- [ ] Build group detail screen showing group total + per-member breakdown
- [ ] Wire up realtime updates so group totals update live across members

**Leaderboards**
- [ ] Build a leaderboard view ranking members within a group task by tally
- [ ] Decide tie-breaking and time-window rules (all-time vs. reset periodically)

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
