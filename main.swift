import Cocoa

final class UsageApp: NSObject, NSApplicationDelegate {
    var item: NSStatusItem!
    var process: Process?
    var input: FileHandle?
    var buffer = Data()
    var timer: Timer?
    var pending: Int?
    var nextID = 1
    var lastUpdate: Date?
    let check = CommandLine.arguments.contains("--check")

    func applicationDidFinishLaunching(_ notification: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "Codex: …"
        menu(nil)
        connect()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func connect() {
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
        buffer = Data()
        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { handle.readabilityHandler = nil; return }
            DispatchQueue.main.async { self?.receive(data) }
        }
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                guard self?.process === p else { return }
                self?.process = nil; self?.input = nil; self?.pending = nil
                self?.fail("Connection unavailable; retrying each minute")
            }
        }
        do {
            try p.run(); process = p
            send(["id": 0, "method": "initialize", "params": ["clientInfo": ["name": "codex_usage_bar", "title": "Codex Usage Monitor", "version": "1.0.0"]]])
        } catch { fail("Could not start Codex") }
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
                    guard message["error"] == nil else { fail("Could not initialize Codex"); continue }
                    send(["method": "initialized", "params": [:]])
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
        guard pending == nil else { return }
        let id = nextID; nextID += 1; pending = id
        send(["id": id, "method": "account/rateLimits/read"])
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self] in
            guard let self = self, self.pending == id else { return }
            self.pending = nil
            self.fail("Usage check timed out")
            self.process?.terminate()
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
        let text = "Codex: \(remaining(primary))"
        item.button?.title = text
        lastUpdate = Date()
        menu(limits)
        if check { print("\(text) · Weekly: \(remaining(secondary))"); fflush(stdout); NSApp.terminate(nil) }
    }

    func fail(_ reason: String) {
        item.button?.title = "Codex: —"
        item.button?.toolTip = reason
        menu(nil, reason: reason)
        if check { print(reason); fflush(stdout); exit(1) }
    }

    func menu(_ limits: [String: Any]?, reason: String? = nil) {
        let menu = NSMenu()
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
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
    }

    func applicationWillTerminate(_ notification: Notification) { timer?.invalidate(); process?.terminate() }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = UsageApp()
app.delegate = delegate
app.run()
