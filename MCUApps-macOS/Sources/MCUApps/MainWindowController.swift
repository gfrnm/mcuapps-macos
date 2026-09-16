import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {
    let webViewController = WebViewController()

    convenience init() {
        let defaultWidth: CGFloat = 1280
        let defaultHeight: CGFloat = 820
        
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let initialRect = NSRect(
            x: screenRect.origin.x + (screenRect.width - defaultWidth) / 2,
            y: screenRect.origin.y + (screenRect.height - defaultHeight) / 2,
            width: defaultWidth,
            height: defaultHeight
        )

        let window = NSWindow(
            contentRect: initialRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.init(window: window)

        window.delegate = self
        window.title = "MCUApps - Platform Pembelajaran Kuliah Kesehatan"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.minSize = NSSize(width: 1024, height: 680)
        window.isReleasedWhenClosed = false
        window.center()
        
        // Dark/Light modern slate window styling
        window.backgroundColor = NSColor(red: 248/255, green: 250/255, blue: 252/255, alpha: 1.0)
        window.contentViewController = webViewController
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
}
