import Cocoa

class Screens {
    let screens: [NSScreen]
    let originScreen: NSScreen
    
    static func detect() -> Screens {
        return Screens(NSScreen.screens, NSScreen.screens[0])
    }
    
    init(_ screens: [NSScreen], _ originScreen: NSScreen) {
        self.screens = screens
        self.originScreen = originScreen
    }
    
    func screenContaining(_ window: Window) -> NSScreen? {
        return screens.max(by: {a, b in percentageOf(window, withinScreen: a) < percentageOf(window, withinScreen: b)})
    }
   
    func screenAfter(_ screen: NSScreen) -> NSScreen{
        let i = screens.firstIndex(of: screen)! + 1
        if i >= screens.count {
            return screens[0]
        }
        return screens[i]
    }
    
    private func percentageOf(_ window: Window, withinScreen screen: NSScreen) -> CGFloat {
        let rect = window.normalizedRect(in: screen)
        let intersection = rect.intersection(CGRect(x:0, y:0, width:1, height:1))
        return intersection.size.width * intersection.size.height
     }
}
