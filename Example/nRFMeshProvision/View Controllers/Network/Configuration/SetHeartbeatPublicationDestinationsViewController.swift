/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit
import nRFMeshProvision

protocol HeartbeatDestinationDelegate {
    func keySelected(_ networkKey: NetworkKey)
    func destinationSelected(_ address: Address)
}

class SetHeartbeatPublicationDestinationsViewController: UITableViewController {
    
    // MARK: - Properties
    
    var target: Node!
    var delegate: HeartbeatDestinationDelegate?
    var selectedNetworkKey: NetworkKey?
    var selectedDestination: Address?
    
    /// List of all Nodes, except the target one.
    private var nodes: [Node]!
    private var groups: [Group]!
    private let specialGroups: [(title: String, address: Address)] = [
        ("All Proxies", Address.allProxies),
        ("All Friends", Address.allFriends),
        ("All Relays", Address.allRelays),
        ("All Nodes", Address.allNodes)
    ]
    private var selectedKeyIndexPath: IndexPath?
    private var selectedIndexPath: IndexPath?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let network = MeshNetworkManager.instance.meshNetwork!
        // Exclude the current Node.
        nodes = network.nodes.filter { $0.uuid != target.uuid }
        // Exclude Virtual Groups, which may not be set as Heartbeat destination.
        groups = network.groups.filter { $0.address.address.isGroup }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return IndexPath.numberOfSections(for: groups)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == IndexPath.keysSection {
            return target.networkKeys.count
        }
        if section == IndexPath.nodesSection {
            return max(nodes.count, 1)
        }
        if section == IndexPath.groupsSection && !groups.isEmpty {
            return groups.count
        }
        if section == IndexPath.specialGroupsSection ||
          (section == IndexPath.groupsSection && groups.isEmpty) {
            return specialGroups.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.keysSection:
            return "Network Keys"
        case IndexPath.nodesSection:
            return "Nodes"
        case IndexPath.groupsSection:
            return "Groups"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !indexPath.isNodeSection || nodes.count > 0 else {
            return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.reuseIdentifier, for: indexPath)
        
        if indexPath.isKeySection {
            let networkKey = target.networkKeys[indexPath.row]
            if selectedNetworkKey?.index == networkKey.index {
                selectedKeyIndexPath = indexPath
                selectedNetworkKey = nil
            }
            cell.textLabel?.text = networkKey.name
            cell.accessoryType = indexPath == selectedKeyIndexPath ? .checkmark : .none
        }
        if indexPath.isNodeSection {
            let node = nodes[indexPath.row]
            if let destination = selectedDestination, destination == node.unicastAddress {
                selectedIndexPath = indexPath
                selectedDestination = nil
            }
            cell.textLabel?.text = node.name ?? "Unknown Device"
            cell.imageView?.image = #imageLiteral(resourceName: "ic_flag_24pt")
            cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        }
        if indexPath.isGroupsSection && !groups.isEmpty {
            let group = groups[indexPath.row]
            if let destination = selectedDestination, destination == group.address.address {
                selectedIndexPath = indexPath
                selectedDestination = nil
            }
            cell.textLabel?.text = group.name
            cell.imageView?.image = #imageLiteral(resourceName: "ic_group_24pt")
            cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        }
        if indexPath.isSpecialGroupsSection || (indexPath.isGroupsSection && groups.isEmpty) {
            let pair = specialGroups[indexPath.row]
            if let destination = selectedDestination, destination == pair.address {
                selectedIndexPath = indexPath
                selectedDestination = nil
            }
            cell.textLabel?.text = pair.title
            cell.imageView?.image = #imageLiteral(resourceName: "ic_group_24pt")
            cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !indexPath.isNodeSection || !nodes.isEmpty else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isKeySection {
            keySelected(indexPath)
        } else {
            destinationSelected(indexPath)
        }
    }

}

private extension SetHeartbeatPublicationDestinationsViewController {
    
    func keySelected(_ indexPath: IndexPath) {
        // Refresh previously selected and the new rows.
        var rows: [IndexPath] = []
        if let previousSelection = selectedKeyIndexPath {
            rows.append(previousSelection)
        }
        selectedKeyIndexPath = indexPath
        rows.append(indexPath)
        tableView.reloadRows(at: rows, with: .automatic)
        
        // Call delegate.
        let network = MeshNetworkManager.instance.meshNetwork!
        delegate?.keySelected(network.networkKeys[indexPath.row])
    }
    
    func destinationSelected(_ indexPath: IndexPath) {
        // Refresh previously selected and the new rows.
        var rows: [IndexPath] = []
        if let previousSelection = selectedIndexPath {
            rows.append(previousSelection)
        }
        selectedIndexPath = indexPath
        rows.append(indexPath)
        tableView.reloadRows(at: rows, with: .automatic)
        
        // Call delegate.
        switch indexPath.section {
        case IndexPath.nodesSection:
            let node = nodes[indexPath.row]
            delegate?.destinationSelected(node.unicastAddress)
        case IndexPath.groupsSection where !groups.isEmpty:
            let selectedGroup = groups[indexPath.row]
            delegate?.destinationSelected(selectedGroup.address.address)
        default:
            let selectedGroup = specialGroups[indexPath.row]
            delegate?.destinationSelected(selectedGroup.address)
        }
    }
    
}

private extension IndexPath {
    static let keysSection          = 0
    static let nodesSection         = 1
    static let groupsSection        = 2
    static let specialGroupsSection = 3
    static func numberOfSections(for groups: [Group]) -> Int {
        return groups.isEmpty ?
            IndexPath.groupsSection + 1 :
            IndexPath.specialGroupsSection + 1
    }
    
    var reuseIdentifier: String {
        if isKeySection {
            return "key"
        }
        return "normal"
    }
    
    var isKeySection: Bool {
        return section == IndexPath.keysSection
    }
    
    var isNodeSection: Bool {
        return section == IndexPath.nodesSection
    }
    
    var isGroupsSection: Bool {
        return section == IndexPath.groupsSection
    }
    
    var isSpecialGroupsSection: Bool {
        return section == IndexPath.specialGroupsSection
    }
}

private extension IndexSet {
    
    static let nodes = IndexSet(integer: IndexPath.nodesSection)
    
}
