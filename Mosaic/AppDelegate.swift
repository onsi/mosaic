import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static let launcherAppId = "com.onsi.MosaicLauncher"

    private let accessibilityAuthorization = AccessibilityAuthorization()
    private let statusItem = MosaicStatusItem.instance
    private var shortcutManager: ShortcutManager!
    private var windowManager: WindowManager!
        
    @IBOutlet weak var mainStatusMenu: NSMenu!
    @IBOutlet weak var unauthorizedMenu: NSMenu!
    @IBOutlet weak var quitMenuItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        mainStatusMenu.delegate = self
        statusItem.refreshVisibility()
        checkLaunchOnLogin()
        
        let alreadyTrusted = accessibilityAuthorization.checkAccessibility {
            self.statusItem.statusMenu = self.mainStatusMenu
            self.accessibilityTrusted()
        }
        
        if alreadyTrusted {
            accessibilityTrusted()
        }
        
        statusItem.statusMenu = alreadyTrusted
            ? mainStatusMenu
            : unauthorizedMenu
        
        mainStatusMenu.autoenablesItems = false
        addWindowActionMenuItems()
    }
    
    func accessibilityTrusted() {
        self.windowManager = WindowManager()
        self.shortcutManager = ShortcutManager(windowManager: windowManager)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusItem.openMenu()
        print(ProcessInfo.processInfo.arguments)
        return true
    }
        
    @IBAction func showAbout(_ sender: Any) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(sender)
    }
    
    @IBAction func authorizeAccessibility(_ sender: Any) {
        accessibilityAuthorization.showAuthorizationWindow()
    }

    private func checkLaunchOnLogin() {
        let running = NSWorkspace.shared.runningApplications
        let isRunning = !running.filter({$0.bundleIdentifier == AppDelegate.launcherAppId}).isEmpty
        if isRunning {
            let killNotification = Notification.Name("killLauncher")
            DistributedNotificationCenter.default().post(name: killNotification, object: Bundle.main.bundleIdentifier!)
        }
        
        let smLoginSuccess = SMLoginItemSetEnabled(AppDelegate.launcherAppId as CFString, true)
        if !smLoginSuccess {
            SMLoginItemSetEnabled(AppDelegate.launcherAppId as CFString, true)
        }
    }
    
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        let screenCount = NSScreen.screens.count
        
        for menuItem in menu.items {
            guard let windowAction = menuItem.representedObject as? WindowAction else { continue }

            menuItem.image = windowAction.image
            menuItem.image?.size = NSSize(width: 18, height: 12)

            if let fullKeyEquivalent = shortcutManager.getKeyEquivalent(action: windowAction),
                let keyEquivalent = fullKeyEquivalent.0?.lowercased() {
                menuItem.keyEquivalent = keyEquivalent
                menuItem.keyEquivalentModifierMask = fullKeyEquivalent.1
            }

            if screenCount == 1 && windowAction == .switchDisplay {
                menuItem.isEnabled = false
            }
        }
        
        quitMenuItem.keyEquivalent = "q"
        quitMenuItem.keyEquivalentModifierMask = .command
    }
    
    func menuDidClose(_ menu: NSMenu) {
        for menuItem in menu.items {
            menuItem.keyEquivalent = ""
            menuItem.keyEquivalentModifierMask = NSEvent.ModifierFlags()
            menuItem.isEnabled = true
        }
    }
    
    func addWindowActionMenuItems() {
        var menuIndex = 0
        for action in WindowAction.active {
            if menuIndex != 0 && action.firstInGroup {
                mainStatusMenu.insertItem(NSMenuItem.separator(), at: menuIndex)
                menuIndex += 1
            }
            
            let newMenuItem = NSMenuItem(title: action.displayName, action: #selector(executeMenuWindowAction), keyEquivalent: "")
            newMenuItem.representedObject = action
            mainStatusMenu.insertItem(newMenuItem, at: menuIndex)
            menuIndex += 1
        }
        mainStatusMenu.insertItem(NSMenuItem.separator(), at: menuIndex)
    }
    
    @objc func executeMenuWindowAction(sender: NSMenuItem) {
        guard let windowAction = sender.representedObject as? WindowAction else { return }
        windowAction.post()
    }
    
}
