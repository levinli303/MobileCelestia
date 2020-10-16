//
// AppDelegate.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

import CelestiaCore

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

let newURLOpenedNotificationName = Notification.Name("newURLOpenedNotificationName")
let newURLOpenedNotificationURLKey = "newURLOpenedNotificationURLKey"
#if targetEnvironment(macCatalyst)
let showHelpNotificationName = Notification.Name("showHelpNotificationName")
let requestOpenFileNotificationName = Notification.Name("requestOpenFileNotificationName")
#endif

let officialWebsiteURL = URL(string: "https://celestia.space")!
let supportForumURL = URL(string: "https://celestia.space/forum")!
let apiPrefix = "https://celestia.mobi/api"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        swizzleShouldInheritScreenScaleAsContentScaleFactor()

        #if targetEnvironment(macCatalyst)
        MacBridge.initialize()

        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])

        // Force dark aqua appearance
        MacBridge.forceDarkAppearance()

        // Avoid reading saved state
        if let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
            let savedStatePath = "\(libraryPath)/Saved Application State"
            if FileManager.default.fileExists(atPath: savedStatePath) {
                try? FileManager.default.removeItem(atPath: savedStatePath)
            }
        }
        #endif

        #if !DEBUG
        #if targetEnvironment(macCatalyst)
        let appCenterID = "63a9e404-a07b-40eb-a5e7-320f65934b05"
        #else
        let appCenterID = "4c46cd7d-ea97-452b-920c-4328ac062db3"
        #endif
        MSAppCenter.start(appCenterID, withServices:[
            MSAnalytics.self,
            MSCrashes.self
        ])
        #endif

        if #available(iOS 13.0, *) { return true }

        window = UIWindow()
        let vc = MainViewControler()

        window?.rootViewController = vc
        window?.makeKeyAndVisible()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        urlToRun = url

        NotificationCenter.default.post(name: newURLOpenedNotificationName, object: nil, userInfo: [newURLOpenedNotificationURLKey : url])
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        let core = CelestiaAppCore.shared
        if core.isInitialized {
            core.storeUserDefaults()
        }
    }

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return false
    }

    func application(_ application: UIApplication, shouldSaveSecureApplicationState coder: NSCoder) -> Bool {
        return false
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return false
    }

    func application(_ application: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
        return false
    }

    #if targetEnvironment(macCatalyst)
    @available(iOS 13, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if options.userActivities.contains(where: { $0.activityType == PanelSceneDelegate.activityType }) {
            return UISceneConfiguration(name: "Panel", sessionRole: .windowApplication)
        }
        return UISceneConfiguration(name: "Main", sessionRole: connectingSceneSession.role)
    }
    #endif
}

#if targetEnvironment(macCatalyst)
extension AppDelegate {
    override func buildMenu(with builder: UIMenuBuilder) {
        guard builder.system == .main else { return }
        builder.remove(menu: .newScene)

        guard CelestiaAppCore.shared.isInitialized else { return }

        let newHelpCommand: UIKeyCommand
        let oldHelpCommand = builder.command(for: NSSelectorFromString("showHelp:"))
        if let helpCommand = oldHelpCommand as? UIKeyCommand {
            newHelpCommand = UIKeyCommand(title: helpCommand.title, image: helpCommand.image, action: #selector(showCelestiaHelp(_:)), input: helpCommand.input ?? "?", modifierFlags: helpCommand.modifierFlags)
        } else {
            newHelpCommand = UIKeyCommand(title: oldHelpCommand?.title ?? CelestiaString("", comment: ""), image: oldHelpCommand?.image, action: #selector(showCelestiaHelp(_:)), input: "?", modifierFlags: .command)
        }

        let identifierPrefix = Bundle.main.bundleIdentifier! + "."

        builder.insertChild(UIMenu(title: "", image: nil, identifier: UIMenu.Identifier(identifierPrefix + "open"), options: .displayInline, children: [
            UIKeyCommand(title: CelestiaString("Run Script…", comment: ""), image: nil, action: #selector(openScriptFile), input: "O", modifierFlags: .command)
        ]), atStartOfMenu: .file)
        builder.replaceChildren(ofMenu: .help) { (oldCommands: [UIMenuElement]) -> [UIMenuElement] in
            var newCommands = oldCommands
            if let helpCommandIndex = newCommands.firstIndex(where: { $0 == oldHelpCommand }) {
                newCommands.remove(at: helpCommandIndex)
                newCommands.insert(newHelpCommand, at: helpCommandIndex)
            } else {
                newCommands.insert(newHelpCommand, at: 0)
            }
            newCommands.append(UIMenu(title: "", image: nil, identifier: UIMenu.Identifier(identifierPrefix + "help.sub"), options: .displayInline, children: [
                UICommand(title: CelestiaString("Official Website", comment: ""), image: nil, action: #selector(openOfficialWebsite)),
                UICommand(title: CelestiaString("Support Forum", comment: ""), image: nil, action: #selector(openSupportForum)),
            ]))
            return newCommands
        }
    }

    @objc private func openScriptFile() {
        NotificationCenter.default.post(name: requestOpenFileNotificationName, object: nil)
    }

    @objc private func showCelestiaHelp(_ sender: Any) {
        NotificationCenter.default.post(name: showHelpNotificationName, object: nil, userInfo: nil)
    }

    @objc private func openOfficialWebsite() {
        UIApplication.shared.open(officialWebsiteURL, options: [:], completionHandler: nil)
    }

    @objc private func openSupportForum() {
        UIApplication.shared.open(supportForumURL, options: [:], completionHandler: nil)
    }
}

class MacBridge {
    private static var clazz = NSClassFromString("MacBridge") as! NSObject.Type // Should only be used after calling initialize

    static func initialize() {
        guard let appBundleUrl = Bundle.main.builtInPlugInsURL else { return }
        let helperBundleUrl = appBundleUrl.appendingPathComponent("CelestiaMacBridge.bundle")
        guard let bundle = Bundle(url: helperBundleUrl) else { return }
        bundle.load()
    }

    static var catalystScaleFactor: CGFloat {
        return (clazz.value(forKey: "catalystScaleFactor") as? CGFloat) ?? 1.0
    }

    static func forceDarkAppearance() {
        clazz.perform(NSSelectorFromString("forceDarkAppearance"))
    }

    static func nsWindowForUIWindow(_ uiWindow: UIWindow) -> NSObject? {
        return clazz.perform(NSSelectorFromString("nsWindowForUIWindow:"), with: uiWindow)?.takeUnretainedValue() as? NSObject
    }

    static func disableFullScreenForNSWindow(_ nsWindow: NSObject) {
        clazz.perform(NSSelectorFromString("disableFullScreenForNSWindow:"), with: nsWindow)
    }
}
#endif

extension AppDelegate {
    private func swizzleShouldInheritScreenScaleAsContentScaleFactor() {
        #if USE_MGL
        let clazz = MGLKView.self
        let selector = NSSelectorFromString("_shouldInheritScreenScaleAsContentScaleFactor")
        guard let method = class_getInstanceMethod(clazz, selector) else { return }
        class_replaceMethod(clazz, selector, imp_implementationWithBlock({ (_: MGLKView) -> Bool in
            return false
        } as @convention(block) (MGLKView) -> Bool), method_getTypeEncoding(method))
        #endif
    }
}
