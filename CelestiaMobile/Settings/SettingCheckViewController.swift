//
//  SettingCheckViewController.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

class SettingCheckViewController: UIViewController {
    struct Item {
        let title: String
        let masterKey: String?
        let subitems: [SettingCheckmarkItem]
    }

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private let item: Item

    init(item: Item) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground

        title = NSLocalizedString("Settings", comment: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

}

private extension SettingCheckViewController {
    func setup() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.backgroundColor = .clear
        tableView.alwaysBounceVertical = false
        tableView.separatorColor = .darkSeparator

        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(SettingSwitchCell.self, forCellReuseIdentifier: "Switch")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension SettingCheckViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        let core = CelestiaAppCore.shared
        if item.masterKey != nil && (core.value(forKey: item.masterKey!) as! Bool) {
            return 2
        }
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if item.masterKey != nil && section == 0 { return 1 }
        return item.subitems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let core = CelestiaAppCore.shared

        if item.masterKey != nil && indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath) as! SettingSwitchCell
            cell.title = item.title
            cell.enabled = core.value(forKey: item.masterKey!) as! Bool
            let key = item.masterKey!
            cell.toggleBlock = { [weak self] (enabled) in
                guard let self = self else { return }

                let core = CelestiaAppCore.shared
                core.setValue(enabled, forKey: key)

                self.tableView.reloadData()
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        let subitem = item.subitems[indexPath.row]
        let title = subitem.name
        let enabled = (core.value(forKey: subitem.key) as! Bool)
        cell.title = title
        cell.accessoryType = enabled ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if item.masterKey != nil && indexPath.section == 0 {
            return
        }

        let core = CelestiaAppCore.shared

        let subitem = item.subitems[indexPath.row]
        let key = subitem.key
        let enabled = (core.value(forKey: subitem.key) as! Bool)
        core.setValue(!enabled, forKey: key)
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
