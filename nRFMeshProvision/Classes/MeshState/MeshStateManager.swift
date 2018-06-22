//
//  MeshStateManager.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

public class MeshStateManager: NSObject {
    
    public private (set) var meshState: MeshState!

    private override init() {
        super.init()
    }

    public init(withState aState: MeshState) {
        meshState = aState
    }
   
    public func state() -> MeshState {
        return meshState
    }

    public func saveState() {
        let encodedData = try? JSONEncoder().encode(meshState)
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            do {
                try encodedData!.write(to: fileURL)
            } catch {
                print(error)
            }
        }
    }

    public func restoreState() {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            do {
                let data = try Data(contentsOf: fileURL)
                let decodedState = try JSONDecoder().decode(MeshState.self, from: data)
                meshState = decodedState
            } catch {
                print("Error reading state from file")
            }
        }
    }

    public func generateState() -> Bool {
        let networkKey = generateRandomKeyforNetwork()
        
        guard networkKey != nil else {
            print("Failed to generate network key")
            return false
        }
        let keyIndex = Data([0x00, 0x05])
        let flags = Data([0x00])
        let ivIndex = Data([0x00, 0x00, 0x00, 0x00])
        let unicastAddress = Data([0x01, 0x23])
        let globalTTL: UInt8 = 5
        let networkName = "My Network"
        let appkey1 = generateRandomKeyforApplication()
        let appkey2 = generateRandomKeyforApplication()
        let appkey3 = generateRandomKeyforApplication()

        guard appkey1 != nil, appkey2 != nil, appkey3 != nil else {
            print("Failed to generate appkeys")
            return false
        }
        
        let appKeys = [["AppKey 1": appkey1!],
                       ["AppKey 2": appkey2!],
                       ["AppKey 3": appkey3!]]
        let newState = MeshState(withNodeList: [], netKey: networkKey!, keyIndex: keyIndex,
                              IVIndex: ivIndex, globalTTL: globalTTL, unicastAddress: unicastAddress,
                              flags: flags, appKeys: appKeys, andName: networkName)
        self.meshState = newState

        return true
    }

    public func deleteState() -> Bool {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            if FileManager.default.isDeletableFile(atPath: filePath) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    return true
                } catch {
                    print(error.localizedDescription)
                    return false
                }
            }
        }
        return false;
    }

    // MARK: - Static accessors
    public static func restoreState() -> MeshStateManager? {
        if MeshStateManager.stateExists() {
            let aStateManager = MeshStateManager()
            aStateManager.restoreState()
            return aStateManager
        } else {
            return nil
        }
    }

    public static func stateExists() -> Bool {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            return FileManager.default.fileExists(atPath: filePath)
        } else {
            return false
        }
    }
    
    public static func generateState() -> MeshStateManager? {
        let aStateManager = MeshStateManager()
        if aStateManager.generateState() {
            aStateManager.saveState()
        } else {
            print("Failed to create MeshStateManager object")
            return nil
        }
        return aStateManager
    }
    private static func getDocumentDirectory() -> String? {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    }
    
    // MARK: - Generation helper
    private func generateRandomKeyforApplication() -> Data? {
        let newKey = NSData(bytes: [0x2a, 0xa2, 0xa6, 0xde, 0xd5, 0xa0, 0x79, 0x8c, 0xea, 0xb5, 0x78, 0x7c, 0xa3, 0xae, 0x39, 0xfc] as [UInt8], length: 16)
        return newKey as Data
    }
    
    private func generateRandomKeyforNetwork() -> Data?{
        let newKey = NSData(bytes: [0x18, 0xee, 0xd9, 0xc2, 0xa5, 0x6a, 0xdd, 0x85, 0x04, 0x9f, 0xfc, 0x3c, 0x59, 0xad, 0x0e, 0x12] as [UInt8], length: 16)
        return newKey as Data
    }
}
