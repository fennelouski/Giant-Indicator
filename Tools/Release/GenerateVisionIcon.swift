import AppKit
import SwiftUI

@main
struct GenerateVisionIcon {
    @MainActor static func main() throws {
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        let front = BatteryIcon(level: 1, fillColor: .green, accentColor: .white)
            .environment(\.dashboardPalette, DashboardPalette(colorScheme: .dark))
            .frame(width: 180, height: 84)
            .scaleEffect(3.5)
            .frame(width: 1024, height: 1024)
        try save(front, at: output.appendingPathComponent("Front.png"))
        try save(Color.black.frame(width: 1024, height: 1024), at: output.appendingPathComponent("Back.png"))
    }

    @MainActor static func save<V: View>(_ view: V, at url: URL) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        guard let image = renderer.cgImage,
              let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url)
    }
}
