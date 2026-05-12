import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(L10n.privacyLine1(loc.language), systemImage: "lock.fill")
                        .font(.subheadline)
                    Label(L10n.privacyLine2(loc.language), systemImage: "wifi.slash")
                        .font(.subheadline)
                } header: {
                    Text(L10n.privacyHeader(loc.language))
                }

                Section(L10n.languageHeader(loc.language)) {
                    Picker(selection: Binding(
                        get: { loc.language },
                        set: { loc.language = $0 }
                    )) {
                        ForEach(AppLanguage.allCases) { l in
                            Text(l.displayName).tag(l)
                        }
                    } label: {
                        Label(L10n.languageLabel(loc.language), systemImage: "globe")
                    }
                    .pickerStyle(.menu)
                }

                Section(L10n.aboutHeader(loc.language)) {
                    HStack {
                        Text(L10n.versionLabel(loc.language))
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(L10n.builtWithLabel(loc.language))
                        Spacer()
                        Text("SwiftUI + SwiftData").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(L10n.settingsTitle(loc.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done(loc.language)) { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "#8B6CAF"))
                }
            }
        }
    }
}
