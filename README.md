# Codex Usage Monitor

Built especially for people using Codex with ChatGPT Plus who worry about hitting their usage limits while vibe coding. See how much allowance you have left at a glance, without interrupting your coding flow or opening a chat to check.

![macOS menu bar showing Codex: 47% left, followed by the Codex icon and keyboard icon](assets/menu-bar-preview-adjusted.png)

## How to use

1. **Sign in to Codex.** On your Mac, install the Codex desktop app and sign in with your ChatGPT account. This monitor is designed especially for ChatGPT Plus users.
2. **Open the monitor.** Double-click `Codex Usage Monitor.app`. You can keep it in this folder or move it to Applications. It runs in the menu bar without opening a main window or adding a Dock icon.
3. **Check your remaining allowance.** The menu bar shows a label such as `Codex: 47% left`. This means 47% of your current 5-hour allowance remains. It refreshes automatically every minute.
4. **Click the label for details.** The dropdown shows your 5-hour and weekly remaining percentages, reset times, and the last successful update. Reset times use your Mac's local time zone.
5. **Refresh or quit.** Choose **Refresh now** to check immediately, or **Quit** to close the monitor.

### Start automatically

Add `Codex Usage Monitor.app` in **System Settings → General → Login Items → Open at Login**. Keep the app in the same location after adding it.

### If usage is unavailable

If the menu bar shows `Codex: —`, click it to see the connection message. Check that Codex is installed and signed in, and that your Mac is connected to the internet. Then choose **Refresh now**. The monitor also retries automatically every minute.

## How it works

Uses your existing local Codex sign-in and the documented `account/rateLimits/read` app-server method. It does not start model turns or consume inference tokens. No API key is needed, and no personal credentials are included in the source code. Keep the Codex desktop app installed and signed in.

## Build from source

Source: `main.swift`. Build with:

```sh
swiftc main.swift -o 'Codex Usage Monitor.app/Contents/MacOS/CodexUsage'
codesign --force --sign - 'Codex Usage Monitor.app'
```

Protocol reference: https://learn.chatgpt.com/docs/app-server
