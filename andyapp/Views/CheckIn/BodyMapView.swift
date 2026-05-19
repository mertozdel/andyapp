import SwiftUI

// BodyMapView.swift — v4
// Wider forearms & calves, 8-head canon, full anatomical mass
// Source grid: 500 × 920. Normalised via svgX/500, svgY/920.

private enum MapTokens {
    static let silhouetteFill        = Color(hex: "#7B5AB0").opacity(0.30)
    static let silhouetteStroke      = Color(hex: "#C4A0E8").opacity(0.60)
    static let silhouetteStrokeWidth: CGFloat = 1.3
    static let canvasWidth:  CGFloat = 230
    static let canvasHeight: CGFloat = 423
    static let dotBaseSize:  CGFloat = 20
    static let dotPulseScale: CGFloat = 1.6
    static let sheetCornerRadius: CGFloat = 28
}

// MARK: - BodyMapView

struct BodyMapView: View {
    @Binding var sensations: [BodySensation]
    @State private var activeSide: BodySide = .front
    @State private var pendingTapLocation: CGPoint? = nil
    @State private var pendingNormalized: (x: Double, y: Double)? = nil
    @State private var showSensationPicker = false
    @State private var selectedSensationID: UUID? = nil
    @State private var isFlipping = false
    var isReadOnly: Bool = false
    var isCompact: Bool = false

    @EnvironmentObject private var loc: LocalizationManager
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private var canvasSize: CGSize {
        if isCompact {
            return CGSize(width: 66, height: 121)
        }
        if hSizeClass == .regular {
            return CGSize(width: 300, height: 552)
        }
        return CGSize(width: MapTokens.canvasWidth, height: MapTokens.canvasHeight)
    }

    var body: some View {
        VStack(spacing: isCompact ? 4 : 16) {
            if !isCompact { sideToggle }
            bodyCanvas
                .frame(width: canvasSize.width, height: canvasSize.height)
                .contentShape(Rectangle())
                .onTapGesture { loc in
                    guard !isReadOnly else { return }
                    handleTap(at: loc)
                }
                .rotation3DEffect(
                    .degrees(isFlipping ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isFlipping)
            if !isCompact && !isReadOnly {
                Text(L10n.tapWhereYouFeel(loc.language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .sheet(isPresented: $showSensationPicker) {
            SensationPickerSheet(
                onSelect: { t, i, n in commitSensation(type: t, intensity: i, note: n) },
                onCancel: { pendingTapLocation = nil; pendingNormalized = nil }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(MapTokens.sheetCornerRadius)
        }
    }

    // MARK: Side toggle

    private var sideToggle: some View {
        HStack(spacing: 0) {
            ForEach(BodySide.allCases, id: \.self) { side in
                Button {
                    withAnimation { isFlipping.toggle() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { activeSide = side }
                } label: {
                    Text(side.localizedName(loc.language))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(activeSide == side ? .white : Color(hex: "#6D5F80"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if activeSide == side { Capsule().fill(Color(hex: "#8B6CAF")) }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .background(Capsule().fill(Color(hex: "#2B1B50")))
        .frame(maxWidth: 240)
    }

    // MARK: Canvas

    private var bodyCanvas: some View {
        ZStack {
            if !isCompact {
                RadialGradient(
                    colors: [Color(hex: "#7B5AB0").opacity(0.12), .clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: canvasSize.width * 0.85
                )
            }
            silhouetteView
            ForEach(sensationsForActiveSide) { s in
                SensationDotView(
                    sensation: s,
                    canvasSize: canvasSize,
                    isCompact: isCompact,
                    isSelected: selectedSensationID == s.id,
                    onTap: isReadOnly ? nil : {
                        selectedSensationID = selectedSensationID == s.id ? nil : s.id
                    },
                    onDelete: isReadOnly ? nil : {
                        withAnimation(.spring(response: 0.3)) {
                            sensations.removeAll { $0.id == s.id }
                            selectedSensationID = nil
                        }
                    }
                )
            }
            if let tap = pendingTapLocation, !isReadOnly {
                TapRippleView().position(tap)
            }
        }
    }

    @ViewBuilder private var silhouetteView: some View {
        let sw: CGFloat = {
            if isCompact { return 0.5 }
            return hSizeClass == .regular ? 1.7 : MapTokens.silhouetteStrokeWidth
        }()
        let spineSW: CGFloat = {
            if isCompact { return 0.3 }
            return hSizeClass == .regular ? 0.9 : 0.7
        }()
        ZStack {
            FrontBodyShape()
                .fill(MapTokens.silhouetteFill)
                .overlay(FrontBodyShape().stroke(MapTokens.silhouetteStroke, lineWidth: sw))
            if activeSide == .back {
                SpineDetailShape()
                    .stroke(
                        MapTokens.silhouetteStroke.opacity(0.30),
                        style: StrokeStyle(lineWidth: spineSW, dash: [4, 4])
                    )
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private var sensationsForActiveSide: [BodySensation] {
        sensations.filter { $0.side == activeSide }
    }

    // MARK: Tap handling

    private func handleTap(at location: CGPoint) {
        let nx = Double(location.x / canvasSize.width)
        let ny = Double(location.y / canvasSize.height)
        guard nx > 0.05, nx < 0.95, ny > 0.01, ny < 0.98 else { return }
        pendingTapLocation = location
        pendingNormalized = (nx, ny)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        showSensationPicker = true
    }

    private func commitSensation(type: SensationType, intensity: Int, note: String?) {
        guard let n = pendingNormalized else { return }
        let region = BodyRegionDetector.detect(normalizedX: n.x, normalizedY: n.y, side: activeSide)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            sensations.append(BodySensation(
                side: activeSide,
                normalizedX: n.x,
                normalizedY: n.y,
                region: region,
                sensationType: type,
                localIntensity: intensity,
                note: note
            ))
        }
        pendingTapLocation = nil
        pendingNormalized = nil
    }
}

// MARK: - Front Body Shape (v4 — wider forearms & calves)

struct FrontBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        func pt(_ sx: CGFloat, _ sy: CGFloat) -> CGPoint {
            CGPoint(x: w * (sx / 500), y: h * (sy / 920))
        }

        p.move(to: pt(250, 48))
        // Right head
        p.addCurve(to: pt(292, 100), control1: pt(280, 48),  control2: pt(292, 75))
        p.addCurve(to: pt(268, 158), control1: pt(292, 130), control2: pt(278, 150))
        // Right neck
        p.addCurve(to: pt(278, 178), control1: pt(272, 162), control2: pt(275, 170))
        // Right shoulder
        p.addCurve(to: pt(370, 194), control1: pt(300, 182), control2: pt(345, 188))
        // Right deltoid + upper arm
        p.addCurve(to: pt(390, 248), control1: pt(382, 198), control2: pt(390, 218))
        p.addCurve(to: pt(380, 355), control1: pt(390, 282), control2: pt(386, 322))
        // Right forearm outer (wider)
        p.addCurve(to: pt(396, 472), control1: pt(380, 378), control2: pt(392, 430))
        // Right hand outer — fingertips
        p.addCurve(to: pt(396, 540), control1: pt(398, 492), control2: pt(398, 518))
        p.addCurve(to: pt(384, 542), control1: pt(394, 550), control2: pt(388, 552))
        // Right hand inner — forearm inner (wider)
        p.addCurve(to: pt(370, 470), control1: pt(378, 522), control2: pt(374, 496))
        p.addCurve(to: pt(352, 382), control1: pt(366, 442), control2: pt(358, 408))
        // Right inner arm — armpit
        p.addCurve(to: pt(330, 290), control1: pt(346, 358), control2: pt(338, 322))
        p.addCurve(to: pt(322, 248), control1: pt(326, 272), control2: pt(324, 255))
        // Armpit — torso
        p.addCurve(to: pt(312, 254), control1: pt(320, 242), control2: pt(316, 244))
        p.addCurve(to: pt(300, 338), control1: pt(308, 274), control2: pt(304, 308))
        // Right waist
        p.addCurve(to: pt(302, 382), control1: pt(298, 350), control2: pt(298, 360))
        // Right hip
        p.addCurve(to: pt(322, 448), control1: pt(308, 410), control2: pt(316, 432))
        p.addCurve(to: pt(330, 486), control1: pt(328, 462), control2: pt(332, 472))
        // Right outer thigh
        p.addCurve(to: pt(334, 575), control1: pt(334, 514), control2: pt(338, 548))
        p.addCurve(to: pt(320, 650), control1: pt(330, 600), control2: pt(324, 628))
        // Right knee
        p.addCurve(to: pt(314, 682), control1: pt(316, 665), control2: pt(314, 674))
        // Right calf (wider)
        p.addCurve(to: pt(324, 720), control1: pt(314, 690), control2: pt(318, 700))
        p.addCurve(to: pt(322, 790), control1: pt(328, 740), control2: pt(328, 762))
        // Right ankle + foot
        p.addCurve(to: pt(302, 855), control1: pt(316, 815), control2: pt(308, 840))
        p.addCurve(to: pt(304, 888), control1: pt(300, 865), control2: pt(302, 878))
        p.addLine(to: pt(304, 900))
        p.addLine(to: pt(276, 900))
        // Right inner ankle
        p.addCurve(to: pt(274, 856), control1: pt(274, 888), control2: pt(272, 872))
        p.addCurve(to: pt(286, 785), control1: pt(278, 835), control2: pt(282, 810))
        // Right inner calf (wider)
        p.addCurve(to: pt(288, 715), control1: pt(290, 760), control2: pt(290, 738))
        // Right inner knee
        p.addCurve(to: pt(284, 682), control1: pt(286, 700), control2: pt(284, 690))
        p.addCurve(to: pt(286, 655), control1: pt(284, 674), control2: pt(286, 665))
        // Right inner thigh — crotch
        p.addCurve(to: pt(270, 578), control1: pt(282, 632), control2: pt(276, 604))
        p.addCurve(to: pt(258, 504), control1: pt(266, 558), control2: pt(262, 530))
        p.addCurve(to: pt(250, 474), control1: pt(254, 488), control2: pt(252, 478))
        // Crotch — left inner thigh
        p.addCurve(to: pt(242, 504), control1: pt(248, 478), control2: pt(246, 488))
        p.addCurve(to: pt(230, 578), control1: pt(238, 530), control2: pt(234, 558))
        p.addCurve(to: pt(214, 655), control1: pt(224, 604), control2: pt(218, 632))
        // Left inner knee
        p.addCurve(to: pt(216, 682), control1: pt(214, 665), control2: pt(216, 674))
        // Left inner calf (wider)
        p.addCurve(to: pt(212, 715), control1: pt(216, 690), control2: pt(214, 700))
        p.addCurve(to: pt(214, 785), control1: pt(210, 738), control2: pt(210, 760))
        // Left inner ankle
        p.addCurve(to: pt(226, 856), control1: pt(218, 810), control2: pt(222, 835))
        p.addCurve(to: pt(224, 900), control1: pt(228, 872), control2: pt(226, 888))
        // Left foot
        p.addLine(to: pt(196, 900))
        p.addLine(to: pt(196, 888))
        p.addCurve(to: pt(198, 855), control1: pt(198, 878), control2: pt(200, 865))
        // Left calf outer (wider)
        p.addCurve(to: pt(178, 790), control1: pt(192, 840), control2: pt(184, 815))
        p.addCurve(to: pt(176, 720), control1: pt(172, 762), control2: pt(172, 740))
        // Left knee
        p.addCurve(to: pt(186, 682), control1: pt(182, 700), control2: pt(186, 690))
        p.addCurve(to: pt(180, 650), control1: pt(186, 674), control2: pt(184, 665))
        // Left outer thigh
        p.addCurve(to: pt(166, 575), control1: pt(176, 628), control2: pt(170, 600))
        p.addCurve(to: pt(170, 486), control1: pt(162, 548), control2: pt(166, 514))
        // Left hip
        p.addCurve(to: pt(178, 448), control1: pt(168, 472), control2: pt(172, 462))
        p.addCurve(to: pt(198, 382), control1: pt(184, 432), control2: pt(192, 410))
        // Left waist
        p.addCurve(to: pt(200, 338), control1: pt(202, 360), control2: pt(202, 350))
        // Left torso — armpit
        p.addCurve(to: pt(188, 254), control1: pt(196, 308), control2: pt(192, 274))
        p.addCurve(to: pt(178, 248), control1: pt(184, 244), control2: pt(180, 242))
        // Left inner arm
        p.addCurve(to: pt(170, 290), control1: pt(176, 255), control2: pt(174, 272))
        p.addCurve(to: pt(148, 382), control1: pt(162, 322), control2: pt(154, 358))
        // Left inner forearm (wider)
        p.addCurve(to: pt(130, 470), control1: pt(142, 408), control2: pt(134, 442))
        // Left hand inner — fingertips
        p.addCurve(to: pt(116, 542), control1: pt(126, 496), control2: pt(122, 522))
        p.addCurve(to: pt(104, 540), control1: pt(112, 552), control2: pt(106, 550))
        // Left hand outer — forearm outer (wider)
        p.addCurve(to: pt(104, 472), control1: pt(102, 518), control2: pt(102, 492))
        p.addCurve(to: pt(120, 355), control1: pt(104, 458), control2: pt(108, 430))
        // Left upper arm
        p.addCurve(to: pt(110, 248), control1: pt(122, 368), control2: pt(114, 322))
        p.addCurve(to: pt(130, 194), control1: pt(110, 218), control2: pt(118, 198))
        // Left shoulder
        p.addCurve(to: pt(222, 178), control1: pt(155, 188), control2: pt(200, 182))
        // Left neck
        p.addCurve(to: pt(232, 158), control1: pt(225, 170), control2: pt(228, 162))
        // Left head — top
        p.addCurve(to: pt(208, 100), control1: pt(222, 150), control2: pt(208, 130))
        p.addCurve(to: pt(250, 48),  control1: pt(208, 75),  control2: pt(220, 48))
        p.closeSubpath()
        return p
    }
}

// MARK: - Spine + Shoulder Blades

struct SpineDetailShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        func pt(_ sx: CGFloat, _ sy: CGFloat) -> CGPoint {
            CGPoint(x: w * (sx / 500), y: h * (sy / 920))
        }
        let segs: [(CGFloat, CGFloat)] = [
            (162, 195), (200, 235), (240, 275), (280, 315),
            (320, 355), (360, 395), (400, 435), (440, 465)
        ]
        for s in segs {
            p.move(to: pt(250, s.0))
            p.addLine(to: pt(250, s.1))
        }
        // Left shoulder blade
        p.move(to: pt(215, 195))
        p.addCurve(to: pt(198, 268), control1: pt(202, 220), control2: pt(195, 248))
        p.addCurve(to: pt(232, 280), control1: pt(205, 282), control2: pt(220, 288))
        // Right shoulder blade
        p.move(to: pt(285, 195))
        p.addCurve(to: pt(302, 268), control1: pt(298, 220), control2: pt(305, 248))
        p.addCurve(to: pt(268, 280), control1: pt(295, 282), control2: pt(280, 288))
        return p
    }
}

// MARK: - Sensation Dot View

struct SensationDotView: View {
    let sensation: BodySensation
    let canvasSize: CGSize
    var isCompact = false
    var isSelected = false
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?
    @State private var isPulsing = false

    private var dotSize: CGFloat {
        (isCompact ? 7 : MapTokens.dotBaseSize) * (1.0 + CGFloat(sensation.localIntensity - 1) * 0.08)
    }

    private var position: CGPoint {
        CGPoint(
            x: sensation.normalizedX * canvasSize.width,
            y: sensation.normalizedY * canvasSize.height
        )
    }

    var body: some View {
        ZStack {
            if !isCompact {
                Circle()
                    .fill(sensation.sensationType.dotColor.opacity(0.18))
                    .frame(width: dotSize * MapTokens.dotPulseScale, height: dotSize * MapTokens.dotPulseScale)
                    .scaleEffect(isPulsing ? 1.5 : 1.0)
                    .opacity(isPulsing ? 0.0 : 0.5)
            }
            Circle()
                .fill(sensation.sensationType.dotColor.opacity(0.22))
                .frame(width: dotSize + 4, height: dotSize + 4)
            Circle()
                .fill(sensation.sensationType.dotColor)
                .frame(width: dotSize, height: dotSize)
                .shadow(color: sensation.sensationType.dotColor.opacity(0.4), radius: 4, y: 1)
            if !isCompact && isSelected {
                Text(sensation.sensationType.emoji)
                    .font(.system(size: 11))
                    .offset(y: -(dotSize / 2 + 12))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .position(position)
        .onTapGesture { onTap?() }
        .onAppear {
            guard !isCompact else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
        .overlay {
            if isSelected, let onDelete {
                Button { onDelete() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white, Color.red.opacity(0.85))
                        .shadow(radius: 2)
                }
                .position(x: position.x + dotSize / 2 + 6, y: position.y - dotSize / 2 - 6)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Tap Ripple

struct TapRippleView: View {
    @State private var animate = false
    var body: some View {
        Circle()
            .stroke(Color(hex: "#C4A0E8").opacity(0.7), lineWidth: 2)
            .frame(width: 28, height: 28)
            .scaleEffect(animate ? 2.0 : 0.5)
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.45)) { animate = true }
            }
    }
}

// MARK: - Sensation Picker Sheet

struct SensationPickerSheet: View {
    let onSelect: (SensationType, Int, String?) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var loc: LocalizationManager
    @State private var selectedType: SensationType? = nil
    @State private var intensity: Int = 3
    @State private var note: String = ""

    private var groups: [(String, [SensationType])] {
        [
            (L10n.groupTension(loc.language),     [.tightness, .pressure, .constriction, .heaviness, .knot]),
            (L10n.groupActivation(loc.language),  [.tingling, .vibration, .fluttering, .racing, .pulsing]),
            (L10n.groupTemperature(loc.language), [.warmth, .heat, .coldness, .chills]),
            (L10n.groupEase(loc.language),        [.lightness, .openness, .softness, .expansion]),
            (L10n.groupDiscomfort(loc.language),  [.pain, .ache, .nausea, .dizziness, .numbness]),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(groups, id: \.0) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.0)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .padding(.leading, 4)
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                                spacing: 8
                            ) {
                                ForEach(group.1, id: \.self) { type in chip(type) }
                            }
                        }
                    }

                    if selectedType != nil {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.intensityLabel(loc.language))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { lv in
                                    Button {
                                        intensity = lv
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    } label: {
                                        Circle()
                                            .fill(intensity >= lv
                                                  ? (selectedType?.dotColor ?? .gray)
                                                  : Color(hex: "#2B1B50"))
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Text("\(lv)")
                                                    .font(.caption2.weight(.bold))
                                                    .foregroundStyle(intensity >= lv ? .white : Color(hex: "#6D5F80"))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.noteOptional(loc.language))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            TextField(L10n.whatDoesItFeelLike(loc.language), text: $note, axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(L10n.whatDoYouFeel(loc.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel(loc.language)) { onCancel(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.add(loc.language)) {
                        guard let t = selectedType else { return }
                        onSelect(t, intensity, note.isEmpty ? nil : note)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedType == nil)
                }
            }
            .animation(.spring(response: 0.35), value: selectedType)
        }
    }

    private func chip(_ type: SensationType) -> some View {
        let on = selectedType == type
        return Button {
            selectedType = type
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            HStack(spacing: 4) {
                Text(type.emoji).font(.system(size: 14))
                Text(type.localizedName(loc.language)).font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(on ? type.dotColor.opacity(0.30) : Color(hex: "#2B1B50"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(on ? type.dotColor : .clear, lineWidth: 1.5)
            )
            .foregroundStyle(on ? type.dotColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Body Region Detector

enum BodyRegionDetector {
    static func detect(normalizedX x: Double, normalizedY y: Double, side: BodySide) -> BodyRegion {
        let chin   = 0.172
        let neck   = 0.193
        let armpit = 0.270
        let waist  = 0.385
        let hip    = 0.480
        let crotch = 0.515
        let knee   = 0.720
        let ankle  = 0.930

        if side == .back {
            if y < neck  { return .neckBack }
            if y < 0.30 && (x < 0.40 || x > 0.60) { return .shoulderBlades }
            if y < waist  { return .upperBack }
            if y < crotch { return .lowerBack }
            if y < 0.55   { return .glutes }
            if y >= knee && y < ankle { return .calves }
        }

        if y < chin  { return y < 0.11 ? .head : .jaw }
        if y < neck  { return .throat }
        if y < armpit && (x < 0.26 || x > 0.74) { return .shoulders }
        if y >= neck && y < hip {
            if x < 0.22 || x > 0.78 { return .arms }
            if (x < 0.34 || x > 0.66) && y >= armpit { return .arms }
        }
        if y >= hip && y < 0.60 && (x < 0.22 || x > 0.78) { return .hands }
        if y < 0.24 { return x >= 0.42 && x <= 0.56 ? .heart : .chest }
        if y < waist  { return .chest }
        if y < 0.45   { return .stomach }
        if y < crotch { return .abdomen }
        if y < crotch + 0.015 { return .hips }
        if y < knee   { return .legs }
        if y >= ankle { return .feet }
        return .legs
    }
}

// MARK: - Mini Body Map (for timeline cards)

struct MiniBodyMapView: View {
    let sensations: [BodySensation]
    var body: some View {
        BodyMapView(sensations: .constant(sensations), isReadOnly: true, isCompact: true)
            .frame(width: 66, height: 121)
            .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview("Full") {
    struct W: View {
        @State var s: [BodySensation] = [
            BodySensation(side: .front, normalizedX: 0.50,  normalizedY: 0.228, region: .chest,    sensationType: .tightness,  localIntensity: 4, note: "Heavy"),
            BodySensation(side: .front, normalizedX: 0.496, normalizedY: 0.346, region: .stomach,  sensationType: .fluttering, localIntensity: 3),
            BodySensation(side: .front, normalizedX: 0.50,  normalizedY: 0.065, region: .head,     sensationType: .pressure,   localIntensity: 5),
            BodySensation(side: .back,  normalizedX: 0.50,  normalizedY: 0.261, region: .upperBack, sensationType: .knot,       localIntensity: 4),
        ]
        var body: some View {
            ZStack {
                Color(hex: "#FAF7FD").ignoresSafeArea()
                BodyMapView(sensations: $s).padding()
            }
        }
    }
    return W().environmentObject(LocalizationManager())
}

#Preview("Mini") {
    MiniBodyMapView(sensations: [
        BodySensation(side: .front, normalizedX: 0.50,  normalizedY: 0.228, region: .chest,   sensationType: .tightness,  localIntensity: 4),
        BodySensation(side: .front, normalizedX: 0.496, normalizedY: 0.346, region: .stomach, sensationType: .fluttering, localIntensity: 2),
    ])
    .padding()
    .background(Color(hex: "#FAF7FD"))
    .environmentObject(LocalizationManager())
}
