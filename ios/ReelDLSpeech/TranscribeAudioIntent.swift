import AppIntents
import Foundation

struct TranscribeAudioIntent: AppIntent {
    static let title: LocalizedStringResource = "Transcribe Audio (Offline)"
    static let description = IntentDescription("Transcribes an audio file using the downloaded on-device Ultra model.")
    static let openAppWhenRun = true
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Audio")
    var audio: IntentFile

    func perform() async throws -> some ReturnsValue<String> {
        let text = try await withLocalFile(audio, fallbackExtension: "m4a") { url in
            try await ModelStore.shared.transcribe(audioURL: url)
        }
        return .result(value: text)
    }
}

enum ReelSpeechModel: String, AppEnum {
    case selected
    case ultra
    case hindi

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Speech Model"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .selected: "App Default",
        .ultra: "Parakeet Ultra",
        .hindi: "Hindi / Hinglish"
    ]
}

struct TranscribeReelIntent: AppIntent {
    static let title: LocalizedStringResource = "Transcribe Reel (Offline)"
    static let description = IntentDescription("Saves a speech transcript to Files using reel.ex.")
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Audio")
    var audio: IntentFile

    @Parameter(title: "Speech Model", default: .selected)
    var speechModel: ReelSpeechModel

    @Parameter(title: "File Name")
    var fileName: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Transcribe \(\.$audio) using \(\.$speechModel)") {
            \.$fileName
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try await ReelTranscriptionJob.shared.start(audio: audio, model: speechModel, fileName: fileName)
        return .result()
    }
}

func withLocalFile<T>(
    _ file: IntentFile,
    fallbackExtension: String,
    operation: (URL) async throws -> T
) async throws -> T {
    if let url = file.fileURL {
        guard url.isFileURL else { throw LocalMediaError.unreadableFile }
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        return try await operation(url)
    }

    let data = file.data
    guard !data.isEmpty else { throw LocalMediaError.unreadableFile }
    let manager = FileManager.default
    let directory = manager.temporaryDirectory.appendingPathComponent("reeldl-\(UUID().uuidString)")
    try manager.createDirectory(at: directory, withIntermediateDirectories: false)
    defer { try? manager.removeItem(at: directory) }
    let fileExtension = URL(fileURLWithPath: file.filename).pathExtension
    let url = directory.appendingPathComponent("input")
        .appendingPathExtension(fileExtension.isEmpty ? fallbackExtension : fileExtension)
    try data.write(to: url, options: .atomic)
    return try await operation(url)
}

private enum LocalMediaError: LocalizedError {
    case unreadableFile

    var errorDescription: String? {
        "The supplied media is not a readable local file."
    }
}

struct ReelDLSpeechShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TranscribeAudioIntent(),
            phrases: ["Transcribe audio with \(.applicationName)"],
            shortTitle: "Transcribe Audio",
            systemImageName: "waveform"
        )
        AppShortcut(
            intent: TranscribeReelIntent(),
            phrases: ["Transcribe a Reel with \(.applicationName)"],
            shortTitle: "Transcribe Reel",
            systemImageName: "captions.bubble"
        )
    }
}
