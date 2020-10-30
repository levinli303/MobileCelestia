//
// SettingStepperCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class SettingStepperCell: UITableViewCell {
    private var label: UILabel { return self.textLabel! }
    private var stepper: UIStepper {
        guard let view = accessoryView as? UIStepper else {
            let sp = UIStepper()
            super.accessoryView = sp
            return sp
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

    var changeBlock: ((Bool) -> Void)?
    var stopBlock: (() -> Void)?

    private enum Button {
        case plus
        case minus
    }

    private var stepperValue: Double = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SettingStepperCell {
    func setup() {
        selectionStyle = .none

        backgroundColor = .darkSecondaryBackground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .darkSelection

        stepper.wraps = true
        stepperValue = stepper.value
        stepper.addTarget(self, action: #selector(handleChange(_:)), for: .valueChanged)
        stepper.addTarget(self, action: #selector(handleTouchUp(_:)), for: .touchUpInside)
        stepper.addTarget(self, action: #selector(handleTouchUp(_:)), for: .touchUpOutside)
        stepper.addTarget(self, action: #selector(handleTouchUp(_:)), for: .touchCancel)
    }

    @objc private func handleChange(_ sender: UIStepper) {
        let orig = stepperValue
        let newValue = sender.value
        var isPlus = orig < newValue
        var isMinus = orig > newValue
        if sender.wraps {
            if orig > sender.maximumValue - sender.stepValue {
                isPlus = newValue < sender.minimumValue + sender.stepValue
                isMinus = isMinus && !isPlus
            } else if orig < sender.minimumValue + sender.stepValue {
                isMinus = newValue > sender.maximumValue - sender.stepValue
                isPlus = isPlus && !isMinus
            }
        }
        stepperValue = sender.value
        changeBlock?(isPlus)
    }

    @objc private func handleTouchUp(_ sender: UIStepper) {
        stopBlock?()
    }
}
