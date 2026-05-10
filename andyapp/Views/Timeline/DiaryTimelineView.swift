import SwiftUI
import SwiftData

struct DiaryTimelineView: View {
    @Query(sort: \DiaryEntry.createdAt, order: .reverse) private var entries: [DiaryEntry]
    @State private var showCheckIn = false
    @State private var showSettings = false

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
            .navigationTitle("Medicus")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color(hex: "#C4A0E8"))
                    }
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
        .sheet(isPresented: $showCheckIn)  { CheckInView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    // MARK: Timeline list

    private var timelineList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(groupedEntries, id: \.0) { title, dayEntries in
                    Section {
                        ForEach(dayEntries) { entry in
                            NavigationLink(value: entry) {
                                EntryCardView(entry: entry)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                            }
                            .buttonStyle(.plain)
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

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "#7B5AB0"))
            Text("Your journal is waiting")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(hex: "#C4A0E8"))
            Text("Tap + to check in with yourself")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func sectionTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: date)
    }
}
