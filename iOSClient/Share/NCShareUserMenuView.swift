//
//  NCShareUserMenuView.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 25/07/2019.
//  Copyright © 2019 Marino Faggiana. All rights reserved.
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

import Foundation
import FSCalendar

class NCShareUserMenuView: UIView, UIGestureRecognizerDelegate, NCShareNetworkingDelegate, FSCalendarDelegate, FSCalendarDelegateAppearance {
    
    @IBOutlet weak var switchCanReshare: UISwitch!
    @IBOutlet weak var labelCanReshare: UILabel!
    
    @IBOutlet weak var switchSetExpirationDate: UISwitch!
    @IBOutlet weak var labelSetExpirationDate: UILabel!
    @IBOutlet weak var fieldSetExpirationDate: UITextField!
    
    @IBOutlet weak var imageNoteToRecipient: UIImageView!
    @IBOutlet weak var labelNoteToRecipient: UILabel!
    @IBOutlet weak var fieldNoteToRecipient: UITextField!
    
    @IBOutlet weak var buttonUnshare: UIButton!
    @IBOutlet weak var labelUnshare: UILabel!
    @IBOutlet weak var imageUnshare: UIImageView!
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    public let width: CGFloat = 250
    public let height: CGFloat = 260
    private var tableShare: tableShare?
    public var metadata: tableMetadata?
    
    public var viewWindow: UIView?
    public var viewWindowCalendar: UIView?
    
    override func awakeFromNib() {
        
        self.frame.size.width = width
        self.frame.size.height = height
        
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = 5
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 2, height: 2)
        layer.shadowOpacity = 0.2
        
        switchCanReshare.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        switchCanReshare.onTintColor = NCBrandColor.sharedInstance.brand
        switchSetExpirationDate.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        switchSetExpirationDate.onTintColor = NCBrandColor.sharedInstance.brand
        
        fieldSetExpirationDate.inputView = UIView()
        
        imageNoteToRecipient.image = CCGraphics.changeThemingColorImage(UIImage.init(named: "file_txt"), width: 100, height: 100, color: UIColor(red: 76/255, green: 76/255, blue: 76/255, alpha: 1))
        imageUnshare.image = CCGraphics.changeThemingColorImage(UIImage.init(named: "trash"), width: 100, height: 100, color: UIColor(red: 76/255, green: 76/255, blue: 76/255, alpha: 1))
    }
    
    func unLoad() {
        viewWindowCalendar?.removeFromSuperview()
        viewWindow?.removeFromSuperview()
        
        viewWindowCalendar = nil
        viewWindow = nil
    }
    
    func reloadData(idRemoteShared: Int) {
        
        tableShare = NCManageDatabase.sharedInstance.getTableShare(account: metadata!.account, idRemoteShared: idRemoteShared)
        guard let tableShare = self.tableShare else { return }

        // Can reshare
        let canReshare = UtilsFramework.isPermission(toCanShare: tableShare.permissions)
        if canReshare {
            switchCanReshare.setOn(true, animated: false)
        } else {
            switchCanReshare.setOn(false, animated: false)
        }
        
        // Set expiration date
        if tableShare.expirationDate != nil {
            switchSetExpirationDate.setOn(true, animated: false)
            fieldSetExpirationDate.isEnabled = true
            
            let dateFormatter = DateFormatter()
            dateFormatter.formatterBehavior = .behavior10_4
            dateFormatter.dateStyle = .medium
            fieldSetExpirationDate.text = dateFormatter.string(from: tableShare.expirationDate! as Date)
        } else {
            switchSetExpirationDate.setOn(false, animated: false)
            fieldSetExpirationDate.isEnabled = false
            fieldSetExpirationDate.text = ""
        }
        
        // Note to recipient
        fieldNoteToRecipient.text = tableShare.note
    }
    
    // MARK: - IBAction

    // Can reshare
    @IBAction func switchCanReshareChanged(sender: UISwitch) {
        
        guard let tableShare = self.tableShare else { return }
        
        let canEdit = UtilsFramework.isAnyPermission(toEdit: tableShare.permissions)
        var permission: Int = 0
        
        if sender.isOn {
            if canEdit {
                permission = UtilsFramework.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: true, andIsFolder: metadata!.directory)
            } else {
                permission = UtilsFramework.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: true, andIsFolder: metadata!.directory)
            }
        } else {
            if canEdit {
                permission = UtilsFramework.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: false, andIsFolder: metadata!.directory)
            } else {
                permission = UtilsFramework.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: false, andIsFolder: metadata!.directory)
            }
        }
    
        let networking = NCShareNetworking.init(account: metadata!.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
        networking.updateShare(idRemoteShared: tableShare.idRemoteShared, password: nil, permission: permission, note: nil, expirationTime: nil, hideDownload: tableShare.hideDownload)
    }
    
    // Set expiration date
    @IBAction func switchSetExpirationDate(sender: UISwitch) {
        
        guard let tableShare = self.tableShare else { return }
        
        if sender.isOn {
            fieldSetExpirationDate.isEnabled = true
            fieldSetExpirationDate(sender: fieldSetExpirationDate)
        } else {
            let networking = NCShareNetworking.init(account: metadata!.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
            networking.updateShare(idRemoteShared: tableShare.idRemoteShared, password: nil, permission: 0, note: nil, expirationTime: "", hideDownload: tableShare.hideDownload)
        }
    }
    
    @IBAction func fieldSetExpirationDate(sender: UITextField) {
        
        let calendar = NCShareCommon.sharedInstance.openCalendar(view: self, width: width, height: height)
        calendar.calendarView.delegate = self
        viewWindowCalendar = calendar.viewWindow
    }
    
    // Note to recipient
    @IBAction func fieldNoteToRecipientDidEndOnExit(textField: UITextField) {
        
        guard let tableShare = self.tableShare else { return }
        if fieldNoteToRecipient.text == nil { return }
        
        let networking = NCShareNetworking.init(account: metadata!.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
        networking.updateShare(idRemoteShared: tableShare.idRemoteShared, password: nil, permission: 0, note: fieldNoteToRecipient.text, expirationTime: nil, hideDownload: tableShare.hideDownload)
    }
    
    // Unshare
    @IBAction func buttonUnshare(sender: UIButton) {
        
        guard let tableShare = self.tableShare else { return }
        
        let networking = NCShareNetworking.init(account: metadata!.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
        
        networking.unShare(idRemoteShared: tableShare.idRemoteShared)
    }
    
    // MARK: - Delegate networking
    
    func readShareCompleted() {
        reloadData(idRemoteShared: tableShare?.idRemoteShared ?? 0)
    }
    
    func shareCompleted() {
        unLoad()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadDataNCShare"), object: nil, userInfo: nil)
    }
    
    func unShareCompleted() {
        unLoad()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadDataNCShare"), object: nil, userInfo: nil)
    }
    
    func updateShareWithError(idRemoteShared: Int) {
        reloadData(idRemoteShared: idRemoteShared)
    }
    
    func getUserAndGroup(items: [OCShareUser]?) { }
    
    // MARK: - Delegate calendar

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        if monthPosition == .previous || monthPosition == .next {
            calendar.setCurrentPage(date, animated: true)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.formatterBehavior = .behavior10_4
            dateFormatter.dateStyle = .medium
            fieldSetExpirationDate.text = dateFormatter.string(from:date)
            fieldSetExpirationDate.endEditing(true)
            
            viewWindowCalendar?.removeFromSuperview()
            
            guard let tableShare = self.tableShare else { return }
            
            let networking = NCShareNetworking.init(account: metadata!.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
            dateFormatter.dateFormat = "YYYY-MM-dd"
            let expirationTime = dateFormatter.string(from: date)
            networking.updateShare(idRemoteShared: tableShare.idRemoteShared, password: nil, permission: 0, note: nil, expirationTime: expirationTime, hideDownload: tableShare.hideDownload)
        }
    }
    
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        return date > Date()
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        if date > Date() {
            return UIColor(red: 60/255, green: 60/255, blue: 60/255, alpha: 1)
        } else {
            return UIColor(red: 190/255, green: 190/255, blue: 190/255, alpha: 1)
        }
    }
}