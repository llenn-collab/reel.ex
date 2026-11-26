import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ModelSetupView: View {
    @State private var store = ModelStore.shared
    @State private var transcriptionJob = ReelTranscriptionJob.shared
    @State private var selections: [ModelSlot: SpeechModelID] = [:]
    @State private var importingSlot: ModelSlot?
    @State private var isImporting = false
    @State private var slotToDelete: ModelSlot?
    @State private var installNoticeID: UUID?

    private let canvas = Color(red: 1, green: 1, blue: 0.969)
    private let cardSurface = Color(red: 0.933, green: 0.933, blue: 0.898)
    private let hairline = Color(red: 0.780, green: 0.780, blue: 0.737)
    private let controlBorder = Color(red: 0.506, green: 0.506, blue: 0.475)
    private let accent = Color(red: 0, green: 0.388, blue: 0.698)
    private let muted = Color(red: 0.318, green: 0.318, blue: 0.294)
    private let ink = Color(red: 0.114, green: 0.114, blue: 0.106)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    introduction

                    transcriptionStatusCard

                    VStack(spacing: 8) {
                        ForEach(ModelSlot.allCases) { slot in
                            slotCard(slot)
                        }
                    }

                    if let error = store.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.custom("ClashGrotesk-Regular", size: 15, relativeTo: .subheadline))
                            .foregroundStyle(Color(red: 0.608, green: 0.204, blue: 0.173))
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(cardSurface, in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityIdentifier("modelError")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .background(canvas.ignoresSafeArea())
            .overlay(alignment: .top) {
                if installNoticeID != nil {
                    Text("Keep ReelDL open while the model installs.")
                        .font(.custom("ClashGrotesk-Medium", size: 15, relativeTo: .subheadline))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(cardSurface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(hairline, lineWidth: 1))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .allowsHitTesting(false)
                        .zIndex(1)
                }
            }
            .task(id: installNoticeID) {
                guard installNoticeID != nil else { return }
                do {
                    try await Task.sleep(for: .seconds(4))
                    withAnimation { installNoticeID = nil }
                } catch {}
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ReelDL")
                        .font(.custom("ClashGrotesk-Medium", size: 17, relativeTo: .body))
                        .tracking(-0.2)
                        .foregroundStyle(ink)
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                guard let slot = importingSlot else { return }
                importingSlot = nil
                isImporting = false
                switch result {
                case .success(let urls):
                    guard let url = urls.first, let model = selections[slot] else { return }
                    showInstallNotice()
                    Task { await store.importModel(model, from: url, into: slot) }
                case .failure(let error):
                    store.errorMessage = "Could not open the selected folder: \(error.localizedDescription)"
                }
            }
            .confirmationDialog(
                "Delete this model?",
                isPresented: Binding(
                    get: { slotToDelete != nil },
                    set: { if !$0 { slotToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete model", role: .destructive) {
                    guard let slotToDelete else { return }
                    store.deleteModel(in: slotToDelete)
                    self.slotToDelete = nil
                }
                Button("Cancel", role: .cancel) { slotToDelete = nil }
            } message: {
                Text("This removes the downloaded model files from this iPhone. You can download or import a model again later.")
            }
        }
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private var transcriptionStatusCard: some View {
        if transcriptionJob.status != nil || transcriptionJob.errorMessage != nil || transcriptionJob.savedFile != nil || transcriptionJob.unsavedTranscript != nil {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: transcriptionJob.errorMessage == nil ? "waveform" : "exclamationmark.triangle.fill")
                        .foregroundStyle(transcriptionJob.errorMessage == nil ? accent : .red)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transcriptionJob.errorMessage == nil ? "Reel transcription" : "Transcription issue")
                            .font(.custom("ClashGrotesk-Semibold", size: 17, relativeTo: .headline))
                            .foregroundStyle(ink)
                        if let error = transcriptionJob.errorMessage {
                            Text(error).font(.custom("ClashGrotesk-Regular", size: 15, relativeTo: .subheadline)).foregroundStyle(muted)
                        } else if let status = transcriptionJob.status {
                            Text(status).font(.custom("ClashGrotesk-Regular", size: 15, relativeTo: .subheadline)).foregroundStyle(muted)
                        }
                    }
                    Spacer(minLength: 0)
                }

                if transcriptionJob.isRunning {
                    if let progress = transcriptionJob.progress {
                        ProgressView(value: progress).tint(accent).progressViewStyle(.linear)
                    } else {
                        ProgressView().tint(accent).progressViewStyle(.linear)
                    }
                }

                if let savedFile = transcriptionJob.savedFile {
                    ShareLink(item: savedFile) {
                        Label("Share transcript", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("shareSavedTranscript")
                }
                if let transcript = transcriptionJob.unsavedTranscript {
                    ShareLink(item: transcript, subject: Text("ReelDL transcript")) {
                        Label("Share transcript text", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("shareUnsavedTranscript")
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardSurface, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12).stroke(hairline, lineWidth: 1)
            }
            .accessibilityIdentifier("transcriptionStatusCard")
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Speech Models")
                .font(.custom("ClashGrotesk-Semibold", size: 34, relativeTo: .largeTitle))
                .tracking(-0.8)
                .foregroundStyle(ink)
            Text("Download reels with Shortcuts and transcribe their audio offline on your iPhone.")
                .font(.custom("ClashGrotesk-Regular", size: 17, relativeTo: .body))
                .foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 2)
    }

    private func slotCard(_ slot: ModelSlot) -> some View {
        let installedModel = store.model(in: slot)
        let defaultModel: SpeechModelID = slot == .first ? .parakeetUltra : .whisperLargeV3Turbo
        let model = installedModel ?? selections[slot] ?? defaultModel
        let isActive = store.activeSlot == slot

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(slot == .first ? "MODEL 01" : "MODEL 02")
                    .font(.custom("ClashGrotesk-Medium", size: 12, relativeTo: .caption))
                    .tracking(0.8)
                    .foregroundStyle(muted)
                Spacer(minLength: 0)
            }
            .padding(.bottom, 4)

            HStack(spacing: 8) {
                if installedModel == nil {
                    Menu {
                        ForEach(SpeechModelID.allCases) { option in
                            Button {
                                selections[slot] = option
                            } label: {
                                if option == model {
                                    Label(option.title, systemImage: "checkmark")
                                } else {
                                    Text(option.title)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            modelTitle(model.title, isActive: false)
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(muted)
                        }
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Choose model for \(slot == .first ? "Model 01" : "Model 02")")
                    .accessibilityValue(model.title)
                    .accessibilityIdentifier(slot == .first ? "modelPickerFirst" : "modelPickerSecond")
                    .disabled(store.isBusy)
                } else {
                    modelTitle(model.title, isActive: isActive)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }

                if installedModel != nil {
                    Button(role: .destructive) {
                        slotToDelete = slot
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.custom("ClashGrotesk-Medium", size: 14, relativeTo: .footnote))
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(Color(red: 0.608, green: 0.204, blue: 0.173))
                            .padding(.horizontal, 8)
                            .frame(minWidth: 44, minHeight: 44)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(controlBorder, lineWidth: 1))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isBusy)
                    .accessibilityIdentifier(slot == .first ? "deleteFirstModel" : "deleteSecondModel")
                }
            }

            if store.isBusy {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView()
                        .tint(accent)
                    Text(store.status)
                        .font(.custom("ClashGrotesk-Regular", size: 13, relativeTo: .footnote))
                        .foregroundStyle(muted)
                }
                .accessibilityElement(children: .combine)
                .padding(.top, 12)
            }

            if installedModel == nil || !isActive {
                VStack(spacing: 8) {
                    if installedModel == nil {
                        Button {
                            showInstallNotice()
                            Task { await store.download(model, into: slot) }
                        } label: {
                            Text("Download")
                                .font(.custom("ClashGrotesk-Medium", size: 15, relativeTo: .body))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(accent, in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(canvas)
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isBusy)
                        .accessibilityIdentifier(slot == .first ? "downloadFirstModel" : "downloadSecondModel")

                        Button {
                            selections[slot] = model
                            importingSlot = slot
                            isImporting = true
                        } label: {
                            Label("Import from Files", systemImage: "folder")
                                .font(.custom("ClashGrotesk-Medium", size: 15, relativeTo: .body))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color.clear, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(controlBorder, lineWidth: 1))
                                .foregroundStyle(accent)
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isBusy)
                        .accessibilityIdentifier(slot == .first ? "importFirstModel" : "importSecondModel")
                    }

                    if installedModel != nil && !isActive {
                        Button {
                            store.setEnabled(true, for: slot)
                            store.activate(slot)
                        } label: {
                            Text("Make active")
                                .font(.custom("ClashGrotesk-Medium", size: 15, relativeTo: .body))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(accent, in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(canvas)
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isBusy)
                        .accessibilityIdentifier(slot == .first ? "activateFirstModel" : "activateSecondModel")
                    }
                }
                .padding(.top, 14)
                .opacity(store.isBusy ? 0.5 : 1)
                .disabled(store.isBusy)
                .accessibilityIdentifier("modelActions\(slot == .first ? "First" : "Second")")
            }
        }
        .padding(16)
        .background(cardSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? accent : hairline, lineWidth: isActive ? 2 : 1)
        }
        .accessibilityElement(children: .contain)
        .disabled(transcriptionJob.isRunning)
    }

    private func modelTitle(_ title: String, isActive: Bool) -> some View {
        Text(title)
            .font(.custom("ClashGrotesk-Semibold", size: 17, relativeTo: .headline))
            .tracking(-0.1)
            .foregroundStyle(ink)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(isActive ? "Active transcription model" : "")
    }

    private func showInstallNotice() {
        withAnimation { installNoticeID = UUID() }
    }
}
