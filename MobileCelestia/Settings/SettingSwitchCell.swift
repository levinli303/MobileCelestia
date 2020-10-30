//
// SettingSwitchCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class SettingSwitchCell: UITableViewCell {
    private var label: UILabel { return self.textLabel! }
    private var `switch`: UISwitch {
        guard let view = accessoryView as? UISwitch else {
            let sw = UISwitch()
            super.accessoryView = sw
            return sw
        }
        return view
    }

    override var accessoryType: UITableViewCell.AccessoryType {
        get { return .none }
        set {}
    }

    override var accessoryView: UIView? {
        get { return super.accessoryView }
        set {}
    }

    var title: String? { didSet { label.text = title }  }
    var enabled: Bool = false { didSet { `switch`.isOn = enabled } }

    var toggleBlock: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SettingSwitchCell {
    func setup() {
        selectionStyle = .none

        backgroundColor = .darkSecondaryBackground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .darkSelection

        `switch`.addTarget(self, action: #selector(handleToggle(_:)), for: .valueChanged)
    }

    @objc private func handleToggle(_ sender: UISwitch) {
        toggleBlock?(sender.isOn)
    }
}
