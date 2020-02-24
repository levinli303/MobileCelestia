//
//  Celestia+Extension.swift
//  CelestiaMobile
//
//  Created by Li Linfeng on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import CelestiaCore

extension BodyInfo {
    init(selection: CelestiaSelection) {
        self.init(name: selection.name, overview: NSLocalizedString("No overview available.", comment: ""))
    }
}
