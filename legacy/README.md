# DisableCtrlClick (macOS Monterey Legacy Build)

This directory contains a version of DisableCtrlClick specifically built to be compatible with **macOS 12 (Monterey)** and potentially older versions.

The main version of the app uses modern APIs (`SMAppService`) for "Open at Login" that are only available on macOS 13 (Ventura) and newer. This version uses the older, deprecated `SMLoginItemSetEnabled` API to provide the same functionality on older systems.

## Building

1.  Make sure you are in the `old` directory.
2.  Run the build script:
    ```bash
    ./build.sh
    ```
3.  The `DisableCtrlClick.app` bundle will be created in the `old` directory. You can then move it to your `/Applications` folder.

Functionality is otherwise identical to the main application.