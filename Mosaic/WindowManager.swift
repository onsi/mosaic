import Cocoa

class WindowManager {
    private var windowHistory: [WindowId: WindowEvent]
    
    init() {
        self.windowHistory = [WindowId: WindowEvent]()
    }
    
    func execute(_ action: WindowAction) {
        guard let window = Window.frontmostWindow() else {
            NSSound.beep()
            return
        }
        
        let id = window.getIdentifier()
        let previousEvent = id != nil ? self.windowHistory[id!] : nil
                        
        if let event = window.execute(action, previousEvent: previousEvent) {
            if id != nil {
                self.windowHistory[id!] = event
            }
        }
    }
}
