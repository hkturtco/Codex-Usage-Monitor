# Codex Usage Monitor

[English](#how-to-use) | [繁體中文](#中文說明)

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

---

## 中文說明

Codex Usage Monitor 是一款 macOS 選單列用量監控工具，特別適合使用 ChatGPT Plus 中的 Codex、擔心在 Vibe Coding（以自然語言與 AI 協作編寫程式）過程中達到使用上限的使用者。無須中斷編寫程式或開啟聊天視窗，就能隨時查看剩餘額度。

上方截圖展示了選單列中的剩餘額度：`Codex: 47% left` 表示還剩 47%。

### 使用方法

1. **登入 Codex。** 在 Mac 上安裝 Codex 桌面應用程式，並使用你的 ChatGPT 帳號登入。本工具主要面向 ChatGPT Plus 使用者。
2. **開啟監控工具。** 按兩下 `Codex Usage Monitor.app`。你可以將它保留在目前的資料夾，也可以移到「應用程式」資料夾。工具只在選單列顯示，不會開啟主視窗，也不會在 Dock 中顯示圖示。
3. **查看剩餘額度。** 選單列中的 `Codex: 47% left` 表示目前的 5 小時額度還剩 47%。資料每分鐘自動更新一次。
4. **點選查看詳細資訊。** 點選選單列文字，可以查看 5 小時及每週的剩餘額度百分比、額度重設時間，以及上次成功更新的時間。重設時間使用 Mac 的本地時區。
5. **手動更新或結束。** 選擇 **Refresh now（立即更新）** 取得最新資料，或選擇 **Quit（結束）** 關閉工具。

### 登入時自動啟動

在 **系統設定 → 一般 → 登入項目 → 登入時開啟** 中加入 `Codex Usage Monitor.app`。加入後，請保持應用程式的位置不變。

### 無法取得用量時

如果選單列顯示 `Codex: —`，點選它查看連線提示。請確認 Codex 已安裝並登入，且 Mac 已連接網際網路，然後選擇 **Refresh now（立即更新）**。工具也會每分鐘自動重試。

### 運作原理

工具使用你現有的本地 Codex 登入狀態，透過官方文件中的 `account/rateLimits/read` 介面取得用量。它不會發起模型對話，也不會消耗推理 Token。無須提供 API Key，原始碼中也不包含個人登入憑證。請保持 Codex 桌面應用程式已安裝並登入。

### 從原始碼建置

原始碼檔案為 `main.swift`。在專案資料夾中執行：

```sh
swiftc main.swift -o 'Codex Usage Monitor.app/Contents/MacOS/CodexUsage'
codesign --force --sign - 'Codex Usage Monitor.app'
```

介面文件：https://learn.chatgpt.com/docs/app-server
