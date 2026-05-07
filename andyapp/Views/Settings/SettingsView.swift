import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("All diary entries are stored only on this device.", systemImage: "lock.fill")
                        .font(.subheadline)
                    Label("Nothing is ever sent to the internet from your diary.", systemImage: "wifi.slash")
                        .font(.subheadline)
                } header: {
                    Text("Privacy")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Built with")
                        Spacer()
                        Text("SwiftUI + SwiftData").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "#8B6CAF"))
                }
            }
        }
    }
}
