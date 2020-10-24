//
// ResourceCategoryListViewController.swift
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

enum ResourceCategoryItem {
    case wrapped(category: ResourceCategory)
    case installed
}

extension ResourceCategoryItem: AsyncListItem {
    var name: String {
        switch self {
        case .installed:
            return CelestiaString("Installed", comment: "")
        case .wrapped(let category):
            return category.name
        }
    }
}

class ResourceCategoryListViewController: AsyncListViewController<ResourceCategoryItem> {
    private let viewInstalledHandler: () -> Void

    init(selection: @escaping (ResourceCategoryItem) -> Void,
         viewInstalledHandler: @escaping () -> Void) {
        self.viewInstalledHandler = viewInstalledHandler
        super.init(selection: selection)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = CelestiaString("Categories", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CelestiaString("Installed", comment: ""), style: .plain, target: self, action: #selector(viewInstalled))
    }

    override func refresh(success: @escaping ([ResourceCategoryItem]) -> Void, failure: @escaping (String) -> Void) {
        let requestURL = apiPrefix + "/resource/categories"
        let locale = LocalizedString("LANGUAGE", "celestia")
        _ = RequestHandler.get(url: requestURL, params: ["lang" : locale], success: { (categories: [ResourceCategory]) in
            success(categories.map{ ResourceCategoryItem.wrapped(category: $0) })
        }, fail: failure)
    }

    @objc private func viewInstalled() {
        viewInstalledHandler()
    }
}
