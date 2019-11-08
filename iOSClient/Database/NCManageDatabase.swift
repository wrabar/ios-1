//
//  NCManageDatabase.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 06/05/17.
//  Copyright © 2017 Marino Faggiana. All rights reserved.
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

import RealmSwift

class NCManageDatabase: NSObject {
        
    @objc static let sharedInstance: NCManageDatabase = {
        let instance = NCManageDatabase()
        return instance
    }()
    
    override init() {
        
        let dirGroup = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: NCBrandOptions.sharedInstance.capabilitiesGroups)
        let databaseFilePath = dirGroup?.appendingPathComponent("\(k_appDatabaseNextcloud)/\(k_databaseDefault)")

        let bundleUrl: URL = Bundle.main.bundleURL
        let bundlePathExtension: String = bundleUrl.pathExtension
        let isAppex: Bool = bundlePathExtension == "appex"
        
        if isAppex {
            
            // App Extension config
            
            let config = Realm.Configuration(
                fileURL: dirGroup?.appendingPathComponent("\(k_appDatabaseNextcloud)/\(k_databaseDefault)"),
                schemaVersion: UInt64(k_databaseSchemaVersion),
                objectTypes: [tableMetadata.self, tableLocalFile.self, tableDirectory.self, tableTag.self, tableAccount.self, tableCapabilities.self]
            )
            
            Realm.Configuration.defaultConfiguration = config
            
        } else {
            
            // App config

            let configCompact = Realm.Configuration(
                
                fileURL: databaseFilePath,
                schemaVersion: UInt64(k_databaseSchemaVersion),
                
                migrationBlock: { migration, oldSchemaVersion in
                    
                    if oldSchemaVersion < 41 {
                        migration.deleteData(forType: tableActivity.className())
                        migration.deleteData(forType: tableMetadata.className())
                        migration.deleteData(forType: tableDirectory.className())
                    }
                    
                    if oldSchemaVersion < 61 {
                        migration.deleteData(forType: tableShare.className())
                    }
                    
                    if oldSchemaVersion < 74 {
                        
                        migration.enumerateObjects(ofType: tableLocalFile.className()) { oldObject, newObject in
                            newObject!["ocId"] = oldObject!["fileID"]
                        }
                        
                        migration.enumerateObjects(ofType: tableTrash.className()) { oldObject, newObject in
                            newObject!["fileId"] = oldObject!["fileID"]
                        }
                        
                        migration.enumerateObjects(ofType: tableTag.className()) { oldObject, newObject in
                            newObject!["ocId"] = oldObject!["fileID"]
                        }
                        
                        migration.enumerateObjects(ofType: tableE2eEncryptionLock.className()) { oldObject, newObject in
                            newObject!["ocId"] = oldObject!["fileID"]
                        }
                    }
                    
                    if oldSchemaVersion < 78 {
                        migration.deleteData(forType: tableActivity.className())
                        migration.deleteData(forType: tableActivityPreview.className())
                        migration.deleteData(forType: tableActivitySubjectRich.className())
                        migration.deleteData(forType: tableComments.className())
                        migration.deleteData(forType: tableDirectory.className())
                        migration.deleteData(forType: tableMetadata.className())
                        migration.deleteData(forType: tableMedia.className())
                        migration.deleteData(forType: tableE2eEncryptionLock.className())
                        migration.deleteData(forType: tableTag.className())
                        migration.deleteData(forType: tableTrash.className())
                    }
                    
                }, shouldCompactOnLaunch: { totalBytes, usedBytes in
                    
                    // totalBytes refers to the size of the file on disk in bytes (data + free space)
                    // usedBytes refers to the number of bytes used by data in the file
                    
                    // Compact if the file is over 100MB in size and less than 50% 'used'
                    let oneHundredMB = 100 * 1024 * 1024
                    return (totalBytes > oneHundredMB) && (Double(usedBytes) / Double(totalBytes)) < 0.5
                }
            )
            
            do {
                _ = try Realm(configuration: configCompact)
            } catch { }
                        
            let config = Realm.Configuration(
                fileURL: dirGroup?.appendingPathComponent("\(k_appDatabaseNextcloud)/\(k_databaseDefault)"),
                schemaVersion: UInt64(k_databaseSchemaVersion)
            )
            
            Realm.Configuration.defaultConfiguration = config
        }
        
        _ = try! Realm()
    }
    
    //MARK: -
    //MARK: Utility Database

    @objc func clearTable(_ table : Object.Type, account: String?) {
        
        let results : Results<Object>
        
        let realm = try! Realm()

        realm.beginWrite()
        
        if let account = account {
            results = realm.objects(table).filter("account == %@", account)
        } else {
            results = realm.objects(table)
        }
        
        realm.delete(results)

        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func clearDatabase(account: String?, removeAccount: Bool) {
        
        self.clearTable(tableActivity.self, account: account)
        self.clearTable(tableActivityPreview.self, account: account)
        self.clearTable(tableActivitySubjectRich.self, account: account)
        self.clearTable(tableCapabilities.self, account: account)
        self.clearTable(tableComments.self, account: account)
        self.clearTable(tableDirectory.self, account: account)
        self.clearTable(tableE2eEncryption.self, account: account)
        self.clearTable(tableE2eEncryptionLock.self, account: account)
        self.clearTable(tableExternalSites.self, account: account)
        self.clearTable(tableGPS.self, account: nil)
        self.clearTable(tableLocalFile.self, account: account)
        self.clearTable(tableMedia.self, account: account)
        self.clearTable(tableMetadata.self, account: account)
        self.clearTable(tablePhotoLibrary.self, account: account)
        self.clearTable(tableShare.self, account: account)
        self.clearTable(tableTag.self, account: account)
        self.clearTable(tableTrash.self, account: account)
        
        if removeAccount {
            self.clearTable(tableAccount.self, account: account)
        }
    }
    
    @objc func removeDB() {
        
        let realmURL = Realm.Configuration.defaultConfiguration.fileURL!
        let realmURLs = [
            realmURL,
            realmURL.appendingPathExtension("lock"),
            realmURL.appendingPathExtension("note"),
            realmURL.appendingPathExtension("management")
        ]
        for URL in realmURLs {
            do {
                try FileManager.default.removeItem(at: URL)
            } catch let error {
                print("[LOG] Could not write to database: ", error)
            }
        }
    }
    
    @objc func getThreadConfined(_ object: Object) -> Any {
     
        // id tradeReference = [[NCManageDatabase sharedInstance] getThreadConfined:metadata];
        return ThreadSafeReference(to: object)
    }
    
    @objc func putThreadConfined(_ tableRef: Any) -> Object? {
        
        //tableMetadata *metadataThread = (tableMetadata *)[[NCManageDatabase sharedInstance] putThreadConfined:tradeReference];
        let realm = try! Realm()
        
        return realm.resolve(tableRef as! ThreadSafeReference<Object>)
    }
    
    @objc func isTableInvalidated(_ object: Object) -> Bool {
     
        return object.isInvalidated
    }
    
    //MARK: -
    //MARK: Table Account
    
    @objc func addAccount(_ account: String, url: String, user: String, password: String) {

        let realm = try! Realm()

        realm.beginWrite()
            
        let addObject = tableAccount()
            
        addObject.account = account
        
        // Brand
        if NCBrandOptions.sharedInstance.use_default_auto_upload {
                
            addObject.autoUpload = true
            addObject.autoUploadImage = true
            addObject.autoUploadVideo = true

            addObject.autoUploadWWAnVideo = true
        }
        
        CCUtility.setPassword(account, password: password)
    
        addObject.url = url
        addObject.user = user
        addObject.userID = user
        
        realm.add(addObject)
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func updateAccount(_ account: tableAccount) {
        
        let realm = try! Realm()
        
        do {
            try realm.write {
                realm.add(account, update: .all)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func deleteAccount(_ account: String) {
        
        let realm = try! Realm()

        realm.beginWrite()

        let result = realm.objects(tableAccount.self).filter("account == %@", account)
        realm.delete(result)
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }

    @objc func getAccountActive() -> tableAccount? {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableAccount.self).filter("active == true").first else {
            return nil
        }
        
        return tableAccount.init(value: result)
    }

    @objc func getAccounts() -> [String]? {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results = realm.objects(tableAccount.self).sorted(byKeyPath: "account", ascending: true)
        
        if results.count > 0 {
            return Array(results.map { $0.account })
        }
        
        return nil
    }
    
    @objc func getAccount(predicate: NSPredicate) -> tableAccount? {
        
        let realm = try! Realm()
        realm.refresh()
        
        if let result = realm.objects(tableAccount.self).filter(predicate).first {
            return tableAccount.init(value: result)
        }
        
        return nil
    }
    
    @objc func getAllAccount() -> [tableAccount] {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results = realm.objects(tableAccount.self)
        
        return Array(results.map { tableAccount.init(value:$0) })
    }
    
    @objc func getAccountAutoUploadFileName() -> String {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableAccount.self).filter("active == true").first else {
            return ""
        }
        
        if result.autoUploadFileName.count > 0 {
            return result.autoUploadFileName
        } else {
            return NCBrandOptions.sharedInstance.folderDefaultAutoUpload
        }
    }
    
    @objc func getAccountAutoUploadDirectory(_ activeUrl : String) -> String {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableAccount.self).filter("active == true").first else {
            return ""
        }
        
        if result.autoUploadDirectory.count > 0 {
            return result.autoUploadDirectory
        } else {
            return CCUtility.getHomeServerUrlActiveUrl(activeUrl)
        }
    }

    @objc func getAccountAutoUploadPath(_ activeUrl : String) -> String {
        
        let cameraFileName = self.getAccountAutoUploadFileName()
        let cameraDirectory = self.getAccountAutoUploadDirectory(activeUrl)
     
        let folderPhotos = CCUtility.stringAppendServerUrl(cameraDirectory, addFileName: cameraFileName)!
        
        return folderPhotos
    }
    
    @objc func setAccountActive(_ account: String) -> tableAccount? {
        
        let realm = try! Realm()

        var activeAccount = tableAccount()
        
        do {
            try realm.write {
            
                let results = realm.objects(tableAccount.self)

                for result in results {
                
                    if result.account == account {
                    
                        result.active = true
                        activeAccount = result
                    
                    } else {
                    
                        result.active = false
                    }
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return nil
        }
        
        return tableAccount.init(value: activeAccount)
    }
    
    @objc func removePasswordAccount(_ account: String) {
        
        let realm = try! Realm()
        
        do {
            try realm.write {
                
                guard let result = realm.objects(tableAccount.self).filter("account == %@", account).first else {
                    return
                }
                
                result.password = "********"
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }

    @objc func setAccountAutoUploadProperty(_ property: String, state: Bool) {
        
        let realm = try! Realm()

        realm.beginWrite()

        guard let result = realm.objects(tableAccount.self).filter("active == true").first else {
            realm.cancelWrite()
            return
        }
        
        if (tableAccount().objectSchema.properties.contains { $0.name == property }) {
            
            result[property] = state
            
            do {
                try realm.commitWrite()
            } catch let error {
                print("[LOG] Could not write to database: ", error)
            }
        } else {
            print("[LOG] property not found")
        }
    }
    
    @objc func setAccountAutoUploadFileName(_ fileName: String?) {
        
        let realm = try! Realm()

        do {
            try realm.write {
                
                if let result = realm.objects(tableAccount.self).filter("active == true").first {
                    
                    if let fileName = fileName {
                        
                        result.autoUploadFileName = fileName
                        
                    } else {
                        
                        result.autoUploadFileName = self.getAccountAutoUploadFileName()
                    }
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }

    @objc func setAccountAutoUploadDirectory(_ serverUrl: String?, activeUrl: String) {
        
        let realm = try! Realm()

        do {
            try realm.write {
                
                if let result = realm.objects(tableAccount.self).filter("active == true").first {
                    
                    if let serverUrl = serverUrl {
                        
                        result.autoUploadDirectory = serverUrl
                        
                    } else {
                        
                        result.autoUploadDirectory = self.getAccountAutoUploadDirectory(activeUrl)
                    }
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func setAccountUserProfile(_ userProfile: OCUserProfile, HCProperties: Bool) -> tableAccount? {
     
        let realm = try! Realm()

        var returnAccount = tableAccount()

        do {
            guard let activeAccount = self.getAccountActive() else {
                return nil
            }
            
            try realm.write {
                
                guard let result = realm.objects(tableAccount.self).filter("account == %@", activeAccount.account).first else {
                    return
                }
                
                // Update userID
                if userProfile.id.count == 0 { // for old config.
                    result.userID = result.user
                } else {
                    result.userID = userProfile.id
                }
                
                result.enabled = userProfile.enabled
                result.address = userProfile.address
                result.displayName = userProfile.displayName
                result.email = userProfile.email
                result.phone = userProfile.phone
                result.twitter = userProfile.twitter
                result.webpage = userProfile.webpage
                
                if HCProperties {
                    result.businessSize = userProfile.businessSize
                    result.businessType = userProfile.businessType
                    result.city = userProfile.city
                    result.country = userProfile.country
                    result.company = userProfile.company
                    result.role = userProfile.role
                    result.zip = userProfile.zip
                }
                
                result.quota = userProfile.quota
                result.quotaFree = userProfile.quotaFree
                result.quotaRelative = userProfile.quotaRelative
                result.quotaTotal = userProfile.quotaTotal
                result.quotaUsed = userProfile.quotaUsed
                
                returnAccount = result
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
        
        return tableAccount.init(value: returnAccount)
    }
    
    @objc func setAccountHCFeatures(_ features: HCFeatures) -> tableAccount? {
        
        let realm = try! Realm()
        
        var returnAccount = tableAccount()

        do {
            guard let activeAccount = self.getAccountActive() else {
                return nil
            }
            
            try realm.write {
                
                guard let result = realm.objects(tableAccount.self).filter("account == %@", activeAccount.account).first else {
                    return
                }
                
                result.hcIsTrial = features.isTrial
                result.hcTrialExpired = features.trialExpired
                result.hcTrialRemainingSec = features.trialRemainingSec
                if features.trialEndTime > 0 {
                    result.hcTrialEndTime = Date(timeIntervalSince1970: features.trialEndTime) as NSDate
                } else {
                    result.hcTrialEndTime = nil
                }
                
                result.hcAccountRemoveExpired = features.accountRemoveExpired
                result.hcAccountRemoveRemainingSec = features.accountRemoveRemainingSec
                if features.accountRemoveTime > 0 {
                    result.hcAccountRemoveTime = Date(timeIntervalSince1970: features.accountRemoveTime) as NSDate
                } else {
                    result.hcAccountRemoveTime = nil
                }
                
                result.hcNextGroupExpirationGroup = features.nextGroupExpirationGroup
                result.hcNextGroupExpirationGroupExpired = features.nextGroupExpirationGroupExpired
                if features.nextGroupExpirationExpiresTime > 0 {
                    result.hcNextGroupExpirationExpiresTime = Date(timeIntervalSince1970: features.nextGroupExpirationExpiresTime) as NSDate
                } else {
                    result.hcNextGroupExpirationExpiresTime = nil
                }
                result.hcNextGroupExpirationExpires = features.nextGroupExpirationExpires
                
                returnAccount = result
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
        
        return tableAccount.init(value: returnAccount)
    }
    
    @objc func setAccountDateSearchContentTypeImageVideo(_ date: Date) {
        
        guard let activeAccount = self.getAccountActive() else {
            return
        }
        
        let realm = try! Realm()
        
        do {
            try realm.write {
                
                guard let result = realm.objects(tableAccount.self).filter("account == %@", activeAccount.account).first else {
                    return
                }
                
                result.dateSearchContentTypeImageVideo = date
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func getAccountStartDirectoryMediaTabView(_ homeServerUrl: String) -> String {
        
        guard let activeAccount = self.getAccountActive() else {
            return ""
        }
        
        let realm = try! Realm()
        realm.refresh()

        guard let result = realm.objects(tableAccount.self).filter("account == %@", activeAccount.account).first else {
            return ""
        }
        
        if result.startDirectoryPhotosTab == "" {
            
            self.setAccountStartDirectoryMediaTabView(homeServerUrl)
            return homeServerUrl
            
        } else {
            return result.startDirectoryPhotosTab
        }
    }
    
    @objc func setAccountStartDirectoryMediaTabView(_ directory: String) {
        
        guard let activeAccount = self.getAccountActive() else {
            return
        }
        
        let realm = try! Realm()
        
        do {
            try realm.write {
                
                guard let result = realm.objects(tableAccount.self).filter("account == %@", activeAccount.account).first else {
                    return
                }
                
                result.startDirectoryPhotosTab = directory
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    //MARK: -
    //MARK: Table Activity

    @objc func addActivity(_ listOfActivity: [OCActivity], account: String) {
    
        let realm = try! Realm()

        do {
            try realm.write {
            
                for activity in listOfActivity {
                    
                    let addObjectActivity = tableActivity()
                    
                    addObjectActivity.account = account
                    addObjectActivity.idActivity = activity.idActivity
                    addObjectActivity.idPrimaryKey = account + String(activity.idActivity)
            
                    if let date = activity.date {
                        addObjectActivity.date = date as NSDate
                    }
                    
                    addObjectActivity.app = activity.app
                    addObjectActivity.type = activity.type
                    addObjectActivity.user = activity.user
                    addObjectActivity.subject = activity.subject
                    
                    if activity.subject_rich.count > 0 {
                        addObjectActivity.subjectRich = activity.subject_rich[0] as? String ?? ""
                        if activity.subject_rich.count > 1 {
                            if let dict = activity.subject_rich[1] as? [String:AnyObject] {
                                for (key, value) in dict {
                                    let addObjectActivitySubjectRich = tableActivitySubjectRich()
                                    if let dict = value as? [String:AnyObject] {
                                        addObjectActivitySubjectRich.account = account
                                        switch dict["id"] {
                                        case is String:
                                            addObjectActivitySubjectRich.id = dict["id"] as? String ?? ""
                                        case is Int:
                                            addObjectActivitySubjectRich.id = String(dict["id"] as? Int ?? 0)
                                        default: addObjectActivitySubjectRich.id = ""
                                        }
                                        addObjectActivitySubjectRich.name = dict["name"] as? String ?? ""
                                        addObjectActivitySubjectRich.idPrimaryKey = account + String(activity.idActivity) + addObjectActivitySubjectRich.id + addObjectActivitySubjectRich.name
                                        addObjectActivitySubjectRich.key = key
                                        addObjectActivitySubjectRich.idActivity = activity.idActivity
                                        addObjectActivitySubjectRich.link = dict["link"] as? String ?? ""
                                        addObjectActivitySubjectRich.path = dict["path"] as? String ?? ""
                                        addObjectActivitySubjectRich.type = dict["type"] as? String ?? ""

                                        realm.add(addObjectActivitySubjectRich, update: .all)
                                    }
                                }
                            }
                        }
                    }
                    
                    if activity.previews.count > 0 {
                        for case let activityPreview as [String:AnyObject] in activity.previews {
                            let addObjectActivityPreview = tableActivityPreview()
                            addObjectActivityPreview.account = account
                            addObjectActivityPreview.idActivity = activity.idActivity
                            addObjectActivityPreview.fileId = activityPreview["fileId"] as? Int ?? 0
                            addObjectActivityPreview.idPrimaryKey = account + String(activity.idActivity) + String(addObjectActivityPreview.fileId)
                            addObjectActivityPreview.source = activityPreview["source"] as? String ?? ""
                            addObjectActivityPreview.link = activityPreview["link"] as? String ?? ""
                            addObjectActivityPreview.mimeType = activityPreview["mimeType"] as? String ?? ""
                            addObjectActivityPreview.view = activityPreview["view"] as? String ?? ""
                            addObjectActivityPreview.isMimeTypeIcon = activityPreview["isMimeTypeIcon"] as? Bool ?? false
                            
                            realm.add(addObjectActivityPreview, update: .all)
                        }
                    }
                    
                    addObjectActivity.icon = activity.icon
                    addObjectActivity.link = activity.link
                    addObjectActivity.message = activity.message
                    addObjectActivity.objectType = activity.object_type
                    addObjectActivity.objectId = activity.object_id
                    addObjectActivity.objectName = activity.object_name
                    
                    realm.add(addObjectActivity, update: .all)
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    func getActivity(predicate: NSPredicate, filterFileId: String?) -> (all: [tableActivity], filter: [tableActivity]) {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results = realm.objects(tableActivity.self).filter(predicate).sorted(byKeyPath: "idActivity", ascending: false)
        let allActivity = Array(results.map { tableActivity.init(value:$0) })
        if filterFileId != nil {
            var resultsFilter = [tableActivity]()
            for result in results {
                let resultsActivitySubjectRich = realm.objects(tableActivitySubjectRich.self).filter("account == %@ && idActivity == %d", result.account, result.idActivity)
                for resultActivitySubjectRich in resultsActivitySubjectRich {
                    if filterFileId!.contains(resultActivitySubjectRich.id) && resultActivitySubjectRich.key == "file" {
                        resultsFilter.append(result)
                        break
                    }
                }
            }
            return(all: allActivity, filter: Array(resultsFilter.map { tableActivity.init(value:$0) }))
        } else {
            return(all: allActivity, filter: allActivity)
        }
    }
    
    @objc func getActivitySubjectRich(account: String, idActivity: Int, key: String) -> tableActivitySubjectRich? {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results = realm.objects(tableActivitySubjectRich.self).filter("account == %@ && idActivity == %d && key == %@", account, idActivity, key).first
        
        return results.map { tableActivitySubjectRich.init(value:$0) }
    }
    
    @objc func getActivitySubjectRich(account: String, idActivity: Int, id: String) -> tableActivitySubjectRich? {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results = realm.objects(tableActivitySubjectRich.self).filter("account == %@ && idActivity == %d && id == %@", account, idActivity, id).first
        
        return results.map { tableActivitySubjectRich.init(value:$0) }
    }
    
    @objc func getActivityPreview(account: String, idActivity: Int, orderKeysId: [String]) -> [tableActivityPreview] {
        
        let realm = try! Realm()
        realm.refresh()
        
        var results = [tableActivityPreview]()
        
        for id in orderKeysId {
            if let result = realm.objects(tableActivityPreview.self).filter("account == %@ && idActivity == %d && fileId == %d", account, idActivity, Int(id) ?? 0).first {
                results.append(result)
            }
        }
        
        return results
    }
    
    @objc func getActivityLastIdActivity(account: String) -> Int {
        
        let realm = try! Realm()
        realm.refresh()
        
        if let entities = realm.objects(tableActivity.self).filter("account == %@", account).max(by: { $0.idActivity < $1.idActivity }) {
            return entities.idActivity
        }
        
        return 0
    }
    
    //MARK: -
    //MARK: Table Capabilities
    
    @objc func addCapabilities(_ capabilities: OCCapabilities, account: String) {
        
        let realm = try! Realm()

        do {
            try realm.write {
            
                let result = realm.objects(tableCapabilities.self).filter("account == %@", account).first

                var resultCapabilities = tableCapabilities()
            
                if let result = result {
                    resultCapabilities = result
                }
                
                resultCapabilities.account = account
                resultCapabilities.themingBackground = capabilities.themingBackground
                resultCapabilities.themingBackgroundDefault = capabilities.themingBackgroundDefault
                resultCapabilities.themingBackgroundPlain = capabilities.themingBackgroundPlain
                resultCapabilities.themingColor = capabilities.themingColor
                resultCapabilities.themingColorElement = capabilities.themingColorElement
                resultCapabilities.themingColorText = capabilities.themingColorText
                resultCapabilities.themingLogo = capabilities.themingLogo
                resultCapabilities.themingName = capabilities.themingName
                resultCapabilities.themingSlogan = capabilities.themingSlogan
                resultCapabilities.themingUrl = capabilities.themingUrl
                resultCapabilities.versionMajor = capabilities.versionMajor
                resultCapabilities.versionMinor = capabilities.versionMinor
                resultCapabilities.versionMicro = capabilities.versionMicro
                resultCapabilities.versionString = capabilities.versionString
                resultCapabilities.endToEndEncryption = capabilities.isEndToEndEncryptionEnabled
                resultCapabilities.endToEndEncryptionVersion = capabilities.endToEndEncryptionVersion
                resultCapabilities.richdocumentsMimetypes.removeAll()
                for mimeType in capabilities.richdocumentsMimetypes {
                    resultCapabilities.richdocumentsMimetypes.append(mimeType as! String)
                }
                resultCapabilities.richdocumentsDirectEditing = capabilities.richdocumentsDirectEditing
                // FILES SHARING
                resultCapabilities.isFilesSharingAPIEnabled = capabilities.isFilesSharingAPIEnabled
                resultCapabilities.filesSharingDefaulPermissions = capabilities.filesSharingDefaulPermissions
                resultCapabilities.isFilesSharingGroupSharing = capabilities.isFilesSharingGroupSharing
                resultCapabilities.isFilesSharingReSharing = capabilities.isFilesSharingReSharing
                resultCapabilities.isFilesSharingPublicShareLinkEnabled = capabilities.isFilesSharingPublicShareLinkEnabled
                resultCapabilities.isFilesSharingAllowPublicUploadsEnabled = capabilities.isFilesSharingAllowPublicUploadsEnabled
                resultCapabilities.isFilesSharingAllowPublicUserSendMail = capabilities.isFilesSharingAllowPublicUserSendMail
                resultCapabilities.isFilesSharingAllowPublicUploadFilesDrop = capabilities.isFilesSharingAllowPublicUploadFilesDrop
                resultCapabilities.isFilesSharingAllowPublicMultipleLinks = capabilities.isFilesSharingAllowPublicMultipleLinks
                resultCapabilities.isFilesSharingPublicExpireDateByDefaultEnabled = capabilities.isFilesSharingPublicExpireDateByDefaultEnabled
                resultCapabilities.isFilesSharingPublicExpireDateEnforceEnabled = capabilities.isFilesSharingPublicExpireDateEnforceEnabled
                resultCapabilities.filesSharingPublicExpireDateDays = capabilities.filesSharingPublicExpireDateDays
                resultCapabilities.isFilesSharingPublicPasswordEnforced = capabilities.isFilesSharingPublicPasswordEnforced
                resultCapabilities.isFilesSharingAllowUserSendMail = capabilities.isFilesSharingAllowUserSendMail
                resultCapabilities.isFilesSharingUserExpireDate = capabilities.isFilesSharingUserExpireDate
                resultCapabilities.isFilesSharingGroupEnabled = capabilities.isFilesSharingGroupEnabled
                resultCapabilities.isFilesSharingGroupExpireDate = capabilities.isFilesSharingGroupExpireDate
                resultCapabilities.isFilesSharingFederationAllowUserSendShares = capabilities.isFilesSharingFederationAllowUserSendShares
                resultCapabilities.isFilesSharingFederationAllowUserReceiveShares = capabilities.isFilesSharingFederationAllowUserReceiveShares
                resultCapabilities.isFilesSharingFederationExpireDate = capabilities.isFilesSharingFederationExpireDate
                resultCapabilities.isFileSharingShareByMailEnabled = capabilities.isFileSharingShareByMailEnabled
                resultCapabilities.isFileSharingShareByMailPassword = capabilities.isFileSharingShareByMailPassword
                resultCapabilities.isFileSharingShareByMailUploadFilesDrop = capabilities.isFileSharingShareByMailUploadFilesDrop
                // HC
                resultCapabilities.isHandwerkcloudEnabled = capabilities.isHandwerkcloudEnabled
                resultCapabilities.HCShopUrl = capabilities.hcShopUrl
                // Imagemeter
                resultCapabilities.isImagemeterEnabled = capabilities.isImagemeterEnabled
                // Fulltextsearch
                resultCapabilities.isFulltextsearchEnabled = capabilities.isFulltextsearchEnabled
                // Extended Support
                resultCapabilities.isExtendedSupportEnabled = capabilities.isExtendedSupportEnabled
                
                if result == nil {
                    realm.add(resultCapabilities)
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func getCapabilites(account: String) -> tableCapabilities? {
        
        let realm = try! Realm()
        realm.refresh()
        
        return realm.objects(tableCapabilities.self).filter("account == %@", account).first
    }
    
    @objc func getServerVersion(account: String) -> Int {

        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableCapabilities.self).filter("account == %@", account).first else {
            return 0
        }

        return result.versionMajor
    }

    @objc func getEndToEndEncryptionVersion(account: String) -> Float {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableCapabilities.self).filter("account == %@", account).first else {
            return 0
        }
        
        return Float(result.endToEndEncryptionVersion)!
    }
    
    @objc func compareServerVersion(_ versionCompare: String, account: String) -> Int {
        
        let realm = try! Realm()

        guard let capabilities = realm.objects(tableCapabilities.self).filter("account == %@", account).first else {
            return -1
        }
        
        let versionServer = capabilities.versionString
        
        let v1 = versionServer.split(separator:".").map { Int(String($0)) }
        let v2 = versionCompare.split(separator:".").map { Int(String($0)) }
        
        var result = 0
        for i in 0..<max(v1.count,v2.count) {
            let left = i >= v1.count ? 0 : v1[i]
            let right = i >= v2.count ? 0 : v2[i]
            
            if (left == right) {
                result = 0
            } else if left! > right! {
                return 1
            } else if right! > left! {
                return -1
            }
        }
        return result
    }
    
    @objc func getRichdocumentsMimetypes(account: String) -> [String]? {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableCapabilities.self).filter("account == %@", account).first else {
            return nil
        }
        
        return Array(result.richdocumentsMimetypes)
    }
    
    //MARK: -
    //MARK: Table Comments
    
    @objc func addComments(_ listOfComments: [NCComments], account: String, objectId: String) {
        
        let realm = try! Realm()
        
        do {
            try realm.write {
                
                let results = realm.objects(tableComments.self).filter("account == %@ AND objectId == %@", account, objectId)
                realm.delete(results)
                
                for comment in listOfComments {
                    
                    let addObject = tableComments()
                    
                    addObject.account = account
                    addObject.actorDisplayName = comment.actorDisplayName
                    addObject.actorId = comment.actorId
                    addObject.actorType = comment.actorType
                    addObject.creationDateTime = comment.creationDateTime as NSDate
                    addObject.isUnread = comment.isUnread
                    addObject.message = comment.message
                    addObject.messageID = comment.messageID
                    addObject.objectId = comment.objectId
                    addObject.objectType = comment.objectType
                    addObject.verb = comment.verb
                    
                    realm.add(addObject, update: .all)
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func getComments(account: String, objectId: String) -> [tableComments] {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results = realm.objects(tableComments.self).filter("account == %@ AND objectId == %@", account, objectId).sorted(byKeyPath: "creationDateTime", ascending: false)
        
        return Array(results.map { tableComments.init(value:$0) })
    }
    
    //MARK: -
    //MARK: Table Directory
    
    @objc func addDirectory(encrypted: Bool, favorite: Bool, ocId: String, permissions: String?, serverUrl: String, account: String) -> tableDirectory? {
        
        let realm = try! Realm()
        realm.beginWrite()
        
        var addObject = tableDirectory()
        
        let result = realm.objects(tableDirectory.self).filter("ocId == %@", ocId).first
        if result != nil {
            addObject = result!
        } else {
            addObject.ocId = ocId
        }
        addObject.account = account
        addObject.e2eEncrypted = encrypted
        addObject.favorite = favorite
        if let permissions = permissions {
            addObject.permissions = permissions
        }
        addObject.serverUrl = serverUrl
        
        realm.add(addObject, update: .all)
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return nil
        }
    
        return tableDirectory.init(value: addObject)
    }
    
    @objc func deleteDirectoryAndSubDirectory(serverUrl: String, account: String) {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results = realm.objects(tableDirectory.self).filter("account == %@ AND serverUrl BEGINSWITH %@", account, serverUrl)
        
        // Delete table Metadata & LocalFile
        for result in results {
            
            self.deleteMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", result.account, result.serverUrl))
            self.deleteLocalFile(predicate: NSPredicate(format: "ocId == %@", result.ocId))
        }
        
        // Delete table Dirrectory
        do {
            try realm.write {
                realm.delete(results)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func setDirectory(serverUrl: String, serverUrlTo: String?, etag: String?, ocId: String?, encrypted: Bool, account: String) {
        
        let realm = try! Realm()

        do {
            try realm.write {
            
                guard let result = realm.objects(tableDirectory.self).filter("account == %@ AND serverUrl == %@", account, serverUrl).first else {
                    return
                }
                
                let directory = tableDirectory.init(value: result)
                
                realm.delete(result)
                
                directory.e2eEncrypted = encrypted
                if let etag = etag {
                    directory.etag = etag
                }
                if let ocId = ocId {
                    directory.ocId = ocId
                }
                if let serverUrlTo = serverUrlTo {
                    directory.serverUrl = serverUrlTo
                }
                
                realm.add(directory, update: .all)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func clearDateRead(serverUrl: String, account: String) {
        
        let realm = try! Realm()

        do {
            try realm.write {

                var predicate = NSPredicate()
            
                predicate = NSPredicate(format: "account == %@ AND serverUrl == %@", account, serverUrl)
                
                guard let result = realm.objects(tableDirectory.self).filter(predicate).first else {
                    return
                }
                
                result.dateReadDirectory = nil
                result.etag = ""
                realm.add(result, update: .all)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func getTableDirectory(predicate: NSPredicate) -> tableDirectory? {
        
        let realm = try! Realm()
        realm.refresh()

        guard let result = realm.objects(tableDirectory.self).filter(predicate).first else {
            return nil
        }
        
        return tableDirectory.init(value: result)
    }
    
    @objc func getTablesDirectory(predicate: NSPredicate, sorted: String, ascending: Bool) -> [tableDirectory]? {
        
        let realm = try! Realm()
        realm.refresh()

        let results = realm.objects(tableDirectory.self).filter(predicate).sorted(byKeyPath: sorted, ascending: ascending)
        
        if (results.count > 0) {
            return Array(results.map { tableDirectory.init(value:$0) })
        } else {
            return nil
        }
    }
    
    @objc func setDateReadDirectory(serverUrl: String, account: String) {
        
        let realm = try! Realm()

        realm.beginWrite()

        guard let result = realm.objects(tableDirectory.self).filter("account == %@ AND serverUrl == %@", account, serverUrl).first else {
            realm.cancelWrite()
            return
        }
            
        result.dateReadDirectory = NSDate()
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func renameDirectory(ocId: String, serverUrl: String) {
        
        let realm = try! Realm()
        
        realm.beginWrite()
        
        guard let result = realm.objects(tableDirectory.self).filter("ocId == %@", ocId).first else {
            realm.cancelWrite()
            return
        }
        
        result.serverUrl = serverUrl
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func setClearAllDateReadDirectory() {
        
        let realm = try! Realm()

        do {
            try realm.write {
            
                let results = realm.objects(tableDirectory.self)

                for result in results {
                    result.dateReadDirectory = nil;
                    result.etag = ""
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func setDirectoryLock(serverUrl: String, lock: Bool, account: String) -> Bool {
        
        let realm = try! Realm()

        var update = false
        
        do {
            try realm.write {
            
                guard let result = realm.objects(tableDirectory.self).filter("account == %@ AND serverUrl == %@", account, serverUrl).first else {
                    realm.cancelWrite()
                    return
                }
                
                result.lock = lock
                update = true
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return false
        }
        
        return update
    }
    
    @objc func setAllDirectoryUnLock(account: String) {
        
        let realm = try! Realm()

        do {
            try realm.write {
            
                let results = realm.objects(tableDirectory.self).filter("account == %@", account)

                for result in results {
                    result.lock = false;
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func setDirectory(serverUrl: String, offline: Bool, account: String) {
        
        let realm = try! Realm()
        
        do {
            try realm.write {
                
                guard let result = realm.objects(tableDirectory.self).filter("account == %@ AND serverUrl == %@", account, serverUrl).first else {
                    realm.cancelWrite()
                    return
                }
                
                result.offline = offline
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }

    //MARK: -
    //MARK: Table e2e Encryption
    
    @objc func addE2eEncryption(_ e2e: tableE2eEncryption) -> Bool {

        guard self.getAccountActive() != nil else {
            return false
        }
        
        let realm = try! Realm()

        do {
            try realm.write {
                realm.add(e2e, update: .all)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return false
        }
        
        return true
    }
    
    @objc func deleteE2eEncryption(predicate: NSPredicate) {
        
        guard self.getAccountActive() != nil else {
            return
        }
        
        let realm = try! Realm()

        do {
            try realm.write {
                
                let results = realm.objects(tableE2eEncryption.self).filter(predicate)
                realm.delete(results)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func getE2eEncryption(predicate: NSPredicate) -> tableE2eEncryption? {
        
        guard self.getAccountActive() != nil else {
            return nil
        }
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableE2eEncryption.self).filter(predicate).sorted(byKeyPath: "metadataKeyIndex", ascending: false).first else {
            return nil
        }
        
        return tableE2eEncryption.init(value: result)
    }
    
    @objc func getE2eEncryptions(predicate: NSPredicate) -> [tableE2eEncryption]? {
        
        guard self.getAccountActive() != nil else {
            return nil
        }
        
        let realm = try! Realm()
        realm.refresh()
        
        let results : Results<tableE2eEncryption>
        
        results = realm.objects(tableE2eEncryption.self).filter(predicate)
        
        if (results.count > 0) {
            return Array(results.map { tableE2eEncryption.init(value:$0) })
        } else {
            return nil
        }
    }
    
    @objc func renameFileE2eEncryption(serverUrl: String, fileNameIdentifier: String, newFileName: String, newFileNamePath: String) {
        
        guard let tableAccount = self.getAccountActive() else {
            return
        }
        
        let realm = try! Realm()

        realm.beginWrite()

        guard let result = realm.objects(tableE2eEncryption.self).filter("account == %@ AND serverUrl == %@ AND fileNameIdentifier == %@", tableAccount.account, serverUrl, fileNameIdentifier).first else {
            realm.cancelWrite()
            return 
        }
        
        let object = tableE2eEncryption.init(value: result)
        
        realm.delete(result)

        object.fileName = newFileName
        object.fileNamePath = newFileNamePath

        realm.add(object)

        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return
        }
        
        return
    }
    
    //MARK: -
    //MARK: Table e2e Encryption Lock
    
    @objc func getE2ETokenLock(serverUrl: String) -> tableE2eEncryptionLock? {
        
        guard let tableAccount = self.getAccountActive() else {
            return nil
        }
        
        let realm = try! Realm()
        realm.refresh()
            
        guard let result = realm.objects(tableE2eEncryptionLock.self).filter("account == %@ AND serverUrl == %@", tableAccount.account, serverUrl).first else {
            return nil
        }
        
        return tableE2eEncryptionLock.init(value: result)
    }
    
    @objc func setE2ETokenLock(serverUrl: String, ocId: String, token: String) {
        
        guard let tableAccount = self.getAccountActive() else {
            return
        }
            
        let realm = try! Realm()

        realm.beginWrite()
        
        let addObject = tableE2eEncryptionLock()
                
        addObject.account = tableAccount.account
        addObject.ocId = ocId
        addObject.serverUrl = serverUrl
        addObject.token = token
                
        realm.add(addObject, update: .all)
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func deteleE2ETokenLock(serverUrl: String) {
        
        guard let tableAccount = self.getAccountActive() else {
            return
        }
            
        let realm = try! Realm()

        realm.beginWrite()

        guard let result = realm.objects(tableE2eEncryptionLock.self).filter("account == %@ AND serverUrl == %@", tableAccount.account, serverUrl).first else {
            return
        }
            
        realm.delete(result)
            
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }

    //MARK: -
    //MARK: Table External Sites
    
    @objc func addExternalSites(_ externalSites: OCExternalSites, account: String) {
        
        let realm = try! Realm()

        do {
            try realm.write {
            
                let addObject = tableExternalSites()
            
                addObject.account = account
                addObject.idExternalSite = externalSites.idExternalSite
                addObject.icon = externalSites.icon
                addObject.lang = externalSites.lang
                addObject.name = externalSites.name
                addObject.url = externalSites.url
                addObject.type = externalSites.type
           
                realm.add(addObject)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }

    @objc func deleteExternalSites(account: String) {
        
        let realm = try! Realm()

        do {
            try realm.write {
            
                let results = realm.objects(tableExternalSites.self).filter("account == %@", account)
                realm.delete(results)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func getAllExternalSites(account: String) -> [tableExternalSites]? {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results = realm.objects(tableExternalSites.self).filter("account == %@", account).sorted(byKeyPath: "idExternalSite", ascending: true)
        
        return Array(results)
    }

    //MARK: -
    //MARK: Table GPS
    
    @objc func addGeocoderLocation(_ location: String, placemarkAdministrativeArea: String, placemarkCountry: String, placemarkLocality: String, placemarkPostalCode: String, placemarkThoroughfare: String, latitude: String, longitude: String) {

        let realm = try! Realm()

        realm.beginWrite()

        // Verify if exists
        guard realm.objects(tableGPS.self).filter("latitude == %@ AND longitude == %@", latitude, longitude).first == nil else {
            realm.cancelWrite()
            return
        }
        
        // Add new GPS
        let addObject = tableGPS()
            
        addObject.latitude = latitude
        addObject.location = location
        addObject.longitude = longitude
        addObject.placemarkAdministrativeArea = placemarkAdministrativeArea
        addObject.placemarkCountry = placemarkCountry
        addObject.placemarkLocality = placemarkLocality
        addObject.placemarkPostalCode = placemarkPostalCode
        addObject.placemarkThoroughfare = placemarkThoroughfare
            
        realm.add(addObject)
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func getLocationFromGeoLatitude(_ latitude: String, longitude: String) -> String? {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableGPS.self).filter("latitude == %@ AND longitude == %@", latitude, longitude).first else {
            return nil
        }
        
        return result.location
    }

    //MARK: -
    //MARK: Table LocalFile
    
    @objc func addLocalFile(metadata: tableMetadata) {
        
        let realm = try! Realm()

        do {
            try realm.write {
            
                let addObject = tableLocalFile()
            
                addObject.account = metadata.account
                addObject.date = metadata.date
                addObject.etag = metadata.etag
                addObject.exifDate = NSDate()
                addObject.exifLatitude = "-1"
                addObject.exifLongitude = "-1"
                addObject.ocId = metadata.ocId
                addObject.fileName = metadata.fileName
                addObject.size = metadata.size
            
                realm.add(addObject, update: .all)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func deleteLocalFile(predicate: NSPredicate) {
        
        let realm = try! Realm()

        do {
            try realm.write {

                let results = realm.objects(tableLocalFile.self).filter(predicate)
                realm.delete(results)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func setLocalFile(ocId: String, date: NSDate?, exifDate: NSDate?, exifLatitude: String?, exifLongitude: String?, fileName: String?, etag: String?) {
        
        let realm = try! Realm()

        do {
            try realm.write {
                
                guard let result = realm.objects(tableLocalFile.self).filter("ocId == %@", ocId).first else {
                    realm.cancelWrite()
                    return
                }
                
                if let date = date {
                    result.date = date
                }
                if let exifDate = exifDate {
                    result.exifDate = exifDate
                }
                if let exifLatitude = exifLatitude {
                    result.exifLatitude = exifLatitude
                }
                if let exifLongitude = exifLongitude {
                    result.exifLongitude = exifLongitude
                }
                if let fileName = fileName {
                    result.fileName = fileName
                }
                if let etag = etag {
                    result.etag = etag
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func getTableLocalFile(predicate: NSPredicate) -> tableLocalFile? {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableLocalFile.self).filter(predicate).first else {
            return nil
        }

        return tableLocalFile.init(value: result)
    }
    
    @objc func getTableLocalFiles(predicate: NSPredicate, sorted: String, ascending: Bool) -> [tableLocalFile]? {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results = realm.objects(tableLocalFile.self).filter(predicate).sorted(byKeyPath: sorted, ascending: ascending)
        
        if (results.count > 0) {
            return Array(results.map { tableLocalFile.init(value:$0) })
        } else {
            return nil
        }
    }
    
    @objc func setLocalFile(ocId: String, offline: Bool) {
        
        let realm = try! Realm()
        
        do {
            try realm.write {
                
                guard let result = realm.objects(tableLocalFile.self).filter("ocId == %@", ocId).first else {
                    realm.cancelWrite()
                    return
                }
                
                result.offline = offline
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }

    //MARK: -
    //MARK: Table Metadata
    
    @objc func initNewMetadata(_ metadata: tableMetadata) -> tableMetadata {
        return tableMetadata.init(value: metadata)
    }
    
    @objc func addMetadata(_ metadata: tableMetadata) -> tableMetadata? {
            
        if metadata.isInvalidated {
            return nil
        }
        
        let serverUrl = metadata.serverUrl
        let account = metadata.account
        
        let realm = try! Realm()

        do {
            try realm.write {
                realm.add(metadata, update: .all)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return nil
        }
        
        self.setDateReadDirectory(serverUrl: serverUrl, account: account)
        
        if metadata.isInvalidated {
            return nil
        }
        
        return tableMetadata.init(value: metadata)
    }
    
    @objc func addMetadatas(_ metadatas: [tableMetadata]) -> [tableMetadata]? {
        
        var directoryToClearDate = [String:String]()

        let realm = try! Realm()

        do {
            try realm.write {
                for metadata in metadatas {
                    directoryToClearDate[metadata.serverUrl] = metadata.account
                    realm.add(metadata, update: .all)
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return nil
        }
        
        for (serverUrl, account) in directoryToClearDate {
            self.setDateReadDirectory(serverUrl: serverUrl, account: account)
        }
        
        return Array(metadatas.map { tableMetadata.init(value:$0) })
    }

    @objc func addMetadatas(files: [NCFile], account: String, serverUrl: String, removeFirst: Bool) {
    
        var isNotFirstFileOfList: Bool = false
        let realm = try! Realm()
        
        do {
            try realm.write {
                for file in files {
                    
                    if removeFirst == true && isNotFirstFileOfList == false {
                        isNotFirstFileOfList = true
                        continue
                    }
                    
                    if !CCUtility.getShowHiddenFiles() && file.fileName.first == "." {
                        continue
                    }
                    
                    let metadata = tableMetadata()
                    
                    metadata.account = account
                    metadata.commentsUnread = file.commentsUnread
                    metadata.contentType = file.contentType
                    metadata.date = file.date
                    metadata.directory = file.directory
                    metadata.e2eEncrypted = file.e2eEncrypted
                    metadata.etag = file.etag
                    metadata.favorite = file.favorite
                    metadata.fileId = file.fileId
                    metadata.fileName = file.fileName
                    metadata.fileNameView = file.fileName
                    metadata.hasPreview = file.hasPreview
                    metadata.mountType = file.mountType
                    metadata.ocId = file.ocId
                    metadata.ownerId = file.ownerId
                    metadata.ownerDisplayName = file.ownerDisplayName
                    metadata.permissions = file.permissions
                    metadata.quotaUsedBytes = file.quotaUsedBytes
                    metadata.quotaAvailableBytes = file.quotaAvailableBytes
                    metadata.resourceType = file.resourceType
                    metadata.serverUrl = serverUrl
                    metadata.size = file.size
                    
                    CCUtility.insertTypeFileIconName(file.fileName, metadata: metadata)
                                    
                    realm.add(metadata, update: .all)
                    
                    // Directory
                    if file.directory {
                            
                        let directory = tableDirectory()
                        
                        directory.account = account
                        directory.e2eEncrypted = file.e2eEncrypted
                        directory.favorite = file.favorite
                        directory.ocId = file.ocId
                        directory.permissions = file.permissions
                        directory.serverUrl = CCUtility.stringAppendServerUrl(serverUrl, addFileName: file.fileName)
                        
                        realm.add(directory, update: .all)
                    }
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return
        }
        
        self.setDateReadDirectory(serverUrl: serverUrl, account: account)
    }
    
    @objc func deleteMetadata(predicate: NSPredicate) {
        
        var directoryToClearDate = [String:String]()
        
        let realm = try! Realm()

        realm.beginWrite()

        let results = realm.objects(tableMetadata.self).filter(predicate)
        
        for result in results {
            directoryToClearDate[result.serverUrl] = result.account
        }
        
        realm.delete(results)
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return
        }
        
        for (serverUrl, account) in directoryToClearDate {
            self.setDateReadDirectory(serverUrl: serverUrl, account: account)
        }
    }
    
    @objc func moveMetadata(ocId: String, serverUrlTo: String) {
        
        let realm = try! Realm()

        do {
            try realm.write {
                let results = realm.objects(tableMetadata.self).filter("ocId == %@", ocId)
                for result in results {
                    result.serverUrl = serverUrlTo
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return
        }        
    }
    
    @objc func addMetadataServerUrl(ocId: String, serverUrl: String) {
        
        let realm = try! Realm()
        
        do {
            try realm.write {
                let results = realm.objects(tableMetadata.self).filter("ocId == %@", ocId)
                for result in results {
                    result.serverUrl = serverUrl
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return
        }
    }
    
    @objc func renameMetadata(fileNameTo: String, ocId: String) -> tableMetadata? {
        
        var result :tableMetadata?
        let realm = try! Realm()
        
        do {
            try realm.write {
                result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first
                if result != nil {
                    result!.fileName = fileNameTo
                    result!.fileNameView = fileNameTo
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return nil
        }
        
        if result == nil {
            return nil
        }
        
        self.setDateReadDirectory(serverUrl: result!.serverUrl, account: result!.account)
        return tableMetadata.init(value: result!)
    }
    
    @objc func updateMetadata(_ metadata: tableMetadata) -> tableMetadata? {
        
        let account = metadata.account
        let serverUrl = metadata.serverUrl
        
        let realm = try! Realm()

        do {
            try realm.write {
                realm.add(metadata, update: .all)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return nil
        }
        
        self.setDateReadDirectory(serverUrl: serverUrl, account: account)
        
        return tableMetadata.init(value: metadata)
    }
    
    @objc func copyMetadata(_ object: tableMetadata) -> tableMetadata? {
        
        return tableMetadata.init(value: object)
    }
    
    @objc func setMetadataSession(_ session: String?, sessionError: String?, sessionSelector: String?, sessionTaskIdentifier: Int, status: Int, predicate: NSPredicate) {
        
        let realm = try! Realm()

        realm.beginWrite()

        guard let result = realm.objects(tableMetadata.self).filter(predicate).first else {
            realm.cancelWrite()
            return
        }
        
        if let session = session {
            result.session = session
        }
        if let sessionError = sessionError {
            result.sessionError = sessionError
        }
        if let sessionSelector = sessionSelector {
            result.sessionSelector = sessionSelector
        }
        
        result.sessionTaskIdentifier = sessionTaskIdentifier
        result.status = status

        let account = result.account
        let serverUrl = result.serverUrl
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return
        }
        
        // Update Date Read Directory
        self.setDateReadDirectory(serverUrl: serverUrl, account: account)
    }
    
    @objc func setMetadataFavorite(ocId: String, favorite: Bool) {
        
        let realm = try! Realm()

        realm.beginWrite()

        guard let result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first else {
            realm.cancelWrite()
            return
        }
        
        result.favorite = favorite

        let account = result.account
        let serverUrl = result.serverUrl
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return
        }
        
        // Update Date Read Directory
        setDateReadDirectory(serverUrl: serverUrl, account: account)
    }
    
    @objc func setMetadataFileNameView(serverUrl: String, fileName: String, newFileNameView: String, account: String) {
        
        let realm = try! Realm()

        realm.beginWrite()

        guard let result = realm.objects(tableMetadata.self).filter("account == %@ AND serverUrl == %@ AND fileName == %@", account, serverUrl, fileName).first else {
            realm.cancelWrite()
            return
        }
                
        result.fileNameView = newFileNameView
        
        let account = result.account
        let serverUrl = result.serverUrl
    
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return
        }
    
        // Update Date Read Directory
        setDateReadDirectory(serverUrl: serverUrl, account: account)
    }
    
    @objc func getMetadata(predicate: NSPredicate) -> tableMetadata? {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableMetadata.self).filter(predicate).first else {
            return nil
        }
        
        return tableMetadata.init(value: result)
    }
    
    @objc func getMetadata(predicate: NSPredicate, sorted: String, ascending: Bool) -> tableMetadata? {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results = realm.objects(tableMetadata.self).filter(predicate).sorted(byKeyPath: sorted, ascending: ascending)
        
        if (results.count > 0) {
            return tableMetadata.init(value: results[0])
        } else {
            return nil
        }
    }
    
    @objc func getMetadatas(predicate: NSPredicate, sorted: String?, ascending: Bool) -> [tableMetadata]? {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results : Results<tableMetadata>
        
        if let sorted = sorted {
            
            if (tableMetadata().objectSchema.properties.contains { $0.name == sorted }) {
                results = realm.objects(tableMetadata.self).filter(predicate).sorted(byKeyPath: sorted, ascending: ascending)
            } else {
                results = realm.objects(tableMetadata.self).filter(predicate)
            }
            
        } else {
            
            results = realm.objects(tableMetadata.self).filter(predicate)
        }
        
        if (results.count > 0) {
            return Array(results.map { tableMetadata.init(value:$0) })
        } else {
            return nil
        }
    }
    
    @objc func getMetadataAtIndex(predicate: NSPredicate, sorted: String, ascending: Bool, index: Int) -> tableMetadata? {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results = realm.objects(tableMetadata.self).filter(predicate).sorted(byKeyPath: sorted, ascending: ascending)
        
        if (results.count > 0  && results.count > index) {
            return tableMetadata.init(value: results[index])
        } else {
            return nil
        }
    }
    
    @objc func getMetadataInSessionFromFileName(_ fileName: String, serverUrl: String, taskIdentifier: Int) -> tableMetadata? {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableMetadata.self).filter("serverUrl == %@ AND fileName == %@ AND session != '' AND sessionTaskIdentifier == %d", serverUrl, fileName, taskIdentifier).first else {
            return nil
        }
        
        return tableMetadata.init(value: result)
    }
    
    @objc func getTableMetadatasDirectoryFavoriteIdentifierRank(account: String) -> [String:NSNumber] {
        
        var listIdentifierRank = [String:NSNumber]()

        let realm = try! Realm()
        realm.refresh()
        
        var counter = 10 as Int64
        
        let results = realm.objects(tableMetadata.self).filter("account == %@ AND directory == true AND favorite == true", account).sorted(byKeyPath: "fileNameView", ascending: true)
        
        for result in results {
            counter += 1
            listIdentifierRank[result.ocId] = NSNumber(value: Int64(counter))
        }
        
        return listIdentifierRank
    }
    
    @objc func clearMetadatasUpload(account: String) {
        
        let realm = try! Realm()
        
        do {
            try realm.write {
                
                let results = realm.objects(tableMetadata.self).filter("account == %@ AND (status == %d OR status == %@)", account, k_metadataStatusWaitUpload, k_metadataStatusUploadError)
                realm.delete(results)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func readMarkerMetadata(account: String, fileId: String) {
        
        let realm = try! Realm()
        
        realm.beginWrite()
        
        let results = realm.objects(tableMetadata.self).filter("account == %@ AND fileId == %@", account, fileId)
        for result in results {
            result.commentsUnread = false
        }
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    //MARK: -
    //MARK: Table Media
 
    @objc func getTableMedia(predicate: NSPredicate) -> tableMetadata? {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableMedia.self).filter(predicate).first else {
            return nil
        }
        
        return tableMetadata.init(value: result)
    }
   
    @objc func getTablesMedia(account: String) -> [tableMetadata]? {
        
        let realm = try! Realm()
        realm.refresh()
        
        let sortProperties = [SortDescriptor(keyPath: "date", ascending: false), SortDescriptor(keyPath: "fileNameView", ascending: false)]
        let results = realm.objects(tableMedia.self).filter(NSPredicate(format: "account == %@", account)).sorted(by: sortProperties)
        if results.count == 0 {
            return nil
        }
        
        let serversUrlLocked = realm.objects(tableDirectory.self).filter(NSPredicate(format: "account == %@ AND lock == true", account)).map { $0.serverUrl } as Array
        
        var metadatas = [tableMetadata]()
        var oldServerUrl = ""
        var isValidMetadata = true

        for result in results {
            let metadata = tableMetadata.init(value: result)
        
            // Verify Lock
            if (serversUrlLocked.count > 0) && (metadata.serverUrl != oldServerUrl) {
                var foundLock = false
                oldServerUrl = metadata.serverUrl
                for serverUrlLocked in serversUrlLocked {
                    if metadata.serverUrl.contains(serverUrlLocked) {
                        foundLock = true
                        break
                    }
                }
                isValidMetadata = !foundLock
            }
            if isValidMetadata {
                metadatas.append(tableMetadata.init(value: metadata))
            }
        }
      
        return metadatas
    }
    
    func createTableMedia(_ metadatasSource: [tableMetadata], lteDate: Date, gteDate: Date, account: String) -> (isDifferent: Bool, newInsert: Int) {

        let realm = try! Realm()
        realm.refresh()
        
        var numDelete: Int = 0
        var numInsert: Int = 0
        
        var etagsDelete = [String]()
        var etagsInsert = [String]()
        
        var isDifferent: Bool = false
        var newInsert: Int = 0
        
        var oldServerUrl = ""
        var isValidMetadata = true
        
        var metadatas = [tableMetadata]()
        
        let serversUrlLocked = realm.objects(tableDirectory.self).filter(NSPredicate(format: "account == %@ AND lock == true", account)).map { $0.serverUrl } as Array
        if (serversUrlLocked.count > 0) {
            for metadata in metadatasSource {
                // Verify Lock
                if (metadata.serverUrl != oldServerUrl) {
                    var foundLock = false
                    oldServerUrl = metadata.serverUrl
                    for serverUrlLocked in serversUrlLocked {
                        if metadata.serverUrl.contains(serverUrlLocked) {
                            foundLock = true
                            break
                        }
                    }
                    isValidMetadata = !foundLock
                }
                if isValidMetadata {
                    metadatas.append(tableMetadata.init(value: metadata))
                }
            }
        } else {
            metadatas = metadatasSource
        }
        
        do {
            try realm.write {
                
                // DELETE
                let results = realm.objects(tableMedia.self).filter("account == %@ AND date >= %@ AND date <= %@", account, gteDate, lteDate)
                etagsDelete = Array(results.map { $0.etag })
                numDelete = results.count
                
                // INSERT
                let photos = Array(metadatas.map { tableMedia.init(value:$0) })
                etagsInsert = Array(photos.map { $0.etag })
                numInsert = photos.count
                
                // CALCULATE DIFFERENT RETURN
                if etagsDelete.count == etagsInsert.count && etagsDelete.sorted() == etagsInsert.sorted() {
                    isDifferent = false
                } else {
                    isDifferent = true
                    newInsert = numInsert - numDelete
                    
                    realm.delete(results)
                    realm.add(photos, update: .all)
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            realm.cancelWrite()
        }
        
        return(isDifferent, newInsert)
    }
    
    @objc func getTableMediaDate(account: String, order: ComparisonResult) -> Date {
        
        let realm = try! Realm()
        realm.refresh()
        
        if let entities = realm.objects(tableMedia.self).filter("account == %@", account).max(by: { $0.date.compare($1.date as Date) == order }) {
            return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: entities.date as Date)!
        }
        
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
    }
    
    //MARK: -
    //MARK: Table Photo Library
    
    @objc func addPhotoLibrary(_ assets: [PHAsset], account: String) -> Bool {
        
        let realm = try! Realm()

        if realm.isInWriteTransaction {
            
            print("[LOG] Could not write to database, addPhotoLibrary is already in write transaction")
            return false
            
        } else {
        
            do {
                try realm.write {
                
                    var creationDateString = ""

                    for asset in assets {
                    
                        let addObject = tablePhotoLibrary()
                    
                        addObject.account = account
                        addObject.assetLocalIdentifier = asset.localIdentifier
                        addObject.mediaType = asset.mediaType.rawValue
                    
                        if let creationDate = asset.creationDate {
                            addObject.creationDate = creationDate as NSDate
                            creationDateString = String(describing: creationDate)
                        } else {
                            creationDateString = ""
                        }
                        
                        if let modificationDate = asset.modificationDate {
                            addObject.modificationDate = modificationDate as NSDate
                        }
                        
                        addObject.idAsset = "\(account)\(asset.localIdentifier)\(creationDateString)"

                        realm.add(addObject, update: .all)
                    }
                }
            } catch let error {
                print("[LOG] Could not write to database: ", error)
                return false
            }
        }
        
        return true
    }
    
    @objc func getPhotoLibraryIdAsset(image: Bool, video: Bool, account: String) -> [String]? {
        
        let realm = try! Realm()
        realm.refresh()
        
        var predicate = NSPredicate()
        
        if (image && video) {
         
            predicate = NSPredicate(format: "account == %@ AND (mediaType == %d OR mediaType == %d)", account, PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
            
        } else if (image) {
            
            predicate = NSPredicate(format: "account == %@ AND mediaType == %d", account, PHAssetMediaType.image.rawValue)

        } else if (video) {
            
            predicate = NSPredicate(format: "account == %@ AND mediaType == %d", account, PHAssetMediaType.video.rawValue)
        }
        
        let results = realm.objects(tablePhotoLibrary.self).filter(predicate)
        
        let idsAsset = results.map { $0.idAsset }
        
        return Array(idsAsset)
    }
    
    @objc func getPhotoLibrary(predicate: NSPredicate) -> [tablePhotoLibrary] {
        
        let realm = try! Realm()

        let results = realm.objects(tablePhotoLibrary.self).filter(predicate)
        
        return Array(results.map { tablePhotoLibrary.init(value:$0) })
    }
    
    //MARK: -
    //MARK: Table Share
    
    @objc func addShare(account: String, activeUrl: String, items: [OCSharedDto]) -> [tableShare] {
        
        let realm = try! Realm()
        realm.beginWrite()

        for sharedDto in items {
            
            let addObject = tableShare()
            let fullPath = CCUtility.getHomeServerUrlActiveUrl(activeUrl) + "\(sharedDto.path!)"
            let fileName = NSString(string: fullPath).lastPathComponent
            var serverUrl = NSString(string: fullPath).substring(to: (fullPath.count - fileName.count - 1))
            if serverUrl.hasSuffix("/") {
                serverUrl = NSString(string: serverUrl).substring(to: (serverUrl.count - 1))
            }
            
            addObject.account = account
            addObject.displayNameFileOwner = sharedDto.displayNameFileOwner
            addObject.displayNameOwner = sharedDto.displayNameOwner
            if sharedDto.expirationDate > 0 {
                addObject.expirationDate =  Date(timeIntervalSince1970: TimeInterval(sharedDto.expirationDate)) as NSDate
            }
            addObject.fileParent = sharedDto.fileParent
            addObject.fileTarget = sharedDto.fileTarget
            addObject.hideDownload = sharedDto.hideDownload
            addObject.idRemoteShared = sharedDto.idRemoteShared
            addObject.isDirectory = sharedDto.isDirectory
            addObject.itemSource = sharedDto.itemSource
            addObject.label = sharedDto.label
            addObject.mailSend = sharedDto.mailSend
            addObject.mimeType = sharedDto.mimeType
            addObject.note = sharedDto.note
            addObject.path = sharedDto.path
            addObject.permissions = sharedDto.permissions
            addObject.parent = sharedDto.parent
            addObject.sharedDate = Date(timeIntervalSince1970: TimeInterval(sharedDto.sharedDate)) as NSDate
            addObject.shareType = sharedDto.shareType
            addObject.shareWith = sharedDto.shareWith
            addObject.shareWithDisplayName = sharedDto.shareWithDisplayName
            addObject.storage = sharedDto.storage
            addObject.storageID = sharedDto.storageID
            addObject.token = sharedDto.token
            addObject.url = sharedDto.url
            addObject.uidOwner = sharedDto.uidOwner
            addObject.uidFileOwner = sharedDto.uidFileOwner
            
            addObject.fileName = fileName
            addObject.serverUrl = serverUrl
            
            realm.add(addObject, update: .all)
        }
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
        
        return self.getTableShares(account: account)
    }

    @objc func getTableShares(account: String) -> [tableShare] {
        
        let realm = try! Realm()
        realm.refresh()
        
        let sortProperties = [SortDescriptor(keyPath: "shareType", ascending: false), SortDescriptor(keyPath: "idRemoteShared", ascending: false)]
        let results = realm.objects(tableShare.self).filter("account == %@", account).sorted(by: sortProperties)
        
        return Array(results.map { tableShare.init(value:$0) })
    }
    
    func getTableShares(metadata: tableMetadata) -> (firstShareLink: tableShare?,  share: [tableShare]?) {
        
        let realm = try! Realm()
        realm.refresh()
        
        let sortProperties = [SortDescriptor(keyPath: "shareType", ascending: false), SortDescriptor(keyPath: "idRemoteShared", ascending: false)]
        
        let firstShareLink = realm.objects(tableShare.self).filter("account == %@ AND serverUrl == %@ AND fileName == %@ AND shareType == %d", metadata.account, metadata.serverUrl, metadata.fileName, Int(shareTypeLink.rawValue)).first
        if firstShareLink == nil {
            let results = realm.objects(tableShare.self).filter("account == %@ AND serverUrl == %@ AND fileName == %@", metadata.account, metadata.serverUrl, metadata.fileName).sorted(by: sortProperties)
            return(firstShareLink: firstShareLink, share: Array(results.map { tableShare.init(value:$0) }))
        } else {
            let results = realm.objects(tableShare.self).filter("account == %@ AND serverUrl == %@ AND fileName == %@ AND idRemoteShared != %d", metadata.account, metadata.serverUrl, metadata.fileName, firstShareLink!.idRemoteShared).sorted(by: sortProperties)
            return(firstShareLink: firstShareLink, share: Array(results.map { tableShare.init(value:$0) }))
        }
    }
    
    func getTableShare(account: String, idRemoteShared: Int) -> tableShare? {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableShare.self).filter("account = %@ AND idRemoteShared = %d", account, idRemoteShared).first else {
            return nil
        }
        
        return tableShare.init(value: result)
    }
    
    @objc func getTableShares(account: String, serverUrl: String) -> [tableShare] {
        
        let realm = try! Realm()
        realm.refresh()
        
        let sortProperties = [SortDescriptor(keyPath: "shareType", ascending: false), SortDescriptor(keyPath: "idRemoteShared", ascending: false)]
        let results = realm.objects(tableShare.self).filter("account == %@ AND serverUrl == %@", account, serverUrl).sorted(by: sortProperties)

        return Array(results.map { tableShare.init(value:$0) })
    }
    
    @objc func getTableShares(account: String, serverUrl: String, fileName: String) -> [tableShare] {
        
        let realm = try! Realm()
        realm.refresh()
        
        let sortProperties = [SortDescriptor(keyPath: "shareType", ascending: false), SortDescriptor(keyPath: "idRemoteShared", ascending: false)]
        let results = realm.objects(tableShare.self).filter("account == %@ AND serverUrl == %@ AND fileName == %@", account, serverUrl, fileName).sorted(by: sortProperties)
        
        return Array(results.map { tableShare.init(value:$0) })
    }
    
    @objc func deleteTableShare(account: String, idRemoteShared: Int) {
        
        let realm = try! Realm()
        
        realm.beginWrite()
        
        let result = realm.objects(tableShare.self).filter("account == %@ AND idRemoteShared == %d", account, idRemoteShared)
        realm.delete(result)
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func deleteTableShare(account: String) {
        
        let realm = try! Realm()
        
        realm.beginWrite()
        
        let result = realm.objects(tableShare.self).filter("account == %@", account)
        realm.delete(result)
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    //MARK: -
    //MARK: Table Tag
    
    @objc func addTag(_ ocId: String ,tagIOS: Data?, account: String) {
        
        let realm = try! Realm()
        
        do {
            try realm.write {
                
                // Add new
                let addObject = tableTag()
                    
                addObject.account = account
                addObject.ocId = ocId
                addObject.tagIOS = tagIOS
    
                realm.add(addObject, update: .all)
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func deleteTag(_ ocId: String) {
        
        let realm = try! Realm()
        
        realm.beginWrite()
        
        let result = realm.objects(tableTag.self).filter("ocId == %@", ocId)
        realm.delete(result)
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func getTags(predicate: NSPredicate) -> [tableTag] {
        
        let realm = try! Realm()
        realm.refresh()

        let results = realm.objects(tableTag.self).filter(predicate)
        
        return Array(results.map { tableTag.init(value:$0) })
    }
    
    @objc func getTag(predicate: NSPredicate) -> tableTag? {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableTag.self).filter(predicate).first else {
            return nil
        }
        
        return tableTag.init(value: result)
    }
    
    //MARK: -
    //MARK: Table Trash
    
    @objc func addTrashs(_ trashs: [tableTrash]) {
        
        let realm = try! Realm()
        
        do {
            try realm.write {
                for trash in trashs {
                    realm.add(trash, update: .all)
                }
            }
        } catch let error {
            print("[LOG] Could not write to database: ", error)
            return
        }
    }
    
    @objc func deleteTrash(filePath: String?, account: String) {
        
        let realm = try! Realm()
        var predicate = NSPredicate()

        realm.beginWrite()
        
        if filePath == nil {
            predicate = NSPredicate(format: "account == %@", account)
        } else {
            predicate = NSPredicate(format: "account == %@ AND filePath == %@", account, filePath!)
        }
        
        let results = realm.objects(tableTrash.self).filter(predicate)
        realm.delete(results)
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func deleteTrash(fileId: String?, account: String) {
        
        let realm = try! Realm()
        var predicate = NSPredicate()
        
        realm.beginWrite()
        
        if fileId == nil {
            predicate = NSPredicate(format: "account == %@", account)
        } else {
            predicate = NSPredicate(format: "account == %@ AND fileId == %@", account, fileId!)
        }
        
        let result = realm.objects(tableTrash.self).filter(predicate)
        realm.delete(result)
        
        do {
            try realm.commitWrite()
        } catch let error {
            print("[LOG] Could not write to database: ", error)
        }
    }
    
    @objc func getTrash(filePath: String, sorted: String, ascending: Bool, account: String) -> [tableTrash]? {
        
        let realm = try! Realm()
        realm.refresh()
        
        let results = realm.objects(tableTrash.self).filter("account == %@ AND filePath == %@", account, filePath).sorted(byKeyPath: sorted, ascending: ascending)

        return Array(results.map { tableTrash.init(value:$0) })
    }
    
    @objc func getTrashItem(fileId: String, account: String) -> tableTrash? {
        
        let realm = try! Realm()
        realm.refresh()
        
        guard let result = realm.objects(tableTrash.self).filter("account == %@ AND fileId == %@", account, fileId).first else {
            return nil
        }
        
        return tableTrash.init(value: result)
    }
    
    //MARK: -
}
