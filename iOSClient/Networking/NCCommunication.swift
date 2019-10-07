//
//  NCCommunication.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 03/10/2019.
//  Copyright © 2019 TWS. All rights reserved.
//

import Foundation
import Alamofire

class NCCommunication: NSObject {
    
    
    func readFolder(path: String, user: String, password: String) {
        
        // URL
        var url: URLConvertible
        do {
            try url = path.asURL()
        } catch _ {
            return
        }
        
        // Headers
        var headers: HTTPHeaders = [.authorization(username: user, password: password)]
        headers.update(.contentType("application/xml"))

        // Method
        let method = HTTPMethod(rawValue: "PROPFIND")

        AF.request(url, method: method, parameters: [:], encoding: , headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseData { (data) in
            //
        }
    }
}
