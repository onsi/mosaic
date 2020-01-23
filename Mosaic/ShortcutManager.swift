import Foundation
import MASShortcut

class ShortcutManager {
    let windowManager: WindowManager
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
        registerDefaults()
        bindShortcuts()
        subscribeAll(selector: #selector(windowActionTriggered))
    }
    
    public func bindShortcuts() {
        for action in WindowAction.active {
            MASShortcutBinder.shared()?.bindShortcut(withDefaultsKey: action.name, toAction: action.post)
        }
    }
    
    public func unbindShortcuts() {
        for action in WindowAction.active {
            MASShortcutBinder.shared()?.breakBinding(withDefaultsKey: action.name)
        }
    }
    
    public func getKeyEquivalent(action: WindowAction) -> (String?, NSEvent.ModifierFlags)? {
        guard let masShortcut = MASShortcutBinder.shared()?.value(forKey: action.name) as? MASShortcut else { return nil }
        return (masShortcut.keyCodeStringForKeyEquivalent, masShortcut.modifierFlags)
    }
    
    deinit {
        unsubscribe()
    }
    
    private func registerDefaults() {
        let defaultShortcuts = WindowAction.active.reduce(into: [String: MASShortcut]()) { dict, windowAction in
            let shortcut = MASShortcut(keyCode: windowAction.keybindingDefaults.keyCode,
                                       modifierFlags: NSEvent.ModifierFlags(rawValue: windowAction.keybindingDefaults.modifierFlags))
            dict[windowAction.name] = shortcut
        }
        
        MASShortcutBinder.shared()?.registerDefaultShortcuts(defaultShortcuts)
    }
    
    @objc func windowActionTriggered(notification: NSNotification) {
        guard let action = notification.object as? WindowAction else { return }
        windowManager.execute(action)
    }
    
    private func subscribe(notification: WindowAction, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: notification.notificationName, object: nil)
    }
    
    private func unsubscribe() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func subscribeAll(selector: Selector) {
        for windowAction in WindowAction.active {
            subscribe(notification: windowAction, selector: selector)
        }
    }
}
