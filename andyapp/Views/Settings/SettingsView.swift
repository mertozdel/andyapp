import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DiaryEntry.createdAt, order: .reverse) private var entries: [DiaryEntry]
    @State private var showExport = false

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

                Section("Data") {
                    Button {
                        showExport = true
                    } label: {
                        HStack {
                            Label("Export your data", systemImage: "square.and.arrow.up")
                            Spacer()
                            Text("\(entries.count) entries")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
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
        .sheet(isPresented: $showExport) {
            ExportView(entries: entries)
        }
    }
}
