# Codex Usage Monitor

Built especially for people using Codex with ChatGPT Plus who worry about hitting their usage limits while vibe coding. See how much allowance you have left at a glance, without interrupting your coding flow or opening a chat to check.

![macOS menu bar showing Codex: 47% left, followed by the Codex icon and keyboard icon](assets/menu-bar-preview-adjusted.png)

Open `Codex Usage Monitor.app` to show your remaining 5-hour allowance in the macOS menu bar. Click it for weekly allowance, reset times, the last successful update, manual refresh, and Quit.

Refreshes every minute using your existing Codex sign-in and the documented `account/rateLimits/read` app-server method. It does not start model turns or consume inference tokens. Keep the Codex desktop app installed and signed in. On connection errors the title shows an em dash instead of stale usage, and retries each minute.

To start automatically after restarting your Mac, add this app in System Settings → General → Login Items.

Source: `main.swift`. Build with:

```sh
swiftc main.swift -o 'Codex Usage Monitor.app/Contents/MacOS/CodexUsage'
codesign --force --sign - 'Codex Usage Monitor.app'
```

Protocol reference: https://learn.chatgpt.com/docs/app-server
