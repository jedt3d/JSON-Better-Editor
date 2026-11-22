import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  /// The window channel (lib/app/native_window.dart).
  private var windowChannel: FlutterMethodChannel?

  /// The mouse-down that may start a window drag. Flutter reports the drag
  /// only after the mouse has moved, and performDrag needs the press.
  private var lastMouseDown: NSEvent?

  override func sendEvent(_ event: NSEvent) {
    if event.type == .leftMouseDown { lastMouseDown = event }
    super.sendEvent(event)
    if event.type == .leftMouseUp {
      isMovable = false
      lastMouseDown = nil
    }
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    // Not restorable, so macOS does not put back the last session's frame.
    self.isRestorable = false

    // Flutter draws the toolbar in the title-bar row (decision #46): hide the
    // native title, let content run under it, and use an empty unified
    // toolbar so the bar is tall enough and the traffic lights are centred.
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.toolbar = NSToolbar()
    self.toolbarStyle = .unified
    // AppKit would otherwise move the window on any drag in the title-bar
    // band, buttons included; Flutter starts drags only on empty space.
    self.isMovable = false

    // Native window services for Dart (lib/app/native_window.dart).
    let windowChannel = FlutterMethodChannel(
      name: "json_better_editor/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    self.windowChannel = windowChannel
    self.delegate = self
    windowChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      switch call.method {
      case "setTitle":
        self.title = call.arguments as? String ?? ""
        result(nil)
      case "setEdited":
        // The dot in the close button for unsaved changes (decision #55).
        self.isDocumentEdited = call.arguments as? Bool ?? false
        result(nil)
      case "openJsonFile":
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.beginSheetModal(for: self) { response in
          result(response == .OK ? panel.url?.path : nil)
        }
      case "saveJsonFile":
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = call.arguments as? String ?? "Untitled.json"
        panel.beginSheetModal(for: self) { response in
          result(response == .OK ? panel.url?.path : nil)
        }
      case "startWindowDrag":
        // Only while the press that started it is still held.
        if let event = self.lastMouseDown, NSEvent.pressedMouseButtons & 1 != 0 {
          self.isMovable = true  // Back to false on mouse-up.
          self.performDrag(with: event)
        }
        result(nil)
      case "titleBarDoubleClick":
        // Same choice as System Settings › Desktop & Dock.
        switch UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") {
        case "Minimize": self.performMiniaturize(nil)
        case "None": break
        default: self.performZoom(nil)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Sizes are fractions of the usable work area, never fixed pixels:
    // HiDPI scaling differs per machine (decision #48). Open at 60% × 80%,
    // centred; shrink to about 20% × 20% (#46).
    if let area = usableWorkArea() {
      let size = NSSize(width: (area.width * 0.6).rounded(),
                        height: (area.height * 0.8).rounded())
      self.minSize = NSSize(width: (area.width * 0.2).rounded(),
                            height: (area.height * 0.2).rounded())
      self.setFrame(NSRect(x: area.midX - size.width / 2,
                           y: area.midY - size.height / 2,
                           width: size.width, height: size.height),
                    display: true)
    }
  }

  /// Asks Dart's Save / Don't Save / Cancel prompt (decision #55) when the
  /// document is edited; [done] gets true when the window may go away.
  func confirmClose(_ done: @escaping (Bool) -> Void) {
    guard isDocumentEdited, let channel = windowChannel else { return done(true) }
    channel.invokeMethod("confirmClose", arguments: nil) { reply in
      done(reply as? Bool ?? false)
    }
  }

  /// File menu items (AppDelegate.addFileMenu) run the Dart action of the
  /// same name; Close is AppKit's performClose:, which asks first.
  @objc func fileNew(_ sender: Any?) { windowChannel?.invokeMethod("menu", arguments: "new") }
  @objc func fileOpen(_ sender: Any?) { windowChannel?.invokeMethod("menu", arguments: "open") }
  @objc func fileSave(_ sender: Any?) { windowChannel?.invokeMethod("menu", arguments: "save") }
  @objc func fileSaveAs(_ sender: Any?) { windowChannel?.invokeMethod("menu", arguments: "saveAs") }

  /// Close button and Cmd+W: ask first, then close for real.
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    guard isDocumentEdited else { return true }
    confirmClose { ok in
      guard ok else { return }
      // Answered; Quit (after the last window closes) must not ask again.
      self.isDocumentEdited = false
      self.close()
    }
    return false
  }

  /// The part of the screen windows may use: the screen minus the menu bar
  /// and the Dock, in points. Future Windows / Linux runners use their own
  /// equivalent (the work area without the taskbar or the Ubuntu dock).
  private func usableWorkArea() -> NSRect? {
    (NSScreen.main ?? self.screen)?.visibleFrame
  }
}
