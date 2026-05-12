import SwiftUI
import SwiftData

struct DiaryTimelineView: View {
    @Query(sort: \DiaryEntry.createdAt, order: .reverse) private var entries: [DiaryEntry]
    @EnvironmentObject private var loc: LocalizationManager

    @State private var showCheckIn = false
    @State private var showSettings = false

    @State private var selectionMode = false
    @State private var selectedIDs: Set<UUID> = []

    @State private var showExport = false
    @State private var exportInitialMode: ExportMode = .date
    @State private var exportPreselected: Set<UUID> = []

    private var groupedEntries: [(String, [DiaryEntry])] {
        let cal = Calendar.current
        let byDay = Dictionary(grouping: entries) { cal.startOfDay(for: $0.createdAt) }
        return byDay
            .sorted { $0.key > $1.key }
            .map { date, dayEntries in
                (sectionTitle(for: date), dayEntries.sorted { $0.createdAt > $1.createdAt })
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#160D27").ignoresSafeArea()

                if entries.isEmpty {
                    emptyState
                } else {
                    timelineList
                }
            }
            .navigationTitle(L10n.timelineTitle(loc.language))
            .toolbar { toolbarContent }
        }
        .sheet(isPresented: $showCheckIn)  { CheckInView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showExport) {
            ExportView(entries: entries,
                       initialMode: exportInitialMode,
                       preselected: exportPreselected)
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if selectionMode {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.cancel(loc.language)) { exitSelectionMode() }
                    .foregroundStyle(Color(hex: "#C4A0E8"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    openExport(mode: .multiple, preselected: selectedIDs)
                } label: {
                    Text(L10n.sendN(loc.language, selectedIDs.count))
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedIDs.isEmpty ? .secondary : Color(hex: "#C4A0E8"))
                }
                .disabled(selectedIDs.isEmpty)
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color(hex: "#C4A0E8"))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        openExport(mode: .date, preselected: [])
                    } label: {
                        Label(L10n.exportSend(loc.language), systemImage: "square.and.arrow.up")
                    }
                    Button {
                        enterSelectionMode(initial: [])
                    } label: {
                        Label(L10n.selectToSend(loc.language), systemImage: "checklist")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color(hex: "#C4A0E8"))
                }
                .disabled(entries.isEmpty)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCheckIn = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(hex: "#C4A0E8"))
                }
            }
        }
    }

    // MARK: Timeline list

    private var timelineList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(groupedEntries, id: \.0) { title, dayEntries in
                    Section {
                        ForEach(dayEntries) { entry in
                            entryRow(entry)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                        }
                    } header: {
                        Text(title)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial)
                    }
                }
            }
            .padding(.top, 8)
        }
        .navigationDestination(for: DiaryEntry.self) { entry in
            EntryDetailView(entry: entry)
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: DiaryEntry) -> some View {
        if selectionMode {
            Button {
                toggleSelection(entry.id)
            } label: {
                EntryCardView(
                    entry: entry,
                    isSelectionMode: true,
                    isSelected: selectedIDs.contains(entry.id)
                )
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: entry) {
                EntryCardView(
                    entry: entry,
                    onMenuExport: {
                        openExport(mode: .multiple, preselected: [entry.id])
                    },
                    onMenuSelect: {
                        enterSelectionMode(initial: [entry.id])
                    }
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "#7B5AB0"))
            Text(L10n.emptyTitle(loc.language))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(hex: "#C4A0E8"))
            Text(L10n.emptySubtitle(loc.language))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Selection helpers

    private func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func enterSelectionMode(initial: Set<UUID>) {
        selectedIDs = initial
        withAnimation(.spring(response: 0.3)) {
            selectionMode = true
        }
    }

    private func exitSelectionMode() {
        withAnimation(.spring(response: 0.3)) {
            selectionMode = false
        }
        selectedIDs = []
    }

    private func openExport(mode: ExportMode, preselected: Set<UUID>) {
        exportInitialMode = mode
        exportPreselected = preselected
        showExport = true
        if selectionMode { exitSelectionMode() }
    }

    private func sectionTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return L10n.today(loc.language) }
        if cal.isDateInYesterday(date) { return L10n.yesterday(loc.language) }
        let f = DateFormatter()
        f.locale = loc.language.locale
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: date)
    }
}
