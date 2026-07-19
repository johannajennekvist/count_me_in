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

See [TODO.md](TODO.md) for the build plan and current progress.
