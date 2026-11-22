import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    // Narrowest width at which the toolbar row still fits.
    self.minSize = NSSize(width: 640, height: 400)

    // Lets Dart set the window title from the localized app name.
    let windowChannel = FlutterMethodChannel(
      name: "json_better_editor/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    windowChannel.setMethodCallHandler { [weak self] call, result in
      if call.method == "setTitle", let title = call.arguments as? String {
        self?.title = title
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
