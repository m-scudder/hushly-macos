# Hushly

Hushly is an experimental **macOS menu-bar app** that hides selected personal app windows before Zoom or Slack screen sharing.

## MVP

- Select currently running applications or use **Add app** to choose installed applications that are not running; selected bundle identifiers persist locally.
- A **Protected only** filter keeps saved apps available after they quit.
- Use **Launch at Login** to register Hushly via Apple's ServiceManagement API (may require the app to be installed in Applications and permitted in macOS Login Items).
- Press **Control + Option + Command + H** to cloak protected app windows.
- Keep the apps running; periodically re-hide protected windows if they reappear.
- While cloaked, use **Show** next to a protected running app in the Hushly menu to temporarily allow its windows on screen; select **Hide again** to resume protecting it. Other apps stay cloaked. This exception resets when meeting mode ends.
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

Running apps and previously protected apps appear in the selector. To add an installed app that has not been protected before, use **Add app**. A protected app launched later will be hidden when detected, but not necessarily before its first frame. The build requires macOS and has not yet been compiled/tested on a Mac.

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

## Phase 2 test checklist

1. Install/run Hushly, toggle **Launch at Login**, and check macOS System Settings → General → Login Items.
2. Relaunch/login and verify the menu-bar app starts without manually opening its panel (global shortcut behavior should be retested).
3. Add an installed app via **Add app** without launching it.
4. Quit a protected app, refresh, and verify it stays in the protected list marked **Not running**.
5. Start the app while Meeting Mode is active and inspect for any momentary visibility.
6. Turn Launch at Login off and verify it is unregistered.

Do not use personal/confidential data in screen-sharing tests.
