import SwiftUI

struct SettingsView: View {
    @AppStorage("BetterGreenButton.autoHide") private var autoHide: Bool = false
    @AppStorage("BetterGreenButton.skipGames") private var skipGames: Bool = true
    @State private var startAtLogin: Bool = LoginItem.isEnabled

    let interceptor: GreenButtonInterceptor
    let onChange: () -> Void

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var body: some View {
        Form {
            Section {
                Toggle("Auto-hide menu icon", isOn: $autoHide)
                    .onChange(of: autoHide) { _, _ in onChange() }

                Toggle("Skip while gaming", isOn: $skipGames)
                    .onChange(of: skipGames) { _, newValue in
                        interceptor.skipGames = newValue
                        onChange()
                    }

                Toggle("Start at Login", isOn: $startAtLogin)
                    .onChange(of: startAtLogin) { _, newValue in
                        LoginItem.setEnabled(newValue)
                        onChange()
                    }
            }

            Section("About") {
                HStack {
                    Text("Version \(version)")
                    Spacer()
                    Link(
                        "Check for updates",
                        destination: URL(string: "https://github.com/Myraas/BetterGreenButton/releases")!
                    )
                }
                HStack {
                    Text("By Myraas")
                    Spacer()
                    Link(
                        "Buy Me a Coffee",
                        destination: URL(string: "https://buymeacoffee.com/myraas")!
                    )
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .frame(width: 380, height: 290)
    }
}
