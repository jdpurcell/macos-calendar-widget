# macOS Calendar Widget

A small, **interactive month calendar for the macOS Notification Center** (and the
desktop) — the thing macOS doesn't ship: a calendar you can actually page through
month by month, like the Windows taskbar calendar flyout.

Apple's built-in Notification Center calendar widget is view-only (current month,
no navigation). The older third-party apps that did this (MonthlyCal, Calendarique)
were built on the deprecated *Today extension* API and no longer load on modern
macOS. This rebuilds the idea on **WidgetKit + App Intents** — the only interactive
widget model Apple currently supports.

## Features
- Lives in Notification Center / on the desktop (not the menu bar)
- Page months with ◀ ▶; a "today" button jumps back to the current month
- Current day highlighted; locale-aware first day of the week
- Medium and Large sizes

### Roadmap
- Events from Calendar.app (mark days that have meetings) — *next*
- Tap-to-select a date, week numbers, theming

## Requirements
- macOS 14+ (interactive widgets); developed on macOS 26
- Xcode 16 or 26
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build & install
```sh
xcodegen generate
xcodebuild -project CalendarWidget.xcodeproj -scheme CalendarWidget \
  -configuration Debug -derivedDataPath build CODE_SIGN_IDENTITY="-" build
cp -R build/Build/Products/Debug/CalendarWidget.app /Applications/
open /Applications/CalendarWidget.app
```
Then open Notification Center → **Edit Widgets** → add **Calendar Widget**
(Medium or Large).

> If `xcodebuild` reports *"requires Xcode"*, your `xcode-select` points at the
> Command Line Tools. Either run `sudo xcode-select -s /Applications/Xcode.app`
> once, or prefix the build with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

## How it works
- **Signing:** ad-hoc *"Sign to Run Locally"*, so no Apple Developer account is
  needed. Because there's no paid team, the widget avoids App Groups and keeps its
  navigation state inside the extension via `UserDefaults`.
- **Interactivity:** WidgetKit widgets can't use gestures — only `Button`/`Toggle`
  bound to App Intents. The ◀ ▶ / today buttons fire intents that update the stored
  month offset; the system then reloads the timeline and the grid re-renders.

## Project layout
- `project.yml` — XcodeGen spec (source of truth; the `.xcodeproj` is generated and git-ignored)
- `App/` — minimal host app (hosts the widget, shows setup instructions)
- `Widget/` — the WidgetKit extension: widget, timeline provider, App Intents, view
- `Shared/` — month-grid date math and the shared store
