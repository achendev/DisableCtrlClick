// DisableCtrlClick — rewrites ⌃-left-click into a normal left-click
// This is a full application wrapper for the original script logic.
import Cocoa
import CoreGraphics
import ServiceManagement

//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––//
// MARK: - Permissions Handling
//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––//

// Checks if the necessary permissions have been granted by the user.
@inline(__always) func haveRequiredPermissions() -> Bool {
    return AXIsProcessTrusted() && CGPreflightPostEventAccess()
}

// Shows the system prompts for required permissions and then quits the app.
@inline(__always) func requestPermissionsAndQuit() -> Never {
    if !AXIsProcessTrusted() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }
    if !CGPreflightPostEventAccess() {
        _ = CGRequestPostEventAccess()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { NSApp.terminate(nil) }
    RunLoop.current.run();
    fatalError()
}

//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––//
// MARK: - Event Tap Logic
//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––//

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passRetained(event) }
    let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()

    switch type {
    case .leftMouseDown, .leftMouseUp, .leftMouseDragged:
        if appDelegate.isEnabled && event.flags.contains(.maskControl) {
            var f = event.flags
            f.remove(.maskControl)
            event.flags = f
        }
        return Unmanaged.passRetained(event)

    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        if let tap = appDelegate.eventTap {
             CGEvent.tapEnable(tap: tap, enable: true)
        }
        return nil

    default:
        return Unmanaged.passRetained(event)
    }
}

//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––//
// MARK: - Application Delegate
//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––//

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    var eventTap: CFMachPort?
    var isEnabled = true

    // Setting for "Open at Login", persisted in UserDefaults. Defaults to true.
    var openAtLogin: Bool {
        get { UserDefaults.standard.object(forKey: "openAtLogin") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "openAtLogin") }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard haveRequiredPermissions() else { requestPermissionsAndQuit() }

        // Register to "Open at Login" only if the user has it enabled.
        if openAtLogin {
            updateLoginItem(enabled: true)
        }
        
        setupStatusItem()
        setupEventTap()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let icon = NSImage(named: NSImage.Name("NSTouchBarGoForwardTemplate"))
            icon?.isTemplate = true
            button.image = icon
            button.toolTip = "Disables Ctrl-Click to Right-Click"
        }
        
        if #available(macOS 13.0, *) {
            statusItem.behavior = .removalAllowed
        }
        
        // Create Menu
        let menu = NSMenu()
        
        let enabledMenuItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled(_:)), keyEquivalent: "")
        enabledMenuItem.state = isEnabled ? .on : .off
        menu.addItem(enabledMenuItem)
        
        let loginMenuItem = NSMenuItem(title: "Open at Login", action: #selector(toggleOpenAtLogin(_:)), keyEquivalent: "")
        loginMenuItem.state = openAtLogin ? .on : .off
        menu.addItem(loginMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }

    private func setupEventTap() {
        let eventMask = (
            1 << CGEventType.leftMouseDown.rawValue |
            1 << CGEventType.leftMouseUp.rawValue   |
            1 << CGEventType.leftMouseDragged.rawValue |
            1 << CGEventType.tapDisabledByTimeout.rawValue |
            1 << CGEventType.tapDisabledByUserInput.rawValue
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventTapCallback,
            userInfo: selfPtr
        )
        guard let eventTap = eventTap else { fatalError("Failed to create event tap") }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        isEnabled.toggle()
        sender.state = isEnabled ? .on : .off
    }
    
    @objc private func toggleOpenAtLogin(_ sender: NSMenuItem) {
        openAtLogin.toggle()
        sender.state = openAtLogin ? .on : .off
        updateLoginItem(enabled: openAtLogin)
    }

    private func updateLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "register" : "unregister") for login: \(error.localizedDescription)")
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // If the user re-launches the app, show the status bar icon if it was hidden.
        statusItem?.isVisible = true
        return true
    }
}

//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––//
// MARK: - Main App Execution
//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––//

let delegate = AppDelegate()
let app = NSApplication.shared
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()