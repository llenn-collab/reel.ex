<div align="center">

<img src="icon/Monochrome%20Glossy%20Waveform%20Icon.png" alt="ReelDL" width="128" />

# ReelDL

ReelDL is based on the original [MediaDL](https://github.com/plbstl/MediaDL) by plbstl. It adds a Reel transcript shortcut and an iPhone speech companion.

[![Install ReelDL][install-badge]][install-link]
[![Release][gh-release-badge]][gh-release-link]
[![GitHub Issues][gh-issues-badge]][gh-issues-link]
[![GitHub Pull Requests][gh-pulls-badge]][gh-pulls-link]

</div>

<div align="center">

There are **_no ads, unnecessary prompts, tracking or third-party involved_**; everything is **_executed on-device_** and you never have to leave the currently opened application.

</div>

## Supported platforms ✅

- [ ] Facebook
- [x] Instagram (requires sign-in)
- [ ] Pinterest
- [ ] Reddit
- [ ] Snapchat
- [ ] Threads
- [ ] TikTok
- [ ] Tumblr
- [ ] Twitch
- [ ] Vimeo
- [ ] X (formerly Twitter)
- [ ] YouTube

## How to use 🎛️

1. **Share a post:** Click on the relevant Share post icon in the application you're in, to bring up the ShareSheet.

2. **Share to MediaDL:** For a regular media download, choose the original MediaDL shortcut in the share sheet. The first attempt requires you to grant MediaDL permissions to make requests, read through it and click Always Allow.

3. **Continue:** MediaDL starts working and you can continue using the application. Prompts to select media might popup if you're downloading multiple items at once.

4. **Media saved:** A visual loader shows the progress and when its done, the file will have been downloaded and placed in the relevant location in your device.

The original MediaDL shortcut works in browsers too.

## Save an Instagram Reel transcript

### Set up the original shortcut

1. On an iPhone running iOS 17 or later, install [Scriptable][scriptable-app-link] and open it once. Reinstall [Shortcuts][shortcuts-app-link] if you deleted it.
2. Open [ReelDL Reel Transcript](shortcuts/ReelDL%20Reel%20Transcript.shortcut) on your iPhone and tap **Add Shortcut**.
3. Open a Reel in Instagram. Tap its share button, open the iPhone share sheet, and choose **ReelDL Reel Transcript**. You can also copy the Reel link and tap the shortcut in the Shortcuts app.
4. Tap **Always Allow** if Shortcuts asks for access on the first run. Open **Files → Browse → On My iPhone → Scriptable → ReelDL Transcripts** for the saved `.txt` file.

This version uses Apple's **Transcribe Audio** action. For regular photo and video downloads, use the [original MediaDL shortcut][mediadl-shortcut-link].

### Optional offline on-device speech transcription

For offline speech recognition, [install ReelDL Speech on your iPhone from Xcode](ios/README.md). The app requires iOS 26 or later. You still need internet access to download the Reel.

1. Open **ReelDL Speech**. Pick a model in either slot and tap **Download**. Choose **Parakeet Ultra** for English or a multilingual Whisper model for Hindi or Hinglish. The blue border marks the active model.
2. Open **Shortcuts**, touch and hold **ReelDL Reel Transcript**, and tap **Duplicate**. Name the copy **ReelDL Reel Transcript (Offline)**. Tap the copy's **•••** button to edit it.
3. Scroll to the bottom. Find **Encode Media**, followed by Apple's **Transcribe Audio**, then Scriptable's **Run Script Inline**, and finally **End Repeat**.
4. Tap the **×** on Apple's **Transcribe Audio** and on the **Run Script Inline** immediately below it. Leave **Encode Media**, **End Repeat**, and the Scriptable actions higher up in place.
5. Search for **Transcribe Reel (Offline)** in the action search bar. Add the result from **ReelDL Speech** and drag it between **Encode Media** and **End Repeat**.
6. Tap **Audio** in the new action. Choose **Select Variable** if shown, then choose **Reel Audio**, the output under **Encode Media**. Leave **Speech Model** on **App Default** and **File Name** blank. ReelDL Speech generates a filename such as `Reel-A1B2C3D4.txt`.

The bottom of the shortcut should look like this.

```text
Repeat with Each
    Download URL
    Encode Media
    Transcribe Reel (Offline)  →  Reel Audio · App Default
End Repeat
```

Tap **Done**. That's the entire edit. The Scriptable code stays as supplied.

#### Run the offline shortcut

1. Share a Reel to **ReelDL Reel Transcript (Offline)**, or copy the Reel link and tap the offline shortcut in Shortcuts.
2. Keep **ReelDL Speech** on screen while the progress bar moves through preparation, transcription, and saving. Wait for **Saved** in the app.
3. Tap **Share transcript** or open **Files → Browse → On My iPhone → ReelDL Speech → ReelDL Transcripts**. If the app shows a save error, tap **Share transcript text** to recover the text.

When two models are installed, tap **Make active** on the model you want **App Default** to use. To change an installed slot’s model, tap **Delete**, confirm, and select a new model. You can also choose **Parakeet Ultra** or **Hindi / Hinglish** in the Shortcut action to require that kind of model.

## Installation 📲

1. The Shortcuts app comes preinstalled on Apple devices. In the case that yours is deleted, install [Shortcuts][shortcuts-app-link] from the App Store.
2. Scriptable is used for functionality not yet available in the Shortcuts app. Just like Shortcuts app, you can use it for a lot of other things. Install [Scriptable][scriptable-app-link] from the App Store.
3. Add the [original MediaDL][mediadl-shortcut-link] shortcut for regular downloads, or add [ReelDL Reel Transcript](shortcuts/ReelDL%20Reel%20Transcript.shortcut) for Reel transcripts.
4. Attempt to download media from a supported platform of your choice.

   > If the platform requires you to sign in, **Scriptable** will open a WebView for you to sign in. Sign in and close Scriptable. Future downloads from the selected platform should complete from now on.

5. Select `Always Allow` when prompted for network access to avoid prompts every time you use ReelDL.

## Important Notes 🗒️

- ReelDL will **_never ask_** for your username/email or password. You will be presented with a WebView to login into the relevant official platform using their official methods.

- When using mobile data to access the internet, mobile data has to be turned on for both **Shortcuts** & **Scriptable** in your device settings for downloads to work.

- You have to be signed in to the specific platform to access media private to you.

- You may not have access to sensitive/NSFW content without being signed in to the specific platform.

## Ethics and Disclaimer ⚠️

ReelDL is a tool designed to simplify content downloads from the internet, with **_zero liability_**. You are responsible for what you download, how you use, and distribute that content. Please be mindful of using others’ content and always credit the original creators. Fair use and proper credits benefit everyone.

**ReelDL is NOT a piracy tool** and cannot be used as such. It only downloads free, publicly accessible content, which can also be downloaded through any browser’s developer tools. This tool offers a **convenient**, **clutter-free**, **one-click solution** for repetitive actions.

> This section is gotten from <https://github.com/imputnet/cobalt#ethics-and-disclaimer> and refined a bit.

## Contribute 💡

Check the [Contribution Guide](./CONTRIBUTING.md) for how to contribute to this project.

## License 🤝

<p xmlns:cc="http://creativecommons.org/ns#" xmlns:dct="http://purl.org/dc/terms/"><a property="dct:title" rel="cc:attributionURL" href="https://mediadl.plbstl.io">MediaDL</a> is licensed under <a href="https://creativecommons.org/licenses/by-nc-sa/4.0/?ref=chooser-v1" target="_blank" rel="license noopener noreferrer" style="display:inline-block;">CC BY-NC-SA 4.0<img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/cc.svg?ref=chooser-v1" alt=""><img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/by.svg?ref=chooser-v1" alt=""><img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/nc.svg?ref=chooser-v1" alt=""><img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/sa.svg?ref=chooser-v1" alt=""></a></p>

**You are free to:**

- **Share** — copy and redistribute the material in any medium or format.

- **Adapt** — remix, transform, and build upon the material.

**Under the following terms:**

- **Attribution** — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

- **NonCommercial** — You may not use the material for commercial purposes.

- **ShareAlike** — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

- **No additional restrictions** — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.


[gh-issues-badge]: https://img.shields.io/github/issues/llenn-collab/ReelDL
[gh-issues-link]: https://github.com/llenn-collab/ReelDL/issues
[gh-pulls-badge]: https://img.shields.io/github/issues-pr/llenn-collab/ReelDL
[gh-pulls-link]: https://github.com/llenn-collab/ReelDL/pulls
[gh-release-badge]: https://img.shields.io/github/v/release/llenn-collab/ReelDL?sort=semver
[gh-release-link]: https://github.com/llenn-collab/ReelDL/releases
[install-badge]: https://img.shields.io/badge/install_ReelDL-7c3aed?style=flat-square
[install-link]: shortcuts/ReelDL%20Reel%20Transcript.shortcut


[mediadl-shortcut-link]: https://www.icloud.com/shortcuts/b0792743b4694f28a246f8a31336c960
[scriptable-app-link]: https://apps.apple.com/app/scriptable/id1405459188
[shortcuts-app-link]: https://apps.apple.com/app/shortcuts/id915249334
