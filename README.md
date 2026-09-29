# DisableCtrlClick for macOS

<p align="center">
  <img src="DisableCtrlClick.png" alt="App Icon" width="128">
</p>

<p align="center">
  <a href="https://novasynapse.com/products/betterpad/">
    <img src="https://img.shields.io/badge/Download_for_macOS-BetterPad-4F46E5?style=for-the-badge&logo=apple&logoColor=white" alt="Download BetterPad for macOS">
  </a>
</p>

<p align="center">
  <a href="https://github.com/achendev/DisableCtrlClick">
    <img src="https://img.shields.io/github/stars/achendev/DisableCtrlClick?style=social" alt="Star on GitHub">
  </a>
</p>

**Looking for a ready-to-use Apple notarized app?** [Download BetterPad](https://novasynapse.com/products/betterpad/) — it includes Disable Control-Click as a **free feature**, alongside other mouse and trackpad controls. Signed and notarized by Apple, for Intel and Apple silicon Macs running macOS 12 or later. Accessibility permission is still required.

Prefer the original lightweight app? Its source code remains available below so you can build it yourself.

---

Are you tired of accidentally opening the context menu when you're just trying to use the Control key? Me too.

Many applications, especially in programming, design, and gaming, use `Control` as a modifier for primary actions. If you're used to a two-finger tap or a dedicated mouse button for right-clicking, the default `Ctrl-Click` behavior can be an annoying interruption. This app fixes that.

## What It Does

This is a tiny, native macOS utility that lives in your menubar and does one thing: it forces **`Control + Left-Click`** to behave like a normal **`Left-Click`**, disabling the default right-click/context menu behavior.

That's it. No more random right-clicks.

## Features

* ✅ **Lightweight & Native:** A simple Swift app with minimal resource usage.
* ✅ **Configurable via Menubar:** Click the icon to temporarily disable the functionality, toggle "Open at Login", or quit the app.
* ✅ **Menubar App:** Lives discreetly in your menubar. Cmd+Drag to hide it, and launch the app again to bring it back.
* ✅ **Starts at Login (Optional):** Automatically starts when you log in. This can be toggled from the app's menu.
* ✅ **Zero Config:** Just run it and grant permissions. That's it.
* ✅ **Modern & Secure:** Built with modern APIs and requires no special privileges beyond what's necessary to function.
* ✅ **Transparent & Tiny:** It's so small you can literally read the full code of the app or feed it to any AI to understand exactly what it does and what you're running on your Mac.

## Installation & Usage

For a ready-to-use download, use [**BetterPad**](https://novasynapse.com/products/betterpad/).

To use the original **DisableCtrlClick** app:

1. **Build:** Follow [Building from Source](#building-from-source) below.
2. **Install:** Drag `DisableCtrlClick.app` to your `/Applications` folder.
3. **Launch:** Open the app from your Applications folder.
4. **Grant Permissions:** On the first launch, the app will prompt you to grant permissions and then quit. Enable **Accessibility** for `DisableCtrlClick` in:
   * `System Settings > Privacy & Security > Accessibility`

   > **Why?** This lets the app modify mouse events to prevent Control-click from opening a context menu.

5. **Done!** Relaunch the app one more time. It is now running and will launch automatically every time you log in by default. You can change this behavior from the menubar icon.

The app will show a small icon in your menubar.

* Click the icon to open a menu where you can temporarily disable the functionality, control whether it opens at login, or quit the app.
* You can hide the icon by holding `⌘` (Command) and dragging it out of the menubar. If you want it back, just launch the app again.

## Building from Source

If you prefer to build the app yourself:

1. Clone this repository:

   ```bash
   git clone https://github.com/achendev/DisableCtrlClick.git
   cd DisableCtrlClick
   ```

2. Make sure you have the command-line tools for Xcode installed.
3. Run the build script from your terminal:

   ```bash
   ./build.sh
   ```

4. The `DisableCtrlClick.app` bundle will be created in the project directory. You can then move it to your `/Applications` folder.
5. Launch it. It will be added to "Open at Login" automatically by default.
6. Grant the requested Accessibility permission in System Settings and relaunch the app.

## Troubleshooting

The original DisableCtrlClick app is provided "as is" and without any warranty, express or implied.

Requires macOS 13.0 (Ventura) or later.

**How to Quit**

Click the menubar icon and select "Quit". If you have hidden the icon, you can either launch the app again to show it, or use the command `killall DisableCtrlClick` in your Terminal.

**How to Reset Permissions**

If the app is not working, try resetting its permissions:

```bash
tccutil reset Accessibility com.usr.DisableCtrlClick
```

## License

This project is released under the MIT License.
