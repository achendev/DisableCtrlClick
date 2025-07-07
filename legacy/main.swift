// DisableCtrlClick — rewrites ⌃-left-click into a normal left-click
// LEGACY VERSION for macOS 12 (Monterey) and older.
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
        if event.flags.contains(.maskControl) {
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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard haveRequiredPermissions() else { requestPermissionsAndQuit() }

        // **LEGACY:** Automatically register the app to "Open at Login".
        // This uses the deprecated SMLoginItemSetEnabled for macOS 12 (Monterey)
        // and older.
        let bundleId = "com.usr.DisableCtrlClick" as CFString
        if SMLoginItemSetEnabled(bundleId, true) {
             print("Successfully registered for login.")
        } else {
             print("Failed to register for login using SMLoginItemSetEnabled.")
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let icon = NSImage(named: NSImage.Name("NSTouchBarGoForwardTemplate"))
            icon?.isTemplate = true
            button.image = icon
            button.toolTip = "Disables Ctrl-Click to Right-Click"
        }
        
        // Note: The `statusItem.behavior = .removalAllowed` API is only available
        // on macOS 13+ and is omitted here for compatibility. Cmd+Drag still works.
        
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
}

//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––//
// MARK: - Main App Execution
//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––//

let delegate = AppDelegate()
let app = NSApplication.shared
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()