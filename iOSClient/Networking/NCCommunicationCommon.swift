//
//  NSCommunicationCommon.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 12/10/19.
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
import Alamofire

@objc public protocol NCCommunicationCommonDelegate {
    @objc func authenticationChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

class NCCommunicationCommon: NSObject, NCCommunicationBackgroundSessionDelegate {
   
    @objc static let sharedInstance: NCCommunicationCommon = {
        let instance = NCCommunicationCommon()
        return instance
    }()
    
    var username = ""
    var password = ""
    @objc public var userAgent: String?
    var capabilitiesGroup: String?
    
    // Protocol
    @objc public var authenticationChallengeDelegate: NCCommunicationCommonDelegate?
    
    // Session
    @objc let session_maximumConnectionsPerHost = 5
    @objc let session_description_download: String = "com.nextcloud.download.session"
    @objc let session_description_upload: String = "com.nextcloud.upload.session"
    @objc let session_extension: String = "com.nextcloud.session.extension"

    //MARK: - Setup
    
    @objc public func setup(username: String, password: String, userAgent: String?, capabilitiesGroup: String?, authenticationChallengeDelegate: NCCommunicationCommonDelegate?) {
        self.username = username
        self.password = password
        self.userAgent = userAgent
        self.capabilitiesGroup = capabilitiesGroup
        self.authenticationChallengeDelegate = authenticationChallengeDelegate
    }
    
    //MARK: - Authentication Challenge Delegate
    
    @objc public func authenticationChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if authenticationChallengeDelegate == nil {
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        } else {
            authenticationChallengeDelegate?.authenticationChallenge(challenge, completionHandler: { (authChallengeDisposition, credential) in
                completionHandler(authChallengeDisposition, credential)
            })
        }
    }
    
    //MARK: - Common
    
    func convertDate(_ dateString: String, format: String) -> NSDate? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        if let date = dateFormatter.date(from: dateString) {
            return date as NSDate
        } else {
            return nil
        }
    }
    
    func encodeUrlString(_ string: String) -> URLConvertible? {
        let allowedCharacterSet = (CharacterSet(charactersIn: " ").inverted)
        if let escapedString = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) {            
            var url: URLConvertible
            do {
                try url = escapedString.asURL()
                return url
            } catch _ {
                return nil
            }
        }
        return nil
    }
    
    func getError(code: Int, description: String) -> Error {
        return NSError(domain: "Nextcloud", code: code, userInfo: [NSLocalizedDescriptionKey : description])
    }
    
    func getError(error: AFError?, httResponse: HTTPURLResponse?) -> (errorCode: Int, description: String?) {
        if let errorCode = httResponse?.statusCode  {
            return(errorCode, httResponse?.description)
        }
        if let error = error {
            switch error {
            case .createUploadableFailed(let error as NSError):
                return(error.code, error.localizedDescription)
            case .createURLRequestFailed(let error as NSError):
                return(error.code, error.localizedDescription)
            case .requestAdaptationFailed(let error as NSError):
                return(error.code, error.localizedDescription)
            case .sessionInvalidated(let error as NSError):
                return(error.code, error.localizedDescription)
            case .sessionTaskFailed(let error as NSError):
                return(error.code, error.localizedDescription)
            default:
                return(error._code, error.localizedDescription)
            }
        }
        return(0,"")
    }
 }
