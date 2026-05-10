import SwiftUI

// MARK: - Sleep Tracking Card

struct SleepTrackingView: View {
    @Binding var bedtime: Date?
    @Binding var wakeTime: Date?
    @Binding var quality: Int
    @Binding var wakeups: Int
    @Binding var hadDreams: Bool
    @Binding var notes: String

    @State private var isExpanded = false
    @State private var localBedtime: Date = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var localWakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()

    private let accent = Color(hex: "#6C5CE7")

    var body: some View {
        VStack(spacing: 0) {
            headerButton
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 16))
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
    }

    private var headerButton: some View {
        Button {
            isExpanded.toggle()
            if isExpanded {
                bedtime = localBedtime
                wakeTime = localWakeTime
            } else {
                bedtime = nil
                wakeTime = nil
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(accent)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sleep Tracking")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(isExpanded ? "Tap to skip" : "Optional — tap to add")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(Color(hex: "#2B1B50"))

            // Bedtime & Wake time
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bedtime")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    DatePicker("", selection: Binding(
                        get: { localBedtime },
                        set: { localBedtime = $0; bedtime = $0 }
                    ), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wake time")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    DatePicker("", selection: Binding(
                        get: { localWakeTime },
                        set: { localWakeTime = $0; wakeTime = $0 }
                    ), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }
            }

            // Quality bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sleep quality")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(quality)/10")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#2B1B50"))
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(accent)
                            .frame(width: geo.size.width * CGFloat(quality) / 10.0, height: 12)
                    }
                    .gesture(DragGesture(minimumDistance: 0).onChanged { val in
                        let fraction = max(0, min(1, val.location.x / geo.size.width))
                        quality = max(1, min(10, Int((fraction * 10).rounded(.toNearestOrAwayFromZero))))
                    })
                }
                .frame(height: 12)
            }

            // Wakeups + Dreams row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Times woken up")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Stepper(value: $wakeups, in: 0...20) {
                        Text("\(wakeups)")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                Spacer()
                Toggle(isOn: $hadDreams) {
                    Text("Dreams")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .toggleStyle(SwitchToggleStyle(tint: accent))
            }

            // Notes
            VStack(alignment: .leading, spacing: 6) {
                Text("Sleep notes")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                TextField("Any notes about your sleep...", text: $notes, axis: .vertical)
                    .lineLimit(1...3)
                    .font(.callout)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(hex: "#2B1B50"), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Libido / Desire Tracking Card

struct LibidoTrackingView: View {
    @Binding var level: Int?
    @Binding var notes: String

    @State private var isExpanded = false

    private let accent = Color(hex: "#E17055")

    var body: some View {
        VStack(spacing: 0) {
            headerButton
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 16))
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
    }

    private var headerButton: some View {
        Button {
            isExpanded.toggle()
            if !isExpanded { level = nil }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(accent)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Desire / Libido")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(isExpanded ? "Tap to skip" : "Optional — tap to add")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(Color(hex: "#2B1B50"))

            Text("Rate your desire level today")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Level circles 1–10
            HStack(spacing: 5) {
                ForEach(1...10, id: \.self) { lv in
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        level = (level == lv) ? nil : lv
                    } label: {
                        Circle()
                            .fill((level ?? 0) >= lv ? accent : Color(hex: "#2B1B50"))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("\(lv)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle((level ?? 0) >= lv ? .white : Color(hex: "#6D5F80"))
                            )
                            .scaleEffect(level == lv ? 1.18 : 1.0)
                            .animation(.spring(response: 0.2), value: level)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                TextField("Any thoughts...", text: $notes, axis: .vertical)
                    .lineLimit(1...3)
                    .font(.callout)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(hex: "#2B1B50"), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
