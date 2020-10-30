//
// SettngSliderCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class SettingSliderCell: UITableViewCell {
    private lazy var topContainer = UIView()
    private lazy var bottomContainer = UIView()
    private lazy var label = UILabel()
    private lazy var slider = UISlider()

    var title: String? { didSet { label.text = title }  }
    var value: Double = 0 { didSet { slider.value = Float(value) * 100 } }

    var valueChangeBlock: ((Double) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        topContainer.layoutMargins = UIEdgeInsets(top: label.font.lineHeight / 2, left: 16, bottom: label.font.lineHeight / 2, right: 16)
    }
}

private extension SettingSliderCell {
    func setup() {
        selectionStyle = .none

        backgroundColor = .darkSecondaryBackground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .darkSelection

        topContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(topContainer)
        contentView.addSubview(bottomContainer)

        NSLayoutConstraint.activate([
            topContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            topContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomContainer.topAnchor.constraint(equalTo: topContainer.bottomAnchor),
            bottomContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .darkLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        topContainer.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: topContainer.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: topContainer.layoutMarginsGuide.trailingAnchor),
            label.topAnchor.constraint(equalTo: topContainer.layoutMarginsGuide.topAnchor),
            label.bottomAnchor.constraint(equalTo: topContainer.layoutMarginsGuide.bottomAnchor),
        ])

        slider.minimumTrackTintColor = .darkSliderMinimumTrackTintColor
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(slider)
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -16),
            slider.heightAnchor.constraint(equalTo: bottomContainer.heightAnchor, multiplier: 0.5),
            slider.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor)
        ])
        slider.addTarget(self, action: #selector(handleSlideEnd(_:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(handleSlideEnd(_:)), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(handleSlideEnd(_:)), for: .touchCancel)
    }

    @objc private func handleSlideEnd(_ sender: UISlider) {
        valueChangeBlock?(Double(sender.value / 100))
    }
}
