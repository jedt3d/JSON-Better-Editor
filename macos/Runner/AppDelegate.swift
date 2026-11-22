import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationWillFinishLaunching(_ notification: Notification) {
    addFileMenu()
  }

  /// The standard File menu (§3.4, decision #21), after the app menu. Items
  /// go up the responder chain to MainFlutterWindow.
  private func addFileMenu() {
    let menu = NSMenu(title: "File")
    func item(_ title: String, _ action: Selector, _ key: String,
              _ modifiers: NSEvent.ModifierFlags = .command) {
      let entry = NSMenuItem(title: title, action: action, keyEquivalent: key)
      entry.keyEquivalentModifierMask = modifiers
      menu.addItem(entry)
    }
    item("New", #selector(MainFlutterWindow.fileNew(_:)), "n")
    item("Open…", #selector(MainFlutterWindow.fileOpen(_:)), "o")
    menu.addItem(.separator())
    item("Close", #selector(NSWindow.performClose(_:)), "w")
    item("Save", #selector(MainFlutterWindow.fileSave(_:)), "s")
    item("Save As…", #selector(MainFlutterWindow.fileSaveAs(_:)), "s", [.command, .shift])
    let top = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
    top.submenu = menu
    NSApp.mainMenu?.insertItem(top, at: 1)
  }

  /// Quit (Cmd+Q) asks about unsaved changes first (decision #55).
  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    guard let window = sender.windows.compactMap({ $0 as? MainFlutterWindow })
      .first(where: { $0.isVisible && $0.isDocumentEdited })
    else { return .terminateNow }
    window.confirmClose { ok in sender.reply(toApplicationShouldTerminate: ok) }
    return .terminateLater
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
