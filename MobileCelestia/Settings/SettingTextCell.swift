//
// SettingTextCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class SettingTextCell: UITableViewCell {
    private var label: UILabel { return textLabel! }
    private var detailLabel: UILabel { return detailTextLabel! }

    var title: String? { didSet { label.text = title }  }
    var titleColor: UIColor? { didSet { label.textColor = titleColor } }
    var detail: String? { didSet { detailLabel.text = detail } }

    private var savedAccessoryType: UITableViewCell.AccessoryType = .none

    override var accessoryType: UITableViewCell.AccessoryType {
        get {
            if #available(iOS 13, *) {
                return super.accessoryType
            }
            return savedAccessoryType
        }
        set {
            if #available(iOS 13, *) {
                super.accessoryType = newValue
                return
            }
            savedAccessoryType = newValue
            switch newValue {
            case .none:
                accessoryView = nil
            case .disclosureIndicator:
                let view = UIImageView(image: #imageLiteral(resourceName: "accessory_full_disclosure").withRenderingMode(.alwaysTemplate))
                view.tintColor = UIColor.darkTertiaryLabel
                accessoryView = view
            default:
                accessoryView = nil
                super.accessoryType = newValue
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        label.text = nil
        detailLabel.text = nil
        label.textColor = .darkLabel

        super.accessoryType = .none
        savedAccessoryType = .none
        accessoryView = nil
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SettingTextCell {
    func setup() {
        backgroundColor = .darkSecondaryBackground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .darkSelection
    }
}
