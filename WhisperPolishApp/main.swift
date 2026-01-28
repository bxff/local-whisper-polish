import Cocoa

struct ModelOption {
    let name: String
    let id: String
}

class LogWindowController: NSWindowController {
    var textView: NSTextView!
    var logPath: String
    var fileHandle: FileHandle?
    var source: DispatchSourceFileSystemObject?
    
    init(logPath: String) {
        self.logPath = logPath
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "WhisperPolish Logs"
        window.center()
        
        super.init(window: window)
        
        let scrollView = NSScrollView(frame: window.contentView!.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        
        textView = NSTextView(frame: scrollView.bounds)
        textView.autoresizingMask = [.width, .height]
        textView.isEditable = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.textColor
        
        scrollView.documentView = textView
        window.contentView?.addSubview(scrollView)
        
        loadLogs()
        watchFile()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadLogs() {
        if let content = try? String(contentsOfFile: logPath, encoding: .utf8) {
            textView.string = content
            scrollToBottom()
        }
    }
    
    func watchFile() {
        let fd = open(logPath, O_RDONLY)
        guard fd >= 0 else { return }
        
        fileHandle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        
        // Seek to end
        fileHandle?.seekToEndOfFile()
        
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend],
            queue: .main
        )
        
        source?.setEventHandler { [weak self] in
            self?.readNewContent()
        }
        
        source?.resume()
    }
    
    func readNewContent() {
        guard let data = fileHandle?.readDataToEndOfFile(), !data.isEmpty else { return }
        if let newContent = String(data: data, encoding: .utf8) {
            textView.string += newContent
            scrollToBottom()
        }
    }
    
    func scrollToBottom() {
        textView.scrollToEndOfDocument(nil)
    }
    
    deinit {
        source?.cancel()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var serverProcess: Process?
    var currentModelId: String
    var logWindowController: LogWindowController?
    var serverReady = false
    var healthCheckTimer: Timer?
    
    let presetModels = [
        ModelOption(name: "Qwen3 4B (Recommended)", id: "mlx-community/Qwen3-4B-Instruct-2507-4bit"),
        ModelOption(name: "Qwen3 8B (Better)", id: "mlx-community/Qwen3-8B-Instruct-4bit"),
        ModelOption(name: "Qwen2.5 3B (Faster)", id: "mlx-community/Qwen2.5-3B-Instruct-4bit"),
        ModelOption(name: "Gemma 3n E4B", id: "mlx-community/gemma-3n-E4B-it-4bit"),
    ]
    
    let serverURL = "http://localhost:8080"
    let logPath = NSHomeDirectory() + "/Library/Logs/WhisperPolish.log"
    
    override init() {
        self.currentModelId = UserDefaults.standard.string(forKey: "selectedModel") 
            ?? "mlx-community/Qwen3-4B-Instruct-2507-4bit"
        super.init()
    }
    
    func saveModel(_ modelId: String) {
        currentModelId = modelId
        UserDefaults.standard.set(modelId, forKey: "selectedModel")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateMenu()
        startServer()
    }
    
    func modelDisplayName(_ modelId: String) -> String {
        if let preset = presetModels.first(where: { $0.id == modelId }) {
            return preset.name
        }
        return modelId.components(separatedBy: "/").last ?? modelId
    }
    
    func updateMenu() {
        let menu = NSMenu()
        let processRunning = serverProcess?.isRunning ?? false
        
        // Yellow = starting, Green = ready, Gray = stopped
        if processRunning && serverReady {
            statusItem.button?.image = coloredCircle(color: .systemGreen)
        } else if processRunning {
            statusItem.button?.image = coloredCircle(color: .systemYellow)
        } else {
            statusItem.button?.image = coloredCircle(color: .systemGray)
        }
        
        let statusText = processRunning ? (serverReady ? "Running" : "Starting...") : "Stopped"
        let statusMenuItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        let urlItem = NSMenuItem(title: serverURL, action: #selector(copyURL), keyEquivalent: "")
        urlItem.toolTip = "Click to copy"
        menu.addItem(urlItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let modelMenuItem = NSMenuItem(title: modelDisplayName(currentModelId), action: nil, keyEquivalent: "")
        modelMenuItem.isEnabled = false
        menu.addItem(modelMenuItem)
        
        let modelMenu = NSMenu()
        for model in presetModels {
            let item = NSMenuItem(title: model.name, action: #selector(selectPresetModel(_:)), keyEquivalent: "")
            item.representedObject = model.id
            item.state = model.id == currentModelId ? .on : .off
            modelMenu.addItem(item)
        }
        modelMenu.addItem(NSMenuItem.separator())
        modelMenu.addItem(NSMenuItem(title: "Custom Model...", action: #selector(showCustomModelDialog), keyEquivalent: ""))
        
        let modelSubmenu = NSMenuItem(title: "Change Model", action: nil, keyEquivalent: "")
        modelSubmenu.submenu = modelMenu
        menu.addItem(modelSubmenu)
        
        menu.addItem(NSMenuItem.separator())
        
        if processRunning {
            menu.addItem(NSMenuItem(title: "Stop Server", action: #selector(stopServer), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Restart Server", action: #selector(restartServer), keyEquivalent: "r"))
        } else {
            menu.addItem(NSMenuItem(title: "Start Server", action: #selector(startServer), keyEquivalent: ""))
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "View Logs", action: #selector(openLogs), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        self.statusItem.menu = menu
    }
    
    func coloredCircle(color: NSColor) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        let path = NSBezierPath(ovalIn: NSRect(x: 4, y: 4, width: 10, height: 10))
        path.fill()
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
    
    @objc func copyURL() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(serverURL, forType: .string)
    }
    
    @objc func startServer() {
        // Ensure log directory exists and create log file
        let logDir = (logPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: logDir, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: logPath, contents: nil)
        
        guard let logHandle = FileHandle(forWritingAtPath: logPath) else {
            print("Failed to open log file")
            return
        }
        
        // Use shell to resolve python3 from user's shell environment
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "python3 -m mlx_lm.server --model \(currentModelId) --port 8080"]
        process.standardOutput = logHandle
        process.standardError = logHandle
        
        // Set environment with unbuffered python output
        var env = ProcessInfo.processInfo.environment
        env["PYTHONUNBUFFERED"] = "1"
        process.environment = env
        
        do {
            try process.run()
            serverProcess = process
            serverReady = false
            updateMenu()
            startHealthCheck()
        } catch {
            print("Failed to start server: \(error)")
        }
    }
    
    func startHealthCheck() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkServerHealth()
        }
    }
    
    func checkServerHealth() {
        guard let url = URL(string: "\(serverURL)/v1/models") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self?.serverReady = true
                    self?.healthCheckTimer?.invalidate()
                    self?.healthCheckTimer = nil
                }
                self?.updateMenu()
            }
        }
        task.resume()
    }
    
    @objc func stopServer() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
        serverProcess?.terminate()
        serverProcess?.waitUntilExit()
        serverProcess = nil
        serverReady = false
        updateMenu()
    }
    
    @objc func restartServer() {
        stopServer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startServer()
        }
    }
    
    @objc func selectPresetModel(_ sender: NSMenuItem) {
        guard let modelId = sender.representedObject as? String else { return }
        saveModel(modelId)
        restartServer()
    }
    
    @objc func showCustomModelDialog() {
        let alert = NSAlert()
        alert.messageText = "Custom Model"
        alert.informativeText = "Enter mlx-community model ID:\n(e.g., mlx-community/Qwen3-4B-Instruct-2507-4bit)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 350, height: 24))
        input.stringValue = currentModelId
        alert.accessoryView = input
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let modelId = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !modelId.isEmpty {
                saveModel(modelId)
                restartServer()
            }
        }
    }
    
    @objc func openLogs() {
        // Ensure log file exists
        if !FileManager.default.fileExists(atPath: logPath) {
            FileManager.default.createFile(atPath: logPath, contents: nil)
        }
        
        // Show log window
        if logWindowController == nil {
            logWindowController = LogWindowController(logPath: logPath)
        }
        logWindowController?.showWindow(nil)
        logWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quit() {
        stopServer()
        NSApp.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopServer()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
