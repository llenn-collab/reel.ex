import Foundation
import FluidAudio
import Observation

enum SpeechModelID: String, CaseIterable, Identifiable {
    case parakeetUltra
    case whisperTiny = "openai_whisper-tiny"
    case whisperTinyEnglish = "openai_whisper-tiny.en"
    case whisperBase = "openai_whisper-base"
    case whisperBaseEnglish = "openai_whisper-base.en"
    case whisperSmall = "openai_whisper-small"
    case whisperSmallCompressed = "openai_whisper-small_216MB"
    case whisperSmallEnglish = "openai_whisper-small.en"
    case whisperSmallEnglishCompressed = "openai_whisper-small.en_217MB"
    case whisperMedium = "openai_whisper-medium"
    case whisperMediumEnglish = "openai_whisper-medium.en"
    case whisperLargeV2 = "openai_whisper-large-v2"
    case whisperLargeV2Compressed = "openai_whisper-large-v2_949MB"
    case whisperLargeV2Turbo = "openai_whisper-large-v2_turbo"
    case whisperLargeV2TurboCompressed = "openai_whisper-large-v2_turbo_955MB"
    case whisperLargeV3 = "openai_whisper-large-v3"
    case whisperLargeV3Compressed = "openai_whisper-large-v3_947MB"
    case whisperLargeV3OriginalTurbo = "openai_whisper-large-v3_turbo"
    case whisperLargeV3OriginalTurboCompressed = "openai_whisper-large-v3_turbo_954MB"
    case whisperLargeV3September = "openai_whisper-large-v3-v20240930"
    case whisperLargeV3SeptemberSmall = "openai_whisper-large-v3-v20240930_547MB"
    case whisperLargeV3Legacy = "openai_whisper-large-v3-v20240930_626MB"
    case whisperLargeV3SeptemberTurbo = "openai_whisper-large-v3-v20240930_turbo"
    case whisperLargeV3Turbo = "openai_whisper-large-v3-v20240930_turbo_632MB"
    case distilLargeV3 = "distil-whisper_distil-large-v3"
    case distilLargeV3Compressed = "distil-whisper_distil-large-v3_594MB"
    case distilLargeV3Turbo = "distil-whisper_distil-large-v3_turbo"
    case distilLargeV3TurboCompressed = "distil-whisper_distil-large-v3_turbo_600MB"

    var id: String { rawValue }

    var title: String {
        if self == .parakeetUltra { return "Parakeet Ultra" }
        return rawValue
            .replacingOccurrences(of: "openai_whisper-", with: "Whisper ")
            .replacingOccurrences(of: "distil-whisper_distil-", with: "Distil Whisper ")
            .replacingOccurrences(of: "_", with: " · ")
            .replacingOccurrences(of: ".en", with: " (English)")
    }

    var sizeNote: String { "Keep reel.ex open while the model installs." }

    var supportsMultilingualSpeech: Bool {
        self != .parakeetUltra && !rawValue.contains(".en") && !rawValue.hasPrefix("distil-")
    }
}

enum ModelSlot: Int, CaseIterable, Identifiable {
    case first
    case second

    var id: Int { rawValue }
}

@MainActor
@Observable
final class ModelStore {
    static let shared = ModelStore()

    private(set) var isReady = false
    private(set) var isHindiReady = false
    private(set) var isBusy = false
    private(set) var enabledSlots: [String: Bool] = [:]
    var selectedModelID: String {
        didSet {
            guard SpeechModelID(rawValue: selectedModelID) != nil else {
                selectedModelID = oldValue
                return
            }
            UserDefaults.standard.set(selectedModelID, forKey: Self.selectedModelKey)
            refreshStatus()
        }
    }
    var status = "Checking model…"
    var errorMessage: String?

    private let version: AsrModelVersion = .ultra
    private let encoderPrecision: ParakeetEncoderPrecision = .int8
    private let fileManager = FileManager.default
    private let hindiTranscriber = HindiSpeechTranscriber()
    private static let selectedModelKey = "selectedSpeechModelID"
    private static let slotsKey = "installedSpeechModelSlots"
    private static let activeSlotKey = "activeSpeechModelSlot"
    private static let enabledSlotsKey = "enabledSpeechModelSlots"
    private var slotModels: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: Self.slotsKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: Self.slotsKey) }
    }
    private(set) var activeSlot: ModelSlot? = nil

    private init() {
        let savedSelection = UserDefaults.standard.string(forKey: Self.selectedModelKey)
        selectedModelID = savedSelection.flatMap(SpeechModelID.init(rawValue:))?.rawValue ?? SpeechModelID.parakeetUltra.rawValue
        let savedSlot = UserDefaults.standard.object(forKey: Self.activeSlotKey) as? Int
        activeSlot = savedSlot.flatMap(ModelSlot.init(rawValue:))
        migrateInstalledModels()
        enabledSlots = UserDefaults.standard.dictionary(forKey: Self.enabledSlotsKey) as? [String: Bool] ?? [:]
        for slot in ModelSlot.allCases where model(in: slot) != nil {
            enabledSlots[String(slot.rawValue), default: true] = true
        }
        UserDefaults.standard.set(enabledSlots, forKey: Self.enabledSlotsKey)
        if let activeSlot, !isEnabled(activeSlot) {
            self.activeSlot = nil
            UserDefaults.standard.removeObject(forKey: Self.activeSlotKey)
        }
        refreshStatus()
    }

    func model(in slot: ModelSlot) -> SpeechModelID? {
        guard let raw = slotModels[String(slot.rawValue)] else { return nil }
        return SpeechModelID(rawValue: raw)
    }

    func isEnabled(_ slot: ModelSlot) -> Bool {
        guard model(in: slot) != nil else { return false }
        return enabledSlots[String(slot.rawValue)] ?? true
    }

    func setEnabled(_ enabled: Bool, for slot: ModelSlot) {
        guard !isBusy, model(in: slot) != nil else { return }
        enabledSlots[String(slot.rawValue)] = enabled
        UserDefaults.standard.set(enabledSlots, forKey: Self.enabledSlotsKey)
        if enabled, activeSlot == nil {
            activate(slot)
        } else if !enabled, activeSlot == slot {
            if let fallback = ModelSlot.allCases.first(where: { $0 != slot && isEnabled($0) }) {
                activate(fallback)
            } else {
                activeSlot = nil
                UserDefaults.standard.removeObject(forKey: Self.activeSlotKey)
            }
        }
        refreshStatus()
    }

    func activate(_ slot: ModelSlot) {
        guard let model = model(in: slot), isEnabled(slot) else { return }
        activeSlot = slot
        UserDefaults.standard.set(slot.rawValue, forKey: Self.activeSlotKey)
        selectedModelID = model.rawValue
    }

    func download(_ model: SpeechModelID, into slot: ModelSlot) async {
        guard canInstall(model, in: slot) else { return }
        let previous = selectedModelID
        selectedModelID = model.rawValue
        await downloadSelectedModel()
        finishInstallation(model, in: slot, previousSelection: previous)
    }

    func importModel(_ model: SpeechModelID, from url: URL, into slot: ModelSlot) async {
        guard canInstall(model, in: slot) else { return }
        let previous = selectedModelID
        selectedModelID = model.rawValue
        await importModel(from: url)
        finishInstallation(model, in: slot, previousSelection: previous)
    }

    private func canInstall(_ model: SpeechModelID, in slot: ModelSlot) -> Bool {
        guard !isBusy else { return false }
        guard !ModelSlot.allCases.contains(where: { $0 != slot && self.model(in: $0) == model }) else {
            errorMessage = "This model is already in the other slot."
            return false
        }
        return true
    }

    private func finishInstallation(_ model: SpeechModelID, in slot: ModelSlot, previousSelection: String) {
        guard errorMessage == nil, isInstalled(model) else {
            selectedModelID = previousSelection
            return
        }
        if let replaced = self.model(in: slot), replaced != model { removeFiles(for: replaced) }
        set(model, in: slot)
    }

    private func removeFiles(for model: SpeechModelID) {
        if model == .parakeetUltra { deleteModel() }
        else { deleteHindiModel(variant: model.rawValue) }
    }

    func deleteModel(in slot: ModelSlot) {
        guard !isBusy, let model = model(in: slot) else { return }
        removeFiles(for: model)
        guard errorMessage == nil else { return }
        slotModels.removeValue(forKey: String(slot.rawValue))
        if activeSlot == slot {
            activeSlot = nil
            UserDefaults.standard.removeObject(forKey: Self.activeSlotKey)
            if let remaining = ModelSlot.allCases.first(where: { isEnabled($0) }) {
                activate(remaining)
            }
        }
        refreshStatus()
    }

    func deleteAllModels() {
        guard !isBusy else { return }
        var failures: [String] = []
        for slot in ModelSlot.allCases where model(in: slot) != nil {
            deleteModel(in: slot)
            if let errorMessage { failures.append(errorMessage) }
        }
        let assigned = Set(ModelSlot.allCases.compactMap { model(in: $0) })
        for model in SpeechModelID.allCases where !assigned.contains(model) && isInstalled(model) {
            removeFiles(for: model)
            if let errorMessage { failures.append(errorMessage) }
        }
        errorMessage = failures.isEmpty ? nil : failures.joined(separator: "\n")
    }

    private func set(_ model: SpeechModelID, in slot: ModelSlot) {
        var values = slotModels
        values[String(slot.rawValue)] = model.rawValue
        slotModels = values
        enabledSlots[String(slot.rawValue)] = true
        UserDefaults.standard.set(enabledSlots, forKey: Self.enabledSlotsKey)
        activeSlot = slot
        UserDefaults.standard.set(slot.rawValue, forKey: Self.activeSlotKey)
        refreshStatus()
    }

    private func migrateInstalledModels() {
        guard slotModels.isEmpty else { return }
        var installed: [SpeechModelID] = []
        if AsrModels.modelsExist(at: modelDirectory, version: version, encoderPrecision: encoderPrecision) { installed.append(.parakeetUltra) }
        installed += SpeechModelID.allCases.filter { $0 != .parakeetUltra && hindiTranscriber.isModelInstalled(variant: $0.rawValue) }
        guard !installed.isEmpty else { return }
        var values: [String: String] = [:]
        for (slot, model) in zip(ModelSlot.allCases, installed.prefix(2)) { values[String(slot.rawValue)] = model.rawValue }
        slotModels = values
        if let preferred = ModelSlot.allCases.first(where: { model(in: $0)?.rawValue == selectedModelID }) {
            activate(preferred)
        } else {
            activate(.first)
        }
    }

    var selectedModel: SpeechModelID {
        SpeechModelID(rawValue: selectedModelID) ?? .parakeetUltra
    }

    var selectedModelIsInstalled: Bool { isSelectedModelInstalled }

    private var isSelectedModelInstalled: Bool {
        ModelSlot.allCases.contains { slot in
            isEnabled(slot) && model(in: slot) == selectedModel && isInstalled(selectedModel)
        }
    }

    private var installedWhisperVariants: [String] {
        var variants = SpeechModelID.allCases
            .filter { $0 != .parakeetUltra }
            .map(\.rawValue)
            .filter { hindiTranscriber.isModelInstalled(variant: $0) }
        if hindiTranscriber.isModelInstalled(), !variants.contains(HindiSpeechTranscriber.modelID) {
            variants.append(HindiSpeechTranscriber.modelID)
        }
        return variants
    }

    private var modelDirectory: URL {
        AsrModels.defaultCacheDirectory(for: version)
    }

    func refreshStatus() {
        isReady = AsrModels.modelsExist(
            at: modelDirectory,
            version: version,
            encoderPrecision: encoderPrecision
        )
        isHindiReady = installedWhisperVariants.count > 0
        status = isSelectedModelInstalled ? "Ready for offline transcription" : "\(selectedModel.title) is not installed"
    }

    func downloadModel() async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        status = "Downloading Ultra model… Keep reel.ex open."
        defer {
            isBusy = false
            refreshStatus()
        }

        do {
            ModelHub.offlineMode = false
            _ = try await AsrModels.download(
                to: modelDirectory,
                version: version,
                encoderPrecision: encoderPrecision
            )
            guard AsrModels.modelsExist(
                at: modelDirectory,
                version: version,
                encoderPrecision: encoderPrecision
            ) else {
                throw ModelStoreError.incompleteDownload
            }
        } catch {
            errorMessage = "Download failed: \(error.localizedDescription)"
        }
    }

    func deleteModel() {
        guard !isBusy else { return }
        do {
            if fileManager.fileExists(atPath: modelDirectory.path) {
                try fileManager.removeItem(at: modelDirectory)
            }
            errorMessage = nil
            refreshStatus()
        } catch {
            errorMessage = "Could not delete the model: \(error.localizedDescription)"
        }
    }

    func downloadHindiModel() async {
        await downloadHindiModel(variant: HindiSpeechTranscriber.modelID)
    }

    func downloadHindiModel(variant: String) async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        status = "Downloading \(SpeechModelID(rawValue: variant)?.title ?? "Whisper")… Keep reel.ex open."
        defer {
            isBusy = false
            refreshStatus()
        }

        do {
            try await hindiTranscriber.downloadModel(variant: variant)
        } catch {
            errorMessage = "Hindi model download failed: \(error.localizedDescription)"
        }
    }

    func downloadSelectedModel() async {
        switch selectedModel {
        case .parakeetUltra: await downloadModel()
        default: await downloadHindiModel(variant: selectedModel.rawValue)
        }
    }

    func deleteSelectedModel() {
        switch selectedModel {
        case .parakeetUltra: deleteModel()
        default: deleteHindiModel(variant: selectedModel.rawValue)
        }
    }

    func importModel(from source: URL) async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        status = "Validating imported model…"
        defer {
            isBusy = false
            refreshStatus()
        }

        let hasAccess = source.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { source.stopAccessingSecurityScopedResource() }
        }

        do {
            switch selectedModel {
            case .parakeetUltra:
                try await importParakeet(from: source)
            default:
                try await hindiTranscriber.importModel(from: source, variant: selectedModel.rawValue)
            }
            errorMessage = nil
        } catch {
            errorMessage = "Model import failed: \(error.localizedDescription)"
        }
    }

    private func importParakeet(from source: URL) async throws {
        let stagingRoot = fileManager.temporaryDirectory.appendingPathComponent("ReelDL-Parakeet-\(UUID().uuidString)", isDirectory: true)
        let staging = stagingRoot.appendingPathComponent(modelDirectory.lastPathComponent, isDirectory: true)
        defer { try? fileManager.removeItem(at: stagingRoot) }
        try fileManager.createDirectory(at: stagingRoot, withIntermediateDirectories: true)
        try fileManager.copyItem(at: source, to: staging)
        guard AsrModels.modelsExist(at: stagingRoot, version: version, encoderPrecision: encoderPrecision) else {
            throw ModelStoreError.incompatibleModel
        }

        let backup = fileManager.temporaryDirectory.appendingPathComponent("ReelDL-Parakeet-backup-\(UUID().uuidString)", isDirectory: true)
        let hadModel = fileManager.fileExists(atPath: modelDirectory.path)
        if hadModel { try fileManager.moveItem(at: modelDirectory, to: backup) }
        do {
            try fileManager.createDirectory(at: modelDirectory.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fileManager.moveItem(at: staging, to: modelDirectory)
            guard AsrModels.modelsExist(at: modelDirectory, version: version, encoderPrecision: encoderPrecision) else {
                throw ModelStoreError.incompleteDownload
            }
            if hadModel { try? fileManager.removeItem(at: backup) }
        } catch {
            try? fileManager.removeItem(at: modelDirectory)
            if hadModel { try? fileManager.moveItem(at: backup, to: modelDirectory) }
            throw error
        }
        selectedModelID = SpeechModelID.parakeetUltra.rawValue
    }

    func deleteHindiModel() {
        deleteHindiModel(variant: HindiSpeechTranscriber.modelID)
    }

    func deleteHindiModel(variant: String) {
        guard !isBusy else { return }
        do {
            try hindiTranscriber.deleteModel(variant: variant)
            errorMessage = nil
            refreshStatus()
        } catch {
            errorMessage = "Could not delete the Hindi model: \(error.localizedDescription)"
        }
    }

    func transcribeSpeech(audioURL: URL, useHindiModel: Bool) async throws -> String {
        if useHindiModel {
            guard let model = enabledInstalledModels.first(where: \.supportsMultilingualSpeech) else {
                throw ModelStoreError.hindiModelMissing
            }
            return try await transcribeWhisper(audioURL: audioURL, variant: model.rawValue)
        }
        guard enabledInstalledModels.contains(.parakeetUltra) else { throw ModelStoreError.modelMissing }
        return try await transcribeUltra(audioURL: audioURL).text
    }

    func transcribeSpeech(audioURL: URL) async throws -> String {
        guard !isBusy else { throw ModelStoreError.busy }
        guard let model = preferredEnabledInstalledModel else {
            throw ModelStoreError.noEnabledModel
        }
        if model == .parakeetUltra { return try await transcribeUltra(audioURL: audioURL).text }
        return try await transcribeWhisper(audioURL: audioURL, variant: model.rawValue)
    }

    private var enabledInstalledModels: [SpeechModelID] {
        ModelSlot.allCases.compactMap { slot in
            guard isEnabled(slot), let model = model(in: slot), isInstalled(model) else { return nil }
            return model
        }
    }

    private var preferredEnabledInstalledModel: SpeechModelID? {
        if let activeSlot, isEnabled(activeSlot), let model = model(in: activeSlot), isInstalled(model) { return model }
        return enabledInstalledModels.first
    }

    private func transcribeWhisper(audioURL: URL, variant: String) async throws -> String {
        guard !isBusy else { throw ModelStoreError.busy }
        isBusy = true
        status = "Transcribing offline…"
        defer { isBusy = false; refreshStatus() }
        return try await hindiTranscriber.transcribe(audioURL: audioURL, variant: variant)
    }

    private func isInstalled(_ model: SpeechModelID) -> Bool {
        switch model {
        case .parakeetUltra: isReady
        default: hindiTranscriber.isModelInstalled(variant: model.rawValue)
        }
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard enabledInstalledModels.contains(.parakeetUltra) else { throw ModelStoreError.modelMissing }
        return try await transcribeUltra(audioURL: audioURL).text
    }

    private func transcribeUltra(audioURL: URL) async throws -> ASRResult {
        guard !isBusy else { throw ModelStoreError.busy }
        guard AsrModels.modelsExist(
            at: modelDirectory,
            version: version,
            encoderPrecision: encoderPrecision
        ) else {
            refreshStatus()
            throw ModelStoreError.modelMissing
        }

        isBusy = true
        status = "Loading offline model…"
        defer {
            isBusy = false
            refreshStatus()
        }

        do {
            let models = try await Self.loadLocalModels(from: modelDirectory)
            let manager = AsrManager(config: .default)
            try await manager.loadModels(models)
            var decoderState = try TdtDecoderState(decoderLayers: version.decoderLayers)
            status = "Transcribing offline…"
            return try await manager.transcribe(audioURL, decoderState: &decoderState)
        } catch {
            throw ModelStoreError.transcriptionFailed(error.localizedDescription)
        }
    }

    private nonisolated static func loadLocalModels(from directory: URL) async throws -> AsrModels {
        try await Task.detached(priority: .userInitiated) {
            try AsrModels.loadLocal(
                from: directory,
                version: .ultra,
                encoderPrecision: .int8
            )
        }.value
    }
}

enum ModelStoreError: LocalizedError {
    case modelMissing
    case hindiModelMissing
    case noEnabledModel
    case busy
    case incompleteDownload
    case incompatibleModel
    case transcriptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelMissing:
            return "Open reel.ex and install and enable Parakeet Ultra."
        case .hindiModelMissing:
            return "Open reel.ex and install and enable a multilingual Whisper model."
        case .noEnabledModel:
            return "Open reel.ex and turn on Use for transcription for an installed model."
        case .busy:
            return "reel.ex is already downloading or transcribing. Try again shortly."
        case .incompleteDownload:
            return "The download did not produce a complete model. Try downloading again."
        case .incompatibleModel:
            return "This folder does not contain a supported Parakeet Ultra or Whisper model."
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        }
    }
}
