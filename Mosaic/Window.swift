import Foundation
import Carbon
import Cocoa

let THRESHOLD: CGFloat = 0.02
let DEBUG = false

protocol ThresholdComparable {
    func closeTo(_ b: Self, tolerance: CGFloat) -> Bool
}

extension CGRect : ThresholdComparable {
    func closeTo(_ b: CGRect, tolerance: CGFloat) -> Bool {
        return abs(b.minX - self.minX) < tolerance && abs(b.maxX - self.maxX) < tolerance && abs(b.minY - self.minY) < tolerance && abs(b.maxY - self.maxY) < tolerance
    }
}

extension CGFloat : ThresholdComparable {
    func closeTo(_ b: CGFloat, tolerance: CGFloat) -> Bool {
        return abs(b - self) < tolerance
    }
}

func cycle<T:ThresholdComparable>(through cycle:[T], current:T) -> T {
    var winningIndex = 0
    for i in 0..<cycle.count-1 {
        if cycle[i].closeTo(current, tolerance: THRESHOLD) {
            winningIndex = i+1
        }
    }
    return cycle[winningIndex]
}


typealias WindowId = Int

struct WindowEvent : CustomStringConvertible {
    var id: WindowId
    var previous: CGRect = CGRect.zero
    var target: CGRect = CGRect.zero
    
    var description: String {
        get {
            return "\(id): Previous: \(previous) Target: \(target)"
        }
    }
}

class Window {
    private let underlyingElement: AXUIElement
    private let screens: Screens
    
    required init(_ axUIElement: AXUIElement) {
        self.underlyingElement = axUIElement
        self.screens = Screens.detect()
    }
    
    static func frontmostWindow() -> Window? {
        guard let frontmostApplication: NSRunningApplication = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApplication = AXUIElementCreateApplication(frontmostApplication.processIdentifier)
        let focusedAttr = NSAccessibility.Attribute.focusedWindow as CFString
        var copiedUnderlyingElement: AnyObject?
        let result: AXError = AXUIElementCopyAttributeValue(axApplication, focusedAttr, &copiedUnderlyingElement)
        if result == .success {
            if let copiedUnderlyingElement = copiedUnderlyingElement {
                return Window(copiedUnderlyingElement as! AXUIElement)
            }
        }
        
        return nil
    }
    
    func execute(_ action: WindowAction, previousEvent: WindowEvent?) -> WindowEvent? {
        if self.isSheet() || self.isSystemDialog() || self.rect().isNull {
            return nil
        }
        
        guard let id = self.getIdentifier() else {
            return nil
        }
        
        guard let screen = self.screens.screenContaining(self) else {
            return nil
        }

        var windowEvent = WindowEvent(id: id)
        windowEvent.previous = self.normalizedRect(in: screen)
        
        switch action {
        case .moveLeft:
            windowEvent.target = self.moveLeft(screen: screen)
        case .moveRight:
            windowEvent.target = self.moveRight(screen: screen)
        case .moveUp:
            windowEvent.target = self.moveUp(screen: screen)
        case .moveDown:
            windowEvent.target = self.moveDown(screen: screen)
        case .maximize:
            windowEvent.target = self.maximize(screen: screen, previousEvent: previousEvent)
        case .center:
            windowEvent.target = self.center(screen: screen)
        case .switchDisplay:
            windowEvent.target = self.switchDisplay(screen: screen)
        }
        
        if DEBUG {
            print("Screens")
            print("=======")
            for s in self.screens.screens {
                if screen == s {
                    print("\t**Frame: \(s.frame), Visible Frame: \(s.visibleFrame))**")
                } else {
                    print("\tFrame: \(s.frame), Visible Frame: \(s.visibleFrame))")
                }
            }
            print("Window")
            print("\t", id)
            print("\tRect:", self.rect())
            print("\tNormalized Rect:", self.normalizedRect(in: screen))
            print("\tTarget:", windowEvent.target)
        }
        
        return windowEvent
    }

    private func moveLeft(screen: NSScreen) -> CGRect {
        let target = cycle(through: [CGRect(x:0, y:0, width:0.5, height:1.0), CGRect(x:0, y:0, width:0.33, height:1.0), CGRect(x:0, y:0, width:0.66, height:1.0)],
                           current: self.normalizedRect(in: screen))
        self.adjustTo(target, screen)
        return target
    }

    private func moveRight(screen: NSScreen) -> CGRect {
        let target = cycle(through: [CGRect(x:0.5, y:0, width:0.5, height:1.0), CGRect(x:0.66, y:0, width:0.34, height:1.0), CGRect(x:0.33, y:0, width:0.67, height:1.0)],
                           current: self.normalizedRect(in: screen))
        self.adjustTo(target, screen)
        return target
    }

    private func moveUp(screen: NSScreen) -> CGRect {
        let current = self.normalizedRect(in: screen)
        
        let x = current.minX
        let width = current.width
        
        var y = current.minY
        var height = current.height
        
        if y <= THRESHOLD {
            y = 0
            height = cycle(through: [0.5, 0.33, 1.0, 0.66], current: height)
        } else if abs(height - 0.33) <= THRESHOLD {
            y = cycle(through: [0.33, 0], current: y)
        } else {
            y = 0
        }
        
        let target = CGRect(x: x, y: y, width: width, height: height)
        
        self.adjustTo(target, screen)
        return target
    }
    
    private func moveDown(screen: NSScreen) -> CGRect {
        let current = self.normalizedRect(in: screen)
        
        let x = current.minX
        let width = current.width
        
        var y = current.minY
        var height = current.height
        
        if abs(1.0 - (y + height)) < THRESHOLD {
            height = cycle(through: [0.5, 0.33, 1.0, 0.66], current: height)
            y = 1.0 - height
        } else if abs(height - 0.33) <= THRESHOLD {
            y = cycle(through: [0.33, 1.0 - height], current: y)
        } else {
            y = 1.0 - height
        }

        let target = CGRect(x: x, y: y, width: width, height: height)
        
        self.adjustTo(target, screen)
        return target
    }

    
    private func maximize(screen: NSScreen, previousEvent: WindowEvent?) -> CGRect {
        let currentNormalizedRect = self.normalizedRect(in: screen)
        var target = CGRect(x:0.0, y:0.0, width:1.0, height:1.0)
        if target.closeTo(currentNormalizedRect, tolerance: THRESHOLD) && previousEvent != nil{
            target = previousEvent!.previous
        }
        self.adjustTo(target, screen)
        return target
    }
    
    private func center(screen: NSScreen) -> CGRect {
        let target = cycle(through: [CGRect(x:0.1, y:0.1, width:0.8, height:0.8), CGRect(x:0.2, y:0.2, width:0.6, height:0.6), CGRect(x:0.33, y:0.33, width:0.33, height:0.33)],
                           current: self.normalizedRect(in: screen))
        self.adjustTo(target, screen)
        return target
    }
    
    private func switchDisplay(screen: NSScreen) -> CGRect {
        let currentNormalizedRect = self.normalizedRect(in: screen)
        self.adjustTo(currentNormalizedRect, self.screens.screenAfter(screen))
        return currentNormalizedRect
    }
        
    private func rect() -> CGRect {
        guard let position: CGPoint = getPosition(),
            let size: CGSize = getSize()
            else {
                return CGRect.null
        }
        return CGRect(x: position.x, y: position.y, width: size.width, height: size.height)
    }
    
    func normalizedRect(in screen: NSScreen) -> CGRect {
        let rect = self.rect()
        
        let originFrame = NSRectToCGRect(self.screens.originScreen.frame)
        let screenFrame = NSRectToCGRect(screen.visibleFrame)
        
        return CGRect(x: (rect.minX - screenFrame.minX) / screenFrame.width,
                      y: (rect.minY + screenFrame.maxY - originFrame.height) / screenFrame.height,
                      width: rect.width / screenFrame.width,
                      height: rect.height / screenFrame.height)
    }
    
    private func adjustTo(_ targetNormalizedRect: CGRect, _ screen: NSScreen) {
        let originFrame = NSRectToCGRect(self.screens.originScreen.frame)
        let screenFrame = NSRectToCGRect(screen.visibleFrame)

        let rect = CGRect(x: screenFrame.minX + screenFrame.width * targetNormalizedRect.minX,
                          y: originFrame.height - screenFrame.maxY + screenFrame.height * targetNormalizedRect.minY,
                          width: screenFrame.width * targetNormalizedRect.width,
                          height: screenFrame.height * targetNormalizedRect.height)
        
        let currentNormalizedRect = self.normalizedRect(in: screen)
        if currentNormalizedRect.minX + targetNormalizedRect.width > 1.0 || currentNormalizedRect.minY + targetNormalizedRect.height > 1.0 {
            set(position: rect.origin)
            set(size: rect.size)
        } else {
            set(size: rect.size)
            set(position: rect.origin)
        }
    }
    
    func isSheet() -> Bool {
        return value(for: .role) == kAXSheetRole
    }
    
    func isSystemDialog() -> Bool {
        return value(for: .subrole) == kAXSystemDialogSubrole
    }
    
    func getIdentifier() -> Int? {
        if let windowInfo = CGWindowListCopyWindowInfo(.optionOnScreenOnly, 0) as? Array<Dictionary<String,Any>> {
            var pid: pid_t = 0;
            AXUIElementGetPid(self.underlyingElement, &pid);

            let rect = self.rect()
            
            let windowsOfSameApp = windowInfo.filter { (infoDict) -> Bool in
                infoDict[kCGWindowOwnerPID as String] as? pid_t == pid
            }
            
            let matchingWindows = windowsOfSameApp.filter { (infoDict) -> Bool in
                if let bounds = infoDict[kCGWindowBounds as String] as? [String: CGFloat] {
                    return bounds["X"] == rect.origin.x && bounds["Y"] == rect.origin.y && bounds["Height"] == rect.height && bounds["Width"] == rect.width
                }
                return false
            }
            
            if let firstMatch = matchingWindows.first {
                return firstMatch[kCGWindowNumber as String] as? Int
            }
        }
        return nil
    }
        
    private func getPosition() -> CGPoint? {
        return self.value(for: .position)
    }
    
    private func set(position: CGPoint) {
        if let value = AXValue.from(value: position, type: .cgPoint) {
            AXUIElementSetAttributeValue(self.underlyingElement, kAXPositionAttribute as CFString, value)
        }
    }
    
    private func getSize() -> CGSize? {
        return self.value(for: .size)
    }
    
    private func set(size: CGSize) {
        if let value = AXValue.from(value: size, type: .cgSize) {
            AXUIElementSetAttributeValue(self.underlyingElement, kAXSizeAttribute as CFString, value)
        }
    }
    
    private func value<T>(for attribute: NSAccessibility.Attribute) -> T? {
        var rawValue: AnyObject?
        let error = AXUIElementCopyAttributeValue(self.underlyingElement, attribute.rawValue as CFString, &rawValue)
        if error == .success && CFGetTypeID(rawValue) == AXValueGetTypeID() {
            return (rawValue as! AXValue).toValue()
        }
        
        return nil
    }
}

extension AXValue {
    func toValue<T>() -> T? {
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        let success = AXValueGetValue(self, AXValueGetType(self), pointer)
        return success ? pointer.pointee : nil
    }
    
    static func from<T>(value: T, type: AXValueType) -> AXValue? {
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.pointee = value
        return AXValueCreate(type, pointer)
    }
}
