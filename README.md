# Hushly

Hushly is an experimental **macOS menu-bar app** that hides selected personal app windows before Zoom or Slack screen sharing.

## MVP

- Select currently running applications to protect; selection persists locally.
- Press **Control + Option + Command + H** to cloak protected app windows.
- Keep the apps running; periodically re-hide protected windows if they reappear.
- Press the shortcut again, or use the menu bar, to restore with macOS device-owner authentication (Touch ID or account password).
- No accounts, cloud sync, keylogger, elevated privileges, or Accessibility permission.

## Build

Requires macOS 14+, Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate
open Hushly.xcodeproj
```

Set a development signing team in Xcode if needed, then run the **Hushly** target.

## Known limitations

**This is not a security or employer-monitoring evasion tool.** Hiding app windows does not hide processes, application icons from all system UIs, Finder files, recent documents, notifications, or app names in share-source selectors. A target app can unhide itself between enforcement checks, possibly producing a visible frame in a screen share. Do not rely on this prototype to guarantee no exposure. Quit while cloaked does not automatically restore apps; macOS can normally unhide them afterward.

Only applications currently running with regular activation policies appear in the selector. A protected app launched later will be hidden when detected, but not necessarily before its first frame. The build requires macOS and has not yet been compiled/tested on a Mac.

Use only where permitted by your organization's device and acceptable-use policies.

## Testing checklist

1. Protect Notes (with harmless sample text) and another test app.
2. Activate meeting mode and verify windows disappear.
3. Attempt to activate a protected app while cloaked, observing any flash.
4. Record an entire display using the macOS screenshot toolbar and review the recording.
5. Repeat in a test Zoom meeting and Slack huddle using dummy data.
6. Restore via shortcut, verify authentication and inspect app state.
7. Inspect Dock, Mission Control, Cmd-Tab and notifications for residual visibility.

The goal is a convenient personal-workspace switch, not OS-level invisibility.
