import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    // Narrowest width at which the toolbar row still fits.
    self.minSize = NSSize(width: 640, height: 400)

    // Native window services for Dart (lib/app/native_window.dart).
    let windowChannel = FlutterMethodChannel(
      name: "json_better_editor/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    windowChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      switch call.method {
      case "setTitle":
        self.title = call.arguments as? String ?? ""
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
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
