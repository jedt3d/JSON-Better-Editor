import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  var statusBarItem: NSMenuItem?

  /// Closing the window leaves the app running, like other macOS editors
  /// (#93, supersedes decision #68); Cmd+Q quits.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  private var window: MainFlutterWindow? {
    NSApp.windows.compactMap { $0 as? MainFlutterWindow }.first
  }

  /// Dock icon with no window showing: bring the window back.
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag { window?.show() }
    return true
  }

  // File › New and Open… with no window showing reach the app delegate
  // (the responder chain has no key window): show the window, then run them.
  @objc func fileNew(_ sender: Any?) {
    window?.show()
    window?.fileNew(sender)
  }

  @objc func fileOpen(_ sender: Any?) {
    window?.show()
    window?.fileOpen(sender)
  }

  override func applicationWillFinishLaunching(_ notification: Notification) {
    addFileMenu()
    retargetEditMenu()
    addWordWrapItem()
    addValidateItem()
  }

  /// Edit › Validate JSON, no shortcut (#86). Checks the Text pane now;
  /// background validation is Phase 5 (#82).
  private func addValidateItem() {
    guard let edit = NSApp.mainMenu?.items.first(where: { $0.submenu?.title == "Edit" })?.submenu
    else { return }
    // After Select All, before the Find submenu: Validate JSON (#86),
    // Format and Minify (#89), no shortcuts.
    let at = edit.items.firstIndex(where: { $0.submenu?.title == "Find" }) ?? edit.items.count
    edit.insertItem(.separator(), at: at)
    // Go to Line… (#90), no shortcut for now.
    for (title, name) in [("Go to Line…", "goToLine"), ("Minify", "minify"), ("Format", "format"),
                          ("Validate JSON", "validate")] {
      let item = NSMenuItem(title: title, action: #selector(MainFlutterWindow.jsonCommand(_:)),
                            keyEquivalent: "")
      item.representedObject = name
      edit.insertItem(item, at: at)
    }
  }

  /// View › Word Wrap (Opt+Z), off by default (decision #58). Dart holds the
  /// setting; the reply sets the checkmark.
  private func addWordWrapItem() {
    guard let view = NSApp.mainMenu?.items.first(where: { $0.submenu?.title == "View" })?.submenu
    else { return }
    let item = NSMenuItem(title: "Word Wrap",
                          action: #selector(MainFlutterWindow.toggleWordWrap(_:)),
                          keyEquivalent: "z")
    item.keyEquivalentModifierMask = [.option]
    item.state = .off
    view.insertItem(item, at: 0)
    // View › Hide / Show Status Bar (⌘/, as in Finder; #98).
    let status = NSMenuItem(title: "Hide Status Bar",
                            action: #selector(MainFlutterWindow.toggleStatusBar(_:)),
                            keyEquivalent: "/")
    view.insertItem(status, at: 1)
    statusBarItem = status
    view.insertItem(.separator(), at: 2)
  }

  /// The template's Edit items (Undo … Select All) send AppKit selectors
  /// that nothing in a Flutter window answers, so they were greyed out.
  /// They now go to MainFlutterWindow.edit(_:), which runs the Text pane's
  /// own action in Dart (#38, #43). Keeps their titles and shortcuts.
  private func retargetEditMenu() {
    let actions = ["undo:": "undo", "redo:": "redo", "cut:": "cut",
                   "copy:": "copy", "paste:": "paste", "selectAll:": "selectAll"]
    guard let edit = NSApp.mainMenu?.items.first(where: { $0.submenu?.title == "Edit" })?.submenu
    else { return }
    for item in edit.items {
      guard let action = item.action, let name = actions[NSStringFromSelector(action)] else { continue }
      item.action = #selector(MainFlutterWindow.edit(_:))
      item.target = nil
      item.representedObject = name
    }
    // Edit › Find: Find… (tag 1), Find Next (2) and Find Previous (3) use
    // the app's search field (#41, #42).
    let find = edit.items.first(where: { $0.submenu?.title == "Find" })?.submenu
    let findActions = [1: "find", 2: "findNext", 3: "findPrevious"]
    for item in find?.items ?? [] {
      guard let name = findActions[item.tag] else { continue }
      item.action = #selector(MainFlutterWindow.find(_:))
      item.target = nil
      item.representedObject = name
    }
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
    let recent = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: "")
    recent.submenu = recentMenu
    menu.addItem(recent)
    rebuildRecentMenu(RecentFiles.paths)
    menu.addItem(.separator())
    item("Close", #selector(NSWindow.performClose(_:)), "w")
    item("Save", #selector(MainFlutterWindow.fileSave(_:)), "s")
    item("Save As…", #selector(MainFlutterWindow.fileSaveAs(_:)), "s", [.command, .shift])
    let top = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
    top.submenu = menu
    NSApp.mainMenu?.insertItem(top, at: 1)
  }

  /// File › Open Recent (#92): the paths Dart keeps, newest first, then
  /// Clear Menu.
  let recentMenu = NSMenu(title: "Open Recent")

  func rebuildRecentMenu(_ paths: [String]) {
    recentMenu.removeAllItems()
    for path in paths {
      let entry = NSMenuItem(
        title: (path as NSString).lastPathComponent,
        action: #selector(MainFlutterWindow.openRecent(_:)), keyEquivalent: "")
      entry.representedObject = path
      entry.toolTip = path
      recentMenu.addItem(entry)
    }
    if !paths.isEmpty { recentMenu.addItem(.separator()) }
    let clear = NSMenuItem(
      title: "Clear Menu", action: #selector(MainFlutterWindow.clearRecent(_:)), keyEquivalent: "")
    recentMenu.addItem(clear)
  }

  // With no window showing, these reach the app delegate (#93).
  @objc func openRecent(_ sender: NSMenuItem) {
    window?.show()
    window?.openRecent(sender)
  }

  @objc func clearRecent(_ sender: Any?) {
    window?.clearRecent(sender)
  }

  /// Files opened from Finder ("Open With", double-click when the app is
  /// the default). One window, so the last file wins (decision #56).
  override func application(_ application: NSApplication, open urls: [URL]) {
    guard let window = application.windows.compactMap({ $0 as? MainFlutterWindow }).first,
      let url = urls.last
    else { return }
    window.show()
    window.openFromFinder(url.path)
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
