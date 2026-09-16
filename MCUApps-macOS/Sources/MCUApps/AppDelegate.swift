import Cocoa
import WebKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: MainWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMainMenu()
        
        let wc = MainWindowController()
        self.windowController = wc
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            windowController?.window?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // MARK: - Native macOS Menu Bar
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // 1. App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "MCUApps")
        appMenu.addItem(withTitle: "Tentang MCUApps", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Sembunyikan MCUApps", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: "Sembunyikan Lainnya", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(withTitle: "Tampilkan Semua", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Keluar dari MCUApps", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 2. Edit Menu (Standard Copy/Paste/Select All shortcuts)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // 3. View Menu (Reload, Fullscreen, Zoom)
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "Tampilan")
        viewMenu.addItem(withTitle: "Muat Ulang Halaman (Reload)", action: #selector(reloadPage), keyEquivalent: "r")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Perbesar (Zoom In)", action: #selector(zoomIn), keyEquivalent: "+")
        viewMenu.addItem(withTitle: "Perkecil (Zoom Out)", action: #selector(zoomOut), keyEquivalent: "-")
        viewMenu.addItem(withTitle: "Ukuran Asli (Reset Zoom)", action: #selector(zoomReset), keyEquivalent: "0")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Layar Penuh (Toggle Full Screen)", action: #selector(toggleFullscreen), keyEquivalent: "f")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // 4. Navigation Menu
        let navMenuItem = NSMenuItem()
        let navMenu = NSMenu(title: "Navigasi")
        navMenu.addItem(withTitle: "Kembali (Back)", action: #selector(goBack), keyEquivalent: "[")
        navMenu.addItem(withTitle: "Maju (Forward)", action: #selector(goForward), keyEquivalent: "]")
        navMenu.addItem(withTitle: "Kembali ke Halaman Login", action: #selector(goToLogin), keyEquivalent: "l")
        navMenuItem.submenu = navMenu
        mainMenu.addItem(navMenuItem)

        // 5. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Jendela")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "MCUApps Desktop untuk Mac"
        alert.informativeText = "Platform Pembelajaran Kuliah Kesehatan\nVersi 2.0.0 (Universal Binary - Intel & Apple Silicon)\n\nhttps://mcu-apps.co.id"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func reloadPage() {
        windowController?.webViewController.reloadPage()
    }

    @objc private func zoomIn() {
        windowController?.webViewController.zoomIn()
    }

    @objc private func zoomOut() {
        windowController?.webViewController.zoomOut()
    }

    @objc private func zoomReset() {
        windowController?.webViewController.zoomReset()
    }

    @objc private func toggleFullscreen() {
        windowController?.window?.toggleFullScreen(nil)
    }

    @objc private func goBack() {
        windowController?.webViewController.goBack()
    }

    @objc private func goForward() {
        windowController?.webViewController.goForward()
    }

    @objc private func goToLogin() {
        windowController?.webViewController.navigateToLogin()
    }
}
