//
//  MainViewControler.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/23.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class MainViewControler: UIViewController {
    private lazy var celestiaController = CelestiaViewController()

    private var loadeed = false

    private lazy var rightSlideInManager = SlideInPresentationManager(direction: .right)

    private lazy var bottomSlideInManager = SlideInPresentationManager(direction: .bottom)

    override func loadView() {
        view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .darkBackground

        install(celestiaController)
        celestiaController.celestiaDelegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if loadeed { return }

        loadeed = true

        let loadingController = LoadingViewController()
        install(loadingController)

        celestiaController.load({ (status) in
            loadingController.update(with: status)
        }) { (result) in
            loadingController.remove()

            switch result {
            case .success():
                print("loading success")
            case .failure(_):
                let failure = LoadingFailureViewController()
                self.install(failure)
            }
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
         return true
    }
}

extension MainViewControler: CelestiaViewControllerDelegate {
    func celestiaController(_ celestiaController: CelestiaViewController, selection: BodyInfo?) {
        var actions: [ToolbarAction] = ToolbarAction.persistentAction
        if selection != nil {
            actions.insert(.celestia, at: 0)
        }
        let controller = ToolbarViewController(actions: actions)
        controller.selectionHandler = { [weak self] (action) in
            guard let self = self else { return }
            guard let ac = action else { return }
            if ac == .celestia {
                self.showBodyInfo(with: selection!)
                return
            }
            switch ac {
            case .celestia:
                self.showBodyInfo(with: selection!)
            case .setting:
                self.showSettings()
            case .search:
                self.showSearch()
            case .browse:
                self.showBrowser()
            // TODO: handle other actions
            case .share:
                break
            }
        }
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = rightSlideInManager
        present(controller, animated: true, completion: nil)
    }

    private func showBodyInfo(with selection: BodyInfo) {
        let controller = InfoViewController(info: selection)
        controller.selectionHandler = { [weak self] (action) in
            guard let ac = action else { return }
            guard let self = self else { return }
            self.celestiaController.receive(action: ac)
        }
        // TODO: special setup for iPad
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = rightSlideInManager
        present(controller, animated: true, completion: nil)
    }

    private func showSettings() {
        let controller = SettingsCoordinatorController()
        // TODO: special setup for iPad
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = rightSlideInManager
        present(controller, animated: true, completion: nil)
    }

    private func showSearch() {
        let controller = SearchCoordinatorController { [weak self] (info) in
            guard let self = self else { return }
            self.showBodyInfo(with: info)
        }
        // TODO: special setup for iPad
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = rightSlideInManager
        present(controller, animated: true, completion: nil)
    }

    private func showBrowser() {
        let controller = BrowserContainerViewController(selected: { [weak self] (info) in
            guard let self = self else { return }
            self.showBodyInfo(with: info)
        })
        // TODO: special setup for iPad
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = rightSlideInManager
        present(controller, animated: true, completion: nil)
    }
}
