//
// CelestiaViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit
import CelestiaCore.CelestiaSelection

enum CelestiaLoadingError: Error {
    case openGLError
    case celestiaError
}

struct RenderingTargetGeometry {
    let size: CGSize
    let scale: CGFloat
}

typealias CelestiaLoadingResult = Result<Void, CelestiaLoadingError>

protocol CelestiaControllerDelegate: class {
    func celestiaController(_ celestiaController: CelestiaViewController, requestShowActionMenuWithSelection selection: CelestiaSelection)
    func celestiaController(_ celestiaController: CelestiaViewController, requestShowInfoWithSelection selection: CelestiaSelection)
    func celestiaController(_ celestiaController: CelestiaViewController, requestWebInfo webURL: URL)
}

class CelestiaViewController: UIViewController {
    weak var delegate: CelestiaControllerDelegate!

    private lazy var displayController = CelestiaDisplayController()
    private var interactionController: CelestiaInteractionController?

    private lazy var auxiliaryWindows = [UIWindow]()

    private var isMirroring = false

    override func loadView() {
        let container = UIView()
        container.backgroundColor = .darkBackground
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        install(displayController)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if #available(iOS 13.4, *), let key = presses.first?.key {
            interactionController?.keyDown(with: key.input, modifiers: UInt(key.modifierFlags.rawValue))
        } else {
            super.pressesBegan(presses, with: event)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if #available(iOS 13.4, *), let key = presses.first?.key {
            interactionController?.keyUp(with: key.input, modifiers: UInt(key.modifierFlags.rawValue))
        } else {
            super.pressesEnded(presses, with: event)
        }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if #available(iOS 13.4, *), let key = presses.first?.key {
            interactionController?.keyUp(with: key.input, modifiers: UInt(key.modifierFlags.rawValue))
        } else {
            super.pressesCancelled(presses, with: event)
        }
    }
}

extension CelestiaViewController: CelestiaInteractionControllerDelegate {
    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestShowActionMenuWithSelection selection: CelestiaSelection) {
        delegate?.celestiaController(self, requestShowActionMenuWithSelection: selection)
    }

    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestShowInfoWithSelection selection: CelestiaSelection) {
        delegate?.celestiaController(self, requestShowInfoWithSelection: selection)
    }

    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestWebInfo webURL: URL) {
        delegate?.celestiaController(self, requestWebInfo: webURL)
    }
}

extension CelestiaViewController {
    func load(statusUpdater: @escaping (String) -> Void, errorHandler: @escaping () -> Bool, completionHandler: @escaping (CelestiaLoadingResult) -> Void) {
        displayController.load(statusUpdater: statusUpdater, errorHandler: errorHandler) { [unowned self] result in
            if case CelestiaLoadingResult.success() = result {
                let interactionController = CelestiaInteractionController()
                interactionController.delegate = self
                interactionController.targetProvider = self
                self.install(interactionController)
                self.interactionController = interactionController
                if isMirroring {
                    interactionController.startMirroring()
                }
            }
            completionHandler(result)
        }
    }

    func openURL(_ url: URL, external: Bool) {
        interactionController?.openURL(url, external: external)
    }

    func moveToNewScreen(_ newScreen: UIScreen) -> Bool {
        let newWindow = UIWindow(frame: newScreen.bounds)
        if #available(iOS 13, *) {
            // Find the window scene associated with the screen...
            guard let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.screen == newScreen }) else {
                return false
            }
            newWindow.windowScene = windowScene
        } else {
            newWindow.screen = newScreen
        }
        // Only move the display controller to the new screen
        displayController.remove()
        newWindow.rootViewController = self.displayController
        newWindow.isHidden = false
        auxiliaryWindows.append(newWindow)
        interactionController?.startMirroring()
        isMirroring = true
        return true
    }

    func moveBack(from screen: UIScreen) {
        guard let windowIndex = auxiliaryWindows.firstIndex(where: { $0.screen == screen }) else {
            // No window with this screen is found
            return
        }
        let window = auxiliaryWindows.remove(at: windowIndex)
        // Only move back when it has the display view controller
        guard window.rootViewController == displayController else { return }
        window.rootViewController = nil
        install(displayController)
        view.sendSubviewToBack(displayController.view)
        isMirroring = false
        interactionController?.stopMirroring()
    }
}

extension CelestiaViewController: RenderingTargetInformationProvider {
    var targetGeometry: RenderingTargetGeometry {
        return displayController.targetGeometry
    }

    var targetImage: UIImage {
        return displayController.screenshot()
    }
}

@available(iOS 13.4, *)
private extension UIKey {
    var input: String? {
        let c = characters
        if c.count > 0 {
            return c
        }
        return charactersIgnoringModifiers
    }
}
