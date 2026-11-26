import AppIntents
import Foundation
import Observation

@MainActor
@Observable
final class ReelTranscriptionJob {
    static let shared = ReelTranscriptionJob()

    private(set) var isRunning = false
    private(set) var status: String?
    private(set) var savedFile: URL?
    private(set) var unsavedTranscript: String?
    private(set) var errorMessage: String?
    private(set) var progress: Double?

    private init() {}

    func start(audio: IntentFile, model: ReelSpeechModel, fileName: String?) async throws {
        let store = ModelStore.shared
        guard !isRunning, !store.isBusy else { throw ModelStoreError.busy }
        isRunning = true
        status = "Preparing audio…"
        progress = 0
        savedFile = nil
        unsavedTranscript = nil
        errorMessage = nil

        let files = FileManager.default
        let staging = files.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let input: URL
        do {
            try files.createDirectory(at: staging, withIntermediateDirectories: false)
            input = try await withLocalFile(audio, fallbackExtension: "m4a") { source in
                let destination = staging.appendingPathComponent("audio")
                    .appendingPathExtension(source.pathExtension.isEmpty ? "m4a" : source.pathExtension)
                try files.copyItem(at: source, to: destination)
                return destination
            }
        } catch {
            try? files.removeItem(at: staging)
            fail("Could not open the Reel audio. \(error.localizedDescription)")
            throw error
        }

        Task {
            defer {
                try? files.removeItem(at: staging)
                isRunning = false
            }

            do {
                status = "Transcribing audio…"
                progress = 1.0 / 3
                let text: String
                switch model {
                case .selected:
                    text = try await store.transcribeSpeech(audioURL: input)
                case .ultra:
                    text = try await store.transcribeSpeech(audioURL: input, useHindiModel: false)
                case .hindi:
                    text = try await store.transcribeSpeech(audioURL: input, useHindiModel: true)
                }

                let transcript = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !transcript.isEmpty else {
                    fail("No speech was found in this Reel.")
                    return
                }

                status = "Saving transcript…"
                progress = 2.0 / 3
                do {
                    let url = try save(transcript, fileName: fileName)
                    savedFile = url
                    progress = 1
                    status = "Saved \(url.lastPathComponent)"
                } catch {
                    unsavedTranscript = transcript
                    fail("Could not save the transcript to Files. \(error.localizedDescription)")
                }
            } catch {
                fail("Could not transcribe the Reel. \(error.localizedDescription)")
            }
        }
    }

    private func fail(_ message: String) {
        status = nil
        progress = nil
        errorMessage = message
        isRunning = false
    }

    private func save(_ transcript: String, fileName: String?) throws -> URL {
        let files = FileManager.default
        let documents = try files.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folder = documents.appendingPathComponent("ReelDL Transcripts", isDirectory: true)
        try files.createDirectory(at: folder, withIntermediateDirectories: true)

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let cleanName = String((fileName ?? "").unicodeScalars.filter { allowed.contains($0) }.prefix(80))
        let base = cleanName.isEmpty ? "Reel-\(UUID().uuidString.prefix(8))" : cleanName
        var destination = folder.appendingPathComponent(base).appendingPathExtension("txt")
        var suffix = 2
        while files.fileExists(atPath: destination.path) {
            destination = folder.appendingPathComponent("\(base)-\(suffix)").appendingPathExtension("txt")
            suffix += 1
        }
        try (transcript + "\n").write(to: destination, atomically: true, encoding: .utf8)
        return destination
    }
}
