//
//  NCService.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 14/03/18.
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

import Foundation
import SVGKit
import NCCommunication

class NCService: NSObject {
    @objc static let sharedInstance: NCService = {
        let instance = NCService()
        return instance
    }()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //MARK: -
    //MARK: Start Services API NC
    
    @objc public func startRequestServicesServer() {
   
        if (appDelegate.activeAccount == nil || appDelegate.activeAccount.count == 0 || appDelegate.maintenanceMode == true) {
            return
        }
        
        self.requestUserProfile()
        self.requestServerStatus()
    }

    //MARK: -
    //MARK: Internal request Service API NC
    
    private func requestUserProfile() {
        
        if (appDelegate.activeAccount == nil || appDelegate.activeAccount.count == 0 || appDelegate.maintenanceMode == true) {
            return
        }
        
        OCNetworking.sharedManager().getUserProfile(withAccount: appDelegate.activeAccount, completion: { (account, userProfile, message, errorCode) in
            
            if errorCode == 0 && account == self.appDelegate.activeAccount {
                
                // Update User (+ userProfile.id) & active account & account network
                guard let tableAccount = NCManageDatabase.sharedInstance.setAccountUserProfile(userProfile!, HCProperties: false) else {
                    self.appDelegate.messageNotification("Accopunt", description: "Internal error : account not found on DB", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.error, errorCode: Int(k_CCErrorInternalError))
                    return
                }
                
                let user = tableAccount.user
                let url = tableAccount.url
                
                self.appDelegate.settingActiveAccount(tableAccount.account, activeUrl: tableAccount.url, activeUser: tableAccount.user, activeUserID: tableAccount.userID, activePassword: CCUtility.getPassword(tableAccount.account))
                
                // Call func thath required the userdID
                self.appDelegate.activeFavorites.listingFavorites()
                self.appDelegate.activeMedia.reloadDataSource(loadNetworkDatasource: true)
                NCFunctionMain.sharedInstance.synchronizeOffline()
                
                DispatchQueue.global().async {
                    
                    let avatarUrl = "\(self.appDelegate.activeUrl!)/index.php/avatar/\(self.appDelegate.activeUser!)/\(k_avatar_size)".addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
                    let fileNamePath = CCUtility.getDirectoryUserData() + "/" + CCUtility.getStringUser(user, activeUrl: url) + "-" + self.appDelegate.activeUser + ".png"
                    
                    OCNetworking.sharedManager()?.downloadContents(ofUrl: avatarUrl, completion: { (data, message, errorCode) in
                        if errorCode == 0 {
                            if let image = UIImage(data: data!) {
                                try? FileManager.default.removeItem(atPath: fileNamePath)
                                if let data = image.pngData() {
                                    try? data.write(to: URL(fileURLWithPath: fileNamePath))
                                }
                            }
                        }
                    })
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "changeUserProfile"), object: nil)
                    }
                }
                
                // Get Capabilities
                self.requestServerCapabilities()
                
            } else {
                
                if errorCode == kOCErrorServerUnauthorized || errorCode == kOCErrorServerForbidden {
                    OCNetworking.sharedManager()?.checkRemoteUser(account)
                }
                
                print("[LOG] It has been changed user during networking process, error.")
            }
        })
    }
    
    private func requestServerStatus() {
        
        NCCommunication.sharedInstance.getServerStatus(urlString: appDelegate.activeUrl) { (serverProductName, serverVersion, versionMajor, versionMinor, versionMicro, extendedSupport, errorCode, errorMessage) in
            if errorCode == 0 {
                if extendedSupport == false {
                    if serverProductName == "owncloud" {
                        self.appDelegate.messageNotification("_warning_", description: "_warning_owncloud_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: Int(k_CCErrorInternalError))
                    } else if versionMajor <= k_nextcloud_unsupported {
                        self.appDelegate.messageNotification("_warning_", description: "_warning_unsupported_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: Int(k_CCErrorInternalError))
                    }
                }
            }
        }
    }
    
    private func requestServerCapabilities() {
        
        if (appDelegate.activeAccount == nil || appDelegate.activeAccount.count == 0 || appDelegate.maintenanceMode == true) {
            return
        }
        
        OCNetworking.sharedManager().getCapabilitiesWithAccount(appDelegate.activeAccount, completion: { (account, capabilities, message, errorCode) in
            
            if errorCode == 0 && account == self.appDelegate.activeAccount {
                
                // Update capabilities db
                NCManageDatabase.sharedInstance.addCapabilities(capabilities!, account: account!)
                
                // ------ THEMING -----------------------------------------------------------------------
                
                if (NCBrandOptions.sharedInstance.use_themingBackground && capabilities!.themingBackground != "") {
                    
                    // Download Theming Background
                    DispatchQueue.global().async {
                        
                        // Download Logo
                        if NCBrandOptions.sharedInstance.use_themingLogo {
                            let fileNameThemingLogo = CCUtility.getStringUser(self.appDelegate.activeUser, activeUrl: self.appDelegate.activeUrl) + "-themingLogo.png"
                            NCUtility.sharedInstance.convertSVGtoPNGWriteToUserData(svgUrlString: capabilities!.themingLogo, fileName: fileNameThemingLogo, width: 40, rewrite: true, closure: { (imageNamePath) in })
                        }
                        
                        let backgroundURL = capabilities!.themingBackground!.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
                        let fileNamePath = CCUtility.getDirectoryUserData() + "/" + CCUtility.getStringUser(self.appDelegate.activeUser, activeUrl: self.appDelegate.activeUrl) + "-themingBackground.png"
                        
                        OCNetworking.sharedManager()?.downloadContents(ofUrl: backgroundURL, completion: { (data, message, errorCode) in
                            if errorCode == 0 {
                                if let image = UIImage(data: data!) {
                                    try? FileManager.default.removeItem(atPath: fileNamePath)
                                    if let data = image.pngData() {
                                        try? data.write(to: URL(fileURLWithPath: fileNamePath))
                                    }
                                }
                            }
                        })
                        
                        DispatchQueue.main.async {
                            self.appDelegate.settingThemingColorBrand()
                        }
                    }
                    
                } else {
                    
                    self.appDelegate.settingThemingColorBrand()
                }
                
                // ------ SEARCH ------------------------------------------------------------------------
                
                if (NCManageDatabase.sharedInstance.getServerVersion(account: account!) != capabilities!.versionMajor && self.appDelegate.activeMain != nil) {
                    self.appDelegate.activeMain.cancelSearchBar()
                }
                
                // ------ GET OTHER SERVICE -------------------------------------------------------------
                
                // Get Notification
                if (capabilities!.isNotificationServerEnabled) {
                    
                    OCNetworking.sharedManager().getNotificationWithAccount(account!, completion: { (account, listOfNotifications, message, errorCode) in
                        
                        if errorCode == 0 && account == self.appDelegate.activeAccount {
                            
                            DispatchQueue.global().async {
                                
                                let sortedListOfNotifications = (listOfNotifications! as NSArray).sortedArray(using: [
                                    NSSortDescriptor(key: "date", ascending: false)
                                    ])
                                
                                var old = ""
                                var new = ""
                                
                                for notification in listOfNotifications! {
                                    // download icon
                                    let id = (notification as! OCNotifications).idNotification
                                    if let icon = (notification as! OCNotifications).icon {
                                        
                                        NCUtility.sharedInstance.convertSVGtoPNGWriteToUserData(svgUrlString: icon, fileName: nil, width: 25, rewrite: false, closure: { (imageNamePath) in })                                        
                                    }
                                    new = new + String(describing: id)
                                }
                                for notification in self.appDelegate.listOfNotifications! {
                                    let id = (notification as! OCNotifications).idNotification
                                    old = old + String(describing: id)
                                }
                                
                                DispatchQueue.main.async {
                                    
                                    if (new != old) {
                                        self.appDelegate.listOfNotifications = NSMutableArray.init(array: sortedListOfNotifications)
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "notificationReloadData"), object: nil)
                                    }
                                    
                                    // Update Main NavigationBar
                                    if (self.appDelegate.activeMain.isSelectedMode == false && self.appDelegate.activeMain != nil) {
                                        self.appDelegate.activeMain.setUINavigationBarDefault()
                                    }
                                }
                            }
                            
                        } else {
                            
                            // Update Main NavigationBar
                            if (self.appDelegate.activeMain.isSelectedMode == false && self.appDelegate.activeMain != nil) {
                                self.appDelegate.activeMain.setUINavigationBarDefault()
                            }
                        }
                    })
                    
                } else {
                    
                    // Remove all Notification
                    self.appDelegate.listOfNotifications.removeAllObjects()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "notificationReloadData"), object: nil)
                    // Update Main NavigationBar
                    if (self.appDelegate.activeMain != nil && self.appDelegate.activeMain.isSelectedMode == false) {
                        self.appDelegate.activeMain.setUINavigationBarDefault()
                    }
                }
                
                // Get External Sites
                if (capabilities!.isExternalSitesServerEnabled) {
                    
                    OCNetworking.sharedManager().getExternalSites(withAccount: account!, completion: { (account, listOfExternalSites, message, errorCode) in
                        if errorCode == 0 && account == self.appDelegate.activeAccount {
                            NCManageDatabase.sharedInstance.deleteExternalSites(account: account!)
                            for externalSites in listOfExternalSites! {
                                NCManageDatabase.sharedInstance.addExternalSites(externalSites as! OCExternalSites, account: account!)
                            }
                        } 
                    })
                   
                } else {
                    
                    NCManageDatabase.sharedInstance.deleteExternalSites(account: account!)
                }
                
                // Get Share Server
                if (capabilities!.isFilesSharingAPIEnabled && self.appDelegate.activeMain != nil) {
                    
                    OCNetworking.sharedManager()?.readShare(withAccount: account, completion: { (account, items, message, errorCode) in
                        if errorCode == 0 && account == self.appDelegate.activeAccount{
                            let itemsOCSharedDto = items as! [OCSharedDto]
                            NCManageDatabase.sharedInstance.deleteTableShare(account: account!)
                            self.appDelegate.shares = NCManageDatabase.sharedInstance.addShare(account: account!, activeUrl: self.appDelegate.activeUrl, items: itemsOCSharedDto)
                            self.appDelegate.activeMain?.tableView?.reloadData()
                            self.appDelegate.activeFavorites?.tableView?.reloadData()
                        } else {
                            self.appDelegate.messageNotification("_share_", description: message, visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.error, errorCode: errorCode)
                        }
                    })
                }
                
                // Get Handwerkcloud
                if (capabilities!.isHandwerkcloudEnabled) {
                    self.requestHC()
                }
              
            } else if errorCode != 0 {
                
                self.appDelegate.settingThemingColorBrand()
                
                if errorCode == kOCErrorServerUnauthorized || errorCode == kOCErrorServerForbidden {
                    OCNetworking.sharedManager()?.checkRemoteUser(account)
                }
                
            } else {
                print("[LOG] It has been changed user during networking process, error.")
                // Change Theming color
                self.appDelegate.settingThemingColorBrand()
            }
        })
    }
    
    @objc public func middlewarePing() {
        
        if (appDelegate.activeAccount == nil || appDelegate.activeAccount.count == 0 || appDelegate.maintenanceMode == true) {
            return
        }
    }
    
    //MARK: -
    //MARK: Thirt Part
    
    private func requestHC() {
        
        let professions = CCUtility.getHCBusinessType()
        if professions != nil && professions!.count > 0 {
            OCNetworking.sharedManager()?.putHCUserProfile(withAccount: appDelegate.activeAccount, serverUrl: appDelegate.activeUrl, address: nil, businesssize: nil, businesstype: professions, city: nil, company: nil, country: nil, displayname: nil, email: nil, phone: nil, role_: nil, twitter: nil, website: nil, zip: nil, completion: { (account, message, errorCode) in
                if errorCode == 0 && account == self.appDelegate.activeAccount {
                    CCUtility.setHCBusinessType(nil)
                    OCNetworking.sharedManager()?.getHCUserProfile(withAccount: self.appDelegate.activeAccount, serverUrl: self.appDelegate.activeUrl, completion: { (account, userProfile, message, errorCode) in
                        if errorCode == 0 && account == self.appDelegate.activeAccount {
                            _ = NCManageDatabase.sharedInstance.setAccountUserProfile(userProfile!, HCProperties: true)
                        }
                    })
                }
            })
        } else {
            OCNetworking.sharedManager()?.getHCUserProfile(withAccount: appDelegate.activeAccount, serverUrl: appDelegate.activeUrl, completion: { (account, userProfile, message, errorCode) in
                if errorCode == 0 && account == self.appDelegate.activeAccount {
                    _ = NCManageDatabase.sharedInstance.setAccountUserProfile(userProfile!, HCProperties: true)
                }
            })
        }
        
        OCNetworking.sharedManager()?.getHCFeatures(withAccount: appDelegate.activeAccount, serverUrl: appDelegate.activeUrl, completion: { (account, features, message, errorCode) in
            if errorCode == 0 && account == self.appDelegate.activeAccount {
                _ = NCManageDatabase.sharedInstance.setAccountHCFeatures(features!)
            }
        })
        
    }
}
