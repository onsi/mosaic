import Foundation
import Carbon
import Cocoa

fileprivate let alt = NSEvent.ModifierFlags.option.rawValue
fileprivate let ctrl = NSEvent.ModifierFlags.control.rawValue
fileprivate let cmd = NSEvent.ModifierFlags.command.rawValue

enum WindowAction: Int {
    case moveLeft = 0,
    moveRight = 1,
    moveUp = 2,
    moveDown = 3,
    maximize = 4,
    center = 5,
    switchDisplay = 6

    // Order matters here - it's used in the menu
    static let active = [moveLeft, moveRight, moveUp, moveDown, maximize, center, switchDisplay]
    
    func post() {
        NotificationCenter.default.post(name: notificationName, object: self)
    }
        
    // Determines where separators should be used in the menu
    var firstInGroup: Bool {
        switch self {
        case .moveLeft, .maximize, .switchDisplay:
            return true
        default:
            return false
        }
    }
    
    var name: String {
        switch self {
        case .moveLeft: return "moveLeft"
        case .moveRight: return "moveRight"
        case .moveUp: return "moveUp"
        case .moveDown: return "moveDown"
        case .maximize: return "maximize"
        case .center: return "center"
        case .switchDisplay: return "switchDisplay"
        }
    }

    var displayName: String {
        switch self {
        case .maximize:
            return "Maximize"
        case .switchDisplay:
            return "Switch Display"
        case .center:
            return "Center"
        case .moveLeft:
            return "Move Left"
        case .moveRight:
            return "Move Right"
        case .moveUp:
            return "Move Up"
        case .moveDown:
            return "Move Down"
        }
    }
    
    var notificationName: Notification.Name {
        return Notification.Name(name)
    }
    
    var isMoveToDisplay: Bool {
        return self == .switchDisplay
    }
    
    var resizes: Bool {
        return self != .switchDisplay
    }
    
    var keybindingDefaults: Shortcut {
        switch self {
        case .moveLeft: return Shortcut( cmd|alt|ctrl, kVK_LeftArrow )
        case .moveRight: return Shortcut( cmd|alt|ctrl, kVK_RightArrow )
        case .moveUp: return Shortcut( cmd|alt|ctrl, kVK_UpArrow )
        case .moveDown: return Shortcut( cmd|alt|ctrl, kVK_DownArrow )
        case .maximize: return Shortcut( cmd|alt|ctrl, kVK_ANSI_M )
        case .center: return Shortcut( cmd|alt|ctrl, kVK_ANSI_C )
        case .switchDisplay: return Shortcut( cmd|alt|ctrl, kVK_Space )
        }
    }
    
    
    var image: NSImage {
        switch self {
        case .moveLeft: return NSImage(imageLiteralResourceName: "moveLeftTemplate")
        case .moveRight: return NSImage(imageLiteralResourceName: "moveRightTemplate")
        case .moveUp: return NSImage(imageLiteralResourceName: "moveUpTemplate")
        case .moveDown: return NSImage(imageLiteralResourceName: "moveDownTemplate")
        case .center: return NSImage(imageLiteralResourceName: "centerTemplate")
        case .maximize: return NSImage(imageLiteralResourceName: "maximizeTemplate")
        case .switchDisplay: return NSImage(imageLiteralResourceName: "nextDisplayTemplate")
        }
    }
}

struct Shortcut {
    let keyCode: Int
    let modifierFlags: UInt
    
    init(_ modifierFlags: UInt, _ keyCode: Int) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }
    
    var dict: [String: UInt] {
        return ["keyCode": UInt(keyCode), "modifierFlags": modifierFlags]
    }
}
