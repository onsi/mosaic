# Mosaic

Mosaic is based on Rectangle which is based on Spectacle.

Mosaic uses [CocoaPods](https://cocoapods.org/) to install MASShortcut. 

1. Make sure CocoaPods is installed and up to date on your machine (`sudo gem install cocoapods`).
1. Execute `pod install` the root directory of the project. 
1. Open the generated xcworkspace file (`open Mosaic.xcworkspace`).

#### Signing
- When running in Xcode (debug), MOsaic is signed to run locally with no developer ID configured.
- You can run the app out of the box this way, but you might have to authorize the app in System Prefs every time you run it. 
- If you don't want to authorize in System Prefs every time you run it and you have a developer ID set up, you'll want to use that to sign it and additionally add the Hardened Runtime capability to the Mosaic and MosaicLauncher targets.