//
//  FileProviderExtension+Thumbnail.swift
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
import NCCommunication

extension FileProviderExtension {

    override func fetchThumbnails(for itemIdentifiers: [NSFileProviderItemIdentifier], requestedSize size: CGSize, perThumbnailCompletionHandler: @escaping (NSFileProviderItemIdentifier, Data?, Error?) -> Void, completionHandler: @escaping (Error?) -> Void) -> Progress {
                
        let progress = Progress(totalUnitCount: Int64(itemIdentifiers.count))
        var counterProgress: Int64 = 0
        
        for itemIdentifier in itemIdentifiers {
            
            guard let metadata = fileProviderUtility.sharedInstance.getTableMetadataFromItemIdentifier(itemIdentifier) else {
                
                counterProgress += 1
                if (counterProgress == progress.totalUnitCount) { completionHandler(nil) }
                continue
            }
            
            if (metadata.hasPreview) {
                
                let width = NCUtility.sharedInstance.getScreenWidthForPreview()
                let height = NCUtility.sharedInstance.getScreenHeightForPreview()
                
                let fileNamePath = CCUtility.returnFileNamePath(fromFileName: metadata.fileName, serverUrl: metadata.serverUrl, activeUrl: fileProviderData.sharedInstance.accountUrl)!
                let fileNameLocalPath = CCUtility.getDirectoryProviderStorageIconOcId(metadata.ocId, fileNameView: metadata.fileNameView)!
                let serverUrl = fileProviderData.sharedInstance.accountUrl
                    
                NCCommunication.sharedInstance.downloadPreview(serverUrl: serverUrl, fileNamePath: fileNamePath, fileNameLocalPath: fileNameLocalPath ,width: width, height: height, account: fileProviderData.sharedInstance.account) { (account, data, errorCode, errorDescription) in
                    if errorCode == 0 && data != nil {
                        perThumbnailCompletionHandler(itemIdentifier, data, nil)
                    } else {
                        perThumbnailCompletionHandler(itemIdentifier, nil, NSFileProviderError(.serverUnreachable))
                    }
                    
                    counterProgress += 1
                    if (counterProgress == progress.totalUnitCount) { completionHandler(nil) }
                }
               
            } else {
                
                counterProgress += 1
                if (counterProgress == progress.totalUnitCount) { completionHandler(nil) }
            }
        }
        
        return progress
    }
    
}
