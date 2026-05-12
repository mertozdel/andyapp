import Foundation

enum L10n: String {
    // App / navigation
    case timelineTitle
    case settingsTitle

    // Timeline empty state
    case emptyTitle
    case emptySubtitle

    // Day labels
    case today
    case yesterday

    // Card
    case levelN

    // Toolbar / menu
    case exportSend
    case selectToSend
    case exportThisEntry
    case selectMultiple
    case cancel
    case send
    case sendN
    case done
    case ok

    // Export view
    case sendTitle
    case calendar
    case selectEntry
    case multiple
    case pickADate
    case selectEntryLabel
    case chooseAnEntry
    case chooseEntryTitle
    case chooseEntriesTitle
    case generating
    case noEntriesOn
    case entrySingular
    case entryPlural
    case entriesCountSelected
    case noEntriesSelected
    case noEntrySelected
    case entriesOnDate
    case entryOnDate
    case oneEntryOnDate

    // Settings
    case privacyHeader
    case privacyLine1
    case privacyLine2
    case aboutHeader
    case versionLabel
    case builtWithLabel
    case languageHeader
    case languageLabel

    // CheckIn nav titles (step titles)
    case step1Title
    case step2Title
    case step3Title
    case step4Title
    case step5Title
    case step6Title
    case continueBtn
    case saveEntry
    case couldNotSave
    case entrySaved
    case entrySavedSub

    // Intensity labels
    case intensityBarely
    case intensityNoticeable
    case intensityQuite
    case intensityVery
    case intensityOverwhelming

    // CheckIn body
    case selectAllApply
    case bodyMapOptional
    case bedtime
    case wakeTime
    case duration
    case sleepQuality
    case timesWokenUp
    case dreams
    case dreamsNone
    case dreamsPleasant
    case dreamsDisturbing
    case notes
    case sleepNotesPlaceholder
    case desireLevel
    case desireVeryLow
    case desireLow
    case desireModerate
    case desireHigh
    case desireVeryHigh
    case context
    case libidoSpontaneous
    case libidoResponsive
    case libidoLow
    case libidoDistracted
    case libidoConnected
    case libidoNotesPlaceholder

    case journalPh1
    case journalPh2
    case journalPh3
    case journalPh4
    case optionalReflections
    case promptTrigger
    case promptNeed
    case promptGratitude

    // Body sensation picker
    case whatDoYouFeel
    case add
    case intensityLabel
    case noteOptional
    case whatDoesItFeelLike
    case groupTension
    case groupActivation
    case groupTemperature
    case groupEase
    case groupDiscomfort
    case tapWhereYouFeel

    // Side toggle
    case sideFront
    case sideBack

    // EntryDetail
    case feelings
    case bodySensationsLabel
    case journalLabel
    case reflectionsLabel
    case detailTriggerLabel
    case detailNeedLabel
    case detailGratitudeLabel

    // PDF
    case pdfHeaderTitle
    case pdfSubtitle
    case pdfExported
    case pdfFooter
    case pdfEmotional
    case pdfJournal
    case pdfBodySensations
    case pdfSleep
    case pdfDesire
    case pdfReflections
    case pdfSensationsNotedSingular
    case pdfSensationsNotedPlural
    case pdfDuration
    case pdfQuality
    case pdfWakeups
    case pdfHadDreams
    case pdfNotes
    case pdfDesireLevel
    case pdfWhatTriggered
    case pdfWhatNeed
    case pdfOneSmallThing
}

extension L10n {

    private static let en: [L10n: String] = [
        .timelineTitle: "Medicus",
        .settingsTitle: "Settings",

        .emptyTitle: "Your journal is waiting",
        .emptySubtitle: "Tap + to check in with yourself",

        .today: "Today",
        .yesterday: "Yesterday",

        .levelN: "Level %d",

        .exportSend: "Export / Send",
        .selectToSend: "Select to Send",
        .exportThisEntry: "Export this entry",
        .selectMultiple: "Select multiple",
        .cancel: "Cancel",
        .send: "Send",
        .sendN: "Send (%d)",
        .done: "Done",
        .ok: "OK",

        .sendTitle: "Send",
        .calendar: "Calendar",
        .selectEntry: "Select Entry",
        .multiple: "Multiple",
        .pickADate: "Pick a Date",
        .selectEntryLabel: "Select Entry",
        .chooseAnEntry: "Choose an entry…",
        .chooseEntryTitle: "Choose Entry",
        .chooseEntriesTitle: "Choose Entries",
        .generating: "Generating…",
        .noEntriesOn: "No entries on %@",
        .entrySingular: "entry",
        .entryPlural: "entries",
        .entriesCountSelected: "%d entries selected",
        .noEntriesSelected: "No entries selected",
        .noEntrySelected: "No entry selected",
        .entriesOnDate: "%d entries · %@",
        .entryOnDate: "1 entry · %@",
        .oneEntryOnDate: "1 entry · %@",

        .privacyHeader: "Privacy",
        .privacyLine1: "All diary entries are stored only on this device.",
        .privacyLine2: "Nothing is ever sent to the internet from your diary.",
        .aboutHeader: "About",
        .versionLabel: "Version",
        .builtWithLabel: "Built with",
        .languageHeader: "Language",
        .languageLabel: "Language",

        .step1Title: "How intense is it?",
        .step2Title: "What are you feeling?",
        .step3Title: "Where do you feel it?",
        .step4Title: "How did you sleep?",
        .step5Title: "Desire & libido",
        .step6Title: "Tell me more",
        .continueBtn: "Continue",
        .saveEntry: "Save Entry",
        .couldNotSave: "Couldn't save entry",
        .entrySaved: "Entry saved",
        .entrySavedSub: "You checked in with yourself.",

        .intensityBarely: "Barely there",
        .intensityNoticeable: "Noticeable",
        .intensityQuite: "Quite intense",
        .intensityVery: "Very intense",
        .intensityOverwhelming: "Overwhelming",

        .selectAllApply: "Select all that apply",
        .bodyMapOptional: "Optional — skip if you don't feel it in your body",
        .bedtime: "Bedtime",
        .wakeTime: "Wake time",
        .duration: "Duration",
        .sleepQuality: "Sleep quality",
        .timesWokenUp: "Times woken up",
        .dreams: "Dreams",
        .dreamsNone: "None",
        .dreamsPleasant: "Pleasant",
        .dreamsDisturbing: "Disturbing",
        .notes: "Notes",
        .sleepNotesPlaceholder: "Anything else about your sleep…",
        .desireLevel: "Desire level",
        .desireVeryLow: "Very low",
        .desireLow: "Low",
        .desireModerate: "Moderate",
        .desireHigh: "High",
        .desireVeryHigh: "Very high",
        .context: "Context",
        .libidoSpontaneous: "Spontaneous",
        .libidoResponsive: "Responsive",
        .libidoLow: "Low",
        .libidoDistracted: "Distracted",
        .libidoConnected: "Connected",
        .libidoNotesPlaceholder: "Any thoughts…",

        .journalPh1: "What's on your mind?",
        .journalPh2: "Where are you right now?",
        .journalPh3: "What does your body want you to know?",
        .journalPh4: "How did your day unfold?",
        .optionalReflections: "Optional reflections",
        .promptTrigger: "What triggered this feeling?",
        .promptNeed: "What do you think you need right now?",
        .promptGratitude: "One small thing you noticed today",

        .whatDoYouFeel: "What do you feel?",
        .add: "Add",
        .intensityLabel: "Intensity",
        .noteOptional: "Note (optional)",
        .whatDoesItFeelLike: "What does it feel like?",
        .groupTension: "Tension",
        .groupActivation: "Activation",
        .groupTemperature: "Temperature",
        .groupEase: "Ease",
        .groupDiscomfort: "Discomfort",
        .tapWhereYouFeel: "Tap where you feel it",

        .sideFront: "Front",
        .sideBack: "Back",

        .feelings: "Feelings",
        .bodySensationsLabel: "Body sensations",
        .journalLabel: "Journal",
        .reflectionsLabel: "Reflections",
        .detailTriggerLabel: "What triggered it",
        .detailNeedLabel: "What I needed",
        .detailGratitudeLabel: "One thing I noticed",

        .pdfHeaderTitle: "Medicus",
        .pdfSubtitle: "Personal Diary  ·  PDF Export  ·  %d %@",
        .pdfExported: "Exported  %@",
        .pdfFooter: "Page %d  ·  Medicus — Personal Diary",
        .pdfEmotional: "EMOTIONAL CHECK-IN",
        .pdfJournal: "JOURNAL",
        .pdfBodySensations: "BODY SENSATIONS",
        .pdfSleep: "SLEEP",
        .pdfDesire: "DESIRE",
        .pdfReflections: "REFLECTIONS",
        .pdfSensationsNotedSingular: "1 sensation area noted",
        .pdfSensationsNotedPlural: "%d sensation areas noted",
        .pdfDuration: "Duration: %@",
        .pdfQuality: "Quality: %d/10",
        .pdfWakeups: "Wakeups: %d",
        .pdfHadDreams: "Had dreams",
        .pdfNotes: "Notes: %@",
        .pdfDesireLevel: "Level: %d/10",
        .pdfWhatTriggered: "What triggered this?",
        .pdfWhatNeed: "What do you need right now?",
        .pdfOneSmallThing: "One small thing noticed",
    ]

    private static let de: [L10n: String] = [
        .timelineTitle: "Medicus",
        .settingsTitle: "Einstellungen",

        .emptyTitle: "Dein Tagebuch wartet",
        .emptySubtitle: "Tippe auf +, um dich einzuchecken",

        .today: "Heute",
        .yesterday: "Gestern",

        .levelN: "Stufe %d",

        .exportSend: "Exportieren / Senden",
        .selectToSend: "Mehrere auswählen",
        .exportThisEntry: "Diesen Eintrag exportieren",
        .selectMultiple: "Mehrere auswählen",
        .cancel: "Abbrechen",
        .send: "Senden",
        .sendN: "Senden (%d)",
        .done: "Fertig",
        .ok: "OK",

        .sendTitle: "Senden",
        .calendar: "Kalender",
        .selectEntry: "Eintrag",
        .multiple: "Mehrere",
        .pickADate: "Datum wählen",
        .selectEntryLabel: "Eintrag auswählen",
        .chooseAnEntry: "Eintrag wählen…",
        .chooseEntryTitle: "Eintrag wählen",
        .chooseEntriesTitle: "Einträge wählen",
        .generating: "Erstellen…",
        .noEntriesOn: "Keine Einträge am %@",
        .entrySingular: "Eintrag",
        .entryPlural: "Einträge",
        .entriesCountSelected: "%d Einträge ausgewählt",
        .noEntriesSelected: "Keine Einträge ausgewählt",
        .noEntrySelected: "Kein Eintrag ausgewählt",
        .entriesOnDate: "%d Einträge · %@",
        .entryOnDate: "1 Eintrag · %@",
        .oneEntryOnDate: "1 Eintrag · %@",

        .privacyHeader: "Datenschutz",
        .privacyLine1: "Alle Tagebucheinträge werden nur auf diesem Gerät gespeichert.",
        .privacyLine2: "Aus deinem Tagebuch wird nichts ins Internet gesendet.",
        .aboutHeader: "Über",
        .versionLabel: "Version",
        .builtWithLabel: "Erstellt mit",
        .languageHeader: "Sprache",
        .languageLabel: "Sprache",

        .step1Title: "Wie stark ist es?",
        .step2Title: "Was fühlst du?",
        .step3Title: "Wo spürst du es?",
        .step4Title: "Wie hast du geschlafen?",
        .step5Title: "Verlangen & Libido",
        .step6Title: "Erzähl mir mehr",
        .continueBtn: "Weiter",
        .saveEntry: "Eintrag speichern",
        .couldNotSave: "Eintrag konnte nicht gespeichert werden",
        .entrySaved: "Eintrag gespeichert",
        .entrySavedSub: "Du hast bei dir eingecheckt.",

        .intensityBarely: "Kaum spürbar",
        .intensityNoticeable: "Spürbar",
        .intensityQuite: "Recht intensiv",
        .intensityVery: "Sehr intensiv",
        .intensityOverwhelming: "Überwältigend",

        .selectAllApply: "Wähle alle Zutreffenden aus",
        .bodyMapOptional: "Optional — überspringen, wenn du es körperlich nicht spürst",
        .bedtime: "Schlafenszeit",
        .wakeTime: "Aufwachzeit",
        .duration: "Dauer",
        .sleepQuality: "Schlafqualität",
        .timesWokenUp: "Aufwachen",
        .dreams: "Träume",
        .dreamsNone: "Keine",
        .dreamsPleasant: "Angenehm",
        .dreamsDisturbing: "Beunruhigend",
        .notes: "Notizen",
        .sleepNotesPlaceholder: "Sonst etwas zu deinem Schlaf…",
        .desireLevel: "Verlangen-Stufe",
        .desireVeryLow: "Sehr niedrig",
        .desireLow: "Niedrig",
        .desireModerate: "Mittel",
        .desireHigh: "Hoch",
        .desireVeryHigh: "Sehr hoch",
        .context: "Kontext",
        .libidoSpontaneous: "Spontan",
        .libidoResponsive: "Reaktiv",
        .libidoLow: "Niedrig",
        .libidoDistracted: "Abgelenkt",
        .libidoConnected: "Verbunden",
        .libidoNotesPlaceholder: "Irgendwelche Gedanken…",

        .journalPh1: "Was geht dir durch den Kopf?",
        .journalPh2: "Wo bist du gerade?",
        .journalPh3: "Was möchte dein Körper dir mitteilen?",
        .journalPh4: "Wie ist dein Tag verlaufen?",
        .optionalReflections: "Optionale Reflexionen",
        .promptTrigger: "Was hat dieses Gefühl ausgelöst?",
        .promptNeed: "Was glaubst du, brauchst du gerade?",
        .promptGratitude: "Eine kleine Sache, die dir heute aufgefallen ist",

        .whatDoYouFeel: "Was spürst du?",
        .add: "Hinzufügen",
        .intensityLabel: "Intensität",
        .noteOptional: "Notiz (optional)",
        .whatDoesItFeelLike: "Wie fühlt es sich an?",
        .groupTension: "Anspannung",
        .groupActivation: "Aktivierung",
        .groupTemperature: "Temperatur",
        .groupEase: "Wohlgefühl",
        .groupDiscomfort: "Beschwerden",
        .tapWhereYouFeel: "Tippe, wo du es spürst",

        .sideFront: "Vorne",
        .sideBack: "Hinten",

        .feelings: "Gefühle",
        .bodySensationsLabel: "Körperempfindungen",
        .journalLabel: "Tagebuch",
        .reflectionsLabel: "Reflexionen",
        .detailTriggerLabel: "Was hat es ausgelöst",
        .detailNeedLabel: "Was ich brauchte",
        .detailGratitudeLabel: "Etwas, das mir auffiel",

        .pdfHeaderTitle: "Medicus",
        .pdfSubtitle: "Persönliches Tagebuch  ·  PDF-Export  ·  %d %@",
        .pdfExported: "Exportiert  %@",
        .pdfFooter: "Seite %d  ·  Medicus — Persönliches Tagebuch",
        .pdfEmotional: "EMOTIONALER CHECK-IN",
        .pdfJournal: "TAGEBUCH",
        .pdfBodySensations: "KÖRPEREMPFINDUNGEN",
        .pdfSleep: "SCHLAF",
        .pdfDesire: "VERLANGEN",
        .pdfReflections: "REFLEXIONEN",
        .pdfSensationsNotedSingular: "1 Empfindungsbereich vermerkt",
        .pdfSensationsNotedPlural: "%d Empfindungsbereiche vermerkt",
        .pdfDuration: "Dauer: %@",
        .pdfQuality: "Qualität: %d/10",
        .pdfWakeups: "Aufwachen: %d",
        .pdfHadDreams: "Hatte Träume",
        .pdfNotes: "Notizen: %@",
        .pdfDesireLevel: "Stufe: %d/10",
        .pdfWhatTriggered: "Was hat das ausgelöst?",
        .pdfWhatNeed: "Was brauchst du gerade?",
        .pdfOneSmallThing: "Eine kleine Sache bemerkt",
    ]

    private static let table: [AppLanguage: [L10n: String]] = [
        .english: en,
        .german:  de,
    ]

    func callAsFunction(_ lang: AppLanguage, _ args: CVarArg...) -> String {
        let format = Self.table[lang]?[self] ?? Self.table[.english]?[self] ?? rawValue
        return args.isEmpty ? format : String(format: format, arguments: args)
    }
}

// MARK: - Localized Emotion / Sensation / Side

extension Emotion {
    func localizedName(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return displayName
        case .german:
            switch self {
            case .joy:           return "Freude"
            case .calm:          return "Ruhe"
            case .gratitude:     return "Dankbarkeit"
            case .love:          return "Liebe"
            case .excitement:    return "Begeisterung"
            case .contentment:   return "Zufriedenheit"
            case .hope:          return "Hoffnung"
            case .pride:         return "Stolz"
            case .anxiety:       return "Angst"
            case .fear:          return "Furcht"
            case .anger:         return "Wut"
            case .frustration:   return "Frust"
            case .shame:         return "Scham"
            case .guilt:         return "Schuld"
            case .disgust:       return "Ekel"
            case .overwhelm:     return "Überforderung"
            case .sadness:       return "Traurigkeit"
            case .loneliness:    return "Einsamkeit"
            case .numbness:      return "Taubheit"
            case .emptiness:     return "Leere"
            case .confusion:     return "Verwirrung"
            case .grief:         return "Trauer"
            case .tension:       return "Anspannung"
            case .restlessness:  return "Unruhe"
            case .vulnerability: return "Verletzlichkeit"
            }
        }
    }
}

extension SensationType {
    func localizedName(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return displayName
        case .german:
            switch self {
            case .tightness:    return "Enge"
            case .pressure:     return "Druck"
            case .constriction: return "Beengung"
            case .heaviness:    return "Schwere"
            case .knot:         return "Knoten"
            case .tingling:     return "Kribbeln"
            case .vibration:    return "Vibration"
            case .fluttering:   return "Flattern"
            case .racing:       return "Rasen"
            case .pulsing:      return "Pulsieren"
            case .warmth:       return "Wärme"
            case .heat:         return "Hitze"
            case .coldness:     return "Kälte"
            case .chills:       return "Schauer"
            case .lightness:    return "Leichtigkeit"
            case .openness:     return "Offenheit"
            case .softness:     return "Weichheit"
            case .expansion:    return "Weite"
            case .pain:         return "Schmerz"
            case .ache:         return "Pochen"
            case .nausea:       return "Übelkeit"
            case .dizziness:    return "Schwindel"
            case .numbness:     return "Taubheit"
            }
        }
    }
}

extension BodySide {
    func localizedName(_ lang: AppLanguage) -> String {
        switch self {
        case .front: return (lang == .german) ? "Vorne" : "Front"
        case .back:  return (lang == .german) ? "Hinten" : "Back"
        }
    }
}
