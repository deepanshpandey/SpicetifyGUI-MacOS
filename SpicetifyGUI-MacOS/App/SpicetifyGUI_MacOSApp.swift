import SwiftUI
import SwiftData
import AppKit

@main
struct SpicetifyGUI_MacOSApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 700, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .modelContainer(for: [AppSettings.self, OperationLog.self])
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About SpicetifyGUI-MacOS") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "SpicetifyGUI-MacOS",
                            NSApplication.AboutPanelOptionKey.applicationVersion: "1.0.0",
                            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2025"
                        ]
                    )
                }
            }
        }
    }
}
