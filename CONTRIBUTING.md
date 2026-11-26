# reel.ex Contribution Guide

Thank you for taking the time to read this Guide.

## Ask questions and provide feedback

Questions can be asked about, suggestions and complaints can be made for new and existing features; error codes and messages; data tracking; typos; the website's contents, look and feel; this guide; ways of doing things; basically anything related to reel.ex. Just [open an issue](https://github.com/llenn-collab/ReelDL/issues/new) and write down everything.

> **NOTE:** You need a GitHub account to open an issue or make a change.

## Submit a pull request

When you are submitting a pull request, _the pull request has to be linked to an open issue_. Although you can open an issue after submission, it is better you open one before submitting the pull request.

Here is a helper video on the process of submitting pull requests: <https://youtu.be/8lGpZkjnkt4>

## Attach Shortcut

You can export a Siri Shortcut as a file and attach it when opening an issue or submitting a pull request.

- You need an internet connection to export a shortcut (Apple needs to sign it on their servers).
- On your mobile device, open the Shortcuts app.
- Long press the shortcut you want to export.
- Tap `Share`, tap `Options >`, and send as `File` for `Anyone`.
- Tap `Done`.
- Now you can `Save to Files`, AirDrop or share in any other way you prefer.

## Build the Reel transcript companion

Use the unsigned MediaDL v1.3 export from the public [iCloud record](https://www.icloud.com/shortcuts/api/records/b0792743b4694f28a246f8a31336c960). Download the URL in `fields.shortcut.value.downloadURL` as `MediaDL-v1.3.shortcut`, then build and sign the companion on macOS.

```sh
python3 scripts/build-reel-transcript.py MediaDL-v1.3.shortcut /tmp/reeldl-reel-transcript.shortcut
shortcuts sign --mode anyone --input /tmp/reeldl-reel-transcript.shortcut --output "shortcuts/ReelDL Reel Transcript.shortcut"
```

## Build and verify the iOS companion

Open `ios/ReelDLSpeech.xcodeproj` in full Xcode with an iOS 27 or newer SDK and select the **ReelDLSpeech** scheme. Install a development build on a physical iPhone with a signing team and a bundle identifier available to that team. Then follow the [offline shortcut setup](ios/README.md).

Before release, test the following on physical iPhones running iOS 26 and iOS 27:

- On a fresh install, try the companion action before downloading the model. Confirm the error explains how to install it. Interrupt a download, retry, and confirm that setup can finish. Import each supported folder layout from Files, reject an incompatible folder, and verify that a failed import leaves the previous model usable.
- Make a separate shortcut that passes a local M4A to **Transcribe Reel (Offline)**. In Airplane Mode, run it and check the progress bar and saved file in reel.ex. Repeat with longer audio, speech-free audio, and an invalid file.
- Run both Reel shortcuts from Instagram's share sheet. Check **On My iPhone → Scriptable → ReelDL Transcripts** for Apple's transcript and **On My iPhone → reel.ex → ReelDL Transcripts** for the offline transcript. Repeat after a cold app launch and after deleting and reinstalling the model.
- Install Parakeet Ultra and a multilingual Whisper model. Disable each slot in turn and confirm **App Default** uses the remaining enabled model. With Whisper enabled, test Hindi and Hindi-English speech in Airplane Mode using local audio.
- Use a held-out set of human-transcribed Reels that includes accents, fast speech, background music, overlap, and relevant names. Score both engines on the same M4A and with the same text normalization. Record corpus word error rate (`(substitutions + deletions + insertions) / reference words`), dropped phrases, and name errors. Keep the optional rollout gated on a reduction of at least 2 absolute word-error-rate points and reliable share-sheet completion on both OS versions.
- On the oldest supported phone, use Instruments to record peak physical footprint and elapsed time for first-use model preparation, a cold shortcut run, and a warm run. Record model files and compiled cache storage separately.

The [published iPhone comparison](https://framememo.aimakemore.com/engineering/on-device-transcription-benchmark/) used 200 English distant-microphone meeting clips on an iPhone 15 with iOS 27.0.1. Parakeet Ultra scored 15.01% word error rate and occupied about 603 MiB on disk. Whisper Large-v3 Turbo (WhisperKit Core ML) scored 27.39% and occupied about 620 MiB. The [unquantized whisper.cpp Turbo file](https://github.com/ggml-org/whisper.cpp/blob/master/models/README.md) is 1.5 GiB. These results cover those specific exports and that corpus.

Model attribution: [Moondream Parakeet Ultra](https://huggingface.co/moondream/parakeet-ultra), derived from [NVIDIA Parakeet TDT 0.6B v3](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3), converted to Core ML by [Fluid Inference](https://huggingface.co/FluidInference/parakeet-ultra-coreml). Model weights are [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
