# reel.ex for iPhone

reel.ex provides on-device Shortcuts actions for iPhone speech transcription:
- **Transcribe Audio (Offline)** accepts an audio file and transcribes speech using Parakeet Ultra.
- **Transcribe Reel (Offline)** accepts the Reel **Audio**, a **Speech Model** selection, and an optional **File Name** (which can be set to the post ID variable or left blank). It queues in the foreground, transcribes audio entirely on-device, and writes the transcript directly to **Files > On My iPhone > reel.ex > ReelDL Transcripts**.

> **Important:** Keep reel.ex open in the foreground until it indicates **Saved**. Once saved, you can share the transcript immediately or access it in the Files app.

## Setup

1. Open `ReelDLSpeech.xcodeproj` in Xcode with the iOS 27 SDK or later. Select a device running iOS 26 or later.
2. Create `ios/Signing.local.xcconfig` with this line. Replace `YOUR_TEAM_ID` with your Apple development team's ID.

   ```xcconfig
   DEVELOPMENT_TEAM = YOUR_TEAM_ID
   ```
3. Select the **ReelDLSpeech** scheme and your iPhone in Xcode. Press **⌘R** to install and open the app. In either slot, select a model and tap its download button or **Import from Files**. The download needs an internet connection. Import the extracted Core ML model folder for the selected entry. For a fully offline Whisper import, place `config.json`, `tokenizer_config.json`, and `tokenizer.json` from the matching OpenAI model in the Core ML folder. The app downloads any missing tokenizer files during setup.
4. Follow the beginner tap-by-tap [offline shortcut setup](../README.md#optional-offline-on-device-speech-transcription) in the main README.

Parakeet Ultra uses FluidAudio 0.18.3 and its int8 model. WhisperKit 0.9.0 runs the models in the [Argmax Core ML catalog](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main). Large models require more memory and storage. The blue border marks the active model. When two models are installed, **Make active** selects the model for **App Default**. To change an installed slot’s model, delete it first. Each slot holds a different model.

See the [physical-device release checks](../CONTRIBUTING.md#build-and-verify-the-ios-companion) for the validation required before distribution.

### Preview typography

For Clash Grotesk in local iOS builds, download [Clash Grotesk from Fontshare](https://www.fontshare.com/fonts/clash-grotesk). Copy the Regular, Medium, and Semibold OTF files into `ios/ReelDLSpeech/Fonts/`. Xcode bundles them for offline use. A checkout without the font files uses system typography.
