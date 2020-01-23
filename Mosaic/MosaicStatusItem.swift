import Cocoa

class MosaicStatusItem {
    static let instance = MosaicStatusItem()
    
    private var nsStatusItem: NSStatusItem?
    public var statusMenu: NSMenu? {
        didSet {
            nsStatusItem?.menu = statusMenu
        }
    }
    
    private init() {}
    
    public func refreshVisibility() {
        nsStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        nsStatusItem?.menu = self.statusMenu
        nsStatusItem?.button?.image = NSImage(named: "StatusTemplate")
    }
    
    public func openMenu() {
        if let menu = statusMenu {
            NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength).popUpMenu(menu)
        }
    }
}
