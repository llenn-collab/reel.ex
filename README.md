# reel.ex

**reel.ex** is an iPhone companion for saving transcripts of Instagram Reels. It includes an Apple Shortcuts workflow that downloads Reel audio and transcribes it, plus an optional iOS app for offline, on-device transcription.

The project is based on [MediaDL](https://github.com/plbstl/MediaDL) by plbstl. The original MediaDL shortcut remains available for supported media downloads; reel.ex adds the Reel transcript workflow and offline speech companion.

## What you need

- An iPhone running iOS 17 or later for the standard transcript shortcut.
- The [Shortcuts](https://apps.apple.com/app/shortcuts/id915249334) and [Scriptable](https://apps.apple.com/app/scriptable/id1405459188) apps.
- An Instagram account with access to the Reel you want to transcribe.

Offline transcription is optional. Building and installing the companion app requires a Mac with Xcode and an iPhone running iOS 26 or later. See [ios/README.md](ios/README.md) for the Xcode setup.

## Install the Reel transcript shortcut

1. Install Scriptable from the App Store and open it once. Shortcuts is normally preinstalled on iPhone.
2. On your iPhone, open [`shortcuts/ReelDL Reel Transcript.shortcut`](shortcuts/ReelDL%20Reel%20Transcript.shortcut) and tap **Add Shortcut**. The shortcut's current filename is `ReelDL Reel Transcript.shortcut`.
3. In Instagram, open a Reel, tap **Share**, then choose **ReelDL Reel Transcript**. Or copy the Reel link and run the shortcut from Shortcuts.
4. Allow requested permissions on the first run. The transcript is saved as a text file under **Files → Browse → On My iPhone → Scriptable → ReelDL Transcripts**.

This workflow uses Apple's **Transcribe Audio** action and needs an internet connection to retrieve the Reel.

## Optional offline transcription

Follow the [iOS companion setup guide](ios/README.md) to build and install the **reel.ex** app from Xcode. It downloads speech models for offline transcription; downloading a Reel still requires internet access.

To connect the app to the shortcut, duplicate **ReelDL Reel Transcript** in Shortcuts, then edit the copy: replace Apple's **Transcribe Audio** action and the following Scriptable **Run Script Inline** action with the **Transcribe Reel (Offline)** action from reel.ex. Set **Audio** to the **Reel Audio** output from **Encode Media**. Keep the Scriptable actions above these steps and the **End Repeat** action. The companion app's README has the complete setup and model instructions.

## Regular media downloads

For the original MediaDL download workflow, install the [MediaDL shortcut](https://www.icloud.com/shortcuts/b0792743b4694f28a246f8a31336c960). That shortcut supports the platforms documented by its upstream project; reel.ex's additional transcript workflow is for Instagram Reels.

## Privacy and responsible use

reel.ex does not ask for your Instagram password. If Instagram requires sign-in, authenticate through Instagram's own interface. Use the tool only for content you have the right to access, and respect creators' rights when downloading, using, or sharing their work. You are responsible for your use of downloaded content.

## Attribution and license

The original MediaDL project by plbstl is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). The original work requires attribution, noncommercial use, and sharing adaptations under the same license. This project is based on MediaDL and retains those terms for that work; see [LICENSE](LICENSE).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidance.
