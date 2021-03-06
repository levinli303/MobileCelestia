//
// FavoriteItemViewController.swift
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

protocol FavoriteItemList {
    associatedtype Item: FavoriteItem

    var title: String { get }

    var count: Int { get }
    subscript(index: Int) -> Item { get }

    var canBeModified: Bool { get }
    func append(_ item: Item)
    func remove(at index: Int)
    func move(from source: Int, to dest: Int)
}

class AnyFavoriteItemList<T: FavoriteItem>: FavoriteItemList {
    typealias Item = T

    let title: String
    var items: [T]

    init(title: String, items: [T]) {
        self.title = title
        self.items = items
    }

    var count: Int { return items.count }

    subscript(index: Int) -> T {
        return items[index]
    }

    var canBeModified: Bool { return false }

    func append(_ item: T) {
        fatalError()
    }

    func remove(at index: Int) {
        fatalError()
    }

    func move(from source: Int, to dest: Int) {
        fatalError()
    }
}

extension BookmarkNode: FavoriteItemList {
    typealias Item = BookmarkNode

    var count: Int {
        return children.count
    }

    subscript(index: Int) -> BookmarkNode {
        return children[index]
    }

    var canBeModified: Bool { return isFolder }

    func append(_ item: BookmarkNode) {
        children.append(item)
    }

    func remove(at index: Int) {
        children.remove(at: index)
    }

    func move(from source: Int, to dest: Int) {
        children.insert(children.remove(at: source), at: dest)
    }
}

protocol FavoriteItem {
    associatedtype ItemList: FavoriteItemList
    associatedtype Representation

    var title: String { get }
    var associatedObject: Representation? { get }
    var isLeaf: Bool { get }
    var itemList: ItemList? { get }
    var canBeRenamed: Bool { get }

    func rename(to name: String)
}

extension BookmarkNode: FavoriteItem {
    typealias ItemList = BookmarkNode
    typealias Representation = URL

    var title: String { return name }

    var associatedObject: URL? {
        return URL(string: url)
    }

    var itemList: BookmarkNode? {
        if !isLeaf {
            return self
        }
        return nil
    }

    var canBeRenamed: Bool { return true }

    func rename(to name: String) {
        self.name = name
    }
}

extension CelestiaScript: FavoriteItem {
    typealias ItemList = AnyFavoriteItemList<CelestiaScript>
    typealias Representation = URL

    var associatedObject: URL? {
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/" + filename)
    }

    var isLeaf: Bool {
        return true
    }

    var itemList: AnyFavoriteItemList<CelestiaScript>? {
        return nil
    }

    var canBeRenamed: Bool { return false }

    func rename(to name: String) {
        fatalError()
    }
}

extension CelestiaDestination: FavoriteItem {
    var title: String {
        return name
    }

    typealias ItemList = AnyFavoriteItemList<CelestiaDestination>
    typealias Representation = CelestiaDestination

    var associatedObject: CelestiaDestination? {
        return self
    }

    var isLeaf: Bool {
        return true
    }

    var itemList: AnyFavoriteItemList<CelestiaDestination>? {
        return nil
    }

    var canBeRenamed: Bool { return false }

    func rename(to name: String) {
        fatalError()
    }
}

class FavoriteItemViewController<ItemList: FavoriteItemList>: BaseTableViewController {
    private let itemList: ItemList

    private let selection: (ItemList.Item) -> Void
    private let add: (() -> ItemList.Item?)?

    init(item: ItemList, selection: @escaping (ItemList.Item) -> Void, add: (() -> ItemList.Item?)?) {
        self.itemList = item
        self.selection = selection
        self.add = add
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if itemList.canBeModified { return 2 }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 { return 1 }
        return itemList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        if indexPath.section == 1 {
            cell.title = CelestiaString("Add new…", comment: "")
            cell.accessoryType = .disclosureIndicator
        } else {
            let item = itemList[indexPath.row]
            cell.title = item.title
            cell.accessoryType = item.isLeaf ? .none : .disclosureIndicator
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            tableView.deselectRow(at: indexPath, animated: true)
            requestAddObject()
        } else {
            let item = itemList[indexPath.row]
            if item.isLeaf {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            selection(item)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 1 { return nil }

        var actions = [UIContextualAction]()
        if itemList.canBeModified {
            actions.append(
                UIContextualAction(style: .destructive, title: CelestiaString("Delete", comment: "")) { [unowned self] (_, _, completionHandler) in
                    self.requestRemoveObject(at: indexPath.row)
                    completionHandler(true)
                }
            )
        }
        let item = itemList[indexPath.row]
        if item.canBeRenamed {
            actions.append(
                UIContextualAction(style: .normal, title: CelestiaString("Edit", comment: "")) { [unowned self] (_, _, completionHandler) in
                    self.requestRenameObject(at: indexPath.row, completionHandler: completionHandler)
                }
            )
        }
        return UISwipeActionsConfiguration(actions: actions)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return itemList.canBeModified && indexPath.section == 0
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return itemList.canBeModified && indexPath.section == 0
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        defer { tableView.reloadData() }
        guard destinationIndexPath.section == 0 else { return }
        itemList.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }

    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if indexPath.section == 1 { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] (_) -> UIMenu? in
            guard let self = self else { return nil }

            var actions = [UIAction]()
            if self.itemList.canBeModified {
                let deleteAction = UIAction(title: CelestiaString("Delete", comment: ""), image: UIImage(systemName: "trash"), identifier: nil) { (_) in
                    self.requestRemoveObject(at: indexPath.row)
                }
                deleteAction.attributes = .destructive
                actions.append(deleteAction)
            }
            let item = self.itemList[indexPath.row]
            if item.canBeRenamed {
                actions.append(
                    UIAction(title: CelestiaString("Edit", comment: ""), image: UIImage(systemName: "square.and.pencil"), identifier: nil) { (_) in
                        self.requestRenameObject(at: indexPath.row)
                    }
                )
            }
            guard actions.count > 0 else { return nil }
            return UIMenu(title: "", image: nil, identifier: nil, children: actions)
        }
    }

    // MARK: Modification
    @objc private func requestEdit() {
        tableView.setEditing(true, animated: true)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(finishEditing))
    }

    @objc private func finishEditing() {
        tableView.setEditing(false, animated: true)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(requestEdit))
    }

    private func requestAddObject() {
        guard let item = add?() else {
            showError(CelestiaString("Cannot add object", comment: ""))
            return
        }
        itemList.append(item)
        tableView.reloadData()
    }

    private func requestRemoveObject(at index: Int) {
        itemList.remove(at: index)
        tableView.reloadData()
    }

    private func requestRenameObject(at index: Int, completionHandler: ((Bool) -> Void)? = nil) {
        let item = itemList[index]
        showTextInput(CelestiaString("Please enter a new name.", comment: ""), text: item.title) { [unowned self] (text) in
            guard let newName = text else {
                completionHandler?(false)
                return
            }
            item.rename(to: newName)
            self.tableView.reloadData()
            completionHandler?(true)
        }
    }
}

private extension FavoriteItemViewController {
    func setup() {
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        title = itemList.title

        if itemList.canBeModified {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(requestEdit))
        }
    }
}
