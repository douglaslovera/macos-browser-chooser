# BrowserChooser

BrowserChooser is a small macOS app that lets you choose which browser opens a link each time you click an `http` or `https` URL.

Instead of sending every web link to one default browser, macOS sends the URL to BrowserChooser. BrowserChooser then shows a floating picker with the installed browsers that can open web links. Pick one, and the original URL opens in that browser.

## ✨ What It Does

- Registers as an alternate handler for `http` and `https` URLs.
- Discovers installed browser apps through macOS Launch Services.
- Shows a browser picker whenever a web URL is opened.
- Lets you open the URL with a click, the Return key, or number shortcuts.
- Lets you hide browsers you do not want to see.
- Lets you reorder browsers so your preferred choices appear first.
- Stores browser visibility and ordering in user defaults.

## 🧰 Requirements

- macOS 14.0 or newer
- Xcode 16 or newer recommended
- Swift 5

## 🛠️ Build and Run

Open the project in Xcode:

```sh
open BrowserChooser.xcodeproj
```

Then select the `BrowserChooser` scheme and run the app.

You can also build it from the command line:

```sh
xcodebuild -project BrowserChooser.xcodeproj -scheme BrowserChooser -configuration Release build
```

## 🌐 Set BrowserChooser as Your Default Browser

After building and running the app once, set it as the default browser in macOS:

1. Open System Settings.
2. Go to Desktop & Dock.
3. Find Default web browser.
4. Select BrowserChooser.

Once this is set, opening a web link from another app should show the BrowserChooser window.

## 🚀 How to Use

When a link is opened, BrowserChooser shows:

- The host name of the URL.
- The full URL below it.
- A list of visible browser apps.

Controls:

- Click a browser to open the URL there.
- Press `1` through `9` to choose one of the first nine browsers.
- Use Up and Down arrows to change the selected browser.
- Press Return to open the selected browser.
- Press Escape or Cancel to dismiss the current URL request.
- Click Manage to show, hide, reorder, or refresh browsers.

## ⚙️ Manage Browsers

The Manage view lets you customize the picker:

- Toggle a browser on or off to control whether it appears in the chooser.
- Use the up and down buttons to change browser order.
- Click Refresh Browsers after installing or removing a browser.
- Click Done to return to the chooser.

## 📁 Project Structure

- `BrowserChooserApp.swift` starts the SwiftUI app.
- `AppDelegate.swift` registers the app as a URL event handler and queues incoming URLs.
- `AppModel.swift` manages browser discovery, request state, selection, ordering, and preferences.
- `BrowserDiscovery.swift` finds installed apps that can open `http` and `https` URLs.
- `ChooserWindow.swift` owns the floating macOS window.
- `ChooserView.swift` renders the picker and browser management UI.
- `Diagnostics.swift` records local lifecycle and link-handling diagnostics.
- `PreferencesStore.swift` persists hidden browsers and browser order.
- `Info.plist` declares URL and document handling metadata.

## 🧯 Troubleshooting

If BrowserChooser does not appear in the default browser list, make sure you have built and launched the app at least once.

If a browser is missing from the picker, open Manage and click Refresh Browsers.

If a browser is hidden, open Manage and turn its visibility toggle back on.

If links still open directly in another browser, confirm that BrowserChooser is selected as the macOS default web browser.

If BrowserChooser is running but no picker appears, inspect its local log:

```sh
open ~/Library/Logs/BrowserChooser/browserchooser.log
```

The log records app launches, incoming link hosts, window presentation, browser-open results, and unclean previous sessions. URL paths and query parameters are intentionally not recorded. Logs rotate after roughly 500 KB, with one previous log retained.
