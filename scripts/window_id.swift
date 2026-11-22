// Prints the CGWindowID of the first on-screen window owned by a process
// whose name contains the first argument. Used by scripts/shot.sh.
import CoreGraphics

let needle = CommandLine.arguments.dropFirst().first ?? "JSON Better Editor"
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
  as? [[String: Any]] ?? []
for w in windows {
  let owner = w[kCGWindowOwnerName as String] as? String ?? ""
  let layer = w[kCGWindowLayer as String] as? Int ?? -1
  if layer == 0, owner.localizedCaseInsensitiveContains(needle),
    let id = w[kCGWindowNumber as String] as? Int
  {
    print(id)
    break
  }
}
