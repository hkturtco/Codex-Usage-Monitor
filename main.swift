import Cocoa

final class UsageApp: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var item: NSStatusItem!
    var process: Process?
    var input: FileHandle?
    var buffer = Data()
    var timer: Timer?
    var pending: Int?
    var nextID = 1
    var initialized = false
    var output: FileHandle?
    var lastUpdate: Date?
    let check = CommandLine.arguments.contains("--check")

    func applicationDidFinishLaunching(_ notification: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "…"
        if let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
           let icon = NSImage(contentsOf: url) {
            icon.size = NSSize(width: 16, height: 16)
            icon.isTemplate = true
            item.button?.image = icon
            item.button?.imagePosition = .imageLeft
        }
        item.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        item.button?.setAccessibilityLabel("Codex remaining usage")
        menu(nil)
        if CommandLine.arguments.contains("--check-login") {
            print("Start at Login status: \(CodexLoginStatus()); menu option present: \(item.menu?.item(withTag: 100) != nil)")
            fflush(stdout)
            NSApp.terminate(nil)
            return
        }
        connect()
        let refreshTimer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
        RunLoop.main.add(refreshTimer, forMode: .common)
        timer = refreshTimer
    }

    func connect() {
        guard process == nil else { return }
        initialized = false
        let candidates = [
            "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
            "/Applications/Codex.app/Contents/Resources/codex",
            "/opt/homebrew/bin/codex", "/usr/local/bin/codex"
        ]
        guard let path = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            fail("Codex installation not found"); return
        }
        let p = Process(), stdinPipe = Pipe(), stdoutPipe = Pipe()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = ["app-server"]
        p.currentDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
        p.standardInput = stdinPipe
        p.standardOutput = stdoutPipe
        p.standardError = FileHandle.nullDevice
        input = stdinPipe.fileHandleForWriting
        output = stdoutPipe.fileHandleForReading
        buffer = Data()
        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { handle.readabilityHandler = nil; return }
            DispatchQueue.main.async {
                guard self?.process === p else { return }
                self?.receive(data)
            }
        }
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                guard self?.process === p else { return }
                self?.process = nil; self?.input = nil; self?.pending = nil
                self?.initialized = false
                self?.output?.readabilityHandler = nil
                self?.output = nil
                self?.fail("Connection unavailable; retrying each minute")
            }
        }
        do {
            try p.run(); process = p
            send(["id": 0, "method": "initialize", "params": ["clientInfo": ["name": "codex_usage_bar", "title": "Codex Usage Monitor", "version": "1.0.0"]]])
            DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self] in
                guard let self = self, self.process === p, !self.initialized else { return }
                self.fail("Connection timed out; choose Refresh now to retry")
                self.disconnect()
            }
        } catch { disconnect(); fail("Could not start Codex") }
    }

    func send(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message) else { return }
        do { try input?.write(contentsOf: data + Data([10])) }
        catch { fail("Connection unavailable") }
    }

    func receive(_ data: Data) {
        buffer.append(data)
        while let end = buffer.firstIndex(of: 10) {
            let line = buffer.prefix(upTo: end)
            buffer.removeSubrange(...end)
            guard let message = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any] else { continue }
            if let id = message["id"] as? Int {
                if id == 0 {
                    guard message["error"] == nil else { fail("Could not initialize Codex"); disconnect(); continue }
                    send(["method": "initialized", "params": [:]])
                    initialized = true
                    refresh()
                } else if id == pending {
                    pending = nil
                    if let result = message["result"] as? [String: Any] { update(result) }
                    else { fail("Usage unavailable; check your Codex sign-in") }
                }
            } else if message["method"] as? String == "account/rateLimits/updated",
                      let result = message["params"] as? [String: Any] { update(result) }
        }
    }

    @objc func refresh() {
        guard process?.isRunning == true else { connect(); return }
        guard initialized else { return }
        guard pending == nil else { return }
        let id = nextID; nextID += 1; pending = id
        send(["id": id, "method": "account/rateLimits/read"])
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self] in
            guard let self = self, self.pending == id else { return }
            self.pending = nil
            self.fail("Usage check timed out")
            self.disconnect()
        }
    }

    func remaining(_ window: [String: Any]?) -> String {
        guard let used = window?["usedPercent"] as? Double else { return "unavailable" }
        return "\(Int(max(0, min(100, 100 - used)).rounded()))% left"
    }

    func update(_ result: [String: Any]) {
        let buckets = result["rateLimitsByLimitId"] as? [String: [String: Any]]
        guard let limits = buckets?["codex"] ?? result["rateLimits"] as? [String: Any] else { fail("Usage unavailable"); return }
        let primary = limits["primary"] as? [String: Any]
        let secondary = limits["secondary"] as? [String: Any]
        var text = remaining(primary).replacingOccurrences(of: " left", with: "")
        if let timestamp = primary?["resetsAt"] as? Double {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            text += " ↻ \(formatter.string(from: Date(timeIntervalSince1970: timestamp)))"
        }
        item.button?.title = text
        lastUpdate = Date()
        menu(limits)
        if check { print("\(text) · Weekly: \(remaining(secondary))"); fflush(stdout); NSApp.terminate(nil) }
    }

    func fail(_ reason: String) {
        item.button?.title = "—"
        item.button?.toolTip = reason
        menu(nil, reason: reason)
        if check { print(reason); fflush(stdout); exit(1) }
    }

    func menu(_ limits: [String: Any]?, reason: String? = nil) {
        let menu = NSMenu()
        menu.delegate = self
        func label(_ text: String) { let row = NSMenuItem(title: text, action: nil, keyEquivalent: ""); row.isEnabled = false; menu.addItem(row) }
        if let limits = limits {
            for (key, name) in [("primary", "5-hour allowance"), ("secondary", "Weekly allowance")] {
                let window = limits[key] as? [String: Any]
                label("\(name): \(remaining(window))")
                if let timestamp = window?["resetsAt"] as? Double {
                    let formatter = DateFormatter(); formatter.dateStyle = .short; formatter.timeStyle = .short
                    label("Resets: \(formatter.string(from: Date(timeIntervalSince1970: timestamp)))")
                }
            }
            if let date = lastUpdate {
                let formatter = DateFormatter(); formatter.timeStyle = .short
                label("Updated \(formatter.string(from: date)) · refreshes every minute")
            }
            item.button?.toolTip = "5h: \(remaining(limits["primary"] as? [String: Any])) · Weekly: \(remaining(limits["secondary"] as? [String: Any]))"
        } else { label(reason ?? "Connecting to Codex…") }
        menu.addItem(.separator())
        let refreshItem = NSMenuItem(title: "Refresh now", action: #selector(refresh), keyEquivalent: "r"); refreshItem.target = self; menu.addItem(refreshItem)
        let loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleStartAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.tag = 100
        menu.addItem(loginItem)
        let settingsItem = NSMenuItem(title: "Approve in System Settings…", action: #selector(openLoginSettings), keyEquivalent: "")
        settingsItem.target = self
        settingsItem.tag = 101
        menu.addItem(settingsItem)
        updateLoginItems(menu)
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) { updateLoginItems(menu) }

    func updateLoginItems(_ menu: NSMenu) {
        guard let loginItem = menu.item(withTag: 100) else { return }
        let status = CodexLoginStatus()
        if status >= 0 {
            loginItem.state = status == 1 ? .on : (status == 2 ? .mixed : .off)
            loginItem.title = status == 2 ? "Start at Login (approval required)" : "Start at Login"
            menu.item(withTag: 101)?.isHidden = status != 2
        } else {
            loginItem.isEnabled = false
            loginItem.title = "Start at Login (requires macOS 13+)"
            menu.item(withTag: 101)?.isHidden = true
        }
    }

    @objc func toggleStartAtLogin() {
        let status = CodexLoginStatus()
        guard status >= 0 else { return }
        let enable = status != 1 && status != 2
        var error: NSError?
        if !CodexSetLoginEnabled(enable, &error) {
            let alert = NSAlert()
            alert.messageText = "Could not change Start at Login"
            alert.informativeText = error?.localizedDescription ?? "Please check Login Items in System Settings."
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        } else if enable && CodexLoginStatus() == 2 {
            CodexOpenLoginSettings()
        }
        if let menu = item.menu { updateLoginItems(menu) }
    }

    @objc func openLoginSettings() {
        CodexOpenLoginSettings()
    }

    func disconnect() {
        let oldProcess = process
        process = nil
        initialized = false
        pending = nil
        output?.readabilityHandler = nil
        output = nil
        try? input?.close()
        input = nil
        if oldProcess?.isRunning == true { oldProcess?.terminate() }
    }

    func applicationWillTerminate(_ notification: Notification) { timer?.invalidate(); disconnect() }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = UsageApp()
app.delegate = delegate
app.run()
