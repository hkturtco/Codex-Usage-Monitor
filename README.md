# Codex Usage Monitor

[English](#how-to-use) | [繁體中文](#中文說明)

Built especially for people using Codex with ChatGPT Plus who worry about hitting their usage limits while vibe coding. See how much allowance you have left at a glance, without interrupting your coding flow or opening a chat to check.

![Codex usage monitor showing 27% remaining and a 13:58 reset time in the macOS menu bar](assets/menu-bar-current.png)

The current version uses a compact icon + percentage + next reset time display, such as `27% ↻ 13:58`.

## How to use

1. **Sign in to Codex.** On your Mac, install the Codex desktop app and sign in with your ChatGPT account. This monitor is designed especially for ChatGPT Plus users.
2. **Open the monitor.** Double-click `Codex Usage Monitor.app`. You can keep it in this folder or move it to Applications. It runs in the menu bar without opening a main window or adding a Dock icon.
3. **Check your remaining allowance.** The menu bar shows a small usage icon followed by a percentage and the next 5-hour reset time, such as `27% ↻ 13:58`. This means 27% remains and the allowance resets at 13:58 in your Mac's local time zone. It refreshes automatically every minute.
4. **Click the label for details.** The dropdown shows your 5-hour and weekly remaining percentages, reset times, and the last successful update. Reset times use your Mac's local time zone.
5. **Refresh or quit.** Choose **Refresh now** to check immediately, or **Quit** to close the monitor.

### Start automatically

Click the menu bar label and select **Start at Login**. A checkmark means automatic startup is enabled; select it again to turn it off. This option requires macOS 13 or later.

If macOS requires approval, choose **Approve in System Settings…** and allow the app in Login Items. Move the app to its permanent location before enabling automatic startup, and keep it there afterward.

### If usage is unavailable

If the menu bar shows `—`, click it to see the connection message. Check that Codex is installed and signed in, and that your Mac is connected to the internet. Then choose **Refresh now**. The monitor also retries automatically every minute.

## How it works

Uses your existing local Codex sign-in and the documented `account/rateLimits/read` app-server method. It does not start model turns or consume inference tokens. No API key is needed, and no personal credentials are included in the source code. Keep the Codex desktop app installed and signed in.

## Build from source

Source: `main.swift`. Build with:

```sh
clang -fobjc-arc -c LoginStartup.m -o /tmp/CodexLoginStartup.o
swiftc -import-objc-header LoginStartup.h main.swift /tmp/CodexLoginStartup.o -framework ServiceManagement -o 'Codex Usage Monitor.app/Contents/MacOS/CodexUsage'
codesign --force --sign - 'Codex Usage Monitor.app'
```

Protocol reference: https://learn.chatgpt.com/docs/app-server

---

## 中文說明

Codex Usage Monitor 是一款 macOS 選單列用量監控工具，特別適合使用 ChatGPT Plus 中的 Codex、擔心在 Vibe Coding（以自然語言與 AI 協作編寫程式）過程中達到使用上限的使用者。無須中斷編寫程式或開啟聊天視窗，就能隨時查看剩餘額度。

上方截圖展示目前的小圖示、剩餘百分比及下次重設時間，例如 `27% ↻ 13:58`，表示還剩 27%，並於 13:58 重設，節省選單列空間。

### 使用方法

1. **登入 Codex。** 在 Mac 上安裝 Codex 桌面應用程式，並使用你的 ChatGPT 帳號登入。本工具主要面向 ChatGPT Plus 使用者。
2. **開啟監控工具。** 按兩下 `Codex Usage Monitor.app`。你可以將它保留在目前的資料夾，也可以移到「應用程式」資料夾。工具只在選單列顯示，不會開啟主視窗，也不會在 Dock 中顯示圖示。
3. **查看剩餘額度。** 選單列的小圖示旁顯示 `27% ↻ 13:58`，表示目前的 5 小時額度還剩 27%，下次重設時間為 Mac 本地時區的 13:58。資料每分鐘自動更新一次。
4. **點選查看詳細資訊。** 點選選單列文字，可以查看 5 小時及每週的剩餘額度百分比、額度重設時間，以及上次成功更新的時間。重設時間使用 Mac 的本地時區。
5. **手動更新或結束。** 選擇 **Refresh now（立即更新）** 取得最新資料，或選擇 **Quit（結束）** 關閉工具。

### 登入時自動啟動

點選選單列文字，再選擇 **Start at Login（登入時啟動）**。勾選標記表示已啟用自動啟動；再次點選即可關閉。此選項需要 macOS 13 或更新版本。

如果 macOS 要求核准，請選擇 **Approve in System Settings…（在系統設定中核准）**，並在登入項目中允許此應用程式。啟用前，請先將應用程式移至固定位置，之後保持位置不變。

### 無法取得用量時

如果選單列顯示 `—`，點選它查看連線提示。請確認 Codex 已安裝並登入，且 Mac 已連接網際網路，然後選擇 **Refresh now（立即更新）**。工具也會每分鐘自動重試。

### 運作原理

工具使用你現有的本地 Codex 登入狀態，透過官方文件中的 `account/rateLimits/read` 介面取得用量。它不會發起模型對話，也不會消耗推理 Token。無須提供 API Key，原始碼中也不包含個人登入憑證。請保持 Codex 桌面應用程式已安裝並登入。

### 從原始碼建置

原始碼檔案為 `main.swift`。在專案資料夾中執行：

```sh
clang -fobjc-arc -c LoginStartup.m -o /tmp/CodexLoginStartup.o
swiftc -import-objc-header LoginStartup.h main.swift /tmp/CodexLoginStartup.o -framework ServiceManagement -o 'Codex Usage Monitor.app/Contents/MacOS/CodexUsage'
codesign --force --sign - 'Codex Usage Monitor.app'
```

介面文件：https://learn.chatgpt.com/docs/app-server
