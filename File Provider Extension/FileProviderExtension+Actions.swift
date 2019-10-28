//
//  FileProviderExtension+Actions.swift
//  PickerFileProvider
//
//  Created by Marino Faggiana on 28/05/18.
//  Copyright © 2018 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import FileProvider

extension FileProviderExtension {

    override func createDirectory(withName directoryName: String, inParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        
        guard let tableDirectory = fileProviderUtility.sharedInstance.getTableDirectoryFromParentItemIdentifier(parentItemIdentifier, account: fileProviderData.sharedInstance.account, homeServerUrl: fileProviderData.sharedInstance.homeServerUrl) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        let serverUrlFileName = tableDirectory.serverUrl + "/" + directoryName
        
        NCCommunication.sharedInstance.createFolder(serverUrlFileName, account: fileProviderData.sharedInstance.account) { (account, ocId, date, error) in
            
            if error == nil {
                
                let metadata = tableMetadata()
                
                metadata.account = account
                metadata.directory = true
                metadata.ocId = ocId!
                metadata.fileName = directoryName
                metadata.fileNameView = directoryName
                metadata.serverUrl = tableDirectory.serverUrl
                metadata.typeFile = k_metadataTypeFile_directory
                
                guard let metadataUpdate = NCManageDatabase.sharedInstance.addMetadata(metadata) else {
                    completionHandler(nil, NSFileProviderError(.noSuchItem))
                    return
                }
                
                guard let _ = NCManageDatabase.sharedInstance.addDirectory(encrypted: false, favorite: false, ocId: ocId!, permissions: nil, serverUrl: tableDirectory.serverUrl + "/" + directoryName, account: account) else {
                    completionHandler(nil, NSFileProviderError(.noSuchItem))
                    return
                }
                
                guard let parentItemIdentifier = fileProviderUtility.sharedInstance.getParentItemIdentifier(metadata: metadataUpdate, homeServerUrl: fileProviderData.sharedInstance.homeServerUrl) else {
                    completionHandler(nil, NSFileProviderError(.noSuchItem))
                    return
                }
                
                let item = FileProviderItem(metadata: metadataUpdate, parentItemIdentifier: parentItemIdentifier)
                completionHandler(item, nil)
                
            } else {
                completionHandler(nil, NSFileProviderError(.serverUnreachable))
            }
        }
    }
    
    override func deleteItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (Error?) -> Void) {
        
        guard let metadata = fileProviderUtility.sharedInstance.getTableMetadataFromItemIdentifier(itemIdentifier) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }
        
        let serverUrlFileName = metadata.serverUrl + "/" + metadata.fileName
        
        NCCommunication.sharedInstance.deleteFileOrFolder(serverUrlFileName, account: fileProviderData.sharedInstance.account) { (account, error) in
            
            if error == nil { //|| error == kOCErrorServerPathNotFound {
            
                let fileNamePath = CCUtility.getDirectoryProviderStorageOcId(itemIdentifier.rawValue)!
                do {
                    try fileProviderUtility.sharedInstance.fileManager.removeItem(atPath: fileNamePath)
                } catch let error {
                    print("error: \(error)")
                }
                
                if metadata.directory {
                    let dirForDelete = CCUtility.stringAppendServerUrl(metadata.serverUrl, addFileName: metadata.fileName)
                    NCManageDatabase.sharedInstance.deleteDirectoryAndSubDirectory(serverUrl: dirForDelete!, account: account)
                }
                
                NCManageDatabase.sharedInstance.deleteMetadata(predicate: NSPredicate(format: "ocId == %@", metadata.ocId))
                NCManageDatabase.sharedInstance.deleteLocalFile(predicate: NSPredicate(format: "ocId == %@", metadata.ocId))
                
                completionHandler(nil)

            } else {
                completionHandler( NSFileProviderError(.serverUnreachable))
            }
        }
    }
    
    override func reparentItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toParentItemWithIdentifier parentItemIdentifier: NSFileProviderItemIdentifier, newName: String?, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        
        guard let itemFrom = try? item(for: itemIdentifier) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        guard let metadataFrom = fileProviderUtility.sharedInstance.getTableMetadataFromItemIdentifier(itemIdentifier) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        let ocIdFrom = metadataFrom.ocId
        let serverUrlFrom = metadataFrom.serverUrl
        let fileNameFrom = serverUrlFrom + "/" + itemFrom.filename
        
        guard let tableDirectoryTo = fileProviderUtility.sharedInstance.getTableDirectoryFromParentItemIdentifier(parentItemIdentifier, account: fileProviderData.sharedInstance.account, homeServerUrl: fileProviderData.sharedInstance.homeServerUrl) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        let serverUrlTo = tableDirectoryTo.serverUrl
        let fileNameTo = serverUrlTo + "/" + itemFrom.filename
        
        NCCommunication.sharedInstance.moveFileOrFolder(serverUrlFileNameSource: fileNameFrom, serverUrlFileNameDestination: fileNameTo, account: fileProviderData.sharedInstance.account) { (account, error) in
       
            if error == nil {
                
                if metadataFrom.directory {
                    NCManageDatabase.sharedInstance.deleteDirectoryAndSubDirectory(serverUrl: serverUrlFrom, account: account)
                    NCManageDatabase.sharedInstance.renameDirectory(ocId: ocIdFrom, serverUrl: serverUrlTo)                    
                }
                
                NCManageDatabase.sharedInstance.moveMetadata(ocId: ocIdFrom, serverUrlTo: serverUrlTo)
                
                guard let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "ocId == %@", ocIdFrom)) else {
                    completionHandler(nil, NSFileProviderError(.noSuchItem))
                    return
                }
                
                let item = FileProviderItem(metadata: metadata, parentItemIdentifier: parentItemIdentifier)
                completionHandler(item, nil)
                
            } else {
                completionHandler(nil, NSFileProviderError(.serverUnreachable))
            }
        }
    }
    
    override func renameItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toName itemName: String, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        
        guard let metadata = fileProviderUtility.sharedInstance.getTableMetadataFromItemIdentifier(itemIdentifier) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        guard let directoryTable = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", metadata.account, metadata.serverUrl)) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        let fileNameFrom = metadata.fileNameView
        let fileNamePathFrom = metadata.serverUrl + "/" + fileNameFrom
        let fileNamePathTo = metadata.serverUrl + "/" + itemName
        
        NCCommunication.sharedInstance.moveFileOrFolder(serverUrlFileNameSource: fileNamePathFrom, serverUrlFileNameDestination: fileNamePathTo, account: fileProviderData.sharedInstance.account) { (account, error) in
       
            if error == nil {
                
                // Rename metadata
                guard let metadata = NCManageDatabase.sharedInstance.renameMetadata(fileNameTo: itemName, ocId: metadata.ocId) else {
                    completionHandler(nil, NSFileProviderError(.noSuchItem))
                    return
                }
                
                if metadata.directory {
                    
                    NCManageDatabase.sharedInstance.setDirectory(serverUrl: fileNamePathFrom, serverUrlTo: fileNamePathTo, etag: nil, ocId: nil, encrypted: directoryTable.e2eEncrypted, account: account)
                    
                } else {
                    
                    let itemIdentifier = fileProviderUtility.sharedInstance.getItemIdentifier(metadata: metadata)
                    
                    // rename file
                    _ = fileProviderUtility.sharedInstance.moveFile(CCUtility.getDirectoryProviderStorageOcId(itemIdentifier.rawValue, fileNameView: fileNameFrom), toPath: CCUtility.getDirectoryProviderStorageOcId(itemIdentifier.rawValue, fileNameView: itemName))
                    _ = fileProviderUtility.sharedInstance.moveFile(CCUtility.getDirectoryProviderStorageIconOcId(itemIdentifier.rawValue, fileNameView: fileNameFrom), toPath: CCUtility.getDirectoryProviderStorageIconOcId(itemIdentifier.rawValue, fileNameView: itemName))
                    
                    NCManageDatabase.sharedInstance.setLocalFile(ocId: metadata.ocId, date: nil, exifDate: nil, exifLatitude: nil, exifLongitude: nil, fileName: itemName, etag: nil)
                }
                
                guard let parentItemIdentifier = fileProviderUtility.sharedInstance.getParentItemIdentifier(metadata: metadata, homeServerUrl: fileProviderData.sharedInstance.homeServerUrl) else {
                    completionHandler(nil, NSFileProviderError(.noSuchItem))
                    return
                }
                
                let item = FileProviderItem(metadata: metadata, parentItemIdentifier: parentItemIdentifier)
                completionHandler(item, nil)
                
            } else {
                completionHandler(nil, NSFileProviderError(.serverUnreachable))
            }
        }
    }
    
    override func setFavoriteRank(_ favoriteRank: NSNumber?, forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        
        guard let metadata = fileProviderUtility.sharedInstance.getTableMetadataFromItemIdentifier(itemIdentifier) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        guard let parentItemIdentifier = fileProviderUtility.sharedInstance.getParentItemIdentifier(metadata: metadata, homeServerUrl: fileProviderData.sharedInstance.homeServerUrl) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        var favorite = false
        if favoriteRank == nil {
            fileProviderData.sharedInstance.listFavoriteIdentifierRank.removeValue(forKey: itemIdentifier.rawValue)
        } else {
            let rank = fileProviderData.sharedInstance.listFavoriteIdentifierRank[itemIdentifier.rawValue]
            if rank == nil {
                fileProviderData.sharedInstance.listFavoriteIdentifierRank[itemIdentifier.rawValue] = favoriteRank
            }
            favorite = true
        }
        
        if (favorite == true && metadata.favorite == false) || (favorite == false && metadata.favorite == true) {
            let fileNamePath = CCUtility.returnFileNamePath(fromFileName: metadata.fileName, serverUrl: metadata.serverUrl, activeUrl: fileProviderData.sharedInstance.accountUrl)!
            
            NCCommunication.sharedInstance.setFavorite(urlString: fileProviderData.sharedInstance.accountUrl, fileName: fileNamePath, favorite: favorite, account: fileProviderData.sharedInstance.account) { (account, error) in
                if error == nil {
                    // Change DB
                    metadata.favorite = favorite
                    guard let metadataUpdate = NCManageDatabase.sharedInstance.addMetadata(metadata) else {
                        completionHandler(nil, NSFileProviderError(.noSuchItem))
                        return
                    }
                    let item = FileProviderItem(metadata: metadataUpdate, parentItemIdentifier: parentItemIdentifier)
                    
                    fileProviderData.sharedInstance.fileProviderSignalUpdateWorkingSetItem[item.itemIdentifier] = item
                    fileProviderData.sharedInstance.signalEnumerator(for: [.workingSet])

                    completionHandler(item, nil)
                } else {
                    // Errore, remove from listFavoriteIdentifierRank
                    fileProviderData.sharedInstance.listFavoriteIdentifierRank.removeValue(forKey: itemIdentifier.rawValue)
                    let item = FileProviderItem(metadata: metadata, parentItemIdentifier: parentItemIdentifier)
                        
                    fileProviderData.sharedInstance.fileProviderSignalUpdateWorkingSetItem[item.itemIdentifier] = item
                    fileProviderData.sharedInstance.signalEnumerator(for: [.workingSet])
                                
                    completionHandler(item, NSFileProviderError(.serverUnreachable))
                }
            }
        }
    }
    
    override func setTagData(_ tagData: Data?, forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        
        guard let metadata = fileProviderUtility.sharedInstance.getTableMetadataFromItemIdentifier(itemIdentifier) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        // Add, Remove (nil)
        NCManageDatabase.sharedInstance.addTag(metadata.ocId, tagIOS: tagData, account: metadata.account)
        
        guard let parentItemIdentifier = fileProviderUtility.sharedInstance.getParentItemIdentifier(metadata: metadata, homeServerUrl: fileProviderData.sharedInstance.homeServerUrl) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        let item = FileProviderItem(metadata: metadata, parentItemIdentifier: parentItemIdentifier)
        
        fileProviderData.sharedInstance.fileProviderSignalUpdateWorkingSetItem[item.itemIdentifier] = item
        fileProviderData.sharedInstance.signalEnumerator(for: [.workingSet])

        completionHandler(item, nil)
    }
    
    override func setLastUsedDate(_ lastUsedDate: Date?, forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        
        guard let metadata = fileProviderUtility.sharedInstance.getTableMetadataFromItemIdentifier(itemIdentifier) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        guard let parentItemIdentifier = fileProviderUtility.sharedInstance.getParentItemIdentifier(metadata: metadata, homeServerUrl: fileProviderData.sharedInstance.homeServerUrl) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        let item = FileProviderItem(metadata: metadata, parentItemIdentifier: parentItemIdentifier)
        item.lastUsedDate = lastUsedDate

        completionHandler(item, nil)
    }
}
